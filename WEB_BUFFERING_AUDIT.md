# Web Buffering & Gapless Transition Audit

This document describes the intended behavior and technical implementation of the real-time next-track buffering progress indicator and gapless transition logic for the web platform.

## 1. Feature Overview
When running on the web with the **Gapless Web Engine** enabled, the app now provides a real-time status update for the upcoming track. This allows the user to verify that the next song is ready for a sample-accurate transition.

## 2. Trigger Logic (The "Transition Window")
The visibility and behavior of the "Next" track message are strictly tied to the **Web Prefetch Window** setting (default: 30 seconds).

The transition process follows a two-stage timeline:

### Phase 1: Fetching (`prefetchSeconds + 7 seconds` before end)
*   **Trigger**: When the current track's remaining time reaches the prefetch window plus a 7-second buffer.
*   **Action**: The engine starts downloading the MP3 data from the server.
*   **UI**: The `Next: MM:SS` message becomes visible.
*   **Progress**: The timer **actively ticks up** from `00:00`, representing the actual amount of audio data (in seconds) currently stored in RAM.

### Phase 2: Decoding & Scheduling (`prefetchSeconds` before end)
*   **Trigger**: When the remaining time hits the exact user setting.
*   **Action**: The engine stops "streaming" and converts the entire downloaded file into a PCM `AudioBuffer`. It then schedules this buffer to play at the exact microsecond the current track ends.
*   **UI**: The `Next: MM:SS` message shows the **full duration** of the upcoming track (e.g., `Next: 08:12`). This serves as a "Readiness Indicator."

## 3. Gapless Precision
To achieve true 0ms gaps, the engine uses the **Web Audio API** (`AudioBufferSourceNode`):
*   **Context Sync**: The engine calculates `_scheduledStartContextTime` (the exact `AudioContext.currentTime` when the next track should start).
*   **Zero-Overhang**: The previous track's `stop()` command is avoided during transition; the browser's native `onended` event triggers the promotion of the scheduled track to "active" status.
*   **Progress Bar Stability**: The `position` and `duration` reported to Dart are strictly isolated between the current and scheduled tracks. This prevents the progress bar from "jumping" or "freezing" while the next track is being prepared.

## 4. Platform Detection
The UI distinguishes between Web-Mobile and Web-Desktop via `DeviceService`:
*   **isMobile**: True for Android/iOS browsers.
*   **isDesktop**: True for Windows/macOS/Linux browsers.
*   **Impact**: Controls font scaling and UI density while maintaining the same high-performance audio engine.

## 5. Verification Checklist
1.  **Settings**: "Gapless Web Engine" must be **ON**.
2.  **Settings**: "Show Playback Messages" must be **ON**.
3.  **Observation**: The "Next" message should be **HIDDEN** for the majority of a song.
4.  **Observation**: It should appear and **tick up** approximately 37 seconds before the end (with a 30s prefetch setting).
5.  **Observation**: The transition should be completely inaudible (no pop, no silence, no click).

## 6. Current Technical State
*   **JS Engine**: `web/gapless_audio_engine.js` (Updated with `ReadableStream` fetching and state gating).
*   **Dart Interop**: `lib/services/gapless_player/gapless_player_web.dart` (Surfacing `nextTrackBufferedStream` and `nextTrackTotalStream`).
*   **UI Component**: `lib/ui/widgets/playback/playback_messages.dart` (Displays the gated progress).
