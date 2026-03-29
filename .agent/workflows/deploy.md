---
description: Fully automated production release and deployment workflow for GDAR (monorepo).
---
// turbo-all
# Deploy Workflow (Monorepo)

**TRIGGERS:** deploy, push-prod, ship-it-now

This is the non-interactive, zero-friction version of the `shipit` release workflow.
Executing this workflow implies full authorization to perform version bumps, 
changelog updates, builds, and production deployments without further confirmation.

## Monorepo Layout

GDAR is a Dart workspace monorepo. Build targets live under `apps/`:

| Target | Path | Build Command |
|---|---|---|
| Android / Play Store artifact (phone + TV listing) | `apps/gdar_mobile` | `flutter build appbundle --release` |
| Web/PWA | `apps/gdar_web` | `flutter build web` |

- **Version** lives in each app target's `pubspec.yaml` - bump all of them.
- **Firebase** config is at the project root. The `public` path is `apps/gdar_web/build/web`.

## Workflow

### 1. Automated Preflight (Hardware-Aware)
1. `git status`
2. Identify hardware limits: check `$MELOS_CAN_HANDLE` (or `$env:MELOS_CAN_HANDLE` on Windows).
3. `melos run format`
4. `melos run analyze`
5. `melos run test`
6. Abort automatically on any failures.

### 2. Automatic Version Bump
1. `dart scripts/bump_version.dart patch` (Standard patch bump)

### 3. Automated Changelog Synchronization
1. Move `[Unreleased]` items into a new versioned block in `CHANGELOG.md`.
2. Generate the Play Store note in `docs/PLAY_STORE_RELEASE.txt` from the new changelog block.
3. Skip manual review of notes; assume staging is correct.

### 4. Sequential Production Builds (Hardware-Aware)

> [!CAUTION]
> **STRICT SEQUENTIAL EXECUTION**: You MUST execute the Android and Web builds sequentially. Wait for Android to finish completely before starting Web. **DO NOT** parallelize these builds, even if `$MELOS_CAN_HANDLE` is high (e.g., 8). `flutter build` maximizes all available threads by default; running two simultaneously will cause extreme system thrashing on the 16-core Windows machine and trigger OOM kills on Chromebooks.

1. Build Android release artifact from `apps/gdar_mobile`:
   - `flutter build appbundle --release`
2. Build web from `apps/gdar_web`:
   - `flutter build web`

### 5. Production Deployment
1. Run `firebase deploy --only hosting` from the workspace root.

### 6. Git Finalization
1. `git add .`
2. `git commit -m "release: $(dart scripts/get_current_version.dart)"` (Auto-commit with new version)
3. `git push`

### 7. Completion Report
1. Report build and deploy status.
2. Link to `apps/gdar_mobile/build/app/outputs/bundle/release/app-release.aab`.

## Hard Rules
- **Non-Interactive**: Never stop for user input or "confirm" prompts.
- **Fail-Fast**: Stop immediately if any build or test step fails.
- **Atomic**: The entire release must be pushed or failed as a unit.
