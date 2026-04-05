#!/bin/bash

# Audit script for GDAR assets (Linux/bash equivalent)
ASSET_DIR="assets"
MAX_SIZE_KB=500
MAX_SIZE_BYTES=$((MAX_SIZE_KB * 1024))

echo "--- GDAR Asset Audit Baseline ---"
echo "Scanning recursively from: $ASSET_DIR"
echo "Target threshold: $MAX_SIZE_KB KB"
echo ""

if [ ! -d "$ASSET_DIR" ]; then
    echo "Error: $ASSET_DIR directory not found."
    exit 1
fi

OVER_LIMIT_COUNT=0
TOTAL_SIZE_BYTES=0
FILE_COUNT=0

# Use find to get all files
while IFS= read -r -d '' file; do
    FILE_COUNT=$((FILE_COUNT + 1))
    SIZE_BYTES=$(stat -c%s "$file")
    TOTAL_SIZE_BYTES=$((TOTAL_SIZE_BYTES + SIZE_BYTES))
    SIZE_KB=$((SIZE_BYTES / 1024))

    if [ "$SIZE_BYTES" -gt "$MAX_SIZE_BYTES" ]; then
        OVER_LIMIT_COUNT=$((OVER_LIMIT_COUNT + 1))
        EXT="${file##*.}"
        EXT_LOWER=$(echo "$EXT" | tr '[:upper:]' '[:lower:]')
        MSG=" [!] LARGE FILE ($SIZE_KB KB): $file"

        # Suggest WebP conversion for PNG/JPG
        if [[ "$EXT_LOWER" == "png" || "$EXT_LOWER" == "jpg" || "$EXT_LOWER" == "jpeg" ]]; then
            MSG="$MSG (Suggest: Convert to WebP)"
        fi

        # Yellow output using ANSI escape codes
        echo -e "\e[33m$MSG\e[0m"
    fi
done < <(find "$ASSET_DIR" -type f -print0)

echo -e "\n--- Summary ---"
echo "Total Files Scanned: $FILE_COUNT"
TOTAL_SIZE_MB=$(echo "scale=2; $TOTAL_SIZE_BYTES / 1048576" | bc 2>/dev/null || awk "BEGIN {printf \"%.2f\", $TOTAL_SIZE_BYTES / 1048576}")
echo "Total Asset Size: $TOTAL_SIZE_MB MB"
echo "Files over $MAX_SIZE_KB KB: $OVER_LIMIT_COUNT"
echo ""

if [ "$OVER_LIMIT_COUNT" -gt 0 ]; then
    # Cyan output
    echo -e "\e[36mAction required: Review large files to ensure they are strictly TV-necessary.\e[0m"
else
    # Green output
    echo -e "\e[32mCheck successful: Assets are lean.\e[0m"
fi
