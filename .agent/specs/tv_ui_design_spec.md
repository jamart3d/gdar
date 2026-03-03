# TV UI Design Specification: GDAR Audio Player

This document defines the visual standards, scaling rules, and design tokens for the **Google TV / Android TV** implementation of GDAR.

### 1. Visual Hierarchy & Scaling
TV UI requires higher contrast and larger interactive targets due to the "10-foot UI" distance.

*   **Global Scaling:** Use `FontLayoutConfig.getEffectiveScale` with a user-configurable **1.35x boost** (UI Scale toggle).
*   **Target Padding:** All focusable items must maintain a minimum **48x48dp** target (e.g., in `RatingControl`).
*   **Focus Multipier:** Focused elements in `TvFocusWrapper` scale by **1.03x** to **1.05x** depending on context.
*   **Dialog Scaling:** Modals like `TvExitDialog` use enlarged text and high-contrast primary colors for rapid selection.

## 2. Theming: Material Dark (OLED Optimized)
TV themes prioritize absolute black depths and high-contrast primary accents over translucency.

*   **Color Palette:**
    *   **Background:** True Black (`Colors.black`) for OLED power savings and high contrast.
    *   **Primary Accent:** Material Blue (`Colors.blue`) for focus states and active tracks.
*   **Translucency (Panes):**
    *   **STRICTLY AVOID** `BackdropFilter` or `LiquidGlassWrapper` (blurred glass). TV UI relies on **solid dark surfaces** or simple alpha-blends.
    *   `TvPlaybackBar`: **0.6 opacity** (Using `withValues(alpha: 0.6)`).
    *   `RatingDialog`: Solid card surface or **0.8 opacity**.
*   **Focus Brushes:**
    *   **Primary Glow:** Uses `colorScheme.primary` with a focus border and a subtle **15dp blur** outer glow.
    *   **Inactive Dimming:** Unfocused panes in `TvDualPaneLayout` are dimmed to **0.2 opacity** via `AnimatedOpacity`.

## 3. Persistent Layout (Dual-Pane)
To ensure context isn't lost during playback, the TV UI utilizes a **Dual-Pane Layout** (`TvDualPaneLayout`) for the primary browsing experience.
- **Left Pane:** Current show overview and source list.
- **Right Pane:** Active track list and source metadata.
- **Visual Focus:** The inactive pane is dimmed to **0.2 opacity** to draw the eye to the active interactive area.

## 4. Navigation & Feedback
- **D-Pad Optimization:** Every navigation path must be reachable via 4-way D-Pad controls.
- **Haptics (Remote):** **STRICTLY AVOID** haptic feedback on TV builds; focus entirely on visual and auditory cues.
- **Marquee:** Use `Marquee` for long track titles in the mini-player and track list.

## 5. Typography & Icons
*   **Font Family:** **RockSalt** is the primary display font family for headers, show metadata, and titles. **Roboto** is used as the secondary font for time-based data, and general UI labels.

*   **Icon Sets:** Standard Material `Icons` exclusively.
*   **Icon Scaling:** Icons in the `MiniPlayer` and `TvPlaybackBar` are set to **32dp** to ensure visibility at a distance.

---
*Version: 0.9.1 (Legacy Google TV / v135)*  
*Last Updated: 2026-03-02*
