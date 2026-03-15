---
trigger: always_on
---
# Root Hygiene Rule (Monorepo)

### Temporary & Backup Files
- **NEVER** write temporary files, backups, debug output, or test results to the project root.
- Scratch files go to `/tmp/` (or `%TEMP%` on Windows).
- If you need to save a "before" copy of a file during a refactor, don't. Git already tracks history.

### Monorepo Layout
This project uses a **Dart workspace monorepo**. The root is the workspace
coordinator, NOT an application target.

- **`apps/`** — Application targets (`gdar_mobile`, `gdar_tv`, `gdar_web`).
  Platform directories (`android/`, `ios/`, `web/`, `linux/`) live **inside**
  each app target, never at root.
- **`packages/`** — Shared packages (`shakedown_core`, `gdar_android`,
  `gdar_fruit`).

### What Belongs at Project Root
Only workspace-level config and documentation belongs at root:
- `pubspec.yaml` (workspace coordinator — no `version:` field)
- `pubspec.lock`, `melos.yaml`, `analysis_options.yaml`, `build.yaml`
- `firebase.json`, `.firebaserc`
- `README.md`, `CHANGELOG.md`, `TODO.md`, `AGENTS.md`
- `.gitignore`, `.editorconfig`, `.gitattributes`
- `.metadata`, `devtools_options.yaml`
- Directories: `apps/`, `packages/`, `docs/`, `scripts/`, `data/`, `.agent/`

### What Does NOT Belong at Root
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` — these are
  per-app and live inside `apps/<target>/`.
- `lib/`, `test/` — app-level code lives inside each app or package target.
- `*.tmp`, `*.bak`, `*.log`, `*.bat` — scratch artifacts, never commit.

### Cleanup Responsibility
If you generate any file outside of `apps/`, `packages/`, `.agent/`, or
`docs/`, you must either:
1. Delete it before the task is complete, or
2. Explicitly tell the user it exists and why it should stay.

> [!TIP]
> Use the **`/clean`** workflow to automatically audit and scrub the project root of non-essential files.
