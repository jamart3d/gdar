---
trigger: always_on
---
# Antigravity Agent Efficiency & Quota Guardrails

You are assisting with a Flutter development environment. To conserve context window and compute quota, you MUST adhere strictly to the following execution rules:

### 1. Mandatory Preview (The "Stop and Ask" Rule)
You are strictly forbidden from executing file modifications, writing code, or running terminal commands without user approval. 
* **Action:** You must ALWAYS provide a concise preview or step-by-step plan of exactly what you intend to do. 
* **Wait:** Pause and wait for explicit confirmation from the user before executing the plan.

### 2. Strict Scope Containment
Do not perform broad searches, index the entire `lib/` directory, or read files that are not strictly necessary.
* **Action:** Only read or modify the specific files the user explicitly mentions. 
* If you need to check a dependency or a state management file to complete a task, you must ask the user for the exact filename first rather than searching the workspace for it.
* **Optimization:** Always call `view_file_outline` before reading a file. Use specific line ranges (`StartLine`/`EndLine`) in `view_file` to minimize context usage.

### 3. No Unauthorized Execution 
Do not assume you need to run the application to test your changes. 
* **Action:** Never automatically trigger `flutter run`, `flutter build`, or any similar execution commands. The user manages the build and execution state independently. 

### 4. Surgical Code Edits
Do not rewrite or output entire files just to change a few lines.
* **Action:** When proposing a code change, only output the specific function, class, or widget being modified. Use comments like `// ... existing code ...` to represent unchanged portions of the file.

### 5. Fast Mode Default
Unless the user explicitly asks for "deep reasoning" or "architectural planning," assume a fast, reactive mode. Provide direct, immediate answers without long-winded exploratory thinking.

### 6. Terminal Auto-Approve Policy
A curated allow-list of safe commands lives in `.agent/rules/auto_approve.md`.
* **Read-only commands** (file reads, `git status/log/diff`, `flutter analyze`, directory listings, path lookups) MUST always be run with `SafeToAutoRun: true`. Never prompt the user for these.
* **Platform syntax**: Windows 10 uses PowerShell — chain commands with `;` not `&&`. ChromeOS uses bash — `&&` is fine.
* Autonomous skills (`shipit`, etc.) are exempt from Rule 1 (Stop and Ask) for the commands explicitly listed in `auto_approve.md`.

### 7. Testing Thresholds (Arlo vs. Jules)
To protect token quota and provide high-performance feedback:
* **Small Tests (< 5 files):** Arlo handles these locally for immediate feedback.
* **Large Tests (Full suite or > 5 files):** Arlo MUST stop and suggest using **Jules** (Web UI or CLI).
* **Action:** If the user asks for a "full test run" or "all tests", Arlo should explain the token cost and provide the Jules CLI command (e.g., `jules new "Run all tests"`) instead of executing `flutter test` locally.

