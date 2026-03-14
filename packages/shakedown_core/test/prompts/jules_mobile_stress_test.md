# Jules Older Phone Stress Test (Web UI & Audio)

**Mission:** Simulate the experience of an older mobile device (e.g., iPhone 8 or Pixel 3) in a high-stress scenario. We are looking for UI jank, audio stutter, and scheduler drift. Use specialized Chrome DevTools settings.

---

### Phase 1: Silicon Decay Simulation
1.  **CPU Throttling**: Open Chrome DevTools > Performance > CPU: **6x slowdown**.
2.  **Network Throttling**: Set Network to **Fast 3G** to simulate real-world mobile data latency during track pre-fetches.
3.  **Navigate**: Load the app and start any show.

### Phase 2: The "Fruit" Friction Test (UI Overhead)
1.  **Enable Fruit Theme**: Ensure "Fruit" style is active (Web/PWA).
2.  **Stress Action**:
    - Open the **Playback Panel**.
    - Rapidly scroll through the show list (if visible) or the tracklist.
    - Quickly toggle the **Miniplayer** and **Sticky Player** (if available).
3.  **Audit**: 
    - Does the `BackdropFilter` (blur) cause the frame rate to drop below 30FPS?
    - Does UI interaction cause the audio to "crack" or gap?

### Phase 3: Audio Memory & Scheduler Gauntlet
1.  **Rapid Sequential Loading**:
    - Pick a random show.
    - Wait for playback to begin.
    - Immediately pick another random show.
    - Repeat 5 times.
2.  **Observation**:
    - Check the console for `Memory Pressure Warning` or `Aborted fetch` peaks.
    - Monitor `gapless_audio_engine.js` logs. Does the look-ahead scheduler maintain the 3s window during these transitions?

### Phase 4: Long-Haul Scheduler Drift
1.  **Monitor Transition**:
    - Seek to 3 seconds before the end of a track.
    - Keep the UI busy (continuous rapid scrolling) during the transition.
2.  **Audit**: 
    - Does the next track start exactly at 0ms? 
    - Does `drift_ms` in the console logs exceed 50ms under this 6x CPU load?

**Report:** 
- Provide a summary of FPS during Phase 2.
- Log any `AudioContext` suspension or scheduler drift errors.
- Screenshot the Playback Panel if the "Fruit" theme lags during rapid UI changes.
