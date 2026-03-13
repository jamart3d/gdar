# Job: Phase 3 Step 1 - Workspace Shells and Asset Migration

## Context
Phase 2 (Core Extraction) is verified. We are now expanding the workspace to support independent app targets.

## Read
- Root `pubspec.yaml`
- `packages/shakedown_core/pubspec.yaml`

## Do
- **Update Root**: Add `apps/gdar_mobile`, `apps/gdar_tv`, and `apps/gdar_fruit` to the `workspace` list in the root `pubspec.yaml`.
- **Relocate Asset**: Move `assets/data/output.optimized_src.json` to `packages/shakedown_core/assets/data/`.
- **Core Update**: Declare this asset in `packages/shakedown_core/pubspec.yaml` under `flutter: assets:`.
- **Initialize Shells**: Create `pubspec.yaml` for `apps/gdar_mobile/`, `apps/gdar_tv/`, and `apps/gdar_fruit/`.
    - Use `resolution: workspace`.
    - Set path dependency: `shakedown_core: {path: ../../packages/shakedown_core}`.
    - Set asset: `- packages/shakedown_core/assets/data/output.optimized_src.json`.
- **Bootstrap**: Run `melos bootstrap`.

## Verify
- Run `melos list` to confirm 4 active packages.
