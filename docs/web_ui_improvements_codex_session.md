# Web UI Audio & HUD Improvements — Session Log (2026-03-13)

This document plans the technical enhancements to the Web UI audio engines and diagnostic tools during this session. It serves as an explicit guide for reproducing these changes or continuing the hardening roadmap.

## ❌ NOT DONE ENHANCEMENTS

### 1. HUD Diagnostic: Visibility & Timer Drift Monitoring
Planned to implement real-time monitoring of browser throttling to diagnose background playback stalls.

*   NOT DONE: **Logic:** Planned to add a high-resolution drift monitor that calculates the delta between expected update intervals (250ms/4Hz) and actual execution time.
*   NOT DONE: **Key Files:**
    *   NOT DONE: `lib/services/gapless_player/gapless_player_web.dart`: Planned to add `_driftController` and `driftStream`.
    *   NOT DONE: `lib/ui/widgets/playback/dev_audio_hud.dart`:
        *   NOT DONE: Planned to add `V` (Visibility: VIS/HID) and `DFT` (Drift in seconds) telemetry chips.
        *   NOT DONE: Planned to wrap HUD build in a `StreamBuilder` for the `driftStream`.
*   NOT DONE: **Metric Interpretation:**
    *   NOT DONE: `DFT: 0.25s` = Healthy (4Hz updates).
    *   NOT DONE: `DFT: 1.00s+` = Throttled (1Hz background clamp).

### 2. Standard Engine (`just_audio`) Background Hardening
Planned to harden the standard fallback engine against OS-level process suspension on mobile browsers.

*   NOT DONE: **Logic:** Planned to integrate the project's silent "heartbeat" infrastructure (audio/video loops) into the fallback path.
*   NOT DONE: **Key Files:**
    *   NOT DONE: `lib/services/gapless_player/gapless_player_web.dart`:
        *   NOT DONE: Planned to add JS interop for `_gdarHeartbeat`.
        *   NOT DONE: Planned to implement `_startSurvival()` and `_stopSurvival()` helpers.
        *   NOT DONE: Planned to modify `play()`, `pause()`, and `stop()` in the fallback path to trigger these survival heartbeats.
        *   NOT DONE: Planned to implement `_startFallbackDriftTimer()` to provide `DFT` metrics and heartbeat pulses when custom JS engines are disabled.
        *   NOT DONE: Planned to update `setHybridBackgroundMode()` to sync survival strategies (Video, Heartbeat, Audio) to the fallback engine.

### 3. Audio Specifications (Source of Truth)
Planned to create and update project specifications to enforce background stability standards.

*   NOT DONE: **`@.agent/specs/web_ui_audio_hud.md`**: Planned spec defining HUD keys, interactive pop-up menus, and dynamic visual signals (Heartbeat Dot, Handoff Orange Alert).
*   NOT DONE: **`@.agent/specs/web_ui_audio_engines.md`**: Planned to update with strict stability requirements for Engine [3] Standard and Engine [4] Passive.

---

## 📝 PLANNED WORK

### 1. Passive Engine (`passive_audio_engine.js`)
Planned: The standalone Passive engine requires three specific changes to reach parity with the Hybrid/Standard stability.

*   NOT DONE: **Survival Triggers:**
    *   NOT DONE: Inject `window._gdarHeartbeat.startAudioHeartbeat()` into the engine's `play()` method.
    *   NOT DONE: Inject `window._gdarHeartbeat.stopHeartbeat()` into the `pause()` method.
*   NOT DONE: **MediaSession State Sync:**
    *   NOT DONE: Explicitly set `navigator.mediaSession.playbackState = 'playing'` during the `_onTrackEnded` transition phase.
    *   NOT DONE: This prevents the OS from reclaiming the media session during the ~500ms gap where the `<audio>` element has no active `src`.
*   NOT DONE: **Worker Timer Integration:**
    *   NOT DONE: Replace the internal `setInterval` polling with a listener for the `gdar-worker-tick` event.
    *   NOT DONE: This ensures the transition logic stays alive at 4Hz even when the main thread is clamped to 1Hz by the browser.

### 2. HUD Diagnostic Upgrades (PWA Recovery)
Planned: To better diagnose "why" playback stops during PWA background/foreground transitions.

*   NOT DONE: **`MDFT` (Max Observed Drift):**
    *   NOT DONE: Implement persistent `_maxDrift` tracking in `GaplessPlayerWeb`.
    *   NOT DONE: Captures the "peak" drift (e.g., 8.0s) encountered while backgrounded, even after returning to foreground.
*   NOT DONE: **`CTX` (Audio Context State):**
    *   NOT DONE: Expose the raw `AudioContext.state` string (Running, Suspended, Closed).
    *   NOT DONE: Critical for identifying "Silent Audio" caused by OS-level resource suspension.
*   NOT DONE: **`V-DUR` (Visibility Duration):**
    *   NOT DONE: Enhance the `V` chip to track duration: `V:HID(12m)` or `V:VIS(4m)`.
    *   NOT DONE: Helps correlate OS process killing with total background time.
*   NOT DONE: **`RVC` (Recovery Count):**
    *   NOT DONE: Track how many times the Hybrid engine's "Stall Recovery" or "Forced Suspension Handoff" have saved the session.
    *   NOT DONE: Indicates engine resiliency in high-stress network or background scenarios.

