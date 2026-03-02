---
description: specialized audit for Google TV UI layout, navigation, and D-Pad interaction.
---
# TV Flow Audit Workflow

**TRIGGERS:** tv, google tv, dpad, focus, remote

This workflow ensures the application's TV-specific layouts and navigation flows are consistent and handle remote inputs (D-Pad) correctly.

> [!IMPORTANT]
> **AUTONOMY & PLANNING MODE**: When this workflow is triggered, switch to **Planning Mode**. This allows for a deep dive into focus node management, TV-specific layout logic (`isTv`), and navigation state across multiple screens without needing constant permission.

## 1. TV Layout & Logic Scan
// turbo
1. Scan the codebase for `deviceService.isTv` (or similar TV detection logic).
2. Verify that specific screens (Playback, Show List, Drawer) have a dedicated `_buildTvLayout` or conditional gating.
3. Check for "Mobile-only" artifacts in TV mode:
   - Flag standard snackbars (should be positioned for TV).
   - Flag hardcoded swipe gestures that lack a D-Pad/Remote fallback.
   - Verify that the Playback screen header correctly shows Date/Venue instead of a track list (per project rules).

## 2. Focus & Navigation Audit
1. **Focus Node Search**: Identify manually created `FocusNode` instances.
2. **Focus Traps**: Ensure that list items and buttons are properly focusable via D-Pad.
3. **Remote Buttons**: Verify `Shortcuts`, `Actions`, or `RawKeyboardListener` implementations for handling Remote 'Play/Pause', 'Next', and 'Back' buttons.

## 3. Aesthetic & Scale Verification
1. **Typography**: Ensure `effectiveScale` for TV includes the 1.2x multiplier.
2. **Contrast**: Check that focused states (e.g., list item highlights) are sufficiently high contrast for 10-foot UI.
3. **Margins**: Verify "Safe Areas" for TV screens (avoiding overscan regions on older displays).

## 4. Findings & Testing
1. Generate `TV_UI_AUDIT_REPORT.md`.
2. Categorize by:
   - **Critical**: Focus traps or missing remote button handlers.
   - **UI Consistency**: Layout glitches or incorrect font scaling.
   - **Optimization**: Unordered tab order or missing focus indicators.
3. Provide code snippets to fix identified gaps (e.g., adding `RequestFocusAction`).
