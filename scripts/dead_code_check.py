#!/usr/bin/env python3
"""Dead-code gate: top-level Swift declarations that nothing references.

For each type/func/extension-member declared in app code, count references to
its name anywhere else in the app, watch, widget, or test sources (declaration
site excluded). Zero references = dead. Names with runtime/framework entry
points that the compiler can't see (App/Widget @main, SwiftUI previews,
protocol witnesses like WCSessionDelegate methods, XCTest methods) are
skipped via ENTRY_POINTS.

Deterministic and dependency-free by design — a name-reference scan, not full
semantic analysis. It will miss dead *members* whose name collides with a
live one; that's an accepted trade for zero flakiness.

Usage: python3 scripts/dead_code_check.py
"""
from __future__ import annotations

import re
import subprocess
import sys

DECL_RE = re.compile(
    r"^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|private|internal|fileprivate|"
    r"open|static|final|nonisolated|mutating|convenience|required|class(?=\s+func))\s+)*"
    r"(?:struct|class|enum|protocol|func|actor)\s+(\w+)"
)
STRING_RE = re.compile(r'"(?:[^"\\]|\\.)*"')
COMMENT_RE = re.compile(r"//.*$")

# Framework/runtime entry points a reference scan can't see.
ENTRY_POINTS = {
    # SwiftUI / WidgetKit lifecycle
    "body", "main", "placeholder", "getSnapshot", "getTimeline", "makeUIView",
    "updateUIView", "makeCoordinator", "applicationShouldRequestHealthAuthorization",
    # WCSessionDelegate / UITextFieldDelegate witnesses
    "session", "sessionDidBecomeInactive", "sessionDidDeactivate",
    "textFieldDidChangeSelection", "textField", "textInputMode",
    # XCTest lifecycle
    "setUp", "tearDown",
}


def all_files() -> list[str]:
    out = subprocess.run(["git", "ls-files", "*.swift"], capture_output=True, text=True, check=True).stdout.splitlines()
    return [f for f in out if "AmplifyModels" not in f]


def app_files(files: list[str]) -> list[str]:
    return [f for f in files if "Tests" not in f and "UITests" not in f]


def main() -> int:
    files = all_files()
    contents: dict[str, list[str]] = {}
    for f in files:
        with open(f, encoding="utf-8") as fh:
            contents[f] = fh.read().splitlines()

    # name -> list of (file, line) declaration sites in app code
    decls: dict[str, list[tuple[str, int]]] = {}
    for f in app_files(files):
        for lineno, raw in enumerate(contents[f], 1):
            line = COMMENT_RE.sub("", STRING_RE.sub('""', raw))
            m = DECL_RE.match(line)
            if not m or m.group(1) in ENTRY_POINTS or m.group(1).startswith("test"):
                continue
            # @main types are invoked by the runtime, not by other code.
            if lineno >= 2 and "@main" in contents[f][lineno - 2]:
                continue
            decls.setdefault(m.group(1), []).append((f, lineno))

    dead = 0
    for name, sites in sorted(decls.items()):
        pattern = re.compile(rf"\b{re.escape(name)}\b")
        refs = 0
        decl_lines = {(f, n) for f, n in sites}
        for f in files:
            for lineno, raw in enumerate(contents[f], 1):
                if (f, lineno) in decl_lines:
                    continue
                line = COMMENT_RE.sub("", raw)
                refs += len(pattern.findall(line))
        if refs == 0:
            for f, lineno in sites:
                print(f"❌ {f}:{lineno}: `{name}` is never referenced")
                dead += 1

    if dead:
        print(f"\n❌ FAIL: {dead} unreferenced declaration(s) — delete them "
              f"(or add a genuine entry point to ENTRY_POINTS with justification).")
        return 1
    print(f"✅ PASS: no unreferenced declarations ({len(decls)} checked)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
