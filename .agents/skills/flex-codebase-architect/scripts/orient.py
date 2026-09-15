#!/usr/bin/env python3
"""
orient.py — Repo orientation for the codebase-architect skill.

Run this FIRST, before editing anything, to answer "where does this code go?"
without guessing. It is read-only and language-agnostic (pure stdlib), so it is
safe to run on any project.

What it reports:
  1. A compact directory tree (noise like node_modules/.git/venv excluded).
  2. The largest source files — candidate "god objects" you should NOT grow.
  3. File-count per top-level area, so you can see where the codebase's weight is.
  4. Detected conventions: dominant languages, test layout, and naming style.

Usage:
    python orient.py [REPO_ROOT] [--depth N] [--top N]

    REPO_ROOT   directory to inspect (default: current directory)
    --depth N   max tree depth to print (default: 3)
    --top N     how many largest files to list (default: 12)

Interpretation guide for the model:
  - Put new code BESIDE the most similar existing files shown in the tree.
  - Treat any file near/over ~400 lines as a god-object risk: add new
    responsibilities in a new focused unit rather than swelling it.
  - Match the detected test layout and naming style; do not invent a new one.
"""

import argparse
import os
import re
import sys
from collections import Counter
from pathlib import Path

# Directories that are never the right place for new product code and only add
# noise to orientation. Excluded from the tree and from all counts.
IGNORE_DIRS = {
    ".git", ".hg", ".svn", "node_modules", "venv", ".venv", "env",
    "__pycache__", ".mypy_cache", ".pytest_cache", ".ruff_cache",
    "dist", "build", "out", "target", ".next", ".nuxt", ".cache",
    "coverage", ".idea", ".vscode", ".gradle", "vendor", "Pods",
    "__snapshots__", ".terraform",
}

# Extensions we treat as "source" for the god-object / language analysis.
SOURCE_EXT = {
    ".py", ".js", ".jsx", ".ts", ".tsx", ".go", ".rb", ".java", ".kt",
    ".rs", ".php", ".cs", ".swift", ".scala", ".c", ".cc", ".cpp", ".h",
    ".hpp", ".m", ".mm", ".vue", ".svelte", ".clj", ".ex", ".exs",
}

# Rough god-object threshold in lines. Mirrors the SKILL.md heuristic (~400).
BIG_FILE_LINES = 400


def is_ignored(path: Path, root: Path) -> bool:
    rel = path.relative_to(root)
    return any(part in IGNORE_DIRS for part in rel.parts)


def count_lines(path: Path) -> int:
    try:
        with path.open("rb") as fh:
            return sum(1 for _ in fh)
    except OSError:
        return 0


def print_tree(root: Path, max_depth: int) -> None:
    print(f"\n# Directory tree (depth {max_depth}, noise dirs hidden)\n")
    print(f"{root.name}/")

    def walk(dir_path: Path, prefix: str, depth: int) -> None:
        if depth > max_depth:
            return
        try:
            entries = sorted(
                (e for e in dir_path.iterdir() if e.name not in IGNORE_DIRS),
                key=lambda e: (e.is_file(), e.name.lower()),
            )
        except OSError:
            return
        dirs = [e for e in entries if e.is_dir()]
        files = [e for e in entries if e.is_file()]
        # Show all dirs, but cap files per directory to keep output readable.
        shown_files = files[:8]
        items = dirs + shown_files
        for i, entry in enumerate(items):
            last = i == len(items) - 1
            connector = "└── " if last else "├── "
            suffix = "/" if entry.is_dir() else ""
            print(f"{prefix}{connector}{entry.name}{suffix}")
            if entry.is_dir():
                extension = "    " if last else "│   "
                walk(entry, prefix + extension, depth + 1)
        if len(files) > len(shown_files):
            print(f"{prefix}    … (+{len(files) - len(shown_files)} more files)")

    walk(root, "", 1)


