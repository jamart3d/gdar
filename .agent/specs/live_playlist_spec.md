# Live Playlist (Session History) Specification

## 1. Overview

**Monorepo scope:** Session history behavior should be implemented primarily in shared logic under `packages/shakedown_core`, while app-specific presentation may differ across `apps/gdar_mobile`, `apps/gdar_tv`, and `apps/gdar_web`.

The "Live Playlist" (also known as Session History) tracks the history of shows played by the user. It allows for seamless navigation backward across different shows and provides "Undo" capabilities for accidental track skips or show blocks.

## 2. Data Model
A `SessionEntry` represents a show and its playback state during the current session.

```dart
class SessionEntry {
  final String showId;
  final String title;
  final String date;
  final int trackIndex;
  final Duration position;
  final DateTime timestamp;
}
```

## 3. Core Logic (AudioProvider)

### 3.1 Session History Management
- **Recording:** A new `SessionEntry` is added to the history whenever:
    - A new show starts playing.
    - A significant playback milestone is reached (e.g., every 5 minutes) to update the "Resume" point in history.
- **Rollback:** The history is a **Rolling Stack** limited to the last **50 shows**.

### 3.2 Navigation Rules
- **Cross-Show Back:** If the current `trackIndex == 0` and the user triggers "Previous Track":
    1. Check if a previous `SessionEntry` exists in the history.
    2. If yes, load that show and jump to its **last track**.
- **Cross-Show Forward:** If the current `trackIndex` is the last in the show:
    1. If the user triggers "Next Track", load the next show in the "Live Playlist" (if one was previously manually selected or if in a "Continuous Play" mode).

## 4. UI Implementation

### 4.1 Google TV (Lean-back)
- **D-Pad Navigation:**
    - Pressing "Left" on the D-pad at the first track of a show will trigger the "Back to Previous Show" logic.
    - A subtle OSD (On-Screen Display) label should appear: *"Back to [Previous Show Title]"*.
- **Blocking Protection:** If a show is blocked, a "Undo Block" toast should appear for 5 seconds, allowing the user to restore the show to the current session.

### 4.2 Web & Phone (Interactive)
- **Undo Button:** A "Glass Pill" notification or a subtle undo icon appears in the playback bar after:
    - A manual track skip.
    - A show block.
    - A manual show change.
- **Swipe Gestures:** On mobile, swiping "Back" past the first track will pull in the previous show's last track with a haptic bump.

## 5. Persistence
- **Storage:** The `SessionHistory` is serialized to JSON and saved to `SharedPreferences` under `session_history_v1`.
- **Lifecycle:** The history persists across app restarts.
- **Manual Cleanup:** An option in "Advanced Settings" allows the user to click "Clear Session History".

---

## 6. Edge Cases
- **Deleted/Blocked Tracks:** If a show in the history is now "Blocked" via the Global Blocklist, it should be skipped when navigating backward.
- **Offline Mode:** If the app is offline, entries in the history that are not cached should display an "Offline - Cannot Resume" placeholder.
