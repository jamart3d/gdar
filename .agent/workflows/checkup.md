---
description: Rapid health check with automated fixes for linting, formatting, and tests.
---
# Checkup Workflow (Monorepo)
// turbo-all

**TRIGGERS:** checkup, health, quick-audit, lint-fix

This workflow is optimized for speed and developer productivity. It prioritizes automated fixes and parallel analysis using optimized MCP tools.

> [!NOTE]
> **FAST MODE DEFAULT**: This workflow is designed to be lean and fast. If significant architectural failures are found, consider upgrading to `/audit` or `/issue_report`.

> [!IMPORTANT]
> **MONOREPO**: This is a Dart workspace. Run analysis/format/fix from the **workspace root** - the Dart tools will recurse into `apps/` and `packages/` automatically.

## 1. Atomic Health Pass
1. Run the health checks and workspace tests via individual terminal commands from the workspace root:
   - `dart fix --apply`
   - `melos run format`
   - `melos run analyze`
   - `melos run test`

## 2. Visual/Design Check (Micro)
1. Scan current working file for `withOpacity()` (deprecated preference) and suggest `.withValues(alpha: ...)`.
2. Scan for hardcoded colors (e.g., `Colors.red`) and suggest using `colorScheme`.
3. **Audit App Size:** Run the `size_guard` workflow to scan workspace assets for newly added large files or unoptimized PNGs.

## 3. Summary & Finalization
1. If Errors = 0 and Tests = Pass:
   // turbo
   - `git add . ; git commit -m "chore: automated checkup pass [skip ci]" ; git push`
2. Only provide a summary after the push is complete. Provide a "Health Score", list automated fixes, and update `.agent/notes/verification_status.json`.
3. If tests failed, offer to trigger the `/issue_report` workflow.
