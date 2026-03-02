# Phone UI Design Specification: GDAR Audio Player

This document defines the visual standards, interaction patterns, and layout rules for the **Mobile (Android/iOS)** implementation of GDAR.

## 1. Core Principles
The Phone UI is designed for one-handed use, portability, and high-energy interaction.
*   **Bottom-Heavy Interaction:** Primary controls (Mini-Player, Show List filters) are positioned within the "thumb zone" at the bottom of the screen.
*   **Dynamic Response:** The UI color palette shifts dynamically based on the currently selected or playing show.
*   **Haptic Feedback:** Physical sensations are integrated into critical actions (Dice roll, track selection, button taps) to provide a tactile experience.

## 2. Layout & Components

### 2.1 Mini-Player (Persistent)
The Mini-Player is the primary anchor for playback state across the app.
*   **Positioning:** Fixed at the bottom of the screen above the navigation bar or system safe area.
*   **Progress Indicator:** A 4dp thin progress bar tracks current playback at the very top edge of the player.
*   **Content:**
    *   **Track Title:** Uses `ConditionalMarquee` to scroll long titles.
    *   **Controls:** Optimized for touch with a minimum **40x40dp** target.
*   **Elevation:** Uses standard Material elevation (4.0) unless "Performance Mode" is enabled.

### 2.2 Playback Screen (Slide-Up)
Implemented via `SlidingUpPanel`, the full player provides an immersive deep-dive into the current show.
*   **Background:** Solid color generated from the show metadata (`ColorGenerator`).
*   **Structure:**
    *   **Upper Pane (Header):** Venue, Date, Location, and Rating summary.
    *   **Middle Pane (Track List):** Scrollable list of tracks, grouped by set.
    *   **Lower Pane (Playback Controls):** Large-scale controls for seeking, skipping, and volume.
*   **Interaction:** Vertical swipe to expand/collapse.

### 2.3 Show List (Browsing)
*   **Card Design:** High-contrast cards with clear hierarchy (Date > Venue > Source).
*   **Lazy Loading:** Uses `scrollable_positioned_list` for smooth scrolling of massive show catalogs.
*   **Curation:** Rating stars and "Block" (Red Star) actions are immediately accessible to allow rapid show management.

## 3. Theming & Scaling

### 3.1 Material 3 Baseline
*   **Standard:** Phone UI defaults to **Material 3** guidelines to ensure a native and fast experience.
*   **Fruit Exclusion:** **STRICTLY AVOID** `LiquidGlassWrapper` and `NeumorphicWrapper` on phone builds. These are reserved for high-power Web/Desktop environments.
*   **Typography:** The `Inter` font family should be used as the primary display font.

### 3.2 Responsive Scaling
*   **Font Scaling:** Uses `FontLayoutConfig.getEffectiveScale` to respect system accessibility settings while maintaining UI integrity.
*   **Safe Areas:** Deep integration with `MediaQuery.padding` to handle notches, punch-holes, and system gestural navigation bars.

## 4. Animation & Physics
*   **Springs:** Use Apple-style spring physics for panel transitions.
*   **Pulse Effects:** Functional elements (e.g., the Search button when active, or the "Random Show" dice) use subtle scale-pulsing to guide the user's eye.

---
*Version: 1.0*  
*Last Updated: 2026-03-02*
