---
trigger: always_on
---
# Monorepo Hygiene & Maintenance Standards

This document centralizes the rules for monorepo structure, builds, versioning, dependency management, and shell execution.

## 1. Monorepo Layout & Root Hygiene
The root is a **workspace coordinator**, not an app target.
- **Apps**: `apps/gdar_mobile`, `apps/gdar_tv`, `apps/gdar_web`.
- **Packages**: `packages/shakedown_core`, `packages/styles`.
- **Root Files**: Only tools/config (`pubspec.yaml`, `melos.yaml`, `firebase.json`, `AGENTS.md`).

### No Root Pollution
- **NEVER** write temporary files, backups, or debug logs to the root.
- All scratch files MUST go to `/tmp/` (or `%TEMP%`).
- Platform folders (`android/`, `ios/`, `web/`) MUST live inside `apps/<target>/`.

## 2. Path Hygiene & Storage
- **Repo-Relative Paths**: Always prefer repo-relative paths in documentation and rules (e.g., `apps/gdar_web`). NEVER use machine-specific absolute paths unless temporarily required.
- **.agent/appdata**: Reserved for project-specific persistent state. Never redirect `PUB_CACHE` or Flutter tool logs here.
- **Cleanup Responsibility**: Any file generated outside of `apps/`, `packages/`, or `docs/` must be deleted before the session ends.
- **Data Cleanup & Privacy**: Directories named `archive`, `temp`, and `backups` are excluded from the active monorepo health map and must not be audited, verified, or proactively searched by agents unless the user passes a direct file reference.

## 3. Build Safety & Hardware-Aware Execution
- **Parallel Builds Are STRICTLY FORBIDDEN**: `flutter build` grabs all available system threads by default. Running builds in parallel will cause extreme system thrashing on high-core machines (e.g., Windows 16-core) and trigger OOM kills on Chromebooks.
  - **Rule**: Always build targets strictly sequentially. Wait for one `flutter build` to finish completely before spawning the next.
- **Concurrency Scaling**: Use explicit concurrency limits (e.g. `--concurrency 4`) in terminal commands. Run the health suite: `melos run fix`, `melos run format`, `melos run analyze`, and `melos run test`. Explicitly override concurrency only if required by environment constraints.
- **Parallel Git Is Not Safe**: The `.git/` directory is shared across the entire workspace. Running `git add`, `git commit`, or `git push` simultaneously will cause `index.lock` failures.
- **Rule**: Always wait for ALL builds and operations to finish before starting `git add .`.

## 4. Deployments & Version Sync
- **Firebase Deploy**: `firebase.json` lives at the project root. Always run `firebase deploy --only hosting` from the project root.
- **Version Sync**: All app targets (`gdar_mobile`, `gdar_tv`, `gdar_web`) must share the exact same `version:` string in their `pubspec.yaml`. The root `pubspec.yaml` has NO `version:` field.
- **Fresh Bump**: The `shipit` workflow MUST always increment the version and build number atomically across all three app targets. Never assume the current file version is the final release version. All app targets must have `publish_to: none`.

## 5. Dependency & Native Stability
- **Native Plugin Upgrades**: When upgrading plugins that have native components, you MUST verify local build stability (e.g., `flutter build appbundle --debug` from `apps/gdar_mobile`) before committing.
- **Community Edition Migrations**: Follow migration guides precisely. Apply Mockito updates immediately.
- **Plugin Registration**: If a `MissingPluginException` occurs, use the `/refresh_native` workflow to force a rebuild.

## 6. Platform-Specific Shell Rules
| Task | Environment |
|---|---|
| Code editing, tests, analysis | Linux / ChromeOS (Bash) |
| `flutter build appbundle` | Windows |
| `firebase deploy` | Windows |
| `flutter build web` | Windows |

- **Linux**: Run `melos` from the repo root. Build commands must run from the specific app directory. Never leave background processes running. Do not use interactive shells.
- **Windows**: Build and deploy commands run on Windows. Use `cmd /c` to assure process terminates. Flutter and Firebase CLI paths are on the Windows PATH.
