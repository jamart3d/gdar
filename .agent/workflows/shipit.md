---
description: Guided production release workflow for GDAR (monorepo).
---
// turbo-all
# Shipit Workflow (Monorepo)

**TRIGGERS:** shipit, release, prod

Use this workflow for explicit release preparation and deployment work. Treat it
as a guided release runbook, not an always-safe autonomous action.

## Monorepo Layout

GDAR is a Dart workspace monorepo. Build targets live under `apps/`:

| Target | Path | Build Command |
|---|---|---|
| Android / Play Store artifact (phone + TV listing) | `apps/gdar_mobile` | `flutter build appbundle --release` |
| Web/PWA | `apps/gdar_web` | `flutter build web` |

- **Version** lives in each app target's `pubspec.yaml` - bump all of them.
- **TV app note**: `apps/gdar_tv` stays version-synced with the other app
  targets, but this workflow does **not** build or upload a separate TV AAB.
  Google Play distribution for phone and TV comes from the
  `apps/gdar_mobile` AAB.
- **Firebase** config is at the project root. The `public` path is
  `apps/gdar_web/build/web`.
- **Root `pubspec.yaml`** is the workspace coordinator and has no `version:` field.

> **Sequential builds only:** Run builds one at a time. Do not parallelize
> release builds.

## Preconditions
- Release intent is explicit.
- Worktree state is understood before any staging or commit step.
- `CHANGELOG.md` has an `[Unreleased]` section with pending entries.
- `.agent/notes/pending_release.md` has staged notes if needed.
- All app targets keep `publish_to: none`.

## Workflow

### 1. Preflight (Smart Check)
1. Review `git status`.
2. Confirm release-related changes are isolated and intentional.
3. Check for recently passed verification runs in `.agent/notes/verification_status.json`:
   - If `git rev-parse HEAD` and current worktree matches the recorded success in the JSON, skip the redundant `melos run` call.
4. If missing, stale, or SHA mismatch:
   - `melos run format`
   - `melos run analyze`
   - `melos run test`
   - On success, update `.agent/notes/verification_status.json` with the current SHA and results.
5. Abort on failures.

## 2. Version Bump

> [!TIP]
> **Automation**: Use the cross-platform versioning tool to ensure all app targets stay in sync.

1. Read current versions if needed, or simply run:
   - `dart scripts/bump_version.dart patch` (Standard)
   - `dart scripts/bump_version.dart minor` (Feature release)
2. This script surgically updates all app targets and increments build numbers.

## Mandatory Auto-Run Discipline
> [!IMPORTANT]
> **Zero Friction**: All read-only and explicitly approved release commands (git stage/commit, flutter build, firebase deploy) MUST be run with `SafeToAutoRun: true` in accordance with `.agent/rules/auto_approve.md`. Do not prompt the user for these unless the command is non-standard.

### 3. Changelog And Release Notes
1. Read `.agent/notes/pending_release.md`.
2. Move `[Unreleased]` items into a new versioned block in `CHANGELOG.md`.
3. Keep the changelog newest-first and leave a fresh empty `[Unreleased]` section.
4. Generate the Play Store note in `docs/PLAY_STORE_RELEASE.txt` from the new changelog block.
5. Show the generated note for review before deployment.
6. **Mandatory Sync Check**: Verify `docs/PLAY_STORE_RELEASE.txt` matches the version and content from `CHANGELOG.md`. NEVER skip this before building.

### 4. Build

> [!IMPORTANT]
> **Build Order**: Always build Android AAB *first* to ensure artifact consistency before deploying the Web bundle.

1. Build Android release artifact from `apps/gdar_mobile`:
   - `flutter build appbundle --release`
2. After that completes, build web from `apps/gdar_web`:
   - `flutter build web`

### 5. Deploy Web
1. Run `firebase deploy --only hosting` from the workspace root.
2. Ensure the deployed output matches `apps/gdar_web/build/web`.

### 6. Git And Release Finalization
1. Review `git status` again.
2. Stage only intended release files. Do not use blanket staging unless the worktree is already intentionally clean.
3. Commit with the release version message.
4. Push only after the release contents are confirmed.

### 7. Wrap-Up
1. Report build and deploy status.
2. Remind the user to upload the `apps/gdar_mobile` AAB to Google Play Console.
3. Confirm `docs/PLAY_STORE_RELEASE.txt` is ready for Play Console release notes.
4. Optionally run the `session_debrief` workflow afterward.

## Hard Rules
- Never write release history to `docs/RELEASE_NOTES.txt`.
- Never rely on `melos.yaml` for workspace orchestration; use the root `pubspec.yaml`.
- Never treat this workflow as safe to run blindly on a dirty worktree.
