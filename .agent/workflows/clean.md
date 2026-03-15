---
description: Comprehensive root directory cleanup and environment health check.
---

# Clean Home Workflow (Monorepo)

**TRIGGERS:** clean, home, hygiene, scrub, doctor

This workflow enforces the "Root Hygiene" rule by identifying and removing
non-essential files from the monorepo workspace root.

## 1. Root Directory Audit
// turbo
1. List all files in the project root.
2. Filter against the **Approved File List**:
   - `pubspec.yaml`, `pubspec.lock` (workspace coordinator)
   - `melos.yaml`, `build.yaml`, `analysis_options.yaml`
   - `firebase.json`, `.firebaserc`
   - `README.md`, `CHANGELOG.md`, `TODO.md`, `AGENTS.md`
   - `.gitignore`, `.editorconfig`, `.gitattributes`
   - `.metadata`, `devtools_options.yaml`
3. Filter against the **Approved Directory List**:
   - `apps/` — application targets (gdar_mobile, gdar_tv, gdar_web)
   - `packages/` — shared packages (shakedown_core, gdar_android, gdar_fruit)
   - `docs/`, `scripts/`, `data/`, `.agent/`
   - IDE/tooling: `.git/`, `.idea/`, `.vscode/`, `.dart_tool/`, `.firebase/`
   - Build output: `build/` (gitignored)

## 2. Identify Intruders
Flag the following for relocation or removal:
- **Temporary Files**: `*.bak`, `*.tmp`, `*.log`, `temp_*`
- **Orphaned Scripts**: `*.bat`, `*.sh`, `*.py` at root (move to `scripts/`)
- **Database Leaks**: `*.hive` (should be in `data/` or deleted if stale)
- **Legacy Platform Dirs at Root**: `android/`, `ios/`, `web/`, `linux/`,
  `macos/`, `windows/` — these belong inside `apps/<target>/`, not at root.
- **Legacy `lib/` or `test/` at Root**: These belong inside app/package targets.
- **Audit/Report Files**: `*.md` reports not in the approved list above.

## 3. Cleanup
1. Delete confirmed temporary files (`*.tmp`, `*.log`, `*.bak`).
2. Move misplaced scripts to `scripts/`.
3. Flag legacy platform dirs for user confirmation before removal.
4. Report results to user.
