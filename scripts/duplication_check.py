#!/usr/bin/env python3
"""Duplicate-code gate: repeated normalized line blocks across app sources.

Slides a WINDOW-line window over every app Swift file (comments/blank lines
stripped, whitespace collapsed, string literals canonicalized) and flags any
block appearing in two places. Identifier names are NOT normalized — this
catches copy-paste, not structural similarity, which keeps it deterministic
and low-noise.

Usage: python3 scripts/duplication_check.py
"""
from __future__ import annotations

import re
import subprocess
import sys
from collections import defaultdict

WINDOW = 6  # consecutive significant lines that must match to count
STRING_RE = re.compile(r'"(?:[^"\\]|\\.)*"')
COMMENT_RE = re.compile(r"//.*$")
BOILERPLATE = re.compile(r"^[}{)\]]*$|^import\b|^@|^(?:public |private |internal )?(?:var|let) \w+: (?:String|Int|Bool|Double)$")


def swift_files() -> list[str]:
    out = subprocess.run(["git", "ls-files", "*.swift"], capture_output=True, text=True, check=True).stdout.splitlines()
    return [f for f in out if "AmplifyModels" not in f and "Tests" not in f
            and "UITests" not in f and ".generated." not in f]


def significant_lines(path: str) -> list[tuple[int, str]]:
    result = []
    with open(path, encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = COMMENT_RE.sub("", STRING_RE.sub('"S"', raw)).strip()
            line = re.sub(r"\s+", " ", line)
            if not line or BOILERPLATE.match(line):
                continue
            result.append((lineno, line))
    return result


def main() -> int:
    blocks: dict[tuple[str, ...], list[tuple[str, int]]] = defaultdict(list)
    for f in swift_files():
        lines = significant_lines(f)
        for i in range(len(lines) - WINDOW + 1):
            key = tuple(line for _, line in lines[i:i + WINDOW])
            blocks[key].append((f, lines[i][0]))

    # Collapse overlapping windows: report each duplicated *run* once, keyed
    # by its first window's locations.
    reported: set[tuple[str, int]] = set()
    dupes = 0
    for key, sites in blocks.items():
        distinct = sorted(set(sites))
        if len(distinct) < 2:
            continue
        if any((f, n) in reported for f, n in distinct):
            continue
        for f, n in distinct:
            for off in range(WINDOW):
                reported.add((f, n + off))
        dupes += 1
        locs = ", ".join(f"{f}:{n}" for f, n in distinct)
        print(f"❌ duplicated {WINDOW}-line block at: {locs}")
        print(f"     starts: {key[0][:80]}")

    if dupes:
        print(f"\n❌ FAIL: {dupes} duplicated block(s) — extract a shared helper.")
        return 1
    print("✅ PASS: no duplicated blocks")
    return 0


if __name__ == "__main__":
    sys.exit(main())
