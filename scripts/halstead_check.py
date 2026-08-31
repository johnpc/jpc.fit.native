#!/usr/bin/env python3
"""Halstead difficulty gate for Swift functions (deterministic, no build).

Difficulty D = (n1 / 2) * (N2 / n2), where n1 = distinct operators,
n2 = distinct operands, N2 = total operand occurrences. High D marks code
where many distinct operators grind over few operands — dense, error-prone
expressions. Per-function threshold: fail if any function exceeds MAX_D.

Function spans are found by brace matching from each `func`/computed-var
declaration. Strings and comments are stripped before counting. Generated
AmplifyModels and test targets are exempt.

Usage: python3 scripts/halstead_check.py
"""
from __future__ import annotations

import math
import re
import subprocess
import sys

MAX_D = 20.0
MIN_TOKENS = 20  # skip trivial bodies where D is noise

OPERATORS = re.compile(
    r"&&|\|\||\?\?|==|!=|<=|>=|\+=|-=|\*=|/=|->|\.\.\.|\.\.<|"
    r"[-+*/%=<>!&|^~?:]|\b(if|guard|else|for|while|switch|case|return|throw|"
    r"try|await|async|catch|defer|break|continue|in|is|as|let|var|func)\b"
)
OPERANDS = re.compile(r'\b(?!(?:if|guard|else|for|while|switch|case|return|throw|'
                      r'try|await|async|catch|defer|break|continue|in|is|as|let|var|func)\b)'
                      r'[A-Za-z_][A-Za-z0-9_]*\b|\b\d+(?:\.\d+)?\b')
STRING_RE = re.compile(r'"(?:[^"\\]|\\.)*"')
COMMENT_RE = re.compile(r"//.*$")
FUNC_RE = re.compile(r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|private|internal|"
                     r"fileprivate|open|static|class|final|override|nonisolated|"
                     r"mutating|convenience|required)\s+)*(?:func\s+(\w+)|var\s+(\w+)[^=\n]*\{)")


def swift_files() -> list[str]:
    out = subprocess.run(["git", "ls-files", "*.swift"], capture_output=True, text=True, check=True).stdout.splitlines()
    return [f for f in out if "AmplifyModels" not in f and "Tests" not in f and "UITests" not in f]


def strip(line: str) -> str:
    return COMMENT_RE.sub("", STRING_RE.sub('"S"', line))


def function_spans(lines: list[str]):
    """Yield (name, start, end) for each brace-balanced func/computed-var body."""
    i = 0
    while i < len(lines):
        m = FUNC_RE.match(strip(lines[i]))
        if not m:
            i += 1
            continue
        name = m.group(1) or m.group(2)
        depth = 0
        opened = False
        j = i
        while j < len(lines):
            for ch in strip(lines[j]):
                if ch == "{":
                    depth += 1
                    opened = True
                elif ch == "}":
                    depth -= 1
            if opened and depth <= 0:
                break
            j += 1
        yield name, i, min(j + 1, len(lines))
        i = j + 1


def difficulty(body: list[str]) -> tuple[float, int]:
    ops: dict[str, int] = {}
    opnds: dict[str, int] = {}
    for raw in body:
        line = strip(raw)
        for m in OPERATORS.finditer(line):
            ops[m.group(0)] = ops.get(m.group(0), 0) + 1
        for m in OPERANDS.finditer(line):
            opnds[m.group(0)] = opnds.get(m.group(0), 0) + 1
    n1, n2 = len(ops), len(opnds)
    total = sum(ops.values()) + sum(opnds.values())
    if n2 == 0:
        return 0.0, total
    return (n1 / 2) * (sum(opnds.values()) / n2), total


def main() -> int:
    worst: list[tuple[float, str, str]] = []
    failures = 0
    for f in swift_files():
        with open(f, encoding="utf-8") as fh:
            lines = fh.read().splitlines()
        for name, start, end in function_spans(lines):
            d, tokens = difficulty(lines[start:end])
            if tokens < MIN_TOKENS:
                continue
            worst.append((d, f, f"{name} (line {start + 1})"))
            if d > MAX_D:
                print(f"❌ {f}:{start + 1}: `{name}` Halstead difficulty {d:.1f} > {MAX_D}")
                failures += 1
    worst.sort(reverse=True)
    print("\nTop 5 hardest functions:")
    for d, f, name in worst[:5]:
        print(f"  D={d:5.1f}  {f.split('/')[-1]}: {name}")
    if failures:
        print(f"\n❌ FAIL: {failures} function(s) over difficulty {MAX_D} — split dense "
              f"expressions into named intermediate steps.")
        return 1
    print(f"\n✅ PASS: all functions ≤ Halstead difficulty {MAX_D}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
