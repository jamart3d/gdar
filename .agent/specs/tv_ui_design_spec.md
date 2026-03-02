# TV UI Design Specification: GDAR Audio Player

This document defines the visual standards, scaling rules, and design tokens for the **Google TV / Android TV** implementation of GDAR.

## 1. Visual Hierarchy & Scaling
TV UI requires higher contrast and larger interactive targets due to the "10-foot UI" distance.

*   **Global Scaling:** Use `AppTypography.responsiveFontSize` with a specific multiplier for TV.
*   **Target Padding:** All focusable items must maintain a minimum **48x48dp** touch/focus target (e.g., in `RatingControl`).
*   **Focus Multipier:** Focused elements scale by **1.05x** via `TvFocusWrapper`.
*   **Dialog Scaling:** Modals like `RatingDialog` use a **1.5x scale factor** for text and buttons to ensure readability.

## 2. Theming: Translucent Material (TV)
TV themes prioritize depth and high-contrast translucency over the "Liquid Glass" (frosted/blur) effect used on Web/Fruit.

*   **Translucency (Panes):**
    *   **STRICTLY AVOID** `BackdropFilter` or `LiquidGlassWrapper` (blurred glass). TV UI relies on **alpha-blended solid colors** for performance and a "clean" architectural feel.
    *   `TvPlaybackBar`: **0.6 opacity** (Using `withValues(alpha: 0.6)`).
    *   `RatingDialog`: **0.4 opacity** for card surfaces.
    *   `TvHeader` / Divider: **0.15 opacity** for white-to-transparent gradients.
*   **Focus Brushes:**
    *   **Primary Glow:** Uses `colorScheme.primary` with a focus border instead of atmospheric shadows.
    *   **Inactive Dimming:** Unfocused panes in `TvDualPaneLayout` are dimmed to **0.2 opacity** via `AnimatedOpacity`.

## 3. Persistent Layout (Dual-Pane)
To ensure context isn't lost during playback, the TV UI utilizes a **Dual-Pane Layout** (`TvDualPaneLayout`) for the primary browsing experience.
- **Left Pane:** Current show overview and source list.
- **Right Pane:** Active track list and source metadata.
- **Visual Focus:** The inactive pane is dimmed to **0.2 opacity** via `AnimatedOpacity`.

## 4. Mini-Player Interaction (TV)
The `MiniPlayer` appears at the bottom of the screen when a show *other* than the one currently being browsed is playing.
- **Standard (Browse):** Full playback controls (Skip/Play/Pause) are visible.
- **Deep-Dive (Full-Screen):** When navigating to a standalone `TrackListScreen` for an inactive show, the `MiniPlayer` **hides all controls** (`hideControls: true`). This reduces visual noise and prioritizes listing information.
- **Scaling:** Uses `FontLayoutConfig.getEffectiveScale` to maintain legibility at distance.

## 5. Typography & Icons
*   **Font Family:** `Inter` is the primary font; `Roboto` is used for time-based monospaced data.
*   **Icon Sets:** Standard Material `Icons` exclusively. **STRICTLY AVOID** `LucideIcons` (reserved for Web/Fruit).
*   **Icon Scaling:** Icons in the `MiniPlayer` and `TvPlaybackBar` are set to **32dp** (compared to standard 24dp).

---
*Version: 1.1*  
*Last Updated: 2026-03-02*
