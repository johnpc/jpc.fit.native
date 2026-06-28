#!/usr/bin/env bash
# Install the repo's git hooks into .git/hooks.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

cp scripts/pre-commit .git/hooks/pre-commit
chmod +x .git/hooks/pre-commit
echo "✅ Installed pre-commit hook (.git/hooks/pre-commit)"
echo "   It runs: line-limit → gherkin sync → unit tests → build"
