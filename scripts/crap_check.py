#!/usr/bin/env python3
"""CRAP score analysis for the jpc.fit.native app.

CRAP = complexity^2 * (1 - coverage)^3 + complexity

Reads an xccov JSON report (produced by `xcrun xccov view --report --json`),
computes per-function cyclomatic complexity by counting real decision points in
the function's source span, and fails if the average exceeds the threshold.

Why count decision points instead of `lines / N`: SwiftUI view `body` getters
are long but flat (declarative view trees with almost no branching). A
line-count proxy mislabels them as highly complex and produces false CRAP
failures even at 100% coverage. Counting actual branches (if/guard/switch/for/
while/&&/||/?:/catch) measures the cyclomatic complexity CRAP is defined on.

Usage:
    xcrun xccov view --report --json TestResults.xcresult > coverage.json
    python3 scripts/crap_check.py coverage.json
"""
from __future__ import annotations

import json
import re
import sys

CRAP_THRESHOLD = 30
MIN_LINES = 5  # Skip trivial accessors/wrappers where complexity is just noise.

# Tokens that each add one independent path (McCabe cyclomatic complexity).
DECISION_RE = re.compile(
    r"\b(if|guard|for|while|case|catch)\b|&&|\|\||\?\?|(?<![?\w])\?(?!\?)"
)

# Only measure files under the app source tree.
SRC_MARKERS = (
    "/jpc.fit.native/jpc.fit.native/",
    "/jpc.fit.native/Services/",
    "/jpc.fit.native/ViewModels/",
    "/jpc.fit.native/Views/",
    "/jpc.fit.native/Constants/",
    "/jpc.fit.native/Models/",
)


def complexity_for_span(lines: list[str]) -> int:
    """1 + number of decision points found in the source span."""
    decisions = 0
    for line in lines:
        code = line.split("//", 1)[0]
        decisions += len(DECISION_RE.findall(code))
    return 1 + decisions


def crap(complexity: int, coverage: float) -> float:
    return complexity ** 2 * (1 - coverage) ** 3 + complexity


def load_source(path: str, cache: dict) -> list[str] | None:
    if path not in cache:
        try:
            with open(path) as f:
                cache[path] = f.read().splitlines()
        except OSError:
            cache[path] = None
    return cache[path]


def included(path: str) -> bool:
    if not any(m in path for m in SRC_MARKERS):
        return False
    if "Tests/" in path or "DerivedData" in path or "SourcePackages" in path:
        return False
    if "AmplifyModels/" in path or "widget" in path.lower() or "watchkit" in path.lower():
        return False
    return True


def main(path: str) -> int:
    with open(path) as f:
        data = json.load(f)

    source_cache: dict = {}
    results = []

    for target in data.get("targets", []):
        name = target.get("name", "")
        if "Tests" in name or "UITests" in name:
            continue
        for file in target.get("files", []):
            file_path = file.get("path", "")
            if not included(file_path):
                continue
            fname = file_path.split("/")[-1]
            src = load_source(file_path, source_cache)

            funcs = sorted(file.get("functions", []), key=lambda fn: fn.get("lineNumber", 0))
            for i, func in enumerate(funcs):
                lines = func.get("executableLines", 0)
                if lines < MIN_LINES:
                    continue
                covered = func.get("coveredLines", 0)
                cov = covered / lines if lines > 0 else 0.0

                if src is not None:
                    start = func.get("lineNumber", 1) - 1
                    end = funcs[i + 1].get("lineNumber", len(src) + 1) - 1 if i + 1 < len(funcs) else len(src)
                    complexity = complexity_for_span(src[start:end])
                else:
                    complexity = max(1, lines // 3)

                score = crap(complexity, cov)
                results.append((func.get("name", ""), fname, cov * 100, complexity, lines, score))

    results.sort(key=lambda r: -r[5])
    total = len(results)
    avg = sum(r[5] for r in results) / total if total else 0.0
    over = sum(1 for r in results if r[5] > CRAP_THRESHOLD)

    print(f"Analyzed {total} functions. Average CRAP: {avg:.1f}")
    print(f"Methods over {CRAP_THRESHOLD}: {over}/{total}")
    print("\nTop 10 highest CRAP:")
    for name, fname, cov, cx, lines, score in results[:10]:
        print(f"  {fname}: {name[:42]:<42} CRAP={score:6.1f}  cx={cx:<3} cov={cov:5.1f}%")

    if avg > CRAP_THRESHOLD:
        print(f"\n❌ FAIL: Average CRAP {avg:.1f} exceeds threshold of {CRAP_THRESHOLD}")
        return 1
    print(f"\n✅ PASS: Average CRAP {avg:.1f} ≤ {CRAP_THRESHOLD}")
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: crap_check.py <coverage.json>", file=sys.stderr)
        sys.exit(2)
    sys.exit(main(sys.argv[1]))
