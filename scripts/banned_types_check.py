#!/usr/bin/env python3
"""Ban weakly-typed declarations in app code (deterministic, no build needed).

Flags `Any` / `AnyObject` in Swift source, EXCEPT the two bridging idioms this
codebase can't avoid:
  - `[String: Any]` / `[[String: Any]]` — required by Amplify GraphQL
    `variables:` and Apple's WCSession message dictionaries.
  - `as? [...: Any]` downcasts when reading those same dictionaries.

Everything else (`Any` parameters/returns/properties, `AnyObject`, bare
`as? Any`, `Any...`) fails: reach for a concrete type or a generic instead.

Scans app + watch + widget sources; generated AmplifyModels and tests exempt.

Usage: python3 scripts/banned_types_check.py
"""
from __future__ import annotations

import re
import subprocess
import sys

ALLOWED = [
    re.compile(r"\[\s*String\s*:\s*Any\s*\]"),  # [String: Any] bridging
]
BANNED = re.compile(r"\bAny(Object)?\b")
STRING_RE = re.compile(r'"(?:[^"\\]|\\.)*"')
COMMENT_RE = re.compile(r"//.*$")


def swift_files() -> list[str]:
    out = subprocess.run(
        ["git", "ls-files", "*.swift"], capture_output=True, text=True, check=True
    ).stdout.splitlines()
    return [
        f for f in out
        if "AmplifyModels" not in f and "Tests" not in f and "UITests" not in f
    ]


def violations_in(path: str) -> list[tuple[int, str]]:
    found = []
    with open(path, encoding="utf-8") as fh:
        for lineno, raw in enumerate(fh, 1):
            line = COMMENT_RE.sub("", STRING_RE.sub('""', raw))
            stripped = line
            for pat in ALLOWED:
                stripped = pat.sub("", stripped)
            if BANNED.search(stripped):
                found.append((lineno, raw.rstrip()))
    return found


def main() -> int:
    bad = 0
    for f in swift_files():
        for lineno, line in violations_in(f):
            print(f"❌ {f}:{lineno}: banned `Any`/`AnyObject`: {line.strip()}")
            bad += 1
    if bad:
        print(f"\n❌ FAIL: {bad} weakly-typed declaration(s). Use a concrete type "
              f"or generic; `[String: Any]` is allowed only as framework bridging.")
        return 1
    print("✅ PASS: no banned `Any`/`AnyObject` usage")
    return 0


if __name__ == "__main__":
    sys.exit(main())
