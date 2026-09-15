#!/usr/bin/env python3
"""
find_similar.py — Search-before-you-synthesize helper for codebase-architect.

The skill's core rule is "assume the behavior you're about to write already
exists." This script grounds that rule: before adding a function/endpoint/
service, search the repo for prior art by INTENT (a verb + a noun), not just by
exact name. It returns ranked candidate locations so you can decide to reuse,
extend, or (with a stated reason) write new.

It is read-only and pure stdlib.

Usage:
    python find_similar.py TERM [TERM ...] [--root DIR] [--ext .py,.ts]

    TERM        words describing the behavior, e.g.  send receipt email
                (order doesn't matter; each term is matched independently)
    --root DIR  repo root (default: current directory)
    --ext       comma-separated extensions to restrict the search
    --max N     max matching files to show (default: 25)

Scoring: a file scores higher when more of your terms appear in it, and higher
still when terms appear in a DEFINITION line (def/function/class/func/fn/method)
rather than only in a comment or string. The goal is to surface the place that
already does ~80% of the job so you extend it instead of forking a near-copy.

Example:
    python find_similar.py notify user --ext .py,.ts
    → ranks files that define notification/user behavior so you can reuse them.
"""

import argparse
import re
import sys
from pathlib import Path

IGNORE_DIRS = {
    ".git", ".hg", ".svn", "node_modules", "venv", ".venv", "env",
    "__pycache__", ".mypy_cache", ".pytest_cache", "dist", "build", "out",
    "target", ".next", ".cache", "coverage", "vendor", "Pods", ".terraform",
}

# Lines that declare a callable/type in common languages. A hit on one of these
# is worth much more than a hit in prose, because it means the behavior is
# actually implemented here, not merely mentioned.
DEF_RE = re.compile(
    r"\b(def|function|func|fn|class|interface|type|struct|trait|module|"
    r"public|private|protected|export|const|let|var)\b",
    re.IGNORECASE,
)

DEFAULT_EXT = {
    ".py", ".js", ".jsx", ".ts", ".tsx", ".go", ".rb", ".java", ".kt",
    ".rs", ".php", ".cs", ".swift", ".scala", ".vue", ".svelte", ".ex",
}


def iter_source_files(root: Path, exts: set[str]):
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        if any(part in IGNORE_DIRS for part in path.relative_to(root).parts):
            continue
        if path.suffix.lower() in exts:
            yield path


def score_file(path: Path, terms: list[str]):
    """Return (score, matched_terms, sample_lines) or None if no term matches."""
    try:
        text = path.read_text(errors="ignore")
    except OSError:
        return None
    lines = text.splitlines()
    matched = set()
    score = 0
    samples: list[tuple[int, str]] = []
    patterns = {t: re.compile(re.escape(t), re.IGNORECASE) for t in terms}
    for lineno, line in enumerate(lines, 1):
        hit_here = [t for t, pat in patterns.items() if pat.search(line)]
        if not hit_here:
            continue
        matched.update(hit_here)
        is_def = bool(DEF_RE.search(line))
        # Definition lines count 3x; multiple terms on one line compound.
        score += len(hit_here) * (3 if is_def else 1)
        if len(samples) < 4 and (is_def or len(samples) < 2):
            samples.append((lineno, line.strip()[:120]))
    if not matched:
        return None
    # Bonus for covering MORE of the requested terms in one file — that's the
    # signal of "this place already does most of the job."
    score += len(matched) * 5
    return score, matched, samples


def main() -> int:
    ap = argparse.ArgumentParser(description="Find existing implementations by intent.")
    ap.add_argument("terms", nargs="+", help="verb/noun words describing the behavior")
    ap.add_argument("--root", default=".", help="repo root (default: .)")
    ap.add_argument("--ext", default="", help="comma-separated extensions, e.g. .py,.ts")
    ap.add_argument("--max", type=int, default=25, help="max files to show")
    args = ap.parse_args()

    root = Path(args.root).resolve()
    if not root.is_dir():
        print(f"error: {root} is not a directory", file=sys.stderr)
        return 1

    if args.ext.strip():
        exts = {e if e.startswith(".") else f".{e}" for e in args.ext.split(",") if e.strip()}
    else:
        exts = DEFAULT_EXT

    terms = [t for t in args.terms if t.strip()]
    results = []
    for path in iter_source_files(root, exts):
        scored = score_file(path, terms)
        if scored:
            results.append((scored[0], path, scored[1], scored[2]))

    results.sort(key=lambda r: r[0], reverse=True)

    print(f"Searching {root} for intent: {' + '.join(terms)}")
    print(f"(higher score = covers more terms, esp. in definitions)\n")
    if not results:
        print("No prior art found. This may genuinely be new behavior —")
        print("but double-check synonyms before deciding to write from scratch.")
        return 0

    full = sum(1 for r in results if r[2] == set(terms))
    if full:
        print(f"★ {full} file(s) match ALL terms — inspect these first for reuse/extend.\n")

    for score, path, matched, samples in results[: args.max]:
        cover = f"{len(matched)}/{len(terms)} terms"
        print(f"[{score:>4}] {path.relative_to(root)}  ({cover}: {', '.join(sorted(matched))})")
        for lineno, snippet in samples:
            print(f"         {lineno}: {snippet}")
    if len(results) > args.max:
        print(f"\n… (+{len(results) - args.max} more files, raise --max to see them)")

    print("\nDecision: if a top hit does ~80% of the job, EXTEND/parameterize it")
    print("rather than writing a near-duplicate. Fork only if the cases truly diverge.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
