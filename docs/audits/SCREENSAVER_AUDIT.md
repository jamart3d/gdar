# Google TV Screensaver & Sleep Audit

This report analyzes the interaction between the application's internal screensaver, the "Prevent Sleep" setting, and the Android system "Dream" (screensaver/sleep) state on Google TV.

## Current Implementation Analysis

### 1. Prevent Sleep (Wakelock)
- **Primary Controller**: `AudioProvider.dart`
- **Mechanism**: Uses `WakelockPlus` via `WakelockService`.
- **Condition**: 
    ```dart
    if (shouldPreventScreensaver && isPlaying) {
      _wakelockService.enable();
    } else {
      _wakelockService.disable();
    }
    ```
- **Finding**: The "Prevent Sleep" setting is **strictly tied to active audio playback**. If the music is paused or stopped, the wakelock is released immediately.

### 2. Internal Screensaver (Oil Slide)
- **Controller**: `InactivityService.dart` (monitors keyboard/touch events).
- **Trigger**: Shows `ScreensaverScreen` after `settingsProvider.oilScreensaverInactivityMinutes`.
- **Finding**: `ScreensaverScreen` **does not** manage its own wakelock. It relies entirely on the global state or the `AudioProvider` wakelock.

## Interaction Scenarios on Google TV

| Scenario | Audio Playing | Prevent Sleep (Setting) | Result | Will it go to "Dream"? |
| :--- | :--- | :--- | :--- | :--- |
| **Normal Playback** | Yes | On | Screen stays on app UI. | **No** |
| **Internal Screensaver** | Yes | On | Internal screensaver is visible and stays indefinitely. | **No** |
| **Internal Screensaver** | No | On/Off | Internal screensaver starts, but after the system timeout (e.g., 5-15 mins), the TV will switch to System Dream or Sleep. | **Yes** |
| **Playback Paused** | No | On | Wakelock is disabled. System will eventually go to Dream/Sleep. | **Yes** |

## Audit Conclusions

### Conflict/Gap identified:
There is a logical gap for users who want the **Internal Screensaver to be persistent** without music playing. 
Currently, if you leave the app on the screensaver but stop the music, the Google TV "Dream" state will eventually take over and hide/kill the app's visualizer.

### Recommendation:
If the goal is for the internal screensaver to *replace* the system dream when active:
1. `ScreensaverScreen` should hold its own `Wakelock` while it is in the foreground.
2. This would ensure that as long as the app's screensaver is visible, the system remains "awake".

## Verification Log
- Checked `AudioProvider.dart`: Wakelock only active if `isPlaying == true`.
- Checked `wakelock_service.dart`: Simple wrapper for `WakelockPlus`.
- Checked `ScreensaverScreen.dart`: No wakelock logic found.
- Checked `main.dart`: `InactivityService` orchestration confirmed.
