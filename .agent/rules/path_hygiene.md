---
trigger: always_on
---
# Path Hygiene

Use repo-relative paths in docs, rules, workflows, skills, and specs whenever possible.

## Rules
- Prefer paths like `apps/gdar_web`, `packages/shakedown_core`, `docs/TV_DEBUGGING.md`, and `.agent/rules/GEMINI.md`.
- Avoid machine-specific absolute paths such as `C:\Users\...`, `/home/...`, and `file:///...` in project documentation.
- Use absolute or platform-specific paths only inside commands that truly require them.
- When writing examples for both Windows and ChromeOS/Linux, keep the file reference itself repo-relative and only vary the command syntax.
- If a markdown link would require a machine-specific absolute path, prefer plain repo-relative code formatting instead.
- Treat `.agent/appdata` as reserved project state, not as a scratch cache directory. Never redirect `APPDATA`, `LOCALAPPDATA`, Pub cache, Dart cache, Flutter cache, or analysis-server state into `.agent/appdata`; use escalation or another explicitly approved location instead.
