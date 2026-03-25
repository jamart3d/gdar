---
trigger: always_on
---

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
| `Get-ChildItem docs/*.md` | List documentation files |
| `Test-Path ...` | Check if path exists |
| `Select-String ...` | Grep-style search in files (Safe) |
| `Get-Location` (alias `pwd`) | Current directory (Safe) |
| `Measure-Object` | Count/stats on output (Safe) |
| `Select-Object` | Select specific properties (Safe) |
| `Get-ChildItem -Path .agent/ -Recurse ...` | Recursive indexing (Safe) |
| `Get-ChildItem -Path .agent/ -Recurse | Select-Object FullName` | Exact indexing command (Safe) |
| `git ls-files .agent/` | Git-based indexing (Safe) |
| `sls ...` | Alias for Select-String (Safe) |

### Git Read-Only
| Command | Notes |
|---|---|
| `git status` | Working tree state |
| `git log ...` | Commit history |
| `git diff ...` | Show changes |
| `git diff --stat` | Change summary |
| `git diff --name-only ...` | List changed files (Safe) |
| `git branch` | List branches |
| `git remote -v` | List remotes |
| `git show ...` | Show commit object |
| `git stash list` | List stashes |
| `git rev-parse HEAD` | Current commit SHA |
| `git add`| `git commit`

### Flutter / Dart Read-Only
| Command | Notes |
|---|---|
| `flutter analyze` | Static analysis (no changes) |
| `dart analyze` | Same |
| `flutter doctor` | Environment check |
| `dart pub deps` | Dependency tree |
| `flutter --version`, `dart --version` | Version info |
| `... --help` (melos, flutter, firebase) | CLI Discovery (Safe and Read-only) |
| `melos --help` | Melos discovery (Safe) |
| `flutter --help` | Flutter discovery (Safe) |
| `dart --help` | Dart discovery (Safe) |
| `melos run analyze` | Static analysis (all apps) |
| `melos run format` | Workspace formatting |
| `melos run test` | Workspace tests |
| dart fix --apply; melos run format; melos run analyze | Chained health check (Safe) |
| `dart fix --apply`, `flutter format .` | Standard code formatting |

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
| `rg ...` | **ripgrep** (fastest search) |
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
Same as Windows table above - all `git` read commands are identical cross-platform.

### Flutter / Dart Read-Only
Same as Windows table above - identical commands on ChromeOS.

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

## Workflow-Specific Exceptions
These commands are auto-approved only when executed within the specific release or health workflows:

### `deploy`, `shipit`, `checkup`, `verify`, `audit`, `size_guard`
- Stage only the intended release files after verifying `git status`.
- `git status`
- `git add .`
- `git commit -m "..."`
- `git commit -m "..."`
- `git push`
- `git push --no-verify`
- Chained release finalization: `git add . ; git commit -m "..." ; git push`
- Chained release finalization: `git status; melos run format; melos run analyze; melos run test`
- Chained release finalization: `git commit -m "release: $(dart scripts/get_current_version.dart)"`
- Chained release finalization: `cd apps/gdar_mobile; flutter build appbundle --release`
- `git rev-parse HEAD ; git status ; melos run format`
- `git rev-parse HEAD ; git status ; melos run analyze`
- `git status ; melos --version`
- `git status ; git rev-parse HEAD`
- `git rev-parse HEAD ; git status`
- `git status; git rev-parse HEAD`
- `git rev-parse HEAD; git status`
- `flutter build appbundle --release`
- `cd apps/gdar_mobile ; flutter build appbundle --release`
- `flutter build web --release`
- `flutter build web`
- `cd apps/gdar_web ; flutter build web`
- `flutter build apk --analyze-size ...`
- `firebase deploy --only hosting`
- `./scripts/size_guard/audit_assets.ps1`, `./scripts/size_guard/audit_assets.sh`
- `melos run test`, `melos run analyze`, `melos run format`, `melos run icons`
- `dart fix --apply` (Health check auto-fix)
- MCP: `mcp_dart-mcp-server_dart_fix`, `mcp_dart-mcp-server_dart_format`, `mcp_dart-mcp-server_run_tests`
- `dart scripts/bump_version.dart patch`, `dart scripts/bump_version.dart minor`
- `dart fix --apply; melos run format; melos run analyze`
- `git rev-parse HEAD`, `git diff --stat`, `git status`

---

## NEVER Auto-Approve
These mutate state and ALWAYS require user confirmation unless covered by the exceptions above:

- `rm`, `Remove-Item`, `del` - file deletion
---

## Notes
- **Windows only**: Use `;` between chained commands, never `&&` (bash-only).
- **ChromeOS only**: `&&` is fine for chaining in bash.
- When in doubt: read-only = auto. Write/mutate = ask.
