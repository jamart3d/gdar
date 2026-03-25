---
trigger: always_on
---
# Antigravity Agent Efficiency & Quota Guardrails

You are assisting with a Flutter development environment. To conserve context window and compute quota, you MUST adhere strictly to the following execution rules:

### 1. Mandatory Preview (The "Stop and Ask" Rule)
You are strictly forbidden from executing file modifications, writing code, or running terminal commands without user approval. 
* **Zero-Friction Mandate**: For read-only commands and authorized workflows (`/shipit`, `/deploy`, `/checkup`, `/verify`, `/audit`, `/size_guard`, `/save`), the agent MUST bypass all plans, previews, and manual confirmation prompts. Triggering the workflow counts as final approval; execution must be immediate and autonomous.
* **Ghost Execution**: When any workflow in the 'Zero-Friction Mandate' list is triggered, the agent is STRICTLY FORBIDDEN from generating ANY preamble text or "plans". The very first character of the response MUST be the `run_command` tool call.

### 2. Strict Scope Containment
Do not perform broad searches, index the entire `lib/` directory, or read files that are not strictly necessary.
* **Action:** Only read or modify the specific files the user explicitly mentions. 
* **Workspace Exceptions:** Maintenance/health workflows (`/checkup`, `/audit`, `/verify`, `/size_guard`, `/image_to_code`) are explicitly authorized to perform broad searches and root-level indexing to fulfill their diagnostic and corrective requirements.
* If you need to check a dependency or a state management file to complete a task, you must ask the user for the exact filename first rather than searching the workspace for it.
* **Optimization:** Always call `view_file_outline` before reading a file. Use specific line ranges (`StartLine`/`EndLine`) in `view_file` to minimize context usage.

### 3. No Unauthorized Execution 
Do not assume you need to run the application to test your changes. 
* **Action:** Never automatically trigger `flutter run`, `flutter build`, or any similar execution commands outside of authorized workflows (`/shipit`, `/deploy`, `/checkup`, `/verify`, `/audit`, `/size_guard`). The user manages the application's runtime state; the agent manages health and release tasks. 

### 4. Surgical Code Edits
Do not rewrite or output entire files just to change a few lines.
* **Action:** When proposing a code change, only output the specific function, class, or widget being modified. Use comments like `// ... existing code ...` to represent unchanged portions of the file.

### 5. Fast Mode Default
Unless the user explicitly asks for "deep reasoning" or "architectural planning," assume a fast, reactive mode. Provide direct, immediate answers without long-winded exploratory thinking.

### 6. Terminal Auto-Approve Policy
A curated allow-list of safe commands lives in `.agent/rules/auto_approve.md`.
* **Read-only commands** (file reads, `git status/log/diff`, `flutter analyze`, directory listings, path lookups) MUST always be run with `SafeToAutoRun: true`. Never prompt the user for these.
* **Platform syntax**: Windows 10 uses PowerShell — chain commands with `;`. ChromeOS uses bash — `&&` is fine.
* The `shipit`, `deploy`, `checkup`, `verify`, `audit`, and `size_guard` workflows may use the commands explicitly listed in their respective sections of `auto_approve.md` with `SafeToAutoRun: true` during an active run.
* **URGENT GATING**: The `shipit` workflow must not be triggered by the word "save". It requires explicit release intent such as "shipit", "release", "deploy", or "prod".
* **Save vs. Ship Boundary**: Any request containing "save" must ONLY trigger the `/save` workflow. You are strictly forbidden from jumping to a release pipeline unless the user explicitly confirms a production deployment intent.
* **Confirmation Requirement**: Even for "Autonomous" skills, you must provide a `notify_user` preview before starting the first command if that command is a long-running build or production deployment. This requirement is **waived** for the `/shipit`, `/deploy`, `/release`, `/checkup`, `/verify`, `/audit`, and `/size_guard` workflows once they have been explicitly initiated by the user.

### 8. Negative Constraint Integrity
To prevent persistent oversights and "stale" implementation details:
* **Action:** When a user explicitly rejects a term, feature, or implementation detail (e.g., "no marquee"), you MUST perform a case-insensitive search across ALL active artifacts (`task.md`, `implementation_plan.md`) and remove or update every instance immediately. 
* **Constraint:** You are strictly forbidden from requesting review via `notify_user` on an artifact that still contains rejected terminology or concepts.

### 9. Technical & Documentation Integrity
To prevent "Cognitive Compression" and information loss during file refactors:
* **Constraint:** When refactoring, splitting, or migrating technical manuals (e.g., `docs/`, `.agent/specs/`), you are STRICTLY FORBIDDEN from summarizing, paraphrasing, or omiting technical blocks (shell commands, Bash/Python scripts, deep-link maps, architectural diagrams).
* **Action:** Content must be moved ATOMICALLY. Every specific configuration detail from the source must exist in the destination before the source is modified or deleted.
* **Verification:** After a documentation split, you must verify that "Anchor Content" (specific CLI strings or script paths) matches the original source exactly.

