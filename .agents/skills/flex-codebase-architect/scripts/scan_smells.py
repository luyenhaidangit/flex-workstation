#!/usr/bin/env python3
"""
scan_smells.py — Completion-gate scanner for codebase-architect.

Run this on the files you TOUCHED (or staged) before declaring a change done.
It is a heuristic, read-only linter for the architectural smells the skill
exists to prevent. It will produce some false positives — that is intentional:
it flags things for you to consciously confirm or fix, it does not auto-edit.

Checks:
  1. Hardcoded literals in logic — magic numbers, inline URLs/IPs, environment
     names ("us-east-1", "prod") that usually belong in config/constants.
  2. Possible secrets — token/key/password-shaped strings in source.
  3. God objects — files near/over the line threshold.
  4. TODO/FIXME/HACK markers — so deliberate debt is visible and gets a trigger.

Usage:
    python scan_smells.py [PATHS ...] [--max-lines 400]

    PATHS         files or directories to scan (default: current directory)
    --max-lines   god-object line threshold (default: 400)

Pure stdlib. Exit code is always 0 (findings are advisory, not a hard failure).
"""

import argparse
import re
import sys
from pathlib import Path

IGNORE_DIRS = {
    ".git", "node_modules", "venv", ".venv", "__pycache__", "dist", "build",
    "out", "target", ".next", ".cache", "coverage", "vendor", "Pods",
}
SOURCE_EXT = {
    ".py", ".js", ".jsx", ".ts", ".tsx", ".go", ".rb", ".java", ".kt",
    ".rs", ".php", ".cs", ".swift", ".scala", ".vue", ".svelte",
}

# --- Heuristics --------------------------------------------------------------

URL_RE = re.compile(r"https?://[^\s\"'`)]+", re.IGNORECASE)
IP_RE = re.compile(r"\b(?:\d{1,3}\.){3}\d{1,3}\b")
# Magic number in logic: a bare numeric literal that isn't 0/1/2/-1/100 and
# isn't part of an obvious version/array index. Crude on purpose.
MAGIC_NUM_RE = re.compile(r"(?<![\w.])-?\d{3,}(?:\.\d+)?(?![\w.])")
ENV_NAME_RE = re.compile(
    r"\"(?:us|eu|ap|sa|ca)-[a-z]+-\d\"|"            # AWS region literals
    r"\b\"(prod|production|staging|stage|dev|development|qa|uat)\"",
    re.IGNORECASE,
)
# Secret-shaped assignments. Looks for key-ish names bound to a long literal.
SECRET_RE = re.compile(
    r"(?i)(api[_-]?key|secret|token|passwd|password|access[_-]?key|"
    r"private[_-]?key|client[_-]?secret|bearer)\s*[:=]\s*"
    r"[\"'][A-Za-z0-9_\-+/=]{12,}[\"']"
)
DEBT_RE = re.compile(r"\b(TODO|FIXME|HACK|XXX)\b")

# Lines that are clearly config/constant declarations are EXEMPT from the
# hardcoding check — a literal living in a named constant is the desired fix,
# not a smell.
CONST_DECL_RE = re.compile(
    r"^\s*(const\s+[A-Z0-9_]+|[A-Z][A-Z0-9_]{2,}\s*[:=]|export\s+const\s+[A-Z0-9_]+)"
)
COMMENT_PREFIXES = ("#", "//", "*", "/*", "<!--")


def iter_targets(paths: list[str]):
    for p in paths:
        path = Path(p)
        if path.is_file():
            yield path
        elif path.is_dir():
            for f in path.rglob("*"):
                if f.is_file() and f.suffix.lower() in SOURCE_EXT:
                    if not any(part in IGNORE_DIRS for part in f.parts):
                        yield f


def is_commentish(line: str) -> bool:
    s = line.strip()
    return s.startswith(COMMENT_PREFIXES)


def scan_file(path: Path, max_lines: int, findings: dict) -> None:
    try:
        text = path.read_text(errors="ignore")
    except OSError:
        return
    lines = text.splitlines()

    if len(lines) >= max_lines:
        findings["god"].append((path, len(lines)))

    for i, line in enumerate(lines, 1):
        if SECRET_RE.search(line):
            findings["secret"].append((path, i, line.strip()[:100]))
            # Don't double-report a secret line as a magic number/URL.
            continue
        comment = is_commentish(line)
        if not comment and CONST_DECL_RE.search(line):
            continue  # named constant: the good outcome, skip.
        if URL_RE.search(line) and not comment:
            findings["url"].append((path, i, line.strip()[:100]))
        if ENV_NAME_RE.search(line) and not comment:
            findings["env"].append((path, i, line.strip()[:100]))
        if not comment and MAGIC_NUM_RE.search(line) and not IP_RE.search(line):
            # Skip obvious non-logic lines (imports, simple assignments to a name
            # that is already uppercase handled above).
            if not re.match(r"^\s*(import|from|#|//)", line):
                findings["magic"].append((path, i, line.strip()[:100]))
        if DEBT_RE.search(line):
            findings["debt"].append((path, i, line.strip()[:100]))


def report(title: str, items, advice: str) -> None:
    if not items:
        return
    print(f"\n## {title}  ({len(items)})")
    print(f"   → {advice}")
    for entry in items[:40]:
        if len(entry) == 2:  # god object
            path, n = entry
            print(f"   {path}  — {n} lines")
        else:
            path, lineno, snippet = entry
            print(f"   {path}:{lineno}  {snippet}")
    if len(items) > 40:
        print(f"   … (+{len(items) - 40} more)")


def main() -> int:
    ap = argparse.ArgumentParser(description="Scan touched files for architectural smells.")
    ap.add_argument("paths", nargs="*", default=["."], help="files/dirs (default: .)")
    ap.add_argument("--max-lines", type=int, default=400, help="god-object threshold")
    args = ap.parse_args()

    findings = {"secret": [], "url": [], "env": [], "magic": [], "god": [], "debt": []}
    targets = list(iter_targets(args.paths))
    if not targets:
        print("No source files matched the given paths.", file=sys.stderr)
        return 0

    for path in targets:
        scan_file(path, args.max_lines, findings)

    print(f"Scanned {len(targets)} file(s) for architectural smells.")

    report(
        "Possible secrets in source", findings["secret"],
        "Secrets NEVER belong in source. Move to env/secret manager immediately.",
    )
    report(
        "Inline URLs / endpoints", findings["url"],
        "Endpoints vary by environment — externalize to config, not a literal.",
    )
    report(
        "Environment / region literals", findings["env"],
        "Env- or region-specific values belong in config, not branch conditions.",
    )
    report(
        "Magic numbers in logic", findings["magic"],
        "Name these as constants so the reader knows what the value MEANS.",
    )
    report(
        "God-object candidates", findings["god"],
        "Do not add new responsibilities here; create a new focused unit.",
    )
    report(
        "Debt markers", findings["debt"],
        "Each should appear in your Debt & Follow-ups with a revisit trigger.",
    )

    total = sum(len(v) for v in findings.values())
    if total == 0:
        print("\nNo smells detected by the heuristics. Still apply human judgment.")
    else:
        print(f"\n{total} item(s) to review. These are heuristics — confirm or justify each.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
