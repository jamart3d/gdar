# Quality Audit Skill

Perform health checks, design audits, and optimization routines to ensure code quality and performance.

**TRIGGERS:** audit, checkup, analyze, lint, format, report, deep link

## General Checkup
1. Analyze: `mcp_dart-mcp-server_analyze_files`.
2. Test: `mcp_dart-mcp-server_run_tests`.
3. Format: `mcp_dart-mcp-server_dart_format`.

## Material 3 Design Audit
1. **System Inspection**: Check `main.dart` for system bar settings and `pubspec.yaml` for `uses-material-design: true`.
2. **Color Tokens**: Scan for legacy `Colors.*` usage and hardcoded opacities. Flag non-semantic colors.
3. **Typography**: Recommend `Theme.of(context).textTheme` over manual `TextStyle`.
4. **Motion/Layout**: Review screen transitions and `SliverAppBar` usage.
5. **Report**: Generate `material3_audit_report.md`.

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
