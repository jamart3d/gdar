---
trigger: always_on
---
# Agent Autonomy & Execution Policy

This policy defines the authority boundaries, efficiency guardrails, and execution permissions for the Antigravity agent.

## 1. Zero-Friction Workflows & Mandatory Preview
You are strictly forbidden from executing file modifications, writing code, or running terminal commands without user approval **EXCEPT** under the Zero-Friction Mandate:

* **Zero-Friction Mandate**: For read-only commands and authorized workflows (`/shipit`, `/release`, `/deploy`, `/prod`, `/checkup`, `/health`, `/lint-fix`, `/audit`, `/clean`, `/glass`, `/liquid_glass`, `/verify`, `/audit_size`, `/size_guard`, `/save`, `/commit`), the agent MUST bypass all plans, previews, and manual confirmation prompts. Triggering the workflow counts as final approval; execution must be immediate and autonomous.
* **Ghost Execution**: When any workflow in the list above is triggered, the agent is STRICTLY FORBIDDEN from generating ANY preamble text or "plans". Workflow execution must begin immediately with the first concrete tool step.
* **Subworkflow Inheritance**: Any internal rule, preflight, or subworkflow invoked by an authorized Zero-Friction workflow inherits that approval automatically. The agent MUST NOT ask for a second confirmation just because the parent workflow reads or runs `.agent/workflows/toolchain_preflight.md`, `.agent/rules/platform_detection.md`, or similar workflow infrastructure.
* **Save vs. Ship Boundary**: Any request containing "save" must ONLY trigger the `/save` workflow. You are strictly forbidden from jumping to a release pipeline unless the user explicitly confirms a production deployment intent.

## 2. Auto-Run Command Lists
Read-only and diagnostic commands MUST always run under the Zero-Friction Mandate without extra confirmation. Never prompt the user for these.

### 0. Unified Preflight (Turbo)
// turbo
1. Run the unified preflight script:
   - `dart scripts/preflight_check.dart --release`
2. **If output is `CHROMEBOOK`:**
   - Notify the user: "Chromebook detected - health suite only. Flutter builds and Firebase deploy must run on Windows 10."
   - Run step 1 (health suite) and then **stop**. Do not proceed to versioning, builds, or deploy.
3. **If output is `WINDOWS_10`:**
   - Continue to all steps end-to-end.

### 0.5. Process Hygiene
Follow `.agent/rules/process_hygiene.md` to detect and handle any hung `flutter`, `dart`, or `melos` processes before proceeding. Re-run `git status --porcelain` after killing any processes.

### Approved Commands (Bash/Linux/ChromeOS/PowerShell):
- **General**: `ls`, `pwd`, `cat`, `head`, `tail`, `wc`, `stat`, `find`, `dir`.
- **Search**: `grep`, `rg` (ripgrep), `fd`, `jq`, `fzf`, `findstr`, `Select-String`.
- **Git (Diagnostic)**: `git status`, `git log`, `git diff`, `git branch`, `git remote`, `git rev-parse HEAD`.
- **Git (Mutating - Authorized Context ONLY)**: `git add`, `git commit`, `git push`, `git tag`. (Must be part of `/shipit`, `/save`, `/commit`, or `/release` flows).
- **Flutter/Dart**: `flutter analyze`, `dart analyze`, `flutter doctor`, `dart pub deps`, `dart run scripts/*.dart`, `flutter pub outdated`, `flutter clean`, `flutter pub get`, `flutter build appbundle --release`, `flutter build appbundle --debug`, `flutter build apk --analyze-size`, `flutter build web --release`.
- **Formatting & Health**: `melos run format`, `melos run analyze`, `melos run test`, `melos run fix`, `melos help`, `melos exec`, `melos bootstrap`, `dart fix --apply`, `flutter format .`, `flutter test`, `jules`.
- **PowerShell Diagnostics**: `Get-ChildItem`, `Measure-Object`, `Get-Content`, `Get-Item`.
- **Project Scripts**: `./scripts/**/*.ps1`, `./scripts/**/*.sh`, `dart scripts/*.dart`.

## 3. Protocol: Fail Fast, No Black Boxes
- **No Black Boxes**: Every primary step in an autonomous chain MUST be run as a discrete tool call to provide real-time status visibility.
- **Fail Fast**: Stop immediately on any step failure. Never "fix and proceed" without new user evaluation.
- **Plan First**: For complex release/audit tasks not in the Zero-Friction list, provide a single plan **once** before starting the autonomous chain.

## 4. Prohibited Actions (Always Prompt)
- `rm`, `Remove-Item`, `del` (Filesystem deletion of project source/config files outside of authorized cleanup/release workflows).
- `git restore`, `git reset --hard` (Destructive worktree modification).
- Multi-step destructive mutations outside of the `/shipit`, `/checkup`, or `/clean` scope.

## 5. Scope Containment & Efficiency
To conserve context window and compute quota:
- Do not perform broad searches, index the entire `lib/` directory, or read files not strictly necessary.
- **Workspace Exceptions:** Maintenance/health workflows (`/checkup`, `/audit`, `/clean`, `/verify`, `/size_guard`, `/image_to_code`) are explicitly authorized to perform broad searches and root-level indexing.
- **Discovery Firewall (Hard Constraint):** Even during Workspace Exceptions, any directory named `archive`, `temp`, or `backups` MUST be skipped by discovery tools (`grep`, `dir /s`, etc.) unless the user has explicitly requested access to a file within them.
- **Optimization:** Always call `view_file_outline` before reading a file. Use specific line ranges (`StartLine`/`EndLine`).
- **Surgical Edits:** When proposing a code change, only output the specific function or widget being modified.
- **Fast Mode Default:** Provide direct, immediate answers without long-winded exploratory thinking.
- Never automatically trigger `flutter run` or `flutter build` outside authorized workflows.

## 6. Constraint Integrity
- **Negative Constraint Integrity:** When a user explicitly rejects a term or feature, perform a search across active artifacts (`task.md`, `implementation_plan.md`) and remove every instance immediately. Never request review on an artifact containing rejected concepts.
- **Documentation Integrity:** When refactoring technical manuals, workflows, or rules, you are STRICTLY FORBIDDEN from summarizing, omitting, or deleting technical blocks, logic gates, hard rules, or caution banners. Content must be moved ATOMICALLY and verified for logical parity.

## 7. Anti-Apology Protocol
- **Auto-Correction Over Apology**: When a mistake is made, or a constraint is violated (e.g., using print instead of logger), you are STRICTLY FORBIDDEN from generating an apology. Instead, you MUST automatically find a one-line structural constraint to prevent the mistake, update the appropriate `.md` rule or workflow file to permanently codify it, and inform the user that the system has learned from the error.
