#!/bin/bash
set -e

# First, everything in tests should be moved to core except tests for things that are in the apps
mkdir -p packages/shakedown_core/test
cp -rn test/* packages/shakedown_core/test/ || true

for app in gdar_mobile gdar_fruit gdar_tv; do
    if [ -d "apps/$app/lib" ]; then
        for file in $(find apps/$app/lib -type f); do
            # We want to replace `package:shakedown_core/ui/...` with `package:gdar_mobile/ui/...` IF it exists in `gdar_mobile`.
            # First, blindly replace EVERYTHING with shakedown_core.
            sed -i -E "s|package:shakedown_core/|package:shakedown_core/|g" "$file"

            # Now, for any UI import, check if we have it locally. If yes, point to local app.
            imports=$(grep -o "import 'package:shakedown_core/ui/[^']*'" "$file" | sed "s/import 'package:shakedown_core\///" | sed "s/'//")
            for imp in $imports; do
                if [ -f "apps/$app/lib/$imp" ]; then
                    sed -i -E "s|package:shakedown_core/$imp|package:$app/$imp|g" "$file"
                fi
            done
        done
    fi
done

for file in $(find packages/shakedown_core/lib -type f); do
    sed -i -E "s|package:shakedown_core/|package:shakedown_core/|g" "$file"
done
for file in $(find packages/shakedown_core/test -type f 2>/dev/null || true); do
    sed -i -E "s|package:shakedown_core/|package:shakedown_core/|g" "$file"
done

# The root main.dart needs to be updated too
sed -i -E "s|package:shakedown_core/|package:shakedown_core/|g" lib/main.dart
