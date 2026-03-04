<!-- Path: docs/dev_environment.md -->
# Dev Environment: Windows 10 + ChromeOS Setup

This project is developed across **Windows 10** and a **Chromebook
(ChromeOS / Crostini)**, synced via Git.

---

## 1. Line Endings
Windows = CRLF. Linux/ChromeOS = LF. Flutter tooling is LF-native.

Three safeguards are in place (all automatic and non-destructive):

| File               | Purpose                                        |
|--------------------|------------------------------------------------|
| `.editorconfig`    | Editor writes LF, indents Dart with 2 spaces.  |
| `.gitattributes`   | Git stores everything as LF for future commits. |
| `.vscode/settings` | `"files.eol": "\n"` enforces LF in VS Code.    |

> Do **NOT** run `git add --renormalize` unless you have an active
> CRLF problem — it is unnecessary if things are already working.

---

## 2. Flutter SDK Paths
* **Windows 10:** `C:\flutter` (no spaces). Add `C:\flutter\bin` to PATH.
* **ChromeOS (Crostini):** `~/flutter`. Add to `~/.bashrc`:
  ```bash
  export PATH="$HOME/flutter/bin:$PATH"
  ```
* `dart.flutterSdkPath` in `.vscode/settings.json` is `null` —
  auto-detects from PATH on both machines. No machine-specific path
  is ever committed.

---

## 3. Git Sync Workflow
`git.autofetch` is disabled to preserve resources on ChromeOS.
Manual fetch/pull required before starting work.

After pulling: `flutter pub get` is almost always sufficient.

---

## 4. Performance Notes (Crostini)
* Allocate **4 GB+ RAM** to the Linux container.
* `.vscode/settings.json` excludes `.dart_tool/`, `build/`, `.gradle/`
  from the file watcher to reduce I/O overhead.
* Avoid `flutter clean` on Crostini — slow disk I/O makes full
  rebuilds painful. Use `flutter pub get` instead.

---
*Last Updated: 2026-03-04*
