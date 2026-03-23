---
description: Rapid health check with automated fixes for linting, formatting, and tests.
---
# Checkup Workflow (Monorepo)

**TRIGGERS:** checkup, health, quick-audit, lint-fix

This workflow is optimized for speed and developer productivity. It prioritizes automated fixes and parallel analysis using optimized MCP tools.

> [!NOTE]
> **FAST MODE DEFAULT**: This workflow is designed to be lean and fast. If significant architectural failures are found, consider upgrading to `/audit` or `/issue_report`.

> [!IMPORTANT]
> **MONOREPO**: This is a Dart workspace. Run analysis/format/fix from the **workspace root** - the Dart tools will recurse into `apps/` and `packages/` automatically.

## 1. Automated Code Hygiene (MCP Optimized)
// turbo
1. Run `mcp_dart-mcp-server_dart_fix` on the workspace root.
// turbo
2. Run `mcp_dart-mcp-server_dart_format` on the workspace root.
   - **Fallback (no MCP tools)**: Run `melos run format`.

## 2. Parallel Static Analysis
// turbo
1. Run `mcp_dart-mcp-server_analyze_files` on the workspace root.
   - The analyzer will cover `apps/gdar_mobile`, `apps/gdar_tv`, `apps/gdar_web`,
     `packages/screensaver_tv`, `packages/shakedown_core`, and `packages/styles`.
   - **Fallback (no MCP tools)**: Run `melos run analyze`.
2. If errors are found, summarize the top 3 critical issues immediately.

## 3. Intelligent Testing
// turbo
1. **Targeted Run**: Run `mcp_dart-mcp-server_run_tests` on specific test files related to current changes (detected via `git status`). Limit to < 5 files.
   - **Fallback (no MCP tools)**: Run `melos run test` or targeted `flutter test` on the changed files.
2. **Full Suite Escalation**: If a full test suite is requested or clearly needed, recommend running the full suite as a dedicated follow-up step rather than expanding this workflow into a long-running catch-all pass.

## 4. Visual/Design Check (Micro)
1. Scan current working file for `withOpacity()` (deprecated preference) and suggest `.withValues(alpha: ...)`.
2. Scan for hardcoded colors (e.g., `Colors.red`) and suggest using `colorScheme`.
3. **Audit App Size:** Run the `size_guard` workflow to scan workspace assets for newly added large files or unoptimized PNGs.

## 5. Summary
1. Provide a "Health Score" (Errors/Warnings count).
2. List automated fixes applied (if any).
3. If tests/analysis pass, update `.agent/notes/verification_status.json` with current Git SHA and results.
4. If tests failed, offer to trigger the `/issue_report` workflow.
