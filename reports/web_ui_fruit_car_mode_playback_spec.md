# Specification: Web UI Fruit Car Mode Playback Screen (Independent)

This document provides a detailed technical and visual specification for a **high-visibility, touch-optimized playback screen** (originally implemented as "Fruit Car Mode"). It is designed to be repository-independent, allowing any agent to implement these patterns in a new application.

## 1. Design Language & Visual Primitives
*   **Aesthetic:** Glassmorphism with deep shadows and high-contrast typography.
*   **Core Background:** A linear vertical gradient (Top: Surface Color -> Middle: Deep Surface -> Bottom: Surface Color).
*   **Visualizers:** Passive, drifting spheres (6 count) that react to audio energy peaks.
*   **Layout Safety:** Standard `SafeArea` applied. Global horizontal padding: `16px`.
*   **Primary Font:** **Inter** (used for all numeric and meta data).
*   **Iconography Library:** **LucideIcons**.

---

## 2. Functional Components

### 2.1 The Telemetry HUD (Top Row)
A horizontal row of four "Stat Chips" designed for real-time performance monitoring.
*   **Visuals:** Rounded rectangle chips (Radius `18px`, Height `74px`). Glass surface (blur: `14`, opacity: `0.82`).
*   **Stat 1 (DRIFT):** Displays numeric clock drift in milliseconds (e.g., `+12ms`).
*   **Stat 2 (HEADROOM):** Duration remaining in current buffer.
    *   **Logic:** Relative to a 30s scale. `fraction = (bufferDuration / 30s).clamp(0, 1)`.
    *   **Visual:** Horizontal gauge fill behind the text.
*   **Stat 3 (NEXT BUFFER):** Buffered duration for the next track.
    *   **Logic:** `fraction = (nextBuffered / nextTotalDuration).clamp(0, 1)`.
    *   **Visual:** Horizontal gauge fill behind the text.
*   **Stat 4 (LAST GAP):** Measured silence between track boundaries (e.g., `0ms`).

### 2.2 Hero Metadata Cluster
*   **Venue Name:** Font Size `34`, weight `800`, letter-spacing `-0.8`.
*   **Location:** Font Size `19`, weight `700`.
*   **Date String:** Font Size `25`, weight `800`.
*   **Track Title:** Scrolling marquee. Font Size `46`, weight `900`, letter-spacing `-2.0`, height `0.92`. Velocity: `48.0 px/s`.

### 2.3 Large-Scale Controls
Optimized for high-reliability interaction (e.g., in a car or active environment).
*   **Dashboard Buttons:** Rounded rectangles (Radius `28`, Height `112`).
*   **Play/Pause Button:** Central circular button (Diameter `152`).
    *   **Visual:** Multi-layered shadow (blur: `28`, spread: `2`). Specular glass highlight on the top arc.
*   **Interaction Contract:**
    *   **Single Tap:** Play/Pause toggle.
    *   **Long Press:** "Web Stuck Reset" — Hard-clears all audio contexts and clears the queue.

### 2.4 Progress & Buffer Tracking
*   **Track Bar:** Height `16`. Thumb diameter `28`.
*   **Visual States:**
    *   **Unplayed:** Subdued background (opacity `0.45`).
    *   **Buffered:** Secondary color highlight (opacity `0.5`).
    *   **Played:** Primary color gradient.
    *   **Loading:** An animated glass sweep ("Bead") that traverses the bar during stall states.

---

## 3. Technical Requirements (Repo-Independent)

### 3.1 State Management
The implementation assumes a central "Audio State" object providing:
*   `position`: Current playback time.
*   `duration`: Total track length.
*   `buffered`: Currently buffered range.
*   `telemetry`: Object containing drift, headroom, and next-track buffer states.

### 3.2 Key Dependencies (Generic)
*   **Icon Set:** Any set containing Play, Pause, ChevronLeft, ChevronRight, and Circle.
*   **Marquee Library:** A component that scrolls text when it exceeds its container.
*   **Haptic Interface:** Access to system-level impact haptics (Heavy and Selection types).
*   **DateTime Formatter:** Library to convert UTC strings to "Day, Month Date, Year" formats.

### 3.3 Typography Specs

| Role | Font | Size (px) | Weight |
| :--- | :--- | :--- | :--- |
| Primary Heading | Inter | 46 | 900 |
| Secondary Heading | Inter | 34 | 800 |
| Metadata | Inter | 25 | 800 |
| Labels | Inter | 9 | 900 |
| Values | Inter | 22 | 900 |
