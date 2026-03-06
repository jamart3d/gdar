---
description: Rapid health check with automated fixes for linting, formatting, and tests.
---
# Checkup Workflow (Optimized)

**TRIGGERS:** checkup, health, quick-audit, lint-fix

This workflow is optimized for speed and developer productivity. It prioritizes automated fixes and parallel analysis using optimized MCP tools.

> [!NOTE]
> **FAST MODE DEFAULT**: This workflow is designed to be lean and fast. If significant architectural failures are found, consider upgrading to `/quality_audit` or `/issue_report`.

## 1. Automated Code Hygiene (MCP Optimized)
// turbo
1. Run `mcp_dart-mcp-server_dart_fix` on the project root to resolve automated lints.
// turbo
2. Run `mcp_dart-mcp-server_dart_format` on the project root to ensure consistent styling.

## 2. Parallel Static Analysis
// turbo
1. Run `mcp_dart-mcp-server_analyze_files` on the `lib/` directory.
2. If errors are found, summarize the top 3 critical issues immediately.

## 3. Intelligent Testing
// turbo
1. **Targeted Run**: Run `mcp_dart-mcp-server_run_tests` on specific test files related to current changes (detected via `git status`).
2. **Full Run (Optional)**: If targeted tests pass, run the full test suite in the background.

## 4. Visual/Design Check (Micro)
1. Scan current working file for `withOpacity()` (deprecated preference) and suggest `.withValues(alpha: ...)`.
2. Scan for hardcoded colors (e.g., `Colors.red`) and suggest using `colorScheme`.
3. **Audit App Size:** Trigger the `size_guard` skill to scan `assets/` for newly added large files or unoptimized PNGs.

## 5. Summary
1. Provide a "Health Score" (Errors/Warnings count).
2. List automated fixes applied (if any).
3. If tests failed, offer to trigger the `/issue_report` workflow.
