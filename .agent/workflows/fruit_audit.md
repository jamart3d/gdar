---
description: Scans the UI directory to verify Fruit theme components are correctly gated.
---
# Workflow: Fruit Theme Audit (`/fruit_audit`)

**Trigger:** `/fruit_audit`

**Goal:** Ensure the "Liquid Glass" and Neumorphic aesthetics remain strictly isolated to the Web/PWA platforms and do not leak into the Native/TV Material 3 experiences.

**Steps:**
1. Use `grep_search` to find all instances of `LiquidGlassWrapper`, `NeumorphicWrapper`, and `FruitTabBar` in the `lib/ui/` directory.
2. For each discovered instance, use `view_file` to examine the surrounding build method or logic block.
3. Validate that the usage is wrapped in a conditional check (e.g., `if (themeStyle == ThemeStyle.fruit)` or `if (kIsWeb)`).
4. If a component is missing a gate, flag it as a Material 3 violation.
5. Generate a markdown report in `artifacts/fruit_audit_report.md` detailing any leaks and proposing the necessary surgical fixes.
