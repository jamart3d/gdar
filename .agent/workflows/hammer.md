---
description: Heavyweight health check that runs autonomously but provides full verbose output at every step.
---
# Hammer Workflow (Monorepo)
// turbo-all

**TRIGGERS:** hammer, turbo-checkup, brute-force, quick-fix

This workflow is an automated version of `/checkup` that maintains extreme transparency. Every command is executed automatically using optimized MCP tools, but the agent MUST provide full command output logs, stack traces, and detailed summaries to ensure "no black boxes."

> [!WARNING]
> **NO BLACK BOXES**: This workflow is intentionally slow and verbose. Use it when you need to audit every specific change or when automated fixes require human oversight.

> [!IMPORTANT]
> **MONOREPO**: This is a Dart workspace. Run analysis/format/fix from the **workspace root**.

## 1. Atomic Health Pass
1. Run the following health checks and workspace tests via individual terminal commands from the workspace root. **Each command is executed automatically (SafeToAutoRun: true) and the agent must display the full output.**
   - `dart fix --apply`
   - `melos run format`
   - `melos run analyze`
   - `melos run test`

## 2. Visual/Design Check (Micro)
1. Scan current working file for `withOpacity()` (deprecated preference) and suggest `.withValues(alpha: ...)`.
2. Scan for hardcoded colors (e.g., `Colors.red`) and suggest using `colorScheme`.
3. **Audit App Size:** Run the `size_guard` workflow to scan workspace assets for newly added large files or unoptimized PNGs.

## 3. Summary & Finalization
1. If Errors = 0 and Tests = Pass, run staging and pushing automatically:
   - `git add . ; git commit -m "chore: manual hammer pass" ; git push`
2. Provide a detailed summary including:
   - A "Health Score" (0-100).
   - A list of every automated fix applied.
   - Full logs of any linting or formatting changes.
   - Update `.agent/notes/verification_status.json`.
3. If tests failed, provide the full stack trace and offer to trigger the `/issue_report` workflow.
