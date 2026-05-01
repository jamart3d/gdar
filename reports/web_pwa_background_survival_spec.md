# Specification: Web PWA Background Survival (Independent)

This document provides a repo-independent technical specification for implementing **background-durable audio playback** in a web-based Progressive Web App (PWA).

---

## 1. Background Survival Strategy
Web browsers strictly throttle or suspend background tabs to save battery. To maintain high-precision playback (especially for gapless Web Audio), "Survival Heartbeats" are required.

### 1.1 The Survival "Heartbeat" Elements
*   **Audio Heartbeat:** A silent, 0.1s looping WAV file played via a standard `<audio>` tag.
*   **Video Heartbeat:** A silent, 1x1 pixel black MP4 video played via a `<video>` tag.
*   **Implementation:**
    *   Set `loop = true`.
    *   Set `volume = 0` (or `muted = true`).
    *   Apply `playsinline` and `webkit-playsinline` attributes.
    *   Hide the elements from the UI (`opacity: 0.01`, `pointer-events: none`).

### 1.2 Orchestration Logic
*   **Activation:** Trigger heartbeats immediately upon user interaction with "Play".
*   **Deactivation:** Stop heartbeats on "Pause" or "Stop" to save battery.
*   **The "Trick":** The OS observes an active media element and assumes the tab is performing a meaningful task, preventing it from being put to sleep.

---

## 2. The Hybrid Playback Engine Pattern
To maximize both reliability and precision, use a **Dual-Engine Handoff** architecture.

### 2.1 Components
1.  **Foreground Engine (Web Audio API):** High-precision, used for sample-accurate gapless transitions. Vulnerable to OS throttling.
2.  **Background Engine (HTML5 Audio Tag):** Robust, OS-native playback. Low-precision (slight gaps between tracks).

### 2.2 Handoff Logic
*   **Instant Start:** Always start playback on the **Background Engine** (HTML5) for immediate responsiveness.
*   **Precision Handoff:** Once the tab is stable in the foreground, silently sync the **Foreground Engine** (Web Audio) to the current timestamp and swap the active output.
*   **Safety Swap:** If the tab is backgrounded and the Foreground Engine exhibits "Drift" or stalls, swap back to the **Background Engine** to ensure the music doesn't stop.

---

## 3. Verification & Hard Reset
*   **Stability Test:** Playback must continue across multiple track boundaries while the screen is off for > 5 minutes.
*   **The "Stuck Reset" Pattern:** Implement a "Kill Switch" (e.g., a long-press on UI Play/Pause) that forcefully clears all audio nodes and purges the playback queue. This is the only reliable way to recover from low-level browser audio engine hangs.

---

## 4. Technical Manifest
*   **Required APIs:** `Web Audio API` (AudioContext), `HTML5 Media Elements` (`<audio>`, `<video>`).
*   **Asset Requirements:** 
    *   Base64 silent WAV (0.1s).
    *   Base64 silent 1x1 MP4.
