---
trigger: always_on
---
# Root Hygiene Rule

### Temporary & Backup Files
- **NEVER** write temporary files, backups, debug output, or test results to the project root.
- Scratch files go to `/tmp/` (or `%TEMP%` on Windows).
- If you need to save a "before" copy of a file during a refactor, don't. Git already tracks history.

### What Belongs at Project Root
Only standard project files belong at root: `pubspec.yaml`, `README.md`, `CHANGELOG.md`, `TODO.md`, `analysis_options.yaml`, `firebase.json`, `.gitignore`, and platform config files.

### Cleanup Responsibility
If you generate any file outside of `lib/`, `test/`, `.agent/`, or `docs/`, you must either:
1. Delete it before the task is complete, or
2. Explicitly tell the user it exists and why it should stay.

> [!TIP]
> Use the **`/clean`** workflow to automatically audit and scrub the project root of non-essential files.

