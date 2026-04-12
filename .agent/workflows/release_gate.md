---
description: Final release-readiness gate before /publish (no builds or deploy).
---
# Release Gate Workflow (Monorepo)
// turbo-all

**TRIGGERS:** release_gate, release-gate, pre_shipit, pre-shipit, preflight-release

> [!IMPORTANT]
> Execute immediately upon trigger. No plans, no confirmation prompts.
> Follow `.agent/skills/zero_friction_execution/SKILL.md` for
> long-running command polling.

## 1. Preflight
// turbo
- `dart scripts/preflight_check.dart`
- If output contains `CHROMEBOOK:STOP` -> notify user and **stop**.
- If output contains `WINDOWS_10:VERIFIED`, `LINUX:VERIFIED`, or `MACOS:VERIFIED` -> proceed to Step 2.

This validates host/toolchain state and refreshes verification receipt metadata
when successful.

## 2. Test Path Guard (Stale-Path Catch)
// turbo
- Confirm expected test roots exist before the release gate:
  - `packages/shakedown_core/test`
  - `apps/gdar_mobile/test`
  - `apps/gdar_web/test`
- If any expected root is missing, halt and report the missing path.
- If a test command references a file path that does not exist, classify as
  stale expectation and update the command/test target before continuing (see
  `.agent/rules/test_expectation_hygiene.md`).

## 3. Release Readiness Gate
// turbo
- `melos run analyze`
- `melos run test`

If either command fails, halt and report the failing command and first error.

## 4. Release Config Gate
// turbo
- Confirm app versions match across:
  - `apps/gdar_mobile/pubspec.yaml`
  - `apps/gdar_tv/pubspec.yaml`
  - `apps/gdar_web/pubspec.yaml`
- Confirm
  `apps/gdar_mobile/android/app/src/main/AndroidManifest.xml` keeps
  `usesCleartextTraffic="false"` for release.
- Confirm `apps/gdar_web/pubspec.yaml` launcher icon paths resolve to real
  assets.

If any static release-config check fails, halt and report the exact mismatch or
missing path.

## 5. Notes & Artifacts Check
// turbo
- Validate `.agent/notes/pending_release.md` has current-session bullets when
  user-facing behavior changed.
- Validate `docs/PLAY_STORE_RELEASE.txt` exists and is non-empty.

If either check fails, halt and report exactly what is missing.

## 6. Hand-Off to Publish
1. If all checks pass, print:
   **"Release gate passed. Safe to run /publish."**
2. Recommend:
   - `/publish` for patch release.
   - `/publish minor` for minor release.

## Hard Rules
- Do not run builds in this workflow.
- Do not deploy in this workflow.
- Do not bump versions in this workflow.
- Keep this workflow as a gate between `/validate` and `/publish`.
