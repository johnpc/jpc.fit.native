#!/usr/bin/env bash
# Enforce the 100-line limit on ALL Swift source files in the app target.
# Files must stay small and single-purpose; views only render, logic belongs in
# ViewModels/Services. Over the limit → extract a helper or split the file.
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

MAX=100
FAILED=0
echo "Checking Swift source files for line count > $MAX..."

while IFS= read -r file; do
  case "$file" in
    # Amplify-generated models are mechanical and exempt.
    */AmplifyModels/*) continue ;;
  esac
  LINES=$(wc -l < "$file" | tr -d ' ')
  if [ "$LINES" -gt "$MAX" ]; then
    echo "❌ $file: $LINES lines (max $MAX)"
    FAILED=1
  fi
done < <(find jpc.fit.native -name "*.swift")

if [ "$FAILED" -eq 1 ]; then
  echo ""
  echo "Source files must be ≤ $MAX lines. Extract logic into a helper, a"
  echo "ViewModel/Service, or split into smaller files. Never raise the limit."
  exit 1
fi
echo "✅ All source files ≤ $MAX lines"
