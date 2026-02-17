---
description: Perform a health check of the codebase (analyze, test, format).
---

# Codebase Checkup

Run this workflow to ensure code quality and verify that no regressions were introduced.

## 1. Static Analysis
// turbo
- [ ] **Analyze Project**: Check for errors, warnings, and lints.
    - Tool: `mcp_dart-mcp-server_analyze_files`

## 2. Automated Tests
// turbo
- [ ] **Run All Tests**: Verify that current logic and existing features are intact.
    - Tool: `mcp_dart-mcp-server_run_tests`

## 3. Code Formatting
// turbo
- [ ] **Format Code**: Ensure all files follow the standard Dart formatting.
    - Tool: `mcp_dart-mcp-server_dart_format`