def analyze(root: Path, top_n: int) -> None:
    source_files: list[tuple[int, Path]] = []
    ext_counter: Counter[str] = Counter()
    area_counter: Counter[str] = Counter()
    test_dirs: set[str] = set()
    test_file_patterns: Counter[str] = Counter()
    naming_styles: Counter[str] = Counter()

    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in IGNORE_DIRS]
        d = Path(dirpath)
        if is_ignored(d, root) and d != root:
            continue
        rel = d.relative_to(root)
        top_area = rel.parts[0] if rel.parts else "."
        for name in filenames:
            fpath = d / name
            ext = fpath.suffix.lower()
            if ext not in SOURCE_EXT:
                continue
            ext_counter[ext] += 1
            area_counter[top_area] += 1
            lines = count_lines(fpath)
            source_files.append((lines, fpath))

            lower = name.lower()
            if "test" in lower or "spec" in lower:
                # Capture where tests live and how they're named.
                if "tests" in rel.parts or "test" in rel.parts or "__tests__" in rel.parts:
                    test_dirs.add(str(rel.parts[0]) if rel.parts else ".")
                stem = fpath.stem
                if stem.startswith("test_"):
                    test_file_patterns["test_*.py"] += 1
                elif stem.endswith("_test"):
                    test_file_patterns["*_test.*"] += 1
                elif ".test" in lower or ".spec" in lower:
                    test_file_patterns["*.test/*.spec.*"] += 1

            # Naming style of the file stem (snake / kebab / camel / Pascal).
            stem = fpath.stem
            if "_" in stem:
                naming_styles["snake_case"] += 1
            elif "-" in stem:
                naming_styles["kebab-case"] += 1
            elif re.match(r"^[A-Z][a-zA-Z0-9]*$", stem):
                naming_styles["PascalCase"] += 1
            elif re.match(r"^[a-z][a-zA-Z0-9]*$", stem) and re.search(r"[A-Z]", stem):
                naming_styles["camelCase"] += 1

    # --- Largest files (god-object candidates) ---
    print(f"\n# Largest source files (god-object risk ≥ {BIG_FILE_LINES} lines flagged)\n")
    source_files.sort(reverse=True)
    if not source_files:
        print("(no recognized source files found)")
    for lines, fpath in source_files[:top_n]:
        flag = "  ⚠ GOD-OBJECT RISK" if lines >= BIG_FILE_LINES else ""
        print(f"  {lines:>6}  {fpath.relative_to(root)}{flag}")

    # --- Weight per top-level area ---
    print("\n# Source files per top-level area\n")
    for area, n in area_counter.most_common():
        print(f"  {n:>5}  {area}/")

    # --- Detected conventions ---
    print("\n# Detected conventions\n")
    if ext_counter:
        langs = ", ".join(f"{e} ({n})" for e, n in ext_counter.most_common(5))
        print(f"  Dominant source types : {langs}")
    if test_dirs:
        print(f"  Tests live under      : {', '.join(sorted(test_dirs))}")
    if test_file_patterns:
        pat = ", ".join(f"{p} ({n})" for p, n in test_file_patterns.most_common())
        print(f"  Test file naming      : {pat}")
    if naming_styles:
        dominant = naming_styles.most_common(1)[0][0]
        mix = ", ".join(f"{s} ({n})" for s, n in naming_styles.most_common())
        print(f"  File naming style     : {dominant} dominant  [{mix}]")
    print()
    print("  → Place new code beside its closest existing siblings above.")
    print("  → Match the dominant naming and test layout; do not invent a new one.")
    print(f"  → Do not add responsibilities to files near/over {BIG_FILE_LINES} lines.")


def main() -> int:
    ap = argparse.ArgumentParser(description="Orient in a codebase before editing.")
    ap.add_argument("root", nargs="?", default=".", help="repo root (default: .)")
    ap.add_argument("--depth", type=int, default=3, help="tree depth (default: 3)")
    ap.add_argument("--top", type=int, default=12, help="largest-files to list")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"error: {root} is not a directory", file=sys.stderr)
        return 1

    print(f"Orienting in: {root}")
    print_tree(root, args.depth)
    analyze(root, args.top)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
