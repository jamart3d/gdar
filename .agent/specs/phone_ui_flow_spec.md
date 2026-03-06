# Phone UI Flow Specification: GDAR Audio Player

This document defines the interaction model, navigation stack, and core user flows for the **Mobile (Android/iOS)** implementation of GDAR. It relies on the [Android Theme Spec](file:///home/jam/StudioProjects/gdar/.agent/specs/android_theme_spec.md) (Look) and the [Phone Platform Spec](file:///home/jam/StudioProjects/gdar/.agent/specs/phone_ui_design_spec.md) (Feel/Hardware).

## 1. Interaction Architecture
The Phone UI is strictly **Walled Off** from the Fruit (Liquid Glass) theme. It utilizes the **Material 3 Expressive** baseline to ensure high-performance native navigation.
The Phone UI follows a standard linear navigation stack using Flutter's `Navigator`.

*   **Primary Screen:** `ShowListScreen` (The catalog/browsing hub).
*   **Expansion Point:** `TrackListScreen` (Detailed track browsing for a specific show).
*   **Context Layer:** `PlaybackScreen` (A persistent `SlidingUpPanel` overlay for active controls).
*   **Utility Screens:** `SettingsScreen`, `AboutScreen`, and `RatedShowsScreen` are pushed onto the stack from the app bar or menus.

## 2. Core Interaction Flows

### 2.1 Browsing & Playback
1.  **Selection:** Tapping a show in the `ShowListScreen` initiates one of two actions:
    *   **Direct Play:** If the show has a single source, it starts playback immediately.
    *   **Expand:** If the show has multiple sources, it expands the card to show available versions.
2.  **Immersive Browser:** Tapping an already expanded show card (or a specific source) navigates the user to the `TrackListScreen` for that show.
3.  **Active Control:** Once playback begins, the **Mini-Player** becomes visible at the bottom of the screen.

### 2.2 Playback Control (The Slide-Up Panel)
*   **Expansion:** A vertical upward swipe or a tap on the Mini-Player expands the `SlidingUpPanel` to reveal the `PlaybackScreen`.
*   **Deep Navigation:** Tapping the venue/date text in the expanded player scrolls the internal track list to the currently playing track.
*   **Dismissal:** A vertical downward swipe or tapping the "down" arrow icon collapses the player back to the Mini-Player state.

### 2.3 Clipboard & Deep Links
GDAR includes specialized logic for handling external show references:
*   **Search Bar Detection:** Pasting a SHNID (e.g., `gd1977-05-08.shnid...`) or an `archive.org/details/gd...` URL into the search bar triggers an automatic playback search.
*   **Auto-Play:** If a valid show is parsed from the clipboard, the app will automatically start playback and navigate to the playback controls.

## 3. Gesture & Haptic Mapping

| Action | Gesture | Feedback |
| :--- | :--- | :--- |
| **Play Random Show** | Tap (Dice Icon) | `mediumImpact` Haptics + Dice Animation |
| **Open Settings** | Tap (Title/Logo) | `selectionClick` Haptics |
| **Expand Player** | Swipe Up / Tap | Smooth panel slide |
| **Seek Track** | Horizontal Slide | Visual time update |
| **Rate Show** | Long-Press | `vibrate` (if blocked) / `selectionClick` |

## 4. UI Transition Philosophy
*   **Consistency:** Transitions between screens use the platform-standard page route transitions (Material for Android, Cupertino for iOS).
*   **Context Preservation:** The `SlidingUpPanel` ensures that the user never loses access to playback controls, regardless of where they are in the navigation stack.
*   **Loading States:** High-performance "Skeletons" or "Slightly Opacity" pulses are used during metadata fetching to maintain a feeling of responsiveness.

---
*Version: 1.0*  
*Last Updated: 2026-03-02*
