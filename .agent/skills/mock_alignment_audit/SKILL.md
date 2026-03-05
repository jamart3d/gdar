---
name: mock_alignment_audit
description: Context-aware UI auditing against provided design mocks.
---

# Mock Alignment Audit Skill

**TRIGGERS:** audit mock, check alignment, UI review, pixel perfect

This skill enables the agent to perform high-precision visual audits by comparing current Flutter implementations against the "source of truth" design specifications or screenshots provided by the user.

## Execution Steps

### 1. Identify Target Component
1. Ask the user for the specific Widget or Screen to be audited.
2. Ask for the reference image or specification path (e.g., in `.agent/assets/mocks/`).

### 2. Deep File Analysis
1. Read the implementation file (e.g., `playback_screen.dart`).
2. Identify all layout-defining properties:
    * `Padding`, `Margin`, `SizedBox` heights/widths.
    * `MainAxisAlignment`, `CrossAxisAlignment`.
    * Typography tokens (Google Fonts, `fontWeight`, `letterSpacing`).
    * Color tokens (Theme specific, `opacity`).
    * Corner radii and glass/neumorphic effect parameters.

### 3. Visual Comparison Logic
* **Metric 1: Spatial Balance**: Does the vertical/horizontal breathing room match the mock?
* **Metric 2: Hierarchy**: Does the relative scaling between elements (e.g., Date vs Show Title) match the mock?
* **Metric 3: Theming**: Is the dark mode background or glass transparency leaking Material 3 defaults when it should be Liqud Glass (Fruit)?

### 4. Generate Audit Report
* **Findings**: 
    * "Issue: Header is currently 48dp offset; mock requires 24dp for a denser look."
    * "Found: Material 3 shadow detected on Now Playing card; implementation rule requires inset glass etching."
* **Actionable Fixes**: Provide specific code snippets to resolve the identified drifts.

> **RULE:** Always respect the `architecture_context.md` (e.g., True Black depth, padding rules) during the audit.
