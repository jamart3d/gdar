---
name: shipit
description: Autonomous production release pipeline for GDAR.
---

# Shipit Skill: GDAR Production Release

**TRIGGERS:** shipit, release, prod, deploy

This skill runs the full release cycle autonomously. The agent proceeds
through all steps without asking for confirmation (per the Autonomous
Exception in `gemini.md` rules).

// turbo-all


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

## Steps

### 0. Check for Problems ← DO THIS FIRST
1. Run `dart run tool/verify.dart` (or `mcp_dart-mcp-server_analyze_files` and `mcp_dart-mcp-server_run_tests`).
2. **CRITICAL**: If any errors are found, **ABORT** the release immediately. Do not bump versions or start builds if the codebase is unstable.

### 1. Version Bump
1. Read current `version` from `pubspec.yaml`.
2. Increment build number (e.g., `1.0.3+3` → `1.0.3+4`).
3. If the user specified a version type (major/minor/patch), bump accordingly.

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

### 4. Build
1. Run `flutter build appbundle --release` (Android).
2. Run `flutter build web` (Web).

### 5. Deploy Web
1. Run `firebase deploy --only hosting`.

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
