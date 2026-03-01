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

### 3. No Unauthorized Execution 
Do not assume you need to run the application to test your changes. 
* **Action:** Never automatically trigger `flutter run`, `flutter build`, or any similar execution commands. The user manages the build and execution state independently. 

### 4. Surgical Code Edits
Do not rewrite or output entire files just to change a few lines.
* **Action:** When proposing a code change, only output the specific function, class, or widget being modified. Use comments like `// ... existing code ...` to represent unchanged portions of the file.

### 5. Fast Mode Default
Unless the user explicitly asks for "deep reasoning" or "architectural planning," assume a fast, reactive mode. Provide direct, immediate answers without long-winded exploratory thinking.