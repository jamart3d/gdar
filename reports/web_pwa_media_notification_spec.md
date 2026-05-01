# Specification: Web PWA Media Notification Player (Independent)

This document provides a repo-independent technical specification for implementing **OS-level media integration** in a web-based Progressive Web App (PWA) using the **Media Session API**.

---

## 1. OS Integration: Media Session API
The PWA must synchronize its internal playback state with the host operating system's media controls (Lock Screen, Notification Shade, Control Center).

### 1.1 Action Handler Registration
The following handlers must be registered with `navigator.mediaSession`:
*   `play` / `pause`: Direct toggles of the active audio context.
*   `previoustrack` / `nexttrack`: Navigation within the current session's playlist.
*   `seekto`: Timeline scrubbing.
*   `seekbackward` / `seekforward`: Skips (recommended offset: 10 seconds).

### 1.2 Metadata Management
*   **Text:** Title, Artist, Album must be pushed to the OS on every track change.
*   **Artwork:** Provide high-resolution icons (192px and 512px) to ensure the notification player is visually complete.
*   **Position State:** Use `navigator.mediaSession.setPositionState` to synchronize the OS progress bar with the app's internal clock (requires `duration`, `position`, and `playbackRate`).

### 1.3 Authoritative Sync Pattern
*   **De-duplication:** Maintain a cache of the last pushed Title, Artist, and PlaybackState. Only write to `navigator.mediaSession` if the values change to minimize main-thread noise.
*   **Authority Pulse:** Mobile browsers often throttle JavaScript or "lose" the session during background transitions. The app should re-broadcast its full state every **15 seconds** while the document is hidden (`document.visibilityState === 'hidden'`).

---

## 2. Technical Manifest
*   **Required APIs:** `MediaSession API` (`navigator.mediaSession`).
*   **Asset Requirements:** 
    *   App icons in 192px and 512px for notification artwork.
*   **Testing:** Verify that the Lock Screen title updates immediately upon track change and that the play/pause state remains in sync after 5+ minutes of backgrounding.
