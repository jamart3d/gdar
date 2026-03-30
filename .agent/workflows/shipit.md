---
description: Guided production release workflow for GDAR (monorepo).
---

# Shipit Workflow (Monorepo)
// turbo-all

**TRIGGERS:** shipit, release, prod

> [!IMPORTANT]
> **AUTONOMY OVERRIDE & GHOST EXECUTION**: When this workflow is triggered, the agent is STRICTLY FORBIDDEN from generating plans or asking for intermediate confirmation. Begin executing the workflow immediately and proceed autonomously end-to-end once triggered. Only pause if a critical error occurs.

> [!IMPORTANT]
> **SHIPIT STEP INHERITANCE**: Every internal step of this workflow inherits the original `/shipit` approval. Do not ask for a second confirmation for toolchain preflight, git operations, version bump scripts, changelog/release-note updates, Flutter builds, Firebase deploy, tagging, or push steps.

> [!WARNING]
> **NO BLACK BOXES**: You are strictly forbidden from chaining multiple long-running terminal commands into a single "black box" string (for example, `build; build; push`). Run each primary tool (Melos, Flutter build, Firebase) as its own step so progress and status are reported in real time.

> [!IMPORTANT]
> **EXECUTION MECHANICS**: Follow `.agent/skills/zero_friction_execution/SKILL.md` for long-running command handling, explicit completion checks, and fail-fast protocol.

## Platform Sync Mandatory
Both Android (Phone/TV) and Web/PWA targets **MUST** be built and deployed in every release to maintain platform synchronization across the monorepo.

| Target | Path | Build Command |
|---|---|---|
| Android (Phone+TV) | `apps/gdar_mobile` | `flutter build appbundle --release` |
| Web/PWA (Glass) | `apps/gdar_web` | `flutter build web --release` |

---

## 0. Platform Detection (MUST RUN FIRST)
1. Run the shared preflight in `.agent/workflows/toolchain_preflight.md`.
   - Required commands for `shipit`: `git`, `dart`, `flutter`, `firebase`
   - Use the host detection result from `.agent/rules/platform_detection.md`
2. **If output is `CHROMEBOOK`:**
   - Notify the user: "Chromebook detected - health suite only. Flutter builds and Firebase deploy must run on Windows 10."
   - Run steps 0.5 and 1 (process hygiene + health suite) and then **stop**. Do not proceed to versioning, builds, or deploy.
3. **If output is `WINDOWS_10`:**
   - Resolve `$MELOS_CAN_HANDLE` per `.agent/rules/platform_detection.md`.
   - Continue to all steps end-to-end.

## 0.5. Process Hygiene
Follow `.agent/rules/process_hygiene.md` to detect and handle any hung `flutter`, `dart`, or `melos` processes before proceeding. Re-run `git status --porcelain` after killing any processes - lock files from a hung process can make a clean worktree appear dirty.

## 1. Preflight Verification (Smart Skip)
1. Run `git status --porcelain` to check workspace status.
   - Note: If the worktree is dirty, those changes will be included in the final release commit after the build. Do **not** commit them now.
2. **Notes Verification**:
   - Check `CHANGELOG.md` for `[Unreleased]` entries.
   - Read `.agent/notes/pending_release.md`.
   - If BOTH are empty, the release will proceed as a pure maintenance version bump.
3. Check `.agent/notes/verification_status.json` and run `git rev-parse HEAD`.
4. If (Current SHA == `last_verification_commit`) AND (status == "PASS"):
   - **SKIP** the `melos run` pass and proceed to versioning.
   - Note: A `"PARTIAL"` result does **not** qualify for skip - run the full suite.
5. Else:
   - Resolve `$MELOS_CAN_HANDLE` per `.agent/rules/platform_detection.md`.
   - Run the health suite: `melos run format`, `melos run analyze`, and `melos run test`. Explicitly override concurrency only if required by environment constraints.
   - Do **not** run `melos run fix` - shipit verifies, it does not auto-modify code. Run `/checkup` first if fixes are needed.
   - Update `verification_status.json` upon success.

## 2. Unified Release Housekeeping (Turbo)
// turbo
1. Run the unified housekeeping script:
   - `dart scripts/finalize_release.dart patch` (default)
   - `dart scripts/finalize_release.dart minor` (if requested)

This script atomically handles:
- Platform-wide version bump.
- Migration of notes from `pending_release.md` to `CHANGELOG.md`.
- Automated Play Store note prepending to `docs/PLAY_STORE_RELEASE.txt`.
- Resetting the pending notes buffer.

## 4. Sequential Production Builds (Hardware-Aware)
> [!CAUTION]
> **STRICT SEQUENTIAL EXECUTION**: You MUST execute the Android and Web builds sequentially. Wait for Android to finish completely before starting Web. **DO NOT** parallelize these builds, even if `$MELOS_CAN_HANDLE` is high (for example, 8). `flutter build` maximizes all available threads by default; running two simultaneously will cause extreme system thrashing on the 16-core Windows machine and trigger OOM kills on Chromebooks.

1. **Target 1: Android**: Build the AAB from `apps/gdar_mobile`:
   - `flutter build appbundle --release`
2. **Target 2: Web**: Build the PWA from `apps/gdar_web`:
   - `flutter build web --release`

## 5. Web Deploy & Final Check-in
1. **Web Deploy**: Run `firebase deploy --only hosting` from the workspace root.
2. **Unified Release Commit (THE FINAL STEP)**:
   - `git add .` (capture versioning, changelog, and doc history updates)
   - `git commit -m "release: $(dart scripts/get_current_version.dart)"`
   - `git tag v$(dart scripts/get_current_version.dart)`
   - `git push origin main`
   - `git push --tags`

## 6. Wrap-Up
1. Report build and deploy status clearly.
2. Remind the user to upload `apps/gdar_mobile/build/app/outputs/bundle/release/app-release.aab` to Google Play Console.
3. Confirm `docs/PLAY_STORE_RELEASE.txt` is ready for the Play Console "Release Notes" section.

## Hard Rules
- Never write release history to `docs/RELEASE_NOTES.txt`.
- The workspace is defined by the root `pubspec.yaml`. Melos commands (`melos run *`) are the task runner - they use `melos.yaml` for script definitions, which is fine. Do not add packages to the workspace via `melos.yaml`; use the root `pubspec.yaml` `workspace:` field.
- **Dirty Worktree Handling**: If the worktree is dirty, DO NOT abort. Instead, proceed with the builds and include these changes in the final unified release commit. This ensures a zero-friction path while capturing all intended changes in the release history.
- A dirty worktree is handled by the release housekeeping flow - never by `git restore` or discarding changes.
