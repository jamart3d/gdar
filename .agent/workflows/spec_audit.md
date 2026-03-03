---
description: Perform a systematic audit of the application's implementation against the source-of-truth design and flow specifications.
---
# Spec Conformity Audit Workflow

**TRIGGERS:** spec audit, conform, compliance, design truth, audit specs

This workflow ensures that the codebase correctly implements the rules defined in the `.agent/specs/` directory. It identifies "Design Drift" where code has deviated from the established standards for TV, Web, or Phone.

> [!IMPORTANT]
> **AUTONOMY & PLANNING MODE**: When this workflow is triggered, switch to **Planning Mode**. You are authorized to read all specifications, perform global codebase searches, and analyze implementation details (Theme logic, Service detection, Widget properties) without needing intermediate permission.

## 1. Requirement Indexing
1. Read and summarize all specification files in:
   - `android_theme_spec.md` (M3 Expressive Look)
   - `fruit_theme_spec.md` (Liquid Glass / Walled Policy)
   - `phone_ui_design_spec.md` (Hardware / Haptics / Feel)
   - `tv_ui_design_spec.md` (v135 Legacy / OLED Dark)
   - `tv_ui_flow_spec.md` (D-Pad / Interaction Modals)
   - `web_ui_design_spec.md` (Responsive / Desktops)

2. Create a "Truth Matrix" of hard constraints (e.g., "Glass Sigma: 15.0 on Web only," "No Haptics on TV").

## 2. Implementation Scan
// turbo
1. **Theme Gating Audit**:
   - Verify `LiquidGlassWrapper` is only active when `kIsWeb && !isTv`.
   - Ensure `RockSalt` and `Roboto` are correctly used within `isTv` conditional blocks vs native ones.
   - Flag any "Material 3 Leakage" (Standard ripples) in the Fruit theme path.

2. **Platform Hardware Audit**:
   - Scan for `HapticFeedback` calls. Ensure they are gated by `!isTv` per the TV UI spec.
   - Verify `effectiveScale` multipliers (1.35x for TV UI Scale, 1.2x for TV Dialogs) match the specs.

3. **Interaction Flow Audit**:
   - Check `ShowListLogicMixin` and `TrackListView` for correctly implemented `TvInteractionModal` and `TvReloadDialog` logic on TV.
   - Verify that non-TV platforms maintain "Direct Play" or standard bottom sheet behaviors.

## 3. Conformity Report
1. Generate or update `SPEC_CONFORMITY_REPORT.md`.
2. Categorize items into:
   - **Aligned**: Features that perfectly match the spec.
   - **Drifted**: Features that work but use non-standard tokens (e.g., wrong blur sigma).
   - **Violation**: Features that break hard rules (e.g., Haptics on TV or Glass on Phone).
   - **Undocumented**: New UI features that lack a corresponding spec in `.agent/specs/`.

## 4. Remediation
1. Provide a list of "Surgical Fixes" for immediate alignment.
2. Offer to update the `.agent/specs/` if the code represents an intentional "new truth" that needs to be documented.
