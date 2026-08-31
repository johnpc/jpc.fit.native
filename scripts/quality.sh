#!/usr/bin/env bash
# Full local quality gate for jpc.fit.native — the same checks CI enforces, in
# one command: source-line limit, Gherkin sync, static checks (dead code,
# duplication, banned types, Halstead ≤20), unit tests + coverage ≥80%,
# CRAP ≤30, and a clean build.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

SCHEME="jpc.fit.native"
DESTINATION="${FIT_DESTINATION:-platform=iOS Simulator,name=iPhone 17 Pro}"
RESULT="TestResults.xcresult"

echo "▶ [1/6] Source file line limit (≤100)"
bash scripts/check_line_limit.sh

echo "▶ [2/6] Acceptance tests generated from .feature files are in sync"
python3 scripts/generate_acceptance_tests.py --check

echo "▶ [3/6] Static checks: dead code, duplication, banned types, Halstead"
python3 scripts/dead_code_check.py
python3 scripts/duplication_check.py
python3 scripts/banned_types_check.py
python3 scripts/halstead_check.py

echo "▶ [4/6] Unit tests + coverage"
rm -rf "$RESULT"
xcodebuild test \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -only-testing:"jpc.fit.nativeTests" \
  -derivedDataPath DerivedData \
  -enableCodeCoverage YES \
  -resultBundlePath "$RESULT" \
  -quiet
xcrun xccov view --report --json "$RESULT" > coverage.json

echo "▶ [5/6] Coverage threshold (≥80%) + CRAP (≤30)"
python3 scripts/coverage_check.py coverage.json
python3 scripts/crap_check.py coverage.json

echo "▶ [6/6] Build app"
xcodebuild build \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -derivedDataPath DerivedData \
  -quiet

echo "✅ Quality gate passed"