### 3. HUD Visual Polish (High-Glance Debugging)
Planned refinements to make the HUD more stable and easier to read during rapid state changes.

*   NOT DONE: **"Traffic Light" Heartbeat (3-Dot Stack):**
    *   NOT DONE: Replace the single dynamic dot with a vertical/horizontal stack of three dedicated indicators:
        *   NOT DONE: **Red:** Flashes ONLY when heartbeat is `Required` but `Not Active`.
        *   NOT DONE: **Orange:** Solid when heartbeat is `Not Needed` by the current OS.
        *   NOT DONE: **Green:** Flashes when heartbeat is `Active` and `Working`.
    *   NOT DONE: **Dimmed State:** All three dots remain low-opacity when playback is paused.
*   NOT DONE: **Fixed-Width Layout (Jitter Prevention):**
    *   NOT DONE: Apply explicit `width` or `constraints` to standard telemetry chips (ENG, AE, DFT, V).
    *   NOT DONE: Prevents the HUD from "dancing" or resizing when values fluctuate (e.g., swapping between `DFT: 0.25s` and `DFT: 10.0s`).

---

## 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability)

Planned: The HTML5 Engine is a direct port of the Relisten gapless architecture, optimized for the aggressive power-saving environments of mobile browsers.

### 1. The Dual-Path Strategy
*   NOT DONE: **Promotion Logic:** The engine can start a track in "Streaming Mode" (HTML5) for zero-latency starts and "promote" it to "Web Audio Mode" mid-playback once the high-fidelity buffer is decoded.
*   NOT DONE: **Fallback Resilience:** If Web Audio fails to decode or the context is suspended, the engine stays in HTML5 mode, ensuring playback never stops.

### 2. Background Persistence
*   NOT DONE: **Worker Heartbeat:** By binding to `gdar-worker-tick`, the engine's prefetch and progress logic bypasses the `requestAnimationFrame` (RAF) suspension that occurs when a mobile tab is hidden.
*   NOT DONE: **Native Buffering:** Leverages the browser's own `<audio>` tag buffering, which is less likely to be reclaimed by the OS than custom JS memory buffers.

### 3. Proposed Mobile HUD Diagnostics
Planned: New signals to monitor PWA performance:
*   NOT DONE: **`H5-EL` (Active Element):** Indicates if the Relisten track is currently using `H5` (Streaming) or `WA` (Promoted Buffer).
*   NOT DONE: **`H5-SW` (Swap Ready):** Confirms if the secondary "next" element is primed for a gapless transition.
*   NOT DONE: **`H5-PRE` (Preload Queue):** Reports which index the engine is currently pre-caching in the background.

Planned: The Web Audio Engine is the flagship choice for high-fidelity, sample-accurate playback on Desktop.

### 1. High-Precision Scheduling
*   NOT DONE: **Sample Accuracy:** Uses `AudioBufferSourceNode.start(time)` to schedule transitions in the future, bypassing the jitter inherent in the JavaScript event loop.
*   NOT DONE: **Watchdog Logic:** A 500ms monitor ensures that if the browser misses a scheduled boundary (due to CPU spike or window throttling), the engine forcefully transitions to prevent a playback "hang."

### 2. The Decode Pipeline
*   NOT DONE: **Dual-Tier Caching:**
    *   NOT DONE: **Compressed (`ArrayBuffer`)**: Kept during download to support partial progress reporting.
    *   NOT DONE: **Decoded (`AudioBuffer`)**: Fully uncompressed PCM data ready for instant scheduling.
*   NOT DONE: **Memory Safety:** Implements `_evictOldBuffers` which strictly limits the uncompressed cache to `Current + 1` tracks, preventing browser crashes during long shows.

### 3. Proposed Desktop HUD Diagnostics
Planned: New signals intended for high-fidelity tuning on desktop environments:
*   NOT DONE: **`MEM` (Memory):** Estimate of JS heap usage to monitor uncompressed buffer overhead.
*   NOT DONE: **`DEC` (Decode Time):** Real-time report of how long the last track took to decompress (indicates CPU bottleneck).
*   NOT DONE: **`SCH` (Schedule Window):** Delta between current context time and the scheduled start of the next track.
*   NOT DONE: **`SR` (Sample Rate):** Reports the active hardware sample rate (e.g., `48k`, `44.1k`) of the AudioContext.

Planned: The Hybrid Engine acts as an orchestrator, managing the transition between the high-performance **Web Audio (Gapless)** engine and the robust **HTML5 (Streaming)** engine.

### 1. Engine Roles
*   NOT DONE: **Web Audio (Foreground):** Primary engine for sample-accurate 0ms transitions. Requires full track download/decode before start.
*   NOT DONE: **HTML5 (Background/Fallback):** Primary engine for "Instant Start" and background longevity. Streams audio immediately without full decode.

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
*   NOT DONE: **5s Stall Recovery:** If Web Audio buffers for >5 seconds, the system triggers an "Escape Hatch" swap to HTML5 to prevent playback death.
*   NOT DONE: **Forced Suspension Handoff:** If the OS kills the Web Audio context, the engine immediately resumes playback via HTML5 at the last known position.
*   NOT DONE: **Boundary Restoration:** When returning to the foreground, the engine defers the swap back to Web Audio until the next track boundary to ensure a hitch-free listener experience.
