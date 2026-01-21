# Random Playback Selection Probability Analysis

This report details the logic governing how `shakedown` selects sources of shows for random playback. The selection process involves **filtering**, **weighting**, and **context-aware triggers**.

## Core Selection Algorithm

The core logic resides in `AudioProvider.pickRandomShow`. It uses a **weighted random selection** method, meaning not all shows have an equal chance of being picked. Favorites and unplayed shows are significantly more likely to be chosen than standard played shows.

### 1. Weighting System (Base Probability)

Each eligible show is assigned a weight score. The higher the score, the higher the probability of selection.

| Status | Rating | Weight Score | Relative Probability |
| :--- | :--- | :--- | :--- |
| **Favorite** | ★★★ (3 Stars) | **200** | Very High |
| **Great** | ★★ (2 Stars) | **100** | High |
| **Unplayed** | ☆☆☆ (0 Stars) | **60** | Medium |
| **Good** | ★ (1 Star) | **40** | Low |
| **Played** | ☆☆☆ (0 Stars) | **10** | Very Low |
| **Blocked** | Red Star (-1) | **0** | Never Selected |

*   **Played Shows**: If a show is marked as played (and has 0 stars), its weight drops from 60 to 10, making it 6x less likely to be picked than an unplayed show.
*   **Favorites**: A 3-star show is 20x more likely to be picked than a generic played show.

### 2. Global Filters (Hard Constraints)

Before weighting occurs, shows can be completely excluded based on user settings. These act as "hard" filters—if a show matches these criteria, its probability is 0%.

*   **Blocked Shows**: Any source with a -1 rating is **always** excluded.
*   **Only Select Unplayed**: If enabled in settings, **all** played shows are excluded.
*   **Only Select High Rated**: If enabled in settings, **all** shows with < 2 stars (0 or 1 star) are excluded.
*   **Source Category**: Shows that do not have a source matching the active source filters (e.g., "Matrix", "SBD") are excluded.

---

## Scenario Analysis

The behavior changes slightly depending on *how* random playback is triggered. The key difference is whether the current **Search Query** is respected.

### Scenario A: App Start (Play on Startup)
*   **Trigger**: `ShowListScreen.initState`
*   **Setting**: `SettingsProvider.playRandomOnStartup == true`
*   **Logic**:
    1.  **Wait for Data**: The logic waits for `ShowListProvider` to finish loading JSON.
    2.  **State Safety**: A listener ensures we don't try to play before the list is ready.
    3.  **One-Shot Execution**: A `_randomShowPlayed` flag ensures it only triggers once per app session (not on every screen rebuild).
    4.  **Race Condition Handling**: `WidgetsBinding.instance.addPostFrameCallback` is used to ensure the UI is mounted before navigation or playback errors can occur.
*   **Search Filter**: **Respects Search** (Usually empty on boot).
*   **Candidate Pool**: Full Library (filtered by Source/Rating).

### Scenario B: Random Button (Show List Screen)
*   **Trigger**: `ShowListScreen._handlePlayRandomShow` (AppBar Question Mark Button)
*   **Search Filter**: **Respects Search** (`filterBySearch: true`).
*   **Source Filter**: **Respects Source Settings** (Global Constraint).
*   **Logic**:
    1.  **Search Priority**: The picker *starts* with the currently visible list.
        *   If you have typed "Maine" or "1977", it **only** picks from those search results.
        *   If the search bar is empty, it considers the **Full Library**.
    2.  **Global Constraints**: It **strictly filters** out blocked shows and sources that don't match your settings.
    3.  **Selection**: Applies standard weighting to the remaining valid candidates.

