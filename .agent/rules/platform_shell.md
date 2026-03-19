# Platform-Specific Shell Execution Rules

### Claude Code (Linux / ChromeOS)
Claude Code executes commands directly via the Bash tool — no wrapper needed.
- Run `melos` commands from the repo root.
- Build commands (`flutter build appbundle`, etc.) must run from the specific app directory (e.g., `apps/gdar_mobile`).
- Never leave background processes running.

### Jules (Linux / ChromeOS)
Jules wraps commands as: `timeout 60s bash -lc "<command>"`
- Never use interactive shells.

### Windows (PowerShell / cmd — build & deploy only)
Build and deploy commands run on Windows. See `.agent/notes/pending_release.md` for exact commands.
- Use `cmd /c` for shell executions to ensure the process terminates correctly.
- Avoid interactive shells.
- Flutter and Firebase CLI paths are on the Windows PATH, not the Linux PATH.

### Which Machine Does What
| Task | Machine |
|---|---|
| Code editing, tests, analysis | Linux / ChromeOS (Claude Code / Jules) |
| `flutter build appbundle` | Windows |
| `firebase deploy` | Windows |
| `flutter build web` | Windows |
