#!/usr/bin/env bash
# Checkup Workflow: Micro-Scanner for Dart Styling Violations
# Scans only modified and staged files for forbidden UI patterns.

set -e

# Collect modified/added dart files (staged or unstaged)
CHANGED_FILES=$(git diff --name-only HEAD | grep '\.dart$' || true)

if [ -z "$CHANGED_FILES" ]; then
    echo "✨ No changed Dart files found. Micro-scanner skipping."
    exit 0
fi

echo "🔍 Scanning $(echo "$CHANGED_FILES" | wc -w) pending file(s) for styling constraints..."

VIOLATIONS=0

for FILE in $CHANGED_FILES; do
    # Skip if file was deleted
    if [ ! -f "$FILE" ]; then
        continue
    fi
    
    # Target 1: withOpacity() - User rule states modern syntax requires .withValues()
    if grep -n "withOpacity(" "$FILE"; then
        echo "⚠️  [WARNING] Legacy 'withOpacity()' found in $FILE."
        echo "   -> Please use the modern '.withValues()' method."
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
    
    # Target 2: Colors.* - User rule states Colors/theme hardcoding breaks multi-platform guidelines
    if grep -n "Colors\." "$FILE"; then
        echo "⚠️  [WARNING] Hardcoded 'Colors.*' found in $FILE."
        echo "   -> Please use the semantic theme variables or styles package to support Dark Mode / Fruit."
        VIOLATIONS=$((VIOLATIONS + 1))
    fi
done

if [ "$VIOLATIONS" -gt 0 ]; then
    echo ""
    echo "❌ Micro-Scanner failed. Found $VIOLATIONS violation(s)."
    echo "   Please fix the listed items to pass the checkup workflow."
    exit 1
fi

echo "✅ Micro-Scanner passed. No styling violations found in pending files."
exit 0
