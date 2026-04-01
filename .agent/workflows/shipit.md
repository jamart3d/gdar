---
description: Production release workflow for GDAR (monorepo).
---

# Shipit Workflow (Monorepo)
// turbo-all

**TRIGGERS:** shipit, release, prod, deploy

> [!IMPORTANT]
> Execute immediately upon trigger. No plans, no confirmation prompts.
> Every step inherits the original `/shipit` approval.
> Follow `.agent/skills/zero_friction_execution/SKILL.md` for
> long-running command polling.

## 1. Preflight & Verification
// turbo
- `dart scripts/preflight_check.dart --release`
- If output contains `CHROMEBOOK:STOP` → notify user and **stop**.
- If output contains `WINDOWS_10:VERIFIED` → proceed to Step 2.

The script handles platform detection, toolchain checks, process hygiene,
smart-skip melos verification, and `verification_status.json` updates
internally. The agent does not need to read or compare SHAs.

## 2. Release Housekeeping
// turbo
- `dart scripts/finalize_release.dart patch` (default)
- `dart scripts/finalize_release.dart minor` (if user requested)

This script atomically handles version bump, changelog migration,
Play Store note prepending, and pending notes reset.

## 3. Android Build
- From `apps/gdar_mobile`: `flutter build appbundle --release`
- Wait for completion before proceeding.

## 4. Web Build
- From `apps/gdar_web`: `flutter build web --release`
- Wait for completion before proceeding.

## 5. Deploy & Sync
// turbo
1. `firebase deploy --only hosting`
2. `dart scripts/release_sync.dart`

## 6. Wrap-Up
- Report build/deploy status.
- Remind: upload `apps/gdar_mobile/build/app/outputs/bundle/release/app-release.aab` to Google Play Console.
- Confirm `docs/PLAY_STORE_RELEASE.txt` is ready for the Play Console "Release Notes" section.

## Hard Rules
- Builds are strictly sequential. Never parallelize.
- Dirty worktree is fine — changes are captured in the release commit.
- Never write to `docs/RELEASE_NOTES.txt` (legacy, retired).
