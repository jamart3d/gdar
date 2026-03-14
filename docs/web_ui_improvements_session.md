# Web UI Audio & HUD Improvements — Session Log (2026-03-13)

This document tracks the technical enhancements made to the Web UI audio engines and diagnostic tools during this session. It serves as an explicit guide for reproducing these changes or continuing the hardening roadmap.

## ✅ COMPLETED ENHANCEMENTS

### 1. HUD Diagnostic: Visibility & Timer Drift Monitoring
Implemented real-time monitoring of browser throttling to diagnose background playback stalls.

*   **Logic:** Added a high-resolution drift monitor that calculates the delta between expected update intervals (250ms/4Hz) and actual execution time.
*   **Key Files:**
    *   `lib/services/gapless_player/gapless_player_web.dart`: Added `_driftController` and `driftStream`.
    *   `lib/ui/widgets/playback/dev_audio_hud.dart`:
        *   Added `V` (Visibility: VIS/HID) and `DFT` (Drift in seconds) telemetry chips.
        *   Wrapped HUD build in a `StreamBuilder` for the `driftStream`.
*   **Metric Interpretation:**
    *   `DFT: 0.25s` = Healthy (4Hz updates).
    *   `DFT: 1.00s+` = Throttled (1Hz background clamp).

### 2. Standard Engine (`just_audio`) Background Hardening
Hardened the standard fallback engine against OS-level process suspension on mobile browsers.

*   **Logic:** Integrated the project's silent "heartbeat" infrastructure (audio/video loops) into the fallback path.
*   **Key Files:**
    *   `lib/services/gapless_player/gapless_player_web.dart`:
        *   Added JS interop for `_gdarHeartbeat`.
        *   Implemented `_startSurvival()` and `_stopSurvival()` helpers.
        *   Modified `play()`, `pause()`, and `stop()` in the fallback path to trigger these survival heartbeats.
        *   Implemented `_startFallbackDriftTimer()` to provide `DFT` metrics and heartbeat pulses when custom JS engines are disabled.
        *   Updated `setHybridBackgroundMode()` to sync survival strategies (Video, Heartbeat, Audio) to the fallback engine.

### 3. Audio Specifications (Source of Truth)
Created and updated project specifications to enforce background stability standards.

*   **`@.agent/specs/web_ui_audio_hud.md`**: New spec defining HUD keys, interactive pop-up menus, and dynamic visual signals (Heartbeat Dot, Handoff Orange Alert).
*   **`@.agent/specs/web_ui_audio_engines.md`**: Updated with strict stability requirements for Engine [3] Standard and Engine [4] Passive.

---

## 📝 BACKLOG / PENDING HARDENING

### 1. Passive Engine (`passive_audio_engine.js`)
The standalone Passive engine requires three specific changes to reach parity with the Hybrid/Standard stability.

*   **Survival Triggers:**
    *   Inject `window._gdarHeartbeat.startAudioHeartbeat()` into the engine's `play()` method.
    *   Inject `window._gdarHeartbeat.stopHeartbeat()` into the `pause()` method.
*   **MediaSession State Sync:**
    *   Explicitly set `navigator.mediaSession.playbackState = 'playing'` during the `_onTrackEnded` transition phase.
    *   This prevents the OS from reclaiming the media session during the ~500ms gap where the `<audio>` element has no active `src`.
*   **Worker Timer Integration:**
    *   Replace the internal `setInterval` polling with a listener for the `gdar-worker-tick` event.
    *   This ensures the transition logic stays alive at 4Hz even when the main thread is clamped to 1Hz by the browser.

### 2. HUD Diagnostic Upgrades (PWA Recovery)
To better diagnose "why" playback stops during PWA background/foreground transitions.

*   **`MDFT` (Max Observed Drift):**
    *   Implement persistent `_maxDrift` tracking in `GaplessPlayerWeb`.
    *   Captures the "peak" drift (e.g., 8.0s) encountered while backgrounded, even after returning to foreground.
*   **`CTX` (Audio Context State):**
    *   Expose the raw `AudioContext.state` string (Running, Suspended, Closed).
    *   Critical for identifying "Silent Audio" caused by OS-level resource suspension.
*   **`V-DUR` (Visibility Duration):**
    *   Enhance the `V` chip to track duration: `V:HID(12m)` or `V:VIS(4m)`.
    *   Helps correlate OS process killing with total background time.
*   **`RVC` (Recovery Count):**
    *   Track how many times the Hybrid engine's "Stall Recovery" or "Forced Suspension Handoff" have saved the session.
    *   Indicates engine resiliency in high-stress network or background scenarios.

### 3. HUD Visual Polish (High-Glance Debugging)
Refinements to make the HUD more stable and easier to read during rapid state changes.

*   **"Traffic Light" Heartbeat (3-Dot Stack):**
    *   Replace the single dynamic dot with a vertical/horizontal stack of three dedicated indicators:
        *   **Red:** Flashes ONLY when heartbeat is `Required` but `Not Active`.
        *   **Orange:** Solid when heartbeat is `Not Needed` by the current OS.
        *   **Green:** Flashes when heartbeat is `Active` and `Working`.
    *   **Dimmed State:** All three dots remain low-opacity when playback is paused.
