#!/usr/bin/env python3
"""Keep docs/state-machines.md honest, both ways (deterministic, no build).

 1. Every catalog row names an owner file that exists under the app or watch
    sources, a status in {explicit, guarded, implicit}, and — unless it is an
    admitted `implicit` gap — a test that exists (unit test file or .feature).
 2. Every `/// StateMachine: <Name>` marker in app/watch sources has a row of
    that name, and every `explicit` row has exactly one marker — so a machine
    cannot be renamed, moved or quietly demoted without the catalog moving.
 3. New implicit machines are caught early. In app/watch sources (tests exempt):
      - a `*Status`/`*State`/`*Mode` property typed `String` (prose as state);
      - more than one `show<X>` boolean presentation flag per file (two flags
        that must agree → one enum);
      - a `show<X>` flag beside a `<y>Message: String?` in the same file (the
        "toast = bool + optional" pair).

Usage: python3 scripts/check_state_machines.py
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DOC = ROOT / "docs" / "state-machines.md"
STATUSES = {"explicit", "guarded", "implicit"}
MARKER_RE = re.compile(r"^\s*///\s*StateMachine:\s*(.+?)\s*$")
STRING_STATE_RE = re.compile(r"\bvar\s+\w*(?:Status|State|Mode)\s*:\s*String\b")
SHOW_FLAG_RE = re.compile(r"\bvar\s+show[A-Z]\w*\s*(?:=\s*(?:true|false)|:\s*Bool)")
MESSAGE_RE = re.compile(r"\bvar\s+\w*[mM]essage\s*:\s*String\?")


def app_files() -> list[str]:
    out = subprocess.run(["git", "ls-files", "*.swift"], capture_output=True, text=True, check=True, cwd=ROOT)
    return [f for f in out.stdout.splitlines()
            if "AmplifyModels" not in f and "Tests" not in f and "UITests" not in f]


def catalog_rows(text: str) -> list[dict]:
    rows = []
    for line in text.splitlines():
        if not line.startswith("| ") or line.startswith("| ---") or line.startswith("| Machine"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split(" | ")]
        if len(cells) < 5:
            continue
        rows.append({"name": cells[0], "states": cells[1], "owner": cells[2], "status": cells[3], "tests": cells[4]})
    return rows


def main() -> int:
    errors: list[str] = []
    if not DOC.exists():
        print(f"❌ {DOC.relative_to(ROOT)} is missing")
        return 1
    doc = DOC.read_text(encoding="utf-8")
    rows = catalog_rows(doc)

    for path in sorted(set(re.findall(r"`((?:jpc\.fit\.native|com\.johncorser[^`]*|scripts)/[^`]+\.(?:swift|feature|py))`", doc))):
        if not (ROOT / path).exists():
            errors.append(f"cited path does not exist: {path}")
    for row in rows:
        if not re.search(r"`(?:jpc\.fit\.native/|com\.johncorser\.fit\.watchkitapp Watch App/)[^`]+\.swift`", row["owner"]):
            errors.append(f'row "{row["name"]}" has no owner under the app or watch sources')
        has_test = re.search(r"`jpc\.fit\.native(?:UI)?Tests/[^`]+\.(?:swift|feature)`", row["tests"])
        if row["status"] != "implicit" and not has_test:
            errors.append(f'row "{row["name"]}" is {row["status"]} but cites no unit test or .feature')
        if row["status"] not in STATUSES:
            errors.append(f'row "{row["name"]}" has unknown status "{row["status"]}"')

    markers: dict[str, str] = {}
    for f in app_files():
        lines = (ROOT / f).read_text(encoding="utf-8").splitlines()
        show_flags = 0
        has_message = False
        for lineno, line in enumerate(lines, 1):
            if m := MARKER_RE.match(line):
                if m.group(1) in markers:
                    errors.append(f'marker "{m.group(1)}" appears twice: {markers[m.group(1)]} and {f}:{lineno}')
                markers[m.group(1)] = f"{f}:{lineno}"
            code = line.split("//", 1)[0]
            if STRING_STATE_RE.search(code):
                errors.append(f"{f}:{lineno}: a *Status/*State/*Mode property typed String — model the states as an enum")
            if SHOW_FLAG_RE.search(code):
                show_flags += 1
            if MESSAGE_RE.search(code):
                has_message = True
        if show_flags > 1:
            errors.append(f"{f}: {show_flags} `show*` boolean flags — fold them into one presentation enum")
        if show_flags and has_message:
            errors.append(f"{f}: a `show*` flag next to a `*Message: String?` — make the toast ONE optional")

    row_names = {r["name"] for r in rows}
    for name, where in markers.items():
        if name not in row_names:
            errors.append(f'marker "StateMachine: {name}" at {where} has no catalog row')
    for row in rows:
        if row["status"] == "explicit" and row["name"] not in markers:
            errors.append(f'explicit row "{row["name"]}" has no `/// StateMachine: {row["name"]}` marker on its owner type')

    if errors:
        print("❌ state-machine catalog check failed:\n  " + "\n  ".join(errors))
        return 1
    print(f"✅ PASS: state-machine catalog OK ({len(rows)} machines, {len(markers)} markers)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
