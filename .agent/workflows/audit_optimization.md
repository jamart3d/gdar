---
description: Perform a comprehensive audit for optimization, size, and code quality before a release.
---

# Optimization & Release Audit

Run this workflow before building a release candidate to ensure the app is optimized, lean, and clean.

## 1. Code Quality & Cleanup
// turbo
- [ ] **Lint Analysis**: Use `dart-mcp-server` to analyze the project.
    - Tool: `mcp_dart-mcp-server_analyze_files`
// turbo
- [ ] **Formatting Check**: Ensure code style consistency.
    - Tool: `mcp_dart-mcp-server_dart_format`
// turbo
- [ ] **Debug Print Check**: Scan for leftover `print` statements or `logger` calls that shouldn't be in release.
    ```bash
    grep -r "print(" lib/
    grep -r "logger." lib/
    ```

## 2. App Size Analysis
- [ ] **Build Size Analysis**: Generate a size breakdown to potentially large dependencies or assets.
    ```bash
    flutter build appbundle --target-platform android-arm64 --analyze-size
    ```
    *Review the output for unexpectedly large assets or packages.*

## 3. Dependency Check
// turbo
- [ ] **Outdated Packages**: Check for outdated dependencies that might have performance fixes.
    ```bash
    flutter pub outdated
    ```

## 4. Asset Audit
// turbo
- [ ] **Large Assets**: Find assets larger than 500KB.
    ```bash
    find assets -type f -size +500k -exec ls -lh {} \;
    ```

## 5. Automated Verification
// turbo
- [ ] **Unit Tests**: Use `dart-mcp-server` to run tests.
    - Tool: `mcp_dart-mcp-server_run_tests`

