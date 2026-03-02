---
description: Context-aware design audit for Liquid Glass (Fruit) and Material 3 themes.
---
# Glass Audit Workflow (Multi-Theme Support)

**TRIGGERS:** glass, liquid glass, design, audit, material3, ripples, blur, backdrop

This workflow enforces the "Liquid Glass UI" (Fruit) design rules while respecting a fallback Material 3 theme option for users.

> [!IMPORTANT]
> **AUTONOMY & PLANNING MODE**: When this workflow is triggered, switch to **Planning Mode**. Proceed autonomously end-to-end (investigating files, running analysis, and generating reports) to ensure a deep architectural and aesthetic review across the entire codebase.

## 1. Aesthetic Scan (Context-Aware)
// turbo
1. Scan for raw Material 3 patterns WITHOUT conditional gating:
   - Identify `InkWell`, `ElevatedButton`, or `Card` usages.
   - Check if they are correctly wrapped in a logic-gate (e.g., `if (themeStyle == ThemeStyle.fruit)`).
   - Flag cases where Material 3 ripples might "leak" into Fruit mode inadvertently.

2. Scan for Fruit Mode Coverage:
   - Ensure primary UI containers (Drawers, Navbars, Panels) have a `BackdropFilter` or `LiquidGlassWrapper` path.
   - Flag standard Material shadows (`elevation > 0`) in Fruit mode; recommend Neumorphic alternatives instead.

## 2. Rule Enforcement
- **Conditional Gating**: Every UI element with interactivity should check `ThemeProvider.themeStyle`.
- **Fruit Mode**: Must strictly AVOID "breathing" ripples and morphing shapes. Use bounce/scale physics.
- **Material Mode**: Should use standard, clean Material 3 defaults for consistency.
- **Universal Rules**: Flag hardcoded, non-semantic colors (e.g., `Colors.red`) that break both themes.

## 3. Findings & Recommendations
1. Generate `GLAS_AUDIT_REPORT.md` (or update existing).
2. Categorize findings into:
   - **Gating Issues**: Material 3 leakage into Fruit theme.
   - **Aesthetic Gaps**: Missing frosted glass or Neumorphism in Fruit paths.
   - **Performance**: High blur usage on non-optimized screens.

## 4. Post-Audit
1. Offer to apply "Surgical Fixes" (e.g., swapping a direct `InkWell` for a gated `Bounceable` + `InkWell` combo).
