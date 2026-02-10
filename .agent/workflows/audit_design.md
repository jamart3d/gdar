---
description: Perform a comprehensive Material 3 Expressive Design Audit on the codebase.
---

# Material 3 Design Audit Workflow

This workflow guides you through auditing the codebase for compliance with Material 3 Expressive Design principles.

## 1. System Inspection
1.  Check `main.dart` for `enableEdgeToEdge` or `SystemChrome` settings.
    *   *Goal:* Ensure system bars are transparent.
2.  Check `pubspec.yaml` for `flutter: uses-material-design: true`.
3.  Verify `ThemeData` uses `ColorScheme.fromSeed` and `useMaterial3: true`.

## 2. Color Tokenization Audit
// turbo
1.  Run `grep -r "Colors\." lib/` to identify hardcoded legacy colors.
2.  Run `grep -r "withOpacity" lib/` to identify manual opacity (should favor Surface Tones or `withValues`).
3.  **Action:** Flag any significant usage of non-semantic colors (e.g., `Colors.blue`, `Colors.grey`) that should be mapped to `ColorScheme`.
    *   **CRITICAL:** List the specific **Widget Names** (e.g., `TideTitle`, `WaterSandFooter`) that are using these hardcoded colors. Do not just say "various widgets".


## 3. Typography & Hierarchy Check
1.  Scan widely used widgets (Cards, Titles) for manual `TextStyle` definitions.
    *   Look for `fontWeight:`, `fontSize:`.
2.  **Action:** Recommend replacing with `Theme.of(context).textTheme.role`.

## 4. Motion & Layout Review
1.  Identify major screen transitions. Are they default (slide/fade) or Expressive (Container Transform, Shared Axis)?
2.  Check scrollable areas. Do they use `SliverAppBar` for dynamic headers?
3.  Check animation curves. Are linear curves used where `easeInOutCubic` (Emphasized) or `easeOutCubic` (Decelerate) would be better?

## 5. Report Generation
1.  Generate a markdown report following the template:
    *   Executive Summary
    *   Color System Status
    *   Typography Status
    *   Motion Status
    *   Action Items
2.  Save report to project root as `material3_audit_report.md` with timestamp.
