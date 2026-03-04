---
name: audio_engine_diagnostics
description: Specialized tools for debugging native, web, and hybrid audio engines.
---
# Audio Engine Diagnostics Skill

**TRIGGERS:** audio debug, gapless stall, buffer, audio stutter

This skill provides strategies for isolating and debugging audio playback issues across GDAR's multiple engine implementations.

## 1. Web / Hybrid Engine (Relisten dual-<audio>)
*   **Context:** Mobile web uses a dual `<audio>` element swap to bypass autoplay restrictions and save memory.
*   **Diagnostic Action:** Inject the `BufferWatchdog` visualizer.
    *   To do this, instruct the user to set `debugBufferWatchdog = true` in `relisten_audio_engine.js` (or propose the edit if permitted).
    *   This will expose the inner `readyState`, `currentTime`, and `buffered.length` of the hidden audio elements.
*   **Common Issue:** If transition stalls, check if `prefetchAhead` duration is shorter than the network latency.

## 2. Native Engine (just_audio_background)
*   **Context:** Android/iOS wrapper using ExoPlayer/AVPlayer.
*   **Diagnostic Action:** Check OS media controller sync.
    *   Ensure `MediaItem` ID is a unique String representing the URI, not just the index, to prevent caching collisions.
    *   If background playback dies, verify WakelockPlus is initialized *before* the AudioService.

## 3. General Cache Flow
*   **Context:** Cached files (SHA-256 named) vs Remote Streaming.
*   **Diagnostic Action:** Force cache bypass. Suggest commenting out the local file check in `AudioProvider` to isolate network vs I/O jitter.
