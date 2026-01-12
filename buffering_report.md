# Audio Buffering Behavior Report

## 1. Start of Playback
*   **Mechanism**: The `AudioProvider` initializes playback by calling `setAudioSource(preload: true)`. This instruction tells the underlying `just_audio` plugin (and the native ExoPlayer on Android) to begin loading the media immediately.
*   **Sequence**:
    1.  **Idle**: Player is waiting for a source.
    2.  **Loading**: Source is set; connection to the stream URL is established.
    3.  **Buffering**: Data begins downloading. The `AudioPlayer` enters the `buffering` processing state.
*   **Playback Trigger**: Playback (video frame rendering or audio output) does not begin immediately upon connection. It waits until the buffer fills to the `initialPlaybackStartTimeMs` threshold (ExoPlayer default is typically **2500ms**).
*   **UI Feedback**: The application UI observes the `processingStateStream`. When the state is `buffering`, a loading spinner is displayed to the user.

## 2. Mid-Playback
*   **Mechanism**: Usage of `ConcatenatingAudioSource` allows the player to pre-buffer subsequent tracks while the current one plays. However, if network conditions deteriorate (throughput drops below the audio bitrate), the buffer for the *current* track may deplete.
*   **Stalling**: When the buffer reaches 0ms (buffer underrun), the player automatically transitions from `playing` to `buffering`.
*   **Behavior**: Playback pauses. It will not resume immediately upon receiving the next packet. Instead, it waits for the **rebuffer threshold** to be met (often same as initial or slightly lower, to prevent rapid toggle between play/pause). Once met, state returns to `ready` or `playing`.

## 3. Foreground vs. Background Execution
*   **Core Logic**: The Dart code and `just_audio` logic remain identical whether the app is in the foreground or background.
*   **Service Architecture**: The app uses `just_audio_background`, which wraps the player in a standard Android `Foreground Service`.
    *   **Purpose**: This informs the Android OS that the user is aware of the app's activity (via the notification controls), preventing the OS from killing the process for memory reclamation.
*   **Operational Differences**:
    *   **Network Throttling**: Android (especially in power-saving modes or "Data Saver") may aggressively throttle network bandwidth for processes not in the "top" visible state, even with a Foreground Service. This can lead to slower buffering or more frequent stalls compared to when the app is open and active.
    *   **CPU Priority**: While the `Foreground Service` keeps the process alive, it may have slightly lower scheduling priority for immediate CPU wakelocks compared to the active UI thread, though this is generally negligible for audio decoding on modern hardware.
