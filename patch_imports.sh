#!/bin/bash
set -e

for app in gdar_mobile gdar_fruit gdar_tv; do
    if [ -d "apps/$app/lib" ]; then
        for file in $(find apps/$app/lib -type f); do
            # Replace shakedown to the current app for its own UI
            # Wait, we first replace EVERYTHING to shakedown_core
            sed -i -E "s|package:shakedown/|package:shakedown_core/|g" "$file"

            # Then we find imports that belong to the app and map them back to the app
            # What belongs to the app? Any file that exists in apps/$app/lib/
            # To do this safely, we will extract all `package:shakedown_core/...` imports
            imports=$(grep -o "import 'package:shakedown_core/[^']*'" "$file" | sed "s/import 'package:shakedown_core\///" | sed "s/'//")
            for imp in $imports; do
                if [ -f "apps/$app/lib/$imp" ]; then
                    sed -i -E "s|package:shakedown_core/$imp|package:$app/$imp|g" "$file"
                fi
            done
        done

        # Do the same for tests in the app
        if [ -d "apps/$app/test" ]; then
            for file in $(find apps/$app/test -type f); do
                sed -i -E "s|package:shakedown/|package:shakedown_core/|g" "$file"
                imports=$(grep -o "import 'package:shakedown_core/[^']*'" "$file" | sed "s/import 'package:shakedown_core\///" | sed "s/'//")
                for imp in $imports; do
                    if [ -f "apps/$app/lib/$imp" ]; then
                        sed -i -E "s|package:shakedown_core/$imp|package:$app/$imp|g" "$file"
                    fi
                done
            done
        fi
    fi
done

# And for core
for file in $(find packages/shakedown_core/lib -type f); do
    sed -i -E "s|package:shakedown/|package:shakedown_core/|g" "$file"
done
for file in $(find packages/shakedown_core/test -type f 2>/dev/null || true); do
    sed -i -E "s|package:shakedown/|package:shakedown_core/|g" "$file"
done