### Scenario C: Show End (Continuous Play / Background)
*   **Trigger**: `AudioProvider._positionSubscription` (Automatic)
*   **Setting**: `SettingsProvider.playRandomOnCompletion == true`
*   **Context**: Often triggered while the **App is Backgrounded** and **Screen is Off**.
*   **Search Filter**: **IGNORES Search** (`filterBySearch: false`).
*   **Deep Sleep Risk**:
    *   **Mechanism**: The trigger relies on a Dart `StreamSubscription` listening to the player position *in the Flutter UI Isolate*.
    *   **The Risk**: On Android 14+ (especially Samsung/Xiaomi), the OS is aggressive about suspending background apps.
    *   **Consequence (Observed)**: The "End of Show" event IS caught, and the app *successfully selects* the next show (UI updates), but the transition fails to start audio.
    *   **Root Cause**: The current implementation calls `await player.stop()` before loading the new source. This creates a **Silence Gap**. During this gap, the Android OS sees "No Audio Playing" and "Screen Off", causing it to immediately suspend the app's execution before `player.play()` can be called for the new show. To the user, it looks like it picked a show but forgot to play it.
    *   **Mitigation**: The app currently uses `partialWakeLock` and `foregroundService`, but these are often insufficient during the critical "Silence Gap".
*   **Logic**:
    1.  Detects when `position` is within 250ms of the end of the *last track*.
    2.  **Ignores Search** (selects from Full Library) to avoid looping small search results.
    3.  **Strictly adheres** to Source Category settings.

---

## Summary Table

| Trigger | Context | Search Filter | Source Filter | Pool of Candidates |
| :--- | :--- | :--- | :--- | :--- |
| **App Start** | `playRandomOnStartup` | **Yes** (Effectively Full*) | **Yes** | Full Library (filtered by Source) |
| **Random Button** | AppBar Icon | **Yes** | **Yes** | **Filtered Results** (or Full if empty) |
| **Show End** | Continuous Play | **No** (Always Full) | **Yes** | **Full Library** (filtered by Source) |


---

## Deep Sleep Solutions (Ensuring Continuous Playback)

The primary risk in "Scenario C" is that the Android OS pauses the Dart code (Flutter Isolate) to save battery while the screen is off, preventing the app from knowing *when* to pick the next show. Below are three strategies to mitigate this.

### Option 1: Native Pre-Queueing (Recommended)
**The "Set It and Forget It" Approach.**
Instead of waiting for the current show to finish, we queue the *next* random show while the *current* one is still playing.
*   **How it works**: When the last track of the current show begins, the app immediately picks a random show and appends it to the native player's playlist (`ConcatenatingAudioSource`).
*   **Why it helps**: It removes the dependency on the Flutter Isolate during the transition. The hand-off happens entirely in the Native Audio Service (ExoPlayer), which is immune to Isolate suspension.
*   **Crucial Benefit**: It eliminates the `stop()` call, removing the "Silence Gap" where the OS usually kills the background process.
*   **Pros**: 100% gapless, highly robust, works even if the phone aggressively kills background apps.
*   **Cons**: Requires more complex state management (e.g., handling what happens if the user skips manually while the next show is already queued).

### Option 2: Critical Window Wakelock
**The "Brute Force" Approach.**
Force the phone's CPU to stay awake during the critical transition period.
*   **How it works**: Use a package like `wakelock_plus` to enable a "Partial Wake Lock" when the playback reaches the last 5 minutes of a show.
*   **Why it helps**: It explicitly forbids the OS from putting the CPU to sleep, ensuring the Flutter code keeps running to catch the "End of Show" event.
*   **Pros**: Easy to implement.
*   **Cons**: Higher battery usage; OS might still ignore it if battery is critically low.

### Option 3: Notification High-Priority Update
**The "Keep Alive" Approach.**
*   **How it works**: Send a specific update to the media notification (e.g., changing the text to "Loading next show...") just before the track ends.
*   **Address User Question**: *"Would doing a silent notification help?"*
    *   **Verdict**: **Likely No.** The issue isn't that the notification is missing (the valid media notification is already there), but that the *code logic* meant to trigger the next action is asleep. Sending a silent notification requires the code to be awake to send it. It's a chicken-and-egg problem. If the code is awake enough to send a notification, it's awake enough to play the song. If it's asleep, it can't do either.
*   **Pros**: Minimal code change.
*   **Cons**: Unreliable. Android 14+ is very smart about ignoring "silent" updates from background apps.

### Recommendation
**Implement Option 1 (Pre-Queueing).** It aligns best with the architecture of `just_audio_background` and solves the root cause (dependency on the Flutter Isolate) rather than fighting the symptoms.

