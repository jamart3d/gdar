# Web Buffering & Gapless Transition Audit

This document describes the intended behavior and technical implementation of the real-time next-track buffering progress indicator and gapless transition logic for the Shakedown platform, categorized by its **Three Engine Architecture**.

## 1. Feature Overview
When running on the web with a **Gapless Engine** enabled, the app provides a real-time status update for the upcoming track. This allows the user to verify that the next song is ready for a sample-accurate (desktop) or near-seamless (mobile) transition.

## 2. The Three Audio Engines

### A. Standard Engine (Native & Default Web)
*   **Implementation**: A transparent proxy to the standard `just_audio` `AudioPlayer`.
*   **Platform**: Android, iOS, and Web (when Gapless is OFF).
*   **Behavior**: Relies on system-level buffering. No custom prefetch logic or "Next" track message is surfaced.

### B. Gapless Web Engine: Desktop (Web Audio API)
*   **Implementation**: `web/gapless_audio_engine.js`.
*   **Mechanism**: Uses `AudioBufferSourceNode` for microsecond-accurate scheduling.
*   **Memory**: Downloads compressed MP3 data to RAM (`ArrayBuffer`), then decodes to PCM (`AudioBuffer`) just before the transition.
*   **Buffering**: Real-time progress ticks up during the fetch phase.

### C. Gapless Web Engine: Mobile (Dual HTML5)
*   **Implementation**: `web/relisten_audio_engine.js` (Inspired by Relisten).
*   **Mechanism**: Swaps between two `<audio>` elements. The secondary element pre-loads the next URL in the background.
*   **Memory**: Leverages browser native HTTP streaming; extremely low RAM overhead.
*   **Buffering**: Progress represents the browser's internal `buffered` range for the secondary element.

---

## 3. Trigger Logic (The "Transition Window")
The visibility and behavior of the "Next" track message are strictly tied to the **Web Prefetch Window** setting (default: 30 seconds).

### Phase 1: Fetching / Preloading
*   **Desktop**: Starts at `prefetchSeconds + 7s` before end. MP3 data stream is captured into RAM.
*   **Mobile**: Starts when remaining time $\le$ `prefetchSeconds + 5s`. The second audio element sets its `src` and calls `load()`.
*   **UI**: The `Next: MM:SS` message becomes visible and **ticks up** from `00:00`.

### Phase 2: Decoding & Scheduling (Desktop Only)
*   **Trigger**: Exactly `prefetchSeconds` before end.
*   **Action**: The engine converts the downloaded file into a PCM `AudioBuffer` and schedules it to play at the exact `AudioContext.currentTime` the current track ends.
*   **UI**: The message shows the **full duration** of the upcoming track as a "Readiness Indicator."

---

## 4. Platform Detection
`web/hybrid_init.js` automatically selects the engine at startup:
*   **Mobile Logic**: Detects `Mobi|Android|iPhone|iPad` or touch-capable devices with width < 1024px. Promotes the **Relisten HTML5 Engine**.
*   **Desktop Logic**: Defaults to the **Web Audio API Engine** for maximum precision.
*   **Diagnostic**: Check `window._shakedownAudioStrategy` in the console.

## 5. Verification Checklist
1.  **Settings**: "Gapless Engine" (or "HTML5 Audio Engine" on mobile) must be **ON**.
2.  **Settings**: "Show Playback Messages" must be **ON**.
3.  **Observation**: The "Next" message should appear and **tick up** approximately 35-37 seconds before the end.
4.  **Observation**: The transition should be completely inaudible (no pop, no silence, no click).
5.  **Observation**: Watch for "Ready" state switch at the 30s mark (Desktop).

## 6. Current Technical State
*   **Dispatcher**: `web/hybrid_init.js`
*   **Desktop Engine**: `web/gapless_audio_engine.js`
*   **Mobile Engine**: `web/relisten_audio_engine.js`
*   **Dart Interop**: `lib/services/gapless_player/gapless_player_web.dart`
*   **UI Component**: `lib/ui/widgets/playback/playback_messages.dart`
