# Phone Platform Specification: GDAR Audio Player

This document defines the **Hardware Interactivity** and **Native OS Integration** standards for the Phone (Android/iOS) implementation of GDAR. It focuses on how the app feels and reacts to physical device constraints.

## 1. Physical Layout & Constraint Management

### 1.1 The "Thumb Zone" Constraint
*   **Active Area:** Primary interactive elements (Filters, Search, Playback Controls) MUST be positioned within the bottom 40% of the screen.
*   **One-Handed Use:** Avoid top-corner buttons for frequently used actions. Use bottom sheets or persistent footers where possible.

### 1.2 Display & Safe Areas
*   **Sensor Housing:** Deep integration with `SafeArea`. Content must never be obscured by notches, dynamic islands, or punch-hole cameras.
*   **OLED Optimization:** On devices with OLED displays, the app should default to **True Black** backgrounds to conserve battery and increase contrast.
*   **Edge-to-Edge:** Navigational elements must seamlessly blend with the system gestural bar.

## 2. Hardware Feedback (Haptics)
Haptics are a first-class citizen on the phone platform to compensate for the lack of physical buttons.

*   **Selection:** Subtle click (Light) on every track or show selection.
*   **Action Success:** Medium vibration for successfully adding to queue or favoring.
*   **Dice Roll (Random):** Multi-stage "rumble" sequence during the selection animation.
*   **Warning:** Heavy vibration for "Block" actions or playback errors.

## 3. Native Integration

### 3.1 Background & Energy
*   **Background Audio:** The app must maintain a stable foreground service during playback to prevent OS-level process killing.
*   **Wakelock:** Enable `wakelock_service` during active playback ONLY. Disable immediately upon pause or stop.
*   **Battery:** Strictly avoid high-frequency UI updates (e.g., 60fps animations) when the app is in the background or the screen is off.

### 3.2 Lock Screen & Media Controls
*   **Service Integration:** Sync current track metadata (Title, Artist, Date) and album art to the system media controller.
*   **Playback Notifications:** Persistent notification with high-contrast Skip/Play/Pause controls.

## 4. Input & Sensors
*   **Gestures:** Vertical swipe-to-dismiss for the playback panel. Left/Right swipe on the mini-player for track skipping.
*   **Connectivity:** Monitor `ConnectivityService`. Automatically pause or notify if entering a cellular-only data state (based on user settings).

---
*Version: 1.0 (Hardware & Integration)*  
*Last Updated: 2026-03-02*
