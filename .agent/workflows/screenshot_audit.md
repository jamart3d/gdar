---
description: Context-aware UI audit against platform design rules
---
# Screenshot Audit Workflow

**When to use:** To verify UI implementation against platform rules.

1.  **Identify Target Platform:** The user provides an image and specifies the target platform (TV, Mobile Web, Desktop Web, Phone, or Tablet).
2.  **Load Rules:** Automatically read the corresponding `.agent/rules/` file (e.g., `tv_ui_flow.md` or `fruit_theme.md`).
3.  **Analyze Image:** Evaluate the provided screenshot against the loaded rules.
    *   **Check for Fruit Theme leakage:** Ensure no Material 3 ripples or hard shadows are present if evaluating Fruit Theme.
    *   **Check for TV Flow:** Verify 1.05x scale focus wrappers, glow borders, and dimmed inactive panes (0.2 opacity).
    *   **Check alignment and spacing:** Look for visual overflow (e.g., the 2.0px overflow previously fixed on TV).
4.  **Report Findings:** Generate a concise list of pass/fail items based *only* on the active ruleset.
5.  **Suggest Fixes:** If failures are found, propose the specific Flutter code changes needed to resolve them based on `.agent/specs/`.
