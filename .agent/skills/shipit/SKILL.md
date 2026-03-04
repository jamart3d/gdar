---
name: shipit
description: Autonomous production release pipeline for GDAR.
---

# Shipit Skill: GDAR Production Release

**TRIGGERS:** shipit, release, prod, deploy

This skill runs the full release cycle autonomously. The agent proceeds
through all steps without asking for confirmation (per the Autonomous
Exception in `gemini.md` rules).

## Prerequisites
- All changes committed and tests passing.
- `CHANGELOG.md` has an `[Unreleased]` section with pending entries.
- `.agent/notes/pending_release.md` has staged notes (optional — will
  be merged into CHANGELOG if present).

## Steps

### 1. Version Bump
1. Read current `version` from `pubspec.yaml`.
2. Increment build number (e.g., `1.0.3+3` → `1.0.3+4`).
3. If the user specified a version type (major/minor/patch), bump accordingly.

### 2. Finalize Changelog
1. Read `.agent/notes/pending_release.md`.
2. Move entries from `[Unreleased]` to a new version heading in `CHANGELOG.md`.
3. Clear `pending_release.md` back to its template.

### 3. Build
1. Run `flutter build appbundle --release` (Android).
2. Run `flutter build web --release` (Web).

### 4. Deploy Web
1. Run `firebase deploy --only hosting`.

### 5. Generate Play Store Release Note
1. Extract the bullet points from the new version block just added to `CHANGELOG.md`.
2. Strip all markdown formatting (bold, backticks, links).
3. Convert `- ` list items to `•` bullets.
4. Prepend with `What's new in vX.X.X`.
5. Trim to ≤500 characters (Google Play Console limit).
6. **Overwrite** root-level `PLAY_STORE_RELEASE.txt` with the result.
7. Display the contents so the user can review it before uploading.

### 6. Git Sync
1. `git add .`
2. `git commit -m "Release vX.X.X+N"`
3. `git push`

### 7. Notify
1. Inform user the build is ready.
2. Remind to upload AAB to [Google Play Console](https://play.google.com/console).
3. Tell user `PLAY_STORE_RELEASE.txt` is ready to copy/paste into Play Console release notes.

### 8. Post-Launch Debrief
1. Run the `/session_debrief` workflow to evaluate the work that went into this release.
2. Suggest any new `.agent/rules/`, `.agent/skills/`, or `.agent/workflows/` based on lessons learned.

> **IMPORTANT:** Never write to `docs/RELEASE_NOTES.txt`. That file is
> legacy and retired. All release history goes to root `CHANGELOG.md`.