*   **Fixed-Width Layout (Jitter Prevention):**
    *   Apply explicit `width` or `constraints` to standard telemetry chips (ENG, AE, DFT, V).
    *   Prevents the HUD from "dancing" or resizing when values fluctuate (e.g., swapping between `DFT: 0.25s` and `DFT: 10.0s`).

---

## 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability)

The HTML5 Engine is a direct port of the Relisten gapless architecture, optimized for the aggressive power-saving environments of mobile browsers.

### 1. The Dual-Path Strategy
*   **Promotion Logic:** The engine can start a track in "Streaming Mode" (HTML5) for zero-latency starts and "promote" it to "Web Audio Mode" mid-playback once the high-fidelity buffer is decoded.
*   **Fallback Resilience:** If Web Audio fails to decode or the context is suspended, the engine stays in HTML5 mode, ensuring playback never stops.

### 2. Background Persistence
*   **Worker Heartbeat:** By binding to `gdar-worker-tick`, the engine's prefetch and progress logic bypasses the `requestAnimationFrame` (RAF) suspension that occurs when a mobile tab is hidden.
*   **Native Buffering:** Leverages the browser's own `<audio>` tag buffering, which is less likely to be reclaimed by the OS than custom JS memory buffers.

### 3. Proposed Mobile HUD Diagnostics
New signals to monitor PWA performance:
*   **`H5-EL` (Active Element):** Indicates if the Relisten track is currently using `H5` (Streaming) or `WA` (Promoted Buffer).
*   **`H5-SW` (Swap Ready):** Confirms if the secondary "next" element is primed for a gapless transition.
*   **`H5-PRE` (Preload Queue):** Reports which index the engine is currently pre-caching in the background.

The Web Audio Engine is the flagship choice for high-fidelity, sample-accurate playback on Desktop.

### 1. High-Precision Scheduling
*   **Sample Accuracy:** Uses `AudioBufferSourceNode.start(time)` to schedule transitions in the future, bypassing the jitter inherent in the JavaScript event loop.
*   **Watchdog Logic:** A 500ms monitor ensures that if the browser misses a scheduled boundary (due to CPU spike or window throttling), the engine forcefully transitions to prevent a playback "hang."

### 2. The Decode Pipeline
*   **Dual-Tier Caching:**
    *   **Compressed (`ArrayBuffer`)**: Kept during download to support partial progress reporting.
    *   **Decoded (`AudioBuffer`)**: Fully uncompressed PCM data ready for instant scheduling.
*   **Memory Safety:** Implements `_evictOldBuffers` which strictly limits the uncompressed cache to `Current + 1` tracks, preventing browser crashes during long shows.

### 3. Proposed Desktop HUD Diagnostics
New signals intended for high-fidelity tuning on desktop environments:
*   **`MEM` (Memory):** Estimate of JS heap usage to monitor uncompressed buffer overhead.
*   **`DEC` (Decode Time):** Real-time report of how long the last track took to decompress (indicates CPU bottleneck).
*   **`SCH` (Schedule Window):** Delta between current context time and the scheduled start of the next track.
*   **`SR` (Sample Rate):** Reports the active hardware sample rate (e.g., `48k`, `44.1k`) of the AudioContext.

The Hybrid Engine acts as an orchestrator, managing the transition between the high-performance **Web Audio (Gapless)** engine and the robust **HTML5 (Streaming)** engine.

### 1. Engine Roles
*   **Web Audio (Foreground):** Primary engine for sample-accurate 0ms transitions. Requires full track download/decode before start.
*   **HTML5 (Background/Fallback):** Primary engine for "Instant Start" and background longevity. Streams audio immediately without full decode.

### 2. Orchestration Matrix

| Mode Type | Option | Behavioral Result |
| :--- | :--- | :--- |
| **Handoff** | `immediate` | **Instant Start + True Gapless**: Starts on HTML5; swaps to Web Audio the moment decoding finishes. Best for high-end devices. |
| | `buffered` | **Stability Priority**: Plays HTML5 until buffer exhaustion (~5s left), then hands off to Web Audio. Best for slow connections. |
| | `none` | **Pure Web Audio**: Disables orchestration; user must wait for full decode before playback starts. |
| **Survival** | `html5` | **Background Swap**: Automatically swaps to HTML5 when tab is hidden. Most stable but loses 0ms gaps. |
| | `video` | **Stealth Survival**: Keeps Web Audio alive using a 1x1 looping silent video trick. |
| | `heartbeat` | **Audio Lock**: Keeps process alive via a silent base64 audio heartbeat. |

### 3. Fail-Safe Mechanisms
*   **5s Stall Recovery:** If Web Audio buffers for >5 seconds, the system triggers an "Escape Hatch" swap to HTML5 to prevent playback death.
*   **Forced Suspension Handoff:** If the OS kills the Web Audio context, the engine immediately resumes playback via HTML5 at the last known position.
*   **Boundary Restoration:** When returning to the foreground, the engine defers the swap back to Web Audio until the next track boundary to ensure a hitch-free listener experience.
