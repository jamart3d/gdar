---
name: cross_platform_shell
description: Standardized, cross-platform wrappers for operations that break between PowerShell and Bash.
---

# Cross-Platform Shell Execution

When executing commands on behalf of the user, be aware of the underlying OS shell (Windows PowerShell vs. Linux/ChromeOS Bash).

### 1. Command Chaining
- **PowerShell (Windows):** Use `;` to chain commands. (e.g., `cd build; flutter clean; flutter pub get`)
- **Bash (Linux/Mac):** Use `&&` to chain commands conditionally.

### 2. Piping & Data Transfer
- **Constraint:** PowerShell's pipe (`|`) frequently breaks or behaves unreliably in automated execution environments, especially when interacting with interactive tools or transferring large text blocks.
- **Action:** When you need to pass output from one command to another on Windows, or read complex output:
  1. Write the output to a temporary file in `%TEMP%` (e.g., `> $env:TEMP\agent_out.txt`).
  2. Read the file in the subsequent command or via the `read_file` tool.
  3. Clean up the temp file.

### 3. File Manipulation
- Avoid using `cat`, `grep`, `sed`, or `awk` in shell commands unless absolutely necessary. Rely on native agent tools (`view_file`, `grep_search`, `replace_file_content`) first, as they are inherently cross-platform.
