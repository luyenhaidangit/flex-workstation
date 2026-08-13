#!/usr/bin/env python3
"""Create a read-only inventory of a .NET repository.

The report combines MSBuild metadata with lightweight C# pattern signals. Signals
are intentionally heuristic and must be verified against the real call path,
configuration, target framework, and runtime behavior before becoming findings.
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
from collections import Counter
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable, Sequence


EXCLUDED_DIRECTORIES = {
    ".git",
    ".idea",
    ".vs",
    ".vscode-test",
    "artifacts",
    "bin",
    "coverage",
    "node_modules",
    "obj",
    "packages",
    "publish",
    "TestResults",
}

GENERATED_SUFFIXES = (
    ".AssemblyAttributes.cs",
    ".AssemblyInfo.cs",
    ".Designer.cs",
    ".Generated.cs",
    ".g.cs",
    ".g.i.cs",
)

CONFIGURATION_NAMES = (
    "global.json",
    "Directory.Build.props",
    "Directory.Build.targets",
    "Directory.Packages.props",
    ".editorconfig",
    "NuGet.Config",
    "nuget.config",
)

PROPERTY_NAMES = (
    "TargetFramework",
    "TargetFrameworks",
    "LangVersion",
    "Nullable",
    "ImplicitUsings",
    "TreatWarningsAsErrors",
    "WarningsAsErrors",
    "EnableNETAnalyzers",
    "AnalysisLevel",
    "AnalysisMode",
    "InvariantGlobalization",
    "PublishAot",
    "PublishTrimmed",
)


@dataclass(frozen=True)
class SignalRule:
    key: str
    category: str
    pattern: re.Pattern[str]
    reason: str


@dataclass(frozen=True)
class Signal:
    key: str
    category: str
    path: str
    line: int
    snippet: str
    reason: str


@dataclass(frozen=True)
class ProjectInfo:
    path: str
    sdk: str
    target_frameworks: list[str]
    output_type: list[str]
    nullable: list[str]
    implicit_usings: list[str]
    lang_version: list[str]
    analyzers: list[str]
    warnings_as_errors: list[str]
    is_test_project: bool
    project_references: list[str]
    package_references: list[dict[str, str]]
    parse_error: str | None = None


SIGNAL_RULES: tuple[SignalRule, ...] = (
    SignalRule(
        "sync-over-async-result",
        "async",
        re.compile(r"\.(?:Result\b|GetAwaiter\(\)\.GetResult\(\))"),
        "Verify that asynchronous work is not synchronously blocking a request or worker thread.",
    ),
    SignalRule(
        "sync-over-async-wait",
        "async",
        re.compile(r"\.Wait\s*\("),
        "Verify that a task wait cannot cause blocking, starvation, or deadlock.",
    ),
    SignalRule(
        "async-void",
        "async",
        re.compile(r"\basync\s+void\b"),
        "Async void is normally valid only for required event-handler signatures.",
    ),
    SignalRule(
        "task-run",
        "async",
        re.compile(r"\bTask\.Run\s*\("),
        "Verify that Task.Run is bounded CPU work and is not disguising blocking server I/O or fire-and-forget work.",
    ),
    SignalRule(
        "thread-sleep",
        "async",
        re.compile(r"\bThread\.Sleep\s*\("),
        "Verify that a thread is not blocked where an asynchronous delay or coordination primitive is required.",
    ),
    SignalRule(
        "new-http-client",
        "http",
        re.compile(r"\bnew\s+HttpClient\s*\("),
        "Verify HttpClient ownership and connection lifetime; server code usually needs a managed long-lived client.",
    ),
    SignalRule(
        "build-service-provider",
        "dependency-injection",
        re.compile(r"\.BuildServiceProvider\s*\("),
        "Verify that registration does not create a second container or duplicate singleton/scoped lifetimes.",
    ),
    SignalRule(
        "service-locator",
        "dependency-injection",
        re.compile(r"\bIServiceProvider\b|\.(?:GetService|GetRequiredService)\s*<"),
        "Verify that service resolution is confined to a composition/framework boundary rather than hiding dependencies.",
    ),
    SignalRule(
        "sensitive-data-logging",
        "security",
        re.compile(r"\.EnableSensitiveDataLogging\s*\("),
        "Verify that sensitive EF Core values cannot be logged in production.",
    ),
    SignalRule(
        "interpolated-raw-sql",
        "security",
        re.compile(r"\b(?:FromSqlRaw|ExecuteSqlRaw|SqlQueryRaw)\s*\(\s*\$[\"@]"),
        "Verify that interpolated raw SQL cannot inject values or identifiers; use parameterized/interpolated-safe APIs.",
    ),
    SignalRule(
        "unsafe-binary-formatter",
        "security",
        re.compile(r"\bBinaryFormatter\b"),
        "BinaryFormatter is unsafe for untrusted input and unsupported in modern .NET; verify and replace its use.",
    ),
    SignalRule(
        "catch-all-exception",
        "errors",
        re.compile(r"\bcatch\s*\(\s*Exception\b"),
        "Catch-all handling can be correct at a boundary; verify it logs/terminates/retries correctly and does not swallow failure.",
    ),
    SignalRule(
        "forced-gc",
        "performance",
        re.compile(r"\bGC\.Collect\s*\("),
        "Forced collection is rarely appropriate in application code; require measured evidence and lifecycle reasoning.",
    ),
    SignalRule(
        "ambient-current-time",
        "testability",
        re.compile(r"\bDateTime(?:Offset)?\.(?:Now|UtcNow)\b"),
        "Verify whether behavior depending on current time should use injected TimeProvider for deterministic tests.",
    ),
    SignalRule(
        "lock-on-public-object",
        "concurrency",
        re.compile(r"\block\s*\(\s*(?:this|typeof\s*\()"),
        "Locking on a publicly reachable object can permit external contention or deadlock; prefer a private lock object.",
    ),
)


def parse_args(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "root",
        nargs="?",
        default=".",
        help="Repository root to inspect (default: current directory).",
    )
    parser.add_argument(
        "--format",
        choices=("markdown", "json"),
        default="markdown",
        dest="output_format",
        help="Report format (default: markdown).",
    )
    parser.add_argument(
        "--max-findings",
        type=int,
        default=100,
        help="Maximum detailed heuristic signals to emit (default: 100).",
    )
    parser.add_argument(
        "--max-file-bytes",
        type=int,
        default=2_000_000,
        help="Skip C# files larger than this many bytes (default: 2000000).",
    )
    return parser.parse_args(argv)


def iter_repository_files(root: Path) -> Iterable[Path]:
    for directory, child_directories, filenames in os.walk(root, followlinks=False):
        child_directories[:] = sorted(
            name
            for name in child_directories
            if name not in EXCLUDED_DIRECTORIES
            and not (Path(directory) / name).is_symlink()
        )
        for filename in sorted(filenames):
            path = Path(directory) / filename
            if not path.is_symlink():
                yield path


def relative(path: Path, root: Path) -> str:
    return path.relative_to(root).as_posix()


def local_name(tag: str) -> str:
    return tag.rsplit("}", 1)[-1]


def distinct(values: Iterable[str]) -> list[str]:
    return sorted({value.strip() for value in values if value and value.strip()})


def element_values(xml_root: ET.Element, name: str) -> list[str]:
    return distinct(
        element.text or ""
        for element in xml_root.iter()
        if local_name(element.tag) == name
    )


def split_frameworks(values: Iterable[str]) -> list[str]:
    frameworks: list[str] = []
    for value in values:
        frameworks.extend(part.strip() for part in value.split(";") if part.strip())
    return distinct(frameworks)


def parse_project(path: Path, root: Path) -> ProjectInfo:
    try:
        xml_root = ET.parse(path).getroot()
    except (ET.ParseError, OSError) as error:
        return ProjectInfo(
            path=relative(path, root),
            sdk="",
            target_frameworks=[],
            output_type=[],
            nullable=[],
            implicit_usings=[],
            lang_version=[],
            analyzers=[],
            warnings_as_errors=[],
            is_test_project=False,
            project_references=[],
            package_references=[],
            parse_error=str(error),
        )

    package_references: list[dict[str, str]] = []
    project_references: list[str] = []
    for element in xml_root.iter():
        tag = local_name(element.tag)
        if tag == "PackageReference":
            package_name = element.attrib.get("Include") or element.attrib.get("Update") or ""
            version = element.attrib.get("Version", "")
            if not version:
                version = next(
                    (
                        child.text or ""
                        for child in element
                        if local_name(child.tag) == "Version"
                    ),
                    "",
                )
            if package_name:
                package_references.append(
                    {"name": package_name.strip(), "version": version.strip()}
                )
        elif tag == "ProjectReference":
            include = element.attrib.get("Include", "").replace("\\", "/")
            if include:
                project_references.append(include)

    package_references.sort(key=lambda package: package["name"].lower())
    package_names = {package["name"].lower() for package in package_references}
    test_markers = {
        "microsoft.net.test.sdk",
        "mstest.testframework",
        "nunit",
        "xunit",
        "tunit",
    }
    is_test_project = any(
        value.lower() == "true" for value in element_values(xml_root, "IsTestProject")
    ) or bool(package_names & test_markers)

    analyzer_names = distinct(
        package["name"]
        for package in package_references
        if "analyzer" in package["name"].lower()
        or package["name"].lower().startswith(("stylecop", "sonaranalyzer"))
    )
    analyzer_names.extend(element_values(xml_root, "EnableNETAnalyzers"))
    analyzer_names.extend(element_values(xml_root, "AnalysisLevel"))

    target_frameworks = split_frameworks(
        element_values(xml_root, "TargetFramework")
        + element_values(xml_root, "TargetFrameworks")
    )

    return ProjectInfo(
        path=relative(path, root),
        sdk=xml_root.attrib.get("Sdk", ""),
        target_frameworks=target_frameworks,
        output_type=element_values(xml_root, "OutputType"),
        nullable=element_values(xml_root, "Nullable"),
        implicit_usings=element_values(xml_root, "ImplicitUsings"),
        lang_version=element_values(xml_root, "LangVersion"),
        analyzers=distinct(analyzer_names),
        warnings_as_errors=distinct(
            element_values(xml_root, "TreatWarningsAsErrors")
            + element_values(xml_root, "WarningsAsErrors")
        ),
        is_test_project=is_test_project,
        project_references=distinct(project_references),
        package_references=package_references,
    )


def parse_msbuild_properties(path: Path) -> dict[str, list[str]]:
    try:
        xml_root = ET.parse(path).getroot()
    except (ET.ParseError, OSError):
        return {}
    return {
        name: values
        for name in PROPERTY_NAMES
        if (values := element_values(xml_root, name))
    }


def parse_global_json(path: Path) -> dict[str, object]:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (OSError, UnicodeError, json.JSONDecodeError):
        return {"parse_error": "Unable to parse global.json"}


def truncate_snippet(line: str, limit: int = 180) -> str:
    compact = " ".join(line.strip().split())
    return compact if len(compact) <= limit else compact[: limit - 1] + "…"


def scan_signals(
    source_files: Iterable[Path],
    root: Path,
    max_file_bytes: int,
) -> tuple[list[Signal], list[str]]:
    signals: list[Signal] = []
    skipped: list[str] = []
    for path in source_files:
        if path.name.endswith(GENERATED_SUFFIXES):
            continue
        try:
            if path.stat().st_size > max_file_bytes:
                skipped.append(relative(path, root))
                continue
            lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
        except OSError:
            skipped.append(relative(path, root))
            continue

        in_block_comment = False
        for line_number, line in enumerate(lines, start=1):
            stripped = line.strip()
            if in_block_comment:
                if "*/" in stripped:
                    in_block_comment = False
                    stripped = stripped.split("*/", 1)[1]
                else:
                    continue
            if stripped.startswith("/*"):
                if "*/" not in stripped[2:]:
                    in_block_comment = True
                    continue
                stripped = stripped.split("*/", 1)[1]
            if not stripped or stripped.startswith("//"):
                continue

            for rule in SIGNAL_RULES:
                if rule.pattern.search(stripped):
                    signals.append(
                        Signal(
                            key=rule.key,
                            category=rule.category,
                            path=relative(path, root),
                            line=line_number,
                            snippet=truncate_snippet(stripped),
                            reason=rule.reason,
                        )
                    )
    return signals, skipped


def collect_report(root: Path, max_file_bytes: int) -> dict[str, object]:
    files = list(iter_repository_files(root))
    projects = [
        parse_project(path, root)
        for path in files
        if path.suffix.lower() in {".csproj", ".fsproj", ".vbproj"}
    ]
    projects.sort(key=lambda project: project.path)

    source_files = [path for path in files if path.suffix.lower() == ".cs"]
    signals, skipped_source_files = scan_signals(source_files, root, max_file_bytes)

    configuration_files = [
        relative(path, root) for path in files if path.name in CONFIGURATION_NAMES
    ]
    solution_files = [
        relative(path, root) for path in files if path.suffix.lower() in {".sln", ".slnx"}
    ]

    msbuild_properties: dict[str, dict[str, list[str]]] = {}
    for path in files:
        if path.name in {"Directory.Build.props", "Directory.Build.targets"}:
            msbuild_properties[relative(path, root)] = parse_msbuild_properties(path)

    global_json = next((path for path in files if path.name == "global.json"), None)
    packages = Counter(
        package["name"]
        for project in projects
        for package in project.package_references
    )

    return {
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "root": str(root),
        "summary": {
            "solutions": len(solution_files),
            "projects": len(projects),
            "test_projects": sum(project.is_test_project for project in projects),
            "csharp_files": len(source_files),
            "heuristic_signals": len(signals),
        },
        "solution_files": sorted(solution_files),
        "configuration_files": sorted(configuration_files),
        "global_json": parse_global_json(global_json) if global_json else None,
        "directory_build_properties": msbuild_properties,
        "projects": [asdict(project) for project in projects],
        "common_packages": [
            {"name": name, "project_count": count}
            for name, count in packages.most_common(20)
        ],
        "signal_counts": dict(sorted(Counter(signal.key for signal in signals).items())),
        "signals": [asdict(signal) for signal in signals],
        "skipped_source_files": sorted(skipped_source_files),
        "notes": [
            "MSBuild conditions and imported properties are listed, not evaluated.",
            "Pattern signals are candidates for review, not confirmed defects.",
            "Generated files and common build/vendor directories are excluded.",
        ],
    }


def markdown_cell(value: object) -> str:
    if value is None:
        return "—"
    if isinstance(value, list):
        text = ", ".join(str(item) for item in value) or "—"
    else:
        text = str(value) or "—"
    return text.replace("|", "\\|").replace("\n", " ")


def limit_signal_details(report: dict[str, object], max_findings: int) -> None:
    signals = report["signals"]
    assert isinstance(signals, list)
    report["omitted_signal_details"] = max(0, len(signals) - max_findings)
    report["signals"] = signals[:max_findings]


def render_markdown(report: dict[str, object], max_findings: int) -> str:
    summary = report["summary"]
    assert isinstance(summary, dict)
    lines = [
        "# .NET repository inventory",
        "",
        f"- Root: `{report['root']}`",
        f"- Generated: `{report['generated_at_utc']}`",
        f"- Solutions: {summary['solutions']}",
        f"- Projects: {summary['projects']} ({summary['test_projects']} test)",
        f"- C# files: {summary['csharp_files']}",
        f"- Heuristic signals: {summary['heuristic_signals']}",
        "",
        "> Signals are review candidates, not confirmed defects. Verify the real call path, configuration, target framework, and runtime behavior.",
        "",
        "## Repository configuration",
        "",
    ]

    solution_files = report["solution_files"]
    configuration_files = report["configuration_files"]
    lines.append("- Solutions: " + (", ".join(f"`{item}`" for item in solution_files) or "none found"))
    lines.append("- Config: " + (", ".join(f"`{item}`" for item in configuration_files) or "none found"))
    if report["global_json"] is not None:
        lines.append("- `global.json`: `" + json.dumps(report["global_json"], sort_keys=True) + "`")

    directory_properties = report["directory_build_properties"]
    assert isinstance(directory_properties, dict)
    for path, properties in directory_properties.items():
        lines.append(f"- `{path}` properties: `{json.dumps(properties, sort_keys=True)}`")

    lines.extend(
        [
            "",
            "## Projects",
            "",
            "| Project | SDK | Target | Nullable | Language | Analyzers | Test |",
            "| --- | --- | --- | --- | --- | --- | --- |",
        ]
    )
    projects = report["projects"]
    assert isinstance(projects, list)
    if not projects:
        lines.append("| _No project files found_ | — | — | — | — | — | — |")
    for project in projects:
        lines.append(
            "| "
            + " | ".join(
                (
                    f"`{project['path']}`",
                    markdown_cell(project["sdk"]),
                    markdown_cell(project["target_frameworks"]),
                    markdown_cell(project["nullable"]),
                    markdown_cell(project["lang_version"]),
                    markdown_cell(project["analyzers"]),
                    "yes" if project["is_test_project"] else "no",
                )
            )
            + " |"
        )
        if project["parse_error"]:
            lines.append(f"\nProject parse error for `{project['path']}`: {project['parse_error']}")

    common_packages = report["common_packages"]
    assert isinstance(common_packages, list)
    if common_packages:
        lines.extend(["", "## Common package references", ""])
        lines.extend(
            f"- `{item['name']}`: {item['project_count']} project(s)"
            for item in common_packages
        )

    signal_counts = report["signal_counts"]
    assert isinstance(signal_counts, dict)
    lines.extend(["", "## Heuristic signal counts", ""])
    if signal_counts:
        lines.extend(f"- `{key}`: {count}" for key, count in signal_counts.items())
    else:
        lines.append("No configured signals found.")

    signals = report["signals"]
    assert isinstance(signals, list)
    lines.extend(["", f"## Signal details (first {max_findings})", ""])
    for signal in signals:
        safe_snippet = str(signal["snippet"]).replace("`", "'")
        lines.extend(
            [
                f"- **{signal['key']}** at `{signal['path']}:{signal['line']}`",
                f"  - Code: `{safe_snippet}`",
                f"  - Review: {signal['reason']}",
            ]
        )
    omitted_signal_details = report["omitted_signal_details"]
    assert isinstance(omitted_signal_details, int)
    if omitted_signal_details:
        lines.append(f"\n{omitted_signal_details} additional signal(s) omitted.")

    skipped = report["skipped_source_files"]
    assert isinstance(skipped, list)
    if skipped:
        lines.extend(["", "## Skipped C# files", ""])
        lines.extend(f"- `{path}`" for path in skipped)

    lines.extend(["", "## Interpretation notes", ""])
    lines.extend(f"- {note}" for note in report["notes"])
    return "\n".join(lines) + "\n"


def main(argv: Sequence[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])
    if args.max_findings < 0 or args.max_file_bytes < 1:
        print("--max-findings must be non-negative and --max-file-bytes must be positive.", file=sys.stderr)
        return 2

    root = Path(args.root).expanduser().resolve()
    if not root.is_dir():
        print(f"Repository root is not a directory: {root}", file=sys.stderr)
        return 2

    report = collect_report(root, args.max_file_bytes)
    limit_signal_details(report, args.max_findings)
    if args.output_format == "json":
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(render_markdown(report, args.max_findings), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
