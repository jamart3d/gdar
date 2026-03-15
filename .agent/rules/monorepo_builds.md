---
trigger: always_on
---

# Monorepo Build Safety

### Parallel Builds Are Safe — Parallel Git Is Not
- **Default**: `flutter build` from separate app targets (`apps/gdar_mobile`,
  `apps/gdar_tv`, `apps/gdar_web`) can run in parallel safely — they have
  independent `build/` dirs.
- **Chromebook Exception**: On Chromebook/Crostini, do **NOT** run parallel
  builds. Always build targets sequentially to avoid VM memory pressure.
- **Git operations MUST be serialized.** The `.git/` directory is shared across the
  entire workspace. Running `git add`, `git commit`, or `git push` from two terminals
  simultaneously will cause `index.lock` failures.
- **Rule**: Always wait for ALL builds to finish before starting `git add .`.

### Firebase Deploy Runs From Root
- `firebase.json` lives at the project root.
- The `public` path is `apps/gdar_web/build/web`.
- Always run `firebase deploy --only hosting` from the project root, not from `apps/gdar_web/`.

### Version Sync
- All app targets (`gdar_mobile`, `gdar_tv`, `gdar_web`) must share the same
  `version:` in their `pubspec.yaml`.
- The root `pubspec.yaml` (`gdar_root`) has NO `version:` field — it is only
  the workspace coordinator.
- All app targets must have `publish_to: none` since they use path dependencies.
