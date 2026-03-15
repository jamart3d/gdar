---
name: shipit
description: Autonomous production release pipeline for GDAR (monorepo).
---

# Shipit Skill: GDAR Production Release

**TRIGGERS:** shipit, release, prod, deploy

This skill runs the full release cycle autonomously. The agent proceeds
through all steps without asking for confirmation (per the Autonomous
Exception in `gemini.md` rules).

// turbo-all

## Monorepo Layout

GDAR is a Dart workspace monorepo. Build targets live under `apps/`:

| Target | Path | Build Command |
|---|---|---|
| Android (Phone/Tablet) | `apps/gdar_mobile` | `flutter build appbundle --release` |
| Google TV | `apps/gdar_tv` | `flutter build appbundle --release` |
| Web/PWA | `apps/gdar_web` | `flutter build web` |

- **Version** lives in each app target's `pubspec.yaml` — bump ALL of them.
- **Firebase** config is at the project root. The `public` path is
  `apps/gdar_web/build/web`.
- **Root `pubspec.yaml`** (`gdar_root`) is the workspace coordinator and
  has NO `version:` field.

> **IMPORTANT — Sequential Builds**: Run builds ONE AT A TIME, never in
> parallel. Parallel builds cause git index lock collisions during the
> Git Sync step because both terminals share the same `.git/` directory.


## PowerShell Rules (Windows 10)
- **Command separator**: Always use `;` between chained commands. Never use `&&` (bash-only).
- **Read-only commands are always safe**: `Get-Content`, `Get-Item`, `Test-Path`, and any
  other read-only PowerShell command must **always** be run with `SafeToAutoRun: true`.
  These change nothing and the user must never be prompted for them.


## Prerequisites
- All changes committed and tests passing.
- `CHANGELOG.md` has an `[Unreleased]` section with pending entries.
- `.agent/notes/pending_release.md` has staged notes (optional — will
  be merged into CHANGELOG if present).
- All app target `pubspec.yaml` files have `publish_to: none`.

## Steps

### 0. Check for Problems ← DO THIS FIRST
1. Run `mcp_dart-mcp-server_analyze_files` on the workspace root.
2. **CRITICAL**: If any **errors** (severity 1) are found, **ABORT** immediately.
   Severity 2 warnings (e.g., `invalid_dependency`) are acceptable if
   `publish_to: none` is already set.

### 0.5. Quality Gate (Melos)
1. Run `melos run format`.
2. Run `melos run analyze`.
3. Run `melos run test`.
4. If any step fails, **ABORT** and report the failure.

### 1. Version Bump
1. Read current `version` from each app target's `pubspec.yaml`:
   - `apps/gdar_mobile/pubspec.yaml`
   - `apps/gdar_tv/pubspec.yaml`
   - `apps/gdar_web/pubspec.yaml`
2. Evaluate the scope of work to decide on the bump:
   - **Patch**: For bug fixes and small tweaks (e.g., `1.2.1` -> `1.2.2`).
   - **Minor**: For new features (e.g., `1.2.1` -> `1.3.0`).
   - **Build Number**: Always increment the `+N` part for every release (e.g., `+201` -> `+202`).
3. If the user specified a version type (major/minor/patch), bump accordingly. Defaults to a patch bump for routine releases.
4. Bump ALL app targets to the same version.

### 2. Finalize Changelog
1. Read `.agent/notes/pending_release.md`.
2. Move entries from `[Unreleased]` to a new versioned heading in `CHANGELOG.md`.
3. **IMPORTANT — insertion order**: The new version block must be inserted
   **above** the previous release (i.e., immediately after the file header),
   so the file stays newest-first. Never insert below an existing release block.
4. Leave a fresh empty `[Unreleased]` section at the top (above the new block).
5. Clear `pending_release.md` back to its template.

### 3. Generate Play Store Release Note  ← DO THIS BEFORE BUILDS
1. Extract the bullet points from the new version block just added to `CHANGELOG.md`.
2. Strip all markdown formatting (bold, backticks, links).
3. Convert `- ` list items to `•` bullets.
4. Prepend with `What's new in vX.X.X`.
5. Trim to ≤500 characters (Google Play Console limit).
6. **Prepend** (do NOT overwrite) to `docs/PLAY_STORE_RELEASE.txt` with a
   `---` separator so history is preserved. Format:
   ```
   What's new in vX.X.X
   • ...

   ---

   [previous content]
   ```
7. **Display the contents now** so the user can review while builds run.

### 4. Build ← SEQUENTIAL, NOT PARALLEL
1. `cd apps/gdar_mobile` → `flutter build appbundle --release` (Android).
2. Wait for completion.
3. `cd apps/gdar_web` → `flutter build web` (Web).
4. Wait for completion.

> Do NOT run these in parallel — they share the same `.git/` directory
> and parallel git operations will cause index lock failures.

### 5. Deploy Web
1. Run `firebase deploy --only hosting` from the **project root** (not from `apps/gdar_web`).
   - The root `firebase.json` has `"public": "apps/gdar_web/build/web"`.

### 6. Git Sync
1. `git add .`
2. `git commit -m "Release vX.X.X+N"`
3. `git push`
4. **PowerShell note**: Run as separate commands or use `;` as separator.
   Never use `&&` — that is bash-only and will fail on Windows PowerShell.

### 7. Notify
1. Inform user the build is ready.
2. Remind to upload AAB to [Google Play Console](https://play.google.com/console).
3. Tell user `docs/PLAY_STORE_RELEASE.txt` is ready to copy/paste into Play Console release notes.

### 8. Post-Launch Debrief
1. Run the `/session_debrief` workflow to evaluate the work that went into this release.
2. Suggest any new `.agent/rules/`, `.agent/skills/`, or `.agent/workflows/` based on lessons learned.

> **IMPORTANT:** Never write to `docs/RELEASE_NOTES.txt`. That file is
> legacy and retired. All release history goes to root `CHANGELOG.md`.
