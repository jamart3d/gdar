---
description: Perform health checks, design audits, and optimization routines to ensure code quality and performance.
---
# Quality Audit Workflow

**TRIGGERS:** audit, checkup, analyze, lint, format, report, deep link

> [!IMPORTANT]
> **AUTONOMY & PLANNING MODE**: When this workflow is triggered, switch to **Planning Mode**. Proceed autonomously end-to-end (running analysis, analyzing dependencies, and generating audit reports) without pausing for intermediate permission.

## General Checkup
1. Analyze: Use the `mcp_dart-mcp-server_analyze_files` tool.
2. Test: Use the `mcp_dart-mcp-server_run_tests` tool.
3. Format: Use the `mcp_dart-mcp-server_dart_format` tool.

## Material 3 & Glass Design Audit
1. Run `/glass_audit` to perform a deep dive into "Liquid Glass" compliance and Material 3 violations.

## Optimization Audit
1. **Lint/Format**: Run standard analysis and formatting.
2. **Debug Clean**: Scan for `print(` and `logger.` statements.
3. **Size Analysis**: `flutter build appbundle --analyze-size`.
4. **Dependencies**: `flutter pub outdated`.
5. **Assets**: Find files > 500KB.

## Deep Link Manifest
1. Scan `AndroidManifest.xml` for intent filters.
2. Scan Dart for `AppLinks` usage and host mapping.
3. Check `shortcuts.xml` for App Actions.
4. Generate `DEEP_LINK_MANIFEST_V<version>.md`.

## Google TV & Android TV Audit
1. Run `/tv_flow_audit` to perform a comprehensive review of D-Pad focus, remote inputs, and TV-specific layouts (Header/Date/Venue).
