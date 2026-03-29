---
description: Guided production release workflow for GDAR (monorepo).
---
# Shipit Workflow (Monorepo)
// turbo-all


**TRIGGERS:** shipit, release, prod

> [!IMPORTANT]
> **AUTONOMY OVERRIDE & PLANNING MODE**: When this workflow is triggered, provide a single, comprehensive **Release Plan**. Once the user approves the plan, proceed autonomously end-to-end (running analysis/tests, versioning, building, and deploying) without stopping for intermediate permission. Only pause if a critical error occurs. 

> [!WARNING]
> **NO BLACK BOXES**: You are strictly forbidden from chaining multiple long-running terminal commands into a single "black box" string (e.g., `build; build; push`). Run each primary tool (Melos, Flutter build, Firebase) as its own step so progress and status are reported in real-time.

> [!IMPORTANT]
> **EXECUTION MECHANICS**: Follow `.agent/skills/zero_friction_execution/SKILL.md` for async command handling (`WaitMsBeforeAsync: 5000`), polling loop, and fail-fast protocol.

## Platform Sync Mandatory
Both Android (Phone/TV) and Web/PWA targets **MUST** be built and deployed in every release to maintain platform synchronization across the monorepo.

| Target | Path | Build Command |
|---|---|---|
| Android (Phone+TV) | `apps/gdar_mobile` | `flutter build appbundle --release --analyze-size` |
| Web/PWA (Glass) | `apps/gdar_web` | `flutter build web --release --no-wasm` |

---

## 0. Platform Detection
Follow `.agent/rules/platform_detection.md` to identify the current machine and resolve `$MELOS_CAN_HANDLE`.

- **Chromebook**: Run the health suite (steps 1–4 of the Melos pass) and stop. **Do not proceed to versioning, builds, or deploy.** Notify the user: "Flutter builds and Firebase deploy must run on Windows 10."
- **Windows 10**: Run all steps end-to-end.

## 1. Preflight & Smart Skip
1. Run `git status --porcelain` — **abort immediately if the worktree is dirty**. A release must never start from uncommitted changes.
2. Check `.agent/notes/verification_status.json` and run `git rev-parse HEAD`.
3. If (Current SHA == `last_verification_commit`) AND (status == "PASS"):
   - **SKIP** the `melos run` pass and proceed to versioning.
   - Note: A `"PARTIAL"` result does **not** qualify for skip — run the full suite.
4. Else:
   - Resolve `$MELOS_CAN_HANDLE` per `.agent/rules/platform_detection.md`.
   - Run the health suite: `melos run fix`, `melos run format`, `melos run analyze`, and `melos run test`. Explicitly override concurrency only if required by environment constraints.
   - Update `verification_status.json` upon success.

## 2. Platform-Wide Version Bump
1. Run the versioning script:
   - `dart scripts/bump_version.dart patch` (Standard)
   - `dart scripts/bump_version.dart minor` (Feature release)
2. Verify all three app targets (`mobile`, `tv`, `web`) reflect the new version.

## 3. Automated Changelog & Release Notes
1. **Check Unreleased**: Read the `[Unreleased]` block in `CHANGELOG.md`.
   - If empty: **pause and notify the user** — "No unreleased changelog entries found. Add release notes to `[Unreleased]` before continuing."
2. **Move Unreleased**: Move `[Unreleased]` items into a new versioned block in `CHANGELOG.md`.
3. **Update Play Store Note**: Extract the new version's changelog block and PREPEND it to `docs/PLAY_STORE_RELEASE.txt`.
   > [!IMPORTANT]
   > **Sync Verification**: Ensure the version and content in `docs/PLAY_STORE_RELEASE.txt` match `CHANGELOG.md` exactly.

## 4. Sequential Production Builds (Hardware-Aware)

> [!CAUTION]
> **STRICT SEQUENTIAL EXECUTION**: You MUST execute the Android and Web builds sequentially. Wait for Android to finish completely before starting Web. **DO NOT** parallelize these builds, even if `$MELOS_CAN_HANDLE` is high (e.g., 8). `flutter build` maximizes all available threads by default; running two simultaneously will cause extreme system thrashing on the 16-core Windows machine and trigger OOM kills on Chromebooks.

1. **Target 1: Android**: Build the AAB from `apps/gdar_mobile`:
   - `flutter build appbundle --release --analyze-size`
2. **Target 2: Web**: Build the PWA from `apps/gdar_web`:
   - `flutter build web --release --no-wasm`

## 5. Deploy & Git Finalization
1. **Web Deploy**: Run `firebase deploy --only hosting` from the workspace root.
2. **Zero-Friction Staging**:
   - `git add pubspec.yaml apps/*/pubspec.yaml packages/*/pubspec.yaml CHANGELOG.md docs/PLAY_STORE_RELEASE.txt`
   - `git commit -m "release: [new version]"`
   - `git tag v[new version]`
   - `git push && git push --tags`

## 6. Wrap-Up
1. Report build and deploy status clearly.
2. Remind the user to upload `apps/gdar_mobile/build/app/outputs/bundle/release/app-release.aab` to Google Play Console.
3. Confirm `docs/PLAY_STORE_RELEASE.txt` is ready for the Play Console "Release Notes" section.

## Hard Rules
- Never write release history to `docs/RELEASE_NOTES.txt`.
- The workspace is defined by the root `pubspec.yaml`. Melos commands (`melos run *`) are the task runner — they use `melos.yaml` for script definitions, which is fine. Do not add packages to the workspace via `melos.yaml`; use the root `pubspec.yaml` `workspace:` field.
- Never treat this workflow as safe to run blindly on a dirty worktree.
