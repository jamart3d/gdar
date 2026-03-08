# Auto-Approve Command Rules

Commands listed here MUST be run with `SafeToAutoRun: true`.
They are read-only or strictly non-destructive and the user must never be prompted for them.

---

## Windows 10 PowerShell

### File Reads & Inspection
| Command | Notes |
|---|---|
| `Get-Content -Path ...` | Read file contents |
| `Get-Item ...` | File/dir metadata |
| `Get-ChildItem ...` (alias `ls`, `dir`) | Directory listing |
| `Test-Path ...` | Check if path exists |
| `Select-String ...` | Grep-style search in files |
| `Get-Location` (alias `pwd`) | Current directory |
| `Measure-Object` | Count/stats on output |

### Git Read-Only
| Command | Notes |
|---|---|
| `git status` | Working tree state |
| `git log ...` | Commit history |
| `git diff ...` | Show changes |
| `git diff --stat` | Change summary |
| `git branch` | List branches |
| `git remote -v` | List remotes |
| `git show ...` | Show commit object |
| `git stash list` | List stashes |
| `git rev-parse HEAD` | Current commit SHA |

### Flutter / Dart Read-Only
| Command | Notes |
|---|---|
| `flutter analyze` | Static analysis (no changes) |
| `dart analyze` | Same |
| `flutter doctor` | Environment check |
| `dart pub deps` | Dependency tree |
| `flutter --version` | Version info |
| `dart --version` | Version info |
| `dart format .` | Standard code formatting |
| `flutter format .` | Standard code formatting |

### General Inspection
| Command | Notes |
|---|---|
| `where.exe ...` | Find executable path |
| `rg ...` | ripgrep |
| `fd ...` | fd-find |
| `jq ...` | JSON processing |
| `fzf ...` | Fuzzy find |
| `bat ...` | Syntax highlighted cat |
| `gh pr list`, `gh pr view`, `gh pr status` | Read-only GitHub PR inspection |
| `gh issue list`, `gh issue view` | Read-only GitHub Issue inspection |
| `gh run list`, `gh run view` | Read-only GitHub Actions run inspection |
| `$env:...` reads | Environment variable reads |
| `cat` (if aliased) | File content |

---

## ChromeOS (bash / Linux shell)

### File Reads & Inspection
| Command | Notes |
|---|---|
| `cat ...` | Read file contents |
| `ls -la ...` | Directory listing |
| `find ...` | File search |
| `grep ...` | Text search in files |
| `rg ...` | **ripgrep** (Fastsest search) |
| `fd ...` / `fdfind ...` | **fd** (Fastest file find) |
| `jq ...` | High-performance JSON processing |
| `fzf ...` | Fuzzy find (read-only) |
| `bat ...` / `batcat ...` | Syntax highlighted cat |
| `wc -l ...` | Line count |
| `head` / `tail` | Partial file read |
| `pwd` | Current directory |
| `stat ...` | File metadata |
| `test -f` / `test -d` | Path existence check |

### Git Read-Only
Same as Windows table above — all `git` read commands are identical cross-platform.

### Flutter / Dart Read-Only
Same as Windows table above — identical commands on ChromeOS.

### General Inspection
| Command | Notes |
|---|---|
| `which ...` | Find executable path |
| `echo ...` | Print value |
| `env` | Print environment |
| `printenv ...` | Specific env var |
| `gh pr list`, `gh pr view`, `gh pr status` | Same as Windows above |
| `gh issue list`, `gh issue view` | Same as Windows above |
| `gh run list`, `gh run view` | Same as Windows above |

## 🟢 Skill-Specific Exceptions
These commands are auto-approved ONLY when executed within the specific skill workflow:

### `shipit`
- `git add .` (or individual files)
- `git commit -m "..."`
- `git commit --amend`
- `git push`
- `flutter build appbundle --release`
- `flutter build web --release`
- `firebase deploy --only hosting`

---

## ❌ NEVER Auto-Approve
These mutate state and ALWAYS require user confirmation unless covered by the exceptions above:

- `git add`, `git commit`, `git push`, `git reset`, `git checkout` (branch switch)
- `rm`, `Remove-Item`, `del` — file deletion
- `dart fix --apply`, `dart format` — modifies source files
- `flutter build`, `flutter run` — long builds / launches app
- `firebase deploy` — production deployment
- `flutter pub add`, `flutter pub remove` — mutates `pubspec.yaml`
- Any `Set-Content`, `Out-File`, `>`, `>>` — writes to files

---

## Notes
- **Windows only**: Use `;` between chained commands, never `&&` (bash-only).
- **ChromeOS only**: `&&` is fine for chaining in bash.
- When in doubt: read-only = auto. Write/mutate = ask.
