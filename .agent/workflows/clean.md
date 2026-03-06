---
description: Comprehensive root directory cleanup and environment health check.
---

# Clean Home Workflow

**TRIGGERS:** clean, home, hygiene, scrub, doctor

This workflow enforces the "Root Hygiene" rule by identifying and removing non-essential files from the project root.

## 1. Root Directory Audit
// turbo
1. List all files in the project root.
2. Filter against the **Approved List**:
   - `pubspec.yaml`, `pubspec.lock`
   - `README.md`, `CHANGELOG.md`, `TODO.md`
   - `analysis_options.yaml`, `firebase.json`
   - `.gitignore`, `.editorconfig`, `.gitattributes`
   - `.metadata`, `gdar.iml`, `build.yaml`, `devtools_options.yaml`
   - Parent platform directories (`android/`, `ios/`, `lib/`, etc.)

## 2. Identify Intruders
Flag the following for relocation or removal:
- **Temporary Files**: `*.bak`, `*.tmp`, `temp_*`
- **Database Leaks**: `*.hive` (should be moved to `data/` if applicable, or deleted if stale).
- **Orphaned Scripts**: Python scripts or logs created during quick debugging sessions.
