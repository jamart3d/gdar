# Web UI Design Specification: GDAR Audio Player

This document defines the **platform-specific** visual standards, responsive behavior, and unique interactivity for the **Web UI / PWA** implementation of GDAR.

## 1. Web Platform Integration
The Web implementation serves as a hybrid platform between desktop browsing and mobile PWAs. It adapts its look and functionality based on device detection while supporting the two core GDAR themes.

### 1.1 Dual-Theme Support
Web is the only platform that allows users to toggle between two distinct design languages:
*   **Android Theme (Standard):** Implements the **Material 3 Expressive** baseline. See `android_theme_spec.md`.
*   **Fruit Theme (Liquid Glass):** Implements the premium **Walled-Off** aesthetic. See `fruit_theme_spec.md`.

### 1.2 Layout & Context
Web-specific layout rules ensure that both themes translate effectively across varying screen sizes:
*   **Desktop:** Prioritizes horizontal scanning and side-attached navigation.
*   **PWA / Mobile Web:** Switches to a thumb-optimized stacked layout with bottom mini-player.
Web-specific interactivity ensures a native feel on desktop browsers:
*   **Hover Scaling:** All interactive cards (Show/Source) scale to **1.01x** on hover.
*   **Click Cursors:** Explicitly use `SystemMouseCursors.click` for all interactive elements.
*   **Scrollbars:** Integrated custom-styled thin scrollbars (Webkit/Firefox) to minimize UI clutter.
*   **Safe Areas:** Deep integration with browser toolbars and PWA status-bar padding.

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

### 4.2 Show Header mechanics & Overrides
On the Web UI, the Track List Screen's show header provides rapid playback interaction:
*   **Single Click (Empty Player):** If no audio is loaded globally, simply clicking the show header immediately begins playback.
*   **Long Press / Play Icon (Override):** If another show is currently playing, a theme-appropriate Play icon appears in the bottom left of the header. Both a Long Press on the header or a Single Click on the Play icon override the queue, stopping the current stream and playing the new show.

### 4.3 Rating & Curation
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


