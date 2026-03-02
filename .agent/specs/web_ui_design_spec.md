# Web UI Design Specification: GDAR Audio Player

This document defines the visual standards, responsive behavior, and dual-theme system for the **Web UI / PWA** implementation of GDAR.

## 1. The Dual-Theme Strategy
GDAR for Web provides two distinct user experiences optimized for different aesthetic preferences and browser capabilities.

| Feature | Standard (Material 3) | Fruit (Liquid Glass) |
| :--- | :--- | :--- |
| **Philosophy** | Familiarity, Accessibility, Speed | Premium, Tactile, Immersive |
| **Icon Set** | Material Icons (Rounded) | `LucideIcons` (Exclusive) |
| **Depth** | Elevation & Box Shadows | `BackdropFilter` (Blur) & Neumorphism |
| **Corners** | Material Baseline (Standard) | Architectural (14-16px) |
| **Typography** | User Default / Roboto | **Inter** (Hard-enforced) |

## 2. Theme Implementation Details

### 2.1 Standard: Material 3
*   **Behavior:** Follows standard Flutter Material 3 implementation.
*   **Color Logic:** Uses `DynamicColor` when available; otherwise defaults to curated Material palettes.
*   **Accessibility:** Primary target for screen readers and high-contrast requirements.

### 2.2 Fruit: Liquid Glass & Neumorphism
The Fruit theme transitions the UI from an elevation-based model to a translucency-based model.
*   **Translucency (Liquid Glass):** 
    *   Uses `LiquidGlassWrapper` with `sigma: 15.0`.
    *   Opacity: `0.7` for surfaces, allowing underlying colors to bleed through.
*   **Tactility (Neumorphism):** 
    *   Interactive elements (Buttons, Search Bars) use dual-shadow light/dark offsets.
    *   **Convex:** Standard buttons.
    *   **Concave:** Search field and "active" control areas.
*   **RGB Active Track:** The currently playing track card features a rotating `SweepGradient` border.

## 3. Web-Specific Layout Rules

### 3.1 Responsive Breakpoints & PWAs
*   **Mobile Web / PWA:** 
    *   **Stacked Layout (Default):** Metadata (Venue/Date) and interactive controls (Stars/Badges) are vertically aligned in a column for optimal touch targets.
    *   Triggered automatically for detected PWAs or viewports `< 768px`.
    *   Single column navigation; persistent bottom mini-player.
*   **Tablet/Desktop (> 768px):** 
    *   **Horizontal Layout:** Data moves to a single row to maximize vertical scanability of the catalog.
    *   Expanded sidebars or dual-pane layouts if width allows.
*   **Safe Areas:** Browser toolbars are managed via `SafeArea`.

### 3.2 Desktop Interactivity
*   **Hover States:** All interactive cards in the show list scale to **1.01x** on hover.
*   **Pointers:** Explicitly use `SystemMouseCursors.click` for all focusable elements to ensure a native desktop feel.
*   **Scrollbars:** Custom-styled thin scrollbars to prevent UI clutter on browsers.

## 4. Component Standards

### 4.1 Global Player Navigation
*   **Mini-Player:** Persistent at the bottom of the screen.
*   **Expansion:** On desktop, the mini-player may expand into a full-width dashboard or a side-attached control pane.

### 4.2 Rating & Curation
*   **Visual Logic:** Shared with TV but uses `LucideIcons` for Fruit.
*   **Constraints:** The block (Red Star) is always visible in the show list to allow rapid curation during browsing.

## 5. Experimental: Visualizers & Shaders
The Web platform serves as the testbed for GPU-accelerated UI experiments.
*   **StealVisualizer:** A Flame-based engine integrated into the background.
*   **Fragment Shaders:** Custom GLSL shaders (`steal.frag`) are used for background reactivity to audio energy.
*   **Energy Stream:** Real-time analysis from the audio engine drives UI pulse and glow intensities.

---
*Version: 1.0*  
*Last Updated: 2026-03-02*
