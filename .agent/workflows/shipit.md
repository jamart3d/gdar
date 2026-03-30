---
description: Guided production release workflow for GDAR (monorepo).
---
# Shipit Workflow (Monorepo)
// turbo-all


**TRIGGERS:** shipit, release, prod

> [!IMPORTANT]
> **AUTONOMY OVERRIDE & PLANNING MODE**: When this workflow is triggered, generate the Release Plan below instantly from current state, present it to the user, and proceed autonomously once triggered. Only pause if a critical error occurs.
>
> **Release Plan format** (generate this before doing anything else):
> ```
> Release Plan
> ─────────────────────────────
> Current version : <dart scripts/get_current_version.dart>
> Bump type       : patch  ← change to "minor" only if user explicitly requested it
> New version     : <calculated>
> Changelog items : <list [Unreleased] entries, or WARN if empty>
> Health suite    : SKIP (SHA match) | RUN (changes detected)
> Builds          : Android AAB + Web PWA (sequential)
> Deploy          : Firebase hosting
> ─────────────────────────────
> ```

> [!WARNING]
> **NO BLACK BOXES**: You are strictly forbidden from chaining multiple long-running terminal commands into a single "black box" string (e.g., `build; build; push`). Run each primary tool (Melos, Flutter build, Firebase) as its own step so progress and status are reported in real-time.

> [!IMPORTANT]
> **EXECUTION MECHANICS**: Follow `.agent/skills/zero_friction_execution/SKILL.md` for async command handling (`WaitMsBeforeAsync: 5000`), polling loop, and fail-fast protocol.

## Platform Sync Mandatory
Both Android (Phone/TV) and Web/PWA targets **MUST** be built and deployed in every release to maintain platform synchronization across the monorepo.

| Target | Path | Build Command |
|---|---|---|
| Android (Phone+TV) | `apps/gdar_mobile` | `flutter build appbundle --release` |
| Web/PWA (Glass) | `apps/gdar_web` | `flutter build web --release --no-wasm` |

---

## 0. Platform Detection (MUST RUN FIRST — before Release Plan)
1. Run this command immediately:
   ```bash
   uname -s 2>/dev/null || echo "Windows_NT"
   ```
2. **If output is `Linux` (Chromebook):**
   - Notify the user: "Chromebook detected — health suite only. Flutter builds and Firebase deploy must run on Windows 10."
   - Run steps 0.5 and 1 (process hygiene + health suite) then **stop**. Do not generate a Release Plan. Do not proceed to versioning, builds, or deploy.
3. **If output is `Windows_NT` (Windows 10):**
   - Resolve `$MELOS_CAN_HANDLE` per `.agent/rules/platform_detection.md`.
   - Continue to Release Plan and all steps end-to-end.

## 0.5. Process Hygiene
Follow `.agent/rules/process_hygiene.md` to detect and handle any hung `flutter`, `dart`, or `melos` processes before proceeding. Re-run `git status --porcelain` after killing any processes — lock files from a hung process can make a clean worktree appear dirty.

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
   - Note: A `"PARTIAL"` result does **not** qualify for skip — run the full suite.
5. Else:
   - Resolve `$MELOS_CAN_HANDLE` per `.agent/rules/platform_detection.md`.
   - Run the health suite: `melos run format`, `melos run analyze`, and `melos run test`. Explicitly override concurrency only if required by environment constraints.
   - Do **not** run `melos run fix` — shipit verifies, it does not auto-modify code. Run `/checkup` first if fixes are needed.
   - Update `verification_status.json` upon success.

## 2. Platform-Wide Version Bump
1. Run the versioning script:
   - `dart scripts/bump_version.dart patch` — default for all releases
   - `dart scripts/bump_version.dart minor` — only if user explicitly requested `minor` in the trigger
2. Confirm the new version: `dart scripts/get_current_version.dart`
3. Verify all three app targets (`mobile`, `tv`, `web`) reflect the new version.

## 3. Automated Changelog & Release Notes
1. **Move Unreleased**:
   - Merge any content from `.agent/notes/pending_release.md` into the `[Unreleased]` section of `CHANGELOG.md`.
   - Clear `.agent/notes/pending_release.md` (reset to header).
   - **Default Entry**: If the section is empty after merging, add `- **Maintenance**: General maintenance and version synchronization.`
   - Move all `[Unreleased]` items into a new versioned block in `CHANGELOG.md`.
2. **Update Play Store Note**: Extract the new version's changelog block and PREPEND it to `docs/PLAY_STORE_RELEASE.txt`.
   > [!IMPORTANT]
   > **Sync Verification**: Ensure the version and content in `docs/PLAY_STORE_RELEASE.txt` match `CHANGELOG.md` exactly.

## 4. Sequential Production Builds (Hardware-Aware)

> [!CAUTION]
> **STRICT SEQUENTIAL EXECUTION**: You MUST execute the Android and Web builds sequentially. Wait for Android to finish completely before starting Web. **DO NOT** parallelize these builds, even if `$MELOS_CAN_HANDLE` is high (e.g., 8). `flutter build` maximizes all available threads by default; running two simultaneously will cause extreme system thrashing on the 16-core Windows machine and trigger OOM kills on Chromebooks.

1. **Target 1: Android**: Build the AAB from `apps/gdar_mobile`:
   - `flutter build appbundle --release`
2. **Target 2: Web**: Build the PWA from `apps/gdar_web`:
   - `flutter build web --release --no-wasm`

## 5. Deploy & Git Finalization
1. **Web Deploy**: Run `firebase deploy --only hosting` from the workspace root.
2. **Unified Release Commit**:
   - `git add .` (Ensures all housekeeping, versioning, and changelog edits are captured together).
   - `git commit -m "release: $(dart scripts/get_current_version.dart)"`
   - `git tag v$(dart scripts/get_current_version.dart)`
   - `git push && git push --tags`

## 6. Wrap-Up
1. Report build and deploy status clearly.
2. Remind the user to upload `apps/gdar_mobile/build/app/outputs/bundle/release/app-release.aab` to Google Play Console.
3. Confirm `docs/PLAY_STORE_RELEASE.txt` is ready for the Play Console "Release Notes" section.

## Hard Rules
- Never write release history to `docs/RELEASE_NOTES.txt`.
- The workspace is defined by the root `pubspec.yaml`. Melos commands (`melos run *`) are the task runner — they use `melos.yaml` for script definitions, which is fine. Do not add packages to the workspace via `melos.yaml`; use the root `pubspec.yaml` `workspace:` field.
- **Never run `git restore`, `git checkout --`, or any destructive reset to clean a dirty worktree.** If the worktree is dirty, abort and tell the user: "Worktree has uncommitted changes — please commit or stash them before releasing." The user decides what to do with their changes, not this workflow.
- A dirty worktree is handled by a pre-release housekeeping commit — never by `git restore` or discarding changes.
