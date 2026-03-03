# Native Mobile Audio Architecture (GDAR)

This specification documents the current state and structure of the native audio engine used in the GDAR mobile applications (iOS/Android). It serves as the source of truth for background execution, caching policies, buffer handling, and default user configurations.

## 1. Core Architecture

### **The Engine Room (`AudioProvider` & `just_audio`)**
The GDAR mobile application relies heavily on `ryanheise`'s `just_audio` and `audio_service` packages. 
- **AudioProvider:** This acts as the state management wrapper (via `ChangeNotifier`) that interfaces between the UI and the underlying `just_audio` player.
- **AudioService (Background Execution):** To survive Android's App Standby Buckets and iOS's strict background execution limits, `audio_service` links the application to a robust background isolate. This is what allows audio to continue playing when the phone screen turns off or the user switches apps.

### **The Queue Model**
The player uses `setAudioSources` with a sequence of `AudioSource` objects to feed tracks to the OS. Currently, an entire "Show" (e.g., a multi-set concert) is flattened into a single playlist sequence when loaded, allowing the OS to fetch the next track seamlessly. This modern approach replaces the deprecated `ConcatenatingAudioSource`.

---

## 2. Options, Behaviors & Toggles

### **Play on Tap (`playOnTap`)**
- **Default:** `false`
- **Behavior:** When the user taps a track in a show that isn't currently playing, `false` requires them to confirm they want to interrupt their current queue. If `true`, playback swaps immediately.

### **Advanced Cache (`offlineBuffering`)**
- **Default:** `false`
- **Behavior:** When enabled, the `AudioProvider` attempts to pre-fetch and store up to 5 upcoming tracks to the device's local `/cache` directory (or equivalent app-specific storage). 
- **Purpose:** This allows the app to survive complete network dropouts (e.g., driving through a tunnel) without interrupting playback. When disabled, the app relies purely on the OS-level stream buffer.

### **Buffer Agent (`enableBufferAgent`)**
- **Default:** `true`
- **Behavior:** This is a custom recovery mechanism built into `AudioProvider`. It watches the `playerStateStream` for stall conditions (where `processingState` is `buffering` but no data is arriving for >3 seconds). 
- **Action:** If a stall is detected and the buffer agent is enabled, it attempts to force a reconnect or skip the corrupted chunk to prevent infinite loading spinners.

### **Track Transitions (`trackTransitionMode`)**
- **Default:** `gapless` (String)
- **Behavior:** 
    - `gapless`: Instructs `just_audio` to attempt a zero-millisecond handoff between tracks (essential for live continuous concerts).
    - `gap`: Forces a standard pause between tracks (rarely used).
    - `crossfade`: Blends track A out while fading track B in.
- **Crossfade Duration:** Default is `3.0` seconds (configurable between 1.0 - 12.0s).

---

## 3. General Playback Defaults

When a user fresh-installs GDAR, the audio engine inherits the following baseline from `DefaultSettings`:

*   **Play Random on Completion:** `true` (When a show ends, the engine automatically selects and spawns another random show).
*   **Play Random on Startup:** `false` 
*   **Show Playback Messages:** `true` (UI flashes toasts/snackbars on buffer stalls or errors).
*   **Prevent Sleep:** `false` (Screen is allowed to sleep to save battery; audio continues via `audio_service`).

---

## 4. Known Limitations & Future Plans

### **Current Limitations**
1.  **AudioService Notification Synchronization:** Very rarely, rapid tapping of the "Skip" button on a physical Bluetooth car stereo can cause the lock-screen notification to become de-synced from the internal `AudioSource` sequence index.
2.  **Cache Thrashing:** If `offlineBuffering` is enabled on low-storage devices, the OS may silently purge the temporary cache directory *while* the app is playing, causing a skip or error.

### **Future Roadmap**
*   **Equalizer (EQ) Support:** Utilizing the `just_audio` Android/iOS equalizer pipelines to introduce a customizable multi-band EQ and bass boost.
*   **Persistent Custom Playlists:** Evolving the playlist logic to support mixing `AudioSource` objects from entirely different shows into a saved local playlist.
*   **Queue Restore / Undo Block:** Implementing a memory stack to allow users to "undo" an accidental show selection and return to their exact previous spot in a queue, or undo a "swipe to block" action via a standard SnackBar action.
*   **Live Continuous Playlist:** Changing the queue model from clearing on every new show to appending them. As each new show is requested (manually or via `playRandomOnCompletion`), it is appended to a continuous runtime playlist. This would allow a user to legitimately "Skip Previous" at track 1 of Show B, and jump backward into the end of Show A. This live queue would exist only in memory and be destroyed when the app closes.
