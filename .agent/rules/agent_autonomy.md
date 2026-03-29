---
trigger: always_on
---
# Agent Autonomy & Execution Policy

This policy defines the authority boundaries, efficiency guardrails, and execution permissions for the Antigravity agent.

## 1. Zero-Friction Workflows & Mandatory Preview
You are strictly forbidden from executing file modifications, writing code, or running terminal commands without user approval **EXCEPT** under the Zero-Friction Mandate:

* **Zero-Friction Mandate**: For read-only commands and authorized workflows (`/shipit`, `/release`, `/deploy`, `/prod`, `/checkup`, `/health`, `/lint-fix`, `/audit`, `/glass`, `/liquid_glass`, `/verify`, `/audit_size`, `/size_guard`, `/save`, `/commit`), the agent MUST bypass all plans, previews, and manual confirmation prompts. Triggering the workflow counts as final approval; execution must be immediate and autonomous.
* **Ghost Execution**: When any workflow in the list above is triggered, the agent is STRICTLY FORBIDDEN from generating ANY preamble text or "plans". The very first character of the response MUST be the `run_command` tool call.
* **Save vs. Ship Boundary**: Any request containing "save" must ONLY trigger the `/save` workflow. You are strictly forbidden from jumping to a release pipeline unless the user explicitly confirms a production deployment intent.

## 2. Auto-Run Command Lists
Read-only and diagnostic commands MUST always be executed with `SafeToAutoRun: true`. Never prompt the user for these.

### Approved Commands (Bash/Linux/ChromeOS):
- **General**: `ls`, `pwd`, `cat`, `head`, `tail`, `wc`, `stat`, `find`.
- **Search**: `grep`, `rg` (ripgrep), `fd`, `jq`, `fzf`.
- **Git**: `git status`, `git log`, `git diff`, `git branch`, `git remote`, `git rev-parse HEAD`.
- **Flutter/Dart**: `flutter analyze`, `dart analyze`, `flutter doctor`, `dart pub deps`.
- **Formatting**: `melos run format`, `dart fix --apply`, `flutter format .`.

### Chained Sequences (Release Finalization):
- `git add . ; git commit -m "..." ; git push`
- `melos run test; melos run analyze; melos run format`

## 3. Protocol: Fail Fast, No Black Boxes
- **No Black Boxes**: Every primary step in an autonomous chain MUST be run as a discrete tool call to provide real-time status visibility.
- **Fail Fast**: Stop immediately on any step failure. Never "fix and proceed" without new user evaluation.
- **Plan First**: For complex release/audit tasks not in the Zero-Friction list, provide a single plan **once** before starting the autonomous chain.

## 4. Prohibited Actions (Always Prompt)
- `rm`, `Remove-Item`, `del` (Filesystem deletion of project files).
- Multi-step destructive mutations outside of the `/shipit` or `/checkup` scope.

## 5. Scope Containment & Efficiency
To conserve context window and compute quota:
- Do not perform broad searches, index the entire `lib/` directory, or read files not strictly necessary.
- **Workspace Exceptions:** Maintenance/health workflows (`/checkup`, `/audit`, `/verify`, `/size_guard`, `/image_to_code`) are explicitly authorized to perform broad searches and root-level indexing.
- **Optimization:** Always call `view_file_outline` before reading a file. Use specific line ranges (`StartLine`/`EndLine`).
- **Surgical Edits:** When proposing a code change, only output the specific function or widget being modified.
- **Fast Mode Default:** Provide direct, immediate answers without long-winded exploratory thinking.
- Never automatically trigger `flutter run` or `flutter build` outside authorized workflows.

## 6. Constraint Integrity
- **Negative Constraint Integrity:** When a user explicitly rejects a term or feature, perform a search across active artifacts (`task.md`, `implementation_plan.md`) and remove every instance immediately. Never request review on an artifact containing rejected concepts.
- **Documentation Integrity:** When refactoring technical manuals, you are STRICTLY FORBIDDEN from summarizing or omitting technical blocks. Content must be moved ATOMICALLY.
