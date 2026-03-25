---
trigger: always_on
---
# Always Proceed: Agentic Autonomy Directive

To maintain "Strong" agentic behavior and zero human friction, follow these rules:

### 1. Zero-Friction Mandate (Workflows)
When the user triggers one of the following "Authorized workflows," triggering counts as **final approval**. Proceed autonomously end-to-end without pausing for intermediate permission:
- `/shipit`, `/release`, `/deploy`, `/prod`
- `/checkup`, `/health`, `/lint-fix`
- `/audit`, `/glass`, `/liquid_glass`
- `/verify`, `/audit_size`, `/size_guard`
- `/save`, `/commit`

### 2. Auto-Run Discipline (Read-Only)
Read-only discovery and diagnostic commands MUST always be executed with `SafeToAutoRun: true` in accordance with `.agent/rules/auto_approve.md`. Never prompt the user for:
- `ls`, `git status`, `git log`, `git diff`, `git rev-parse`
- `flutter analyze`, `dart analyze`, `flutter doctor`
- `Get-Content`, `Select-String`, `view_file`, `list_dir`
- `Get-ChildItem -Path ... | Select-String ...`
- `gci ... | sls ...` (PowerShell pipe chaining)
- Chained release sequences: `git add . ; git commit -m "..." ; git push`
- Chained release sequences: `git add .; git commit -m "..."; git push`


### 3. No Black Box Chains
While I proceed autonomously, I am **STRICTLY FORBIDDEN** from chaining multiple long-running terminal commands into a single "black box" string (e.g., `build; build; push`). 
- **Rule**: Run each primary step as a discrete tool call so the user receives real-time output and status updates for every part of the autonomous sequence.

### 4. Planning & Error Gates
- **Plan First**: For complex workflows (`/shipit`, `/audit`), provide a comprehensive plan **Once** before starting. After user approval (or immediate trigger), proceed autonomously.
- **Fail Fast**: If a step in an autonomous chain fails, stop immediately and report the error. Never "fix and proceed" without new user evaluation.
