#!/bin/bash
set -e

for app in gdar_mobile gdar_fruit gdar_tv; do
    if [ -d "apps/$app/lib" ]; then
        for file in $(find apps/$app/lib -type f); do
            # App's own UI imports
            sed -i -E "s|package:shakedown/ui|package:$app/ui|g" "$file"
            # Everything else in shakedown -> shakedown_core
            sed -i -E "s|package:shakedown/|package:shakedown_core/|g" "$file"

            # Now, if an import doesn't exist in the app, it must be in core.
            imports=$(grep -o "import 'package:$app/ui/[^']*'" "$file" | sed "s/import 'package:$app\///" | sed "s/'//")
            for imp in $imports; do
                if [ ! -f "apps/$app/lib/$imp" ]; then
                    sed -i -E "s|package:$app/$imp|package:shakedown_core/$imp|g" "$file"
                fi
            done
        done

        if [ -d "apps/$app/test" ]; then
            for file in $(find apps/$app/test -type f); do
                sed -i -E "s|package:shakedown/ui|package:$app/ui|g" "$file"
                sed -i -E "s|package:shakedown/|package:shakedown_core/|g" "$file"
                imports=$(grep -o "import 'package:$app/ui/[^']*'" "$file" | sed "s/import 'package:$app\///" | sed "s/'//")
                for imp in $imports; do
                    if [ ! -f "apps/$app/lib/$imp" ]; then
                        sed -i -E "s|package:$app/$imp|package:shakedown_core/$imp|g" "$file"
                    fi
                done
            done
        fi
    fi
done

for file in $(find packages/shakedown_core/lib -type f); do
    sed -i -E "s|package:shakedown/|package:shakedown_core/|g" "$file"
done
for file in $(find packages/shakedown_core/test -type f); do
    sed -i -E "s|package:shakedown/|package:shakedown_core/|g" "$file"
done
