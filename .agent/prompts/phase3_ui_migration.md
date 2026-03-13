# Job: Phase 3 Step 2 - UI & Feature Migration

## Context
Step 1 is complete. We now have a workspace with 3 app shells and a shared core. We must move the feature code into the appropriate app targets.

## Read
- `lib/` (Current root source)
- `apps/gdar_mobile/pubspec.yaml`
- `apps/gdar_fruit/pubspec.yaml`

## Do
1. **Mobile Migration**: Move all Material 3 mobile UI components from `lib/` to `apps/gdar_mobile/lib/`.
2. **Web/Fruit Migration**: Move all "Apple Liquid Glass" layouts and web-specific logic to `apps/gdar_fruit/lib/`.
3. **Core Imports**: Update all moved files to import from `package:shakedown_core/...` instead of local relative paths where applicable.
4. **Cleanup**: Remove any redundant Material imports from the `gdar_fruit` package to enforce design constraints.

## Verify
- Run `melos exec -- "flutter analyze"` to ensure no broken imports across the 3 apps.
