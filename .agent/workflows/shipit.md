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
- If output contains `WINDOWS_10:VERIFIED` or `LINUX:VERIFIED` → proceed to Step 2.

The script handles platform detection, toolchain checks, process hygiene,
smart-skip melos verification, and `verification_status.json` updates
internally. The agent does not need to read or compare SHAs.

## 2. Pre-Build Health Gate
// turbo
- `melos run analyze`
- `melos run test`

If either fails, halt and report. Do not proceed to version bump with a broken codebase.

## 3. Release Housekeeping
// turbo
- Validate `docs/PLAY_STORE_RELEASE.txt` is non-empty. Halt if missing or empty.
- `dart scripts/finalize_release.dart patch` (default)
- `dart scripts/finalize_release.dart minor` (if user requested)

This script atomically handles version bump, changelog migration,
Play Store note prepending, and pending notes reset.

## 4. Android Build
- From `apps/gdar_mobile`: `flutter build appbundle --release`
- Wait for completion before proceeding.

## 5. Web Build
- From `apps/gdar_web`: `flutter build web --release`
- Wait for completion before proceeding.

## 6. Deploy & Sync
1. `firebase deploy --only hosting`
2. Verify deploy succeeded (exit 0) before continuing.
3. `dart scripts/release_sync.dart`
   (Runs after deploy — records deploy status and updates release metadata.)

## 7. Smoke Test
- `curl -sI https://shakedown-pwa.web.app/ | grep -E "HTTP/[0-9.]+ 200"` (or equivalent)
- If the live URL does not return 200, halt and report before wrapping up.

## 8. Wrap-Up
- Report build/deploy status.
- Remind: upload `apps/gdar_mobile/build/app/outputs/bundle/release/app-release.aab` to Google Play Console.
- Remind: use `docs/PLAY_STORE_RELEASE.txt` for the Play Console "Release Notes" section.

## Hard Rules
- Builds are strictly sequential. Never parallelize.
- Dirty worktree is fine — changes are captured in the release commit.
- Never write to `docs/RELEASE_NOTES.txt` (legacy, retired).
- `gdar_tv` is not a separate build step. Both phone and TV targets are bundled into the single AAB built from `apps/gdar_mobile`. The Play Store routes the correct APK split to each device type.
