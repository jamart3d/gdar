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

## Platform Sync Mandatory
Both Android (Phone/TV) and Web/PWA targets **MUST** be built and deployed in every release to maintain platform synchronization across the monorepo.

| Target | Path | Build Command |
|---|---|---|
| Android (Phone+TV) | `apps/gdar_mobile` | `flutter build appbundle --release --analyze-size` |
| Web/PWA (Glass) | `apps/gdar_web` | `flutter build web --release --no-wasm` |

---

## 1. Preflight & Smart Skip
1. Review `git status` to ensure a clean starting point.
2. Check `.agent/notes/verification_status.json`.
3. If (Current SHA == Last Verified SHA) AND (Results == Passed):
   - **SKIP** the `melos run` pass and proceed to versioning.
4. Else:
   - Run the health suite: `melos run fix`, `melos run format`, `melos run analyze`, `melos run test`.
   - Update `verification_status.json` upon success.

## 2. Platform-Wide Version Bump
1. Run the versioning script:
   - `dart scripts/bump_version.dart patch` (Standard)
   - `dart scripts/bump_version.dart minor` (Feature release)
2. Verify all three app targets (`mobile`, `tv`, `web`) reflect the new version.

## 3. Automated Changelog & Release Notes
1. **Move Unreleased**: Automatically move `[Unreleased]` items into a new versioned block in `CHANGELOG.md`.
2. **Update Play Store Note**: Extract the new version's changelog block and PREPEND it to `docs/PLAY_STORE_RELEASE.txt`. 
   > [!IMPORTANT]
   > **Sync Verification**: Ensure the version and content in `docs/PLAY_STORE_RELEASE.txt` match `CHANGELOG.md` exactly.

## 4. Sequential Production Builds (Chromebook Optimization)
1. **Target 1: Android**: Build the AAB from `apps/gdar_mobile`:
   - `flutter build appbundle --release --analyze-size`
2. **Target 2: Web**: Build the and PWA from `apps/gdar_web`:
   - `flutter build web --release --no-wasm`
   - *Note: Sequential builds avoid memory pressure on Chromebook/Crostini.*

## 5. Deploy & Git Finalization
1. **Web Deploy**: Run `firebase deploy --only hosting` from the workspace root.
2. **Zero-Friction Staging**:
   - `git add pubspec.yaml apps/*/pubspec.yaml CHANGELOG.md docs/PLAY_STORE_RELEASE.txt`
   - `git commit -m "release: [new version]"`
   - `git push`

## 6. Wrap-Up
1. Report build and deploy status clearly.
2. Remind the user to upload `apps/gdar_mobile/build/app/outputs/bundle/release/app-release.aab` to Google Play Console.
3. Confirm `docs/PLAY_STORE_RELEASE.txt` is ready for the Play Console "Release Notes" section.

## Hard Rules
- Never write release history to `docs/RELEASE_NOTES.txt`.
- Never rely on `melos.yaml` for workspace orchestration; use the root `pubspec.yaml`.
- Never treat this workflow as safe to run blindly on a dirty worktree.
