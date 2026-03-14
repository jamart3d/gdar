# Web UI Improvements — TODO Prompts

Use these prompts with an agent. Each section is standalone and pasteable.

## Combined Prompt (All Sections)

### TASK
Implement the checklist items below, preserving intent and details.

### CONTEXT
- ❌ NOT DONE ENHANCEMENTS > 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — **Logic:** Added a high-resolution drift monitor that calculates the delta between expected update intervals (250ms/4Hz) and actual execution time.
- ❌ NOT DONE ENHANCEMENTS > 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — **Key Files:**
- ❌ NOT DONE ENHANCEMENTS > 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — `lib/ui/widgets/playback/dev_audio_hud.dart`:
- ❌ NOT DONE ENHANCEMENTS > 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — **Metric Interpretation:**
- ❌ NOT DONE ENHANCEMENTS > 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — `DFT: 0.25s` = Healthy (4Hz updates).
- ❌ NOT DONE ENHANCEMENTS > 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — `DFT: 1.00s+` = Throttled (1Hz background clamp).
- ❌ NOT DONE ENHANCEMENTS > 2. Standard Engine (`just_audio`) Background Hardening — **Logic:** Integrated the project's silent "heartbeat" infrastructure (audio/video loops) into the fallback path.
- ❌ NOT DONE ENHANCEMENTS > 2. Standard Engine (`just_audio`) Background Hardening — **Key Files:**
- ❌ NOT DONE ENHANCEMENTS > 2. Standard Engine (`just_audio`) Background Hardening — `lib/services/gapless_player/gapless_player_web.dart`:
- 📝 BACKLOG / PENDING HARDENING > 1. Passive Engine (`passive_audio_engine.js`) — **Survival Triggers:**
- 📝 BACKLOG / PENDING HARDENING > 1. Passive Engine (`passive_audio_engine.js`) — **MediaSession State Sync:**
- 📝 BACKLOG / PENDING HARDENING > 1. Passive Engine (`passive_audio_engine.js`) — This prevents the OS from reclaiming the media session during the ~500ms gap where the `<audio>` element has no active `src`.
- 📝 BACKLOG / PENDING HARDENING > 1. Passive Engine (`passive_audio_engine.js`) — **Worker Timer Integration:**
- 📝 BACKLOG / PENDING HARDENING > 1. Passive Engine (`passive_audio_engine.js`) — This ensures the transition logic stays alive at 4Hz even when the main thread is clamped to 1Hz by the browser.
- 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — **`MDFT` (Max Observed Drift):**
- 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — Captures the "peak" drift (e.g., 8.0s) encountered while backgrounded, even after returning to foreground.
- 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — **`CTX` (Audio Context State):**
- 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — Critical for identifying "Silent Audio" caused by OS-level resource suspension.
- 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — **`V-DUR` (Visibility Duration):**
- 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — Helps correlate OS process killing with total background time.
- 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — **`RVC` (Recovery Count):**
- 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — Indicates engine resiliency in high-stress network or background scenarios.
- 📝 BACKLOG / PENDING HARDENING > 3. HUD Visual Polish (High-Glance Debugging) — **"Traffic Light" Heartbeat (3-Dot Stack):**
- 📝 BACKLOG / PENDING HARDENING > 3. HUD Visual Polish (High-Glance Debugging) — **Red:** Flashes ONLY when heartbeat is `Required` but `Not Active`.
- 📝 BACKLOG / PENDING HARDENING > 3. HUD Visual Polish (High-Glance Debugging) — **Orange:** Solid when heartbeat is `Not Needed` by the current OS.
- 📝 BACKLOG / PENDING HARDENING > 3. HUD Visual Polish (High-Glance Debugging) — **Green:** Flashes when heartbeat is `Active` and `Working`.
- 📝 BACKLOG / PENDING HARDENING > 3. HUD Visual Polish (High-Glance Debugging) — **Dimmed State:** All three dots remain low-opacity when playback is paused.
- 📝 BACKLOG / PENDING HARDENING > 3. HUD Visual Polish (High-Glance Debugging) — **Fixed-Width Layout (Jitter Prevention):**
- 📝 BACKLOG / PENDING HARDENING > 3. HUD Visual Polish (High-Glance Debugging) — Prevents the HUD from "dancing" or resizing when values fluctuate (e.g., swapping between `DFT: 0.25s` and `DFT: 10.0s`).
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 1. The Dual-Path Strategy — **Promotion Logic:** The engine can start a track in "Streaming Mode" (HTML5) for zero-latency starts and "promote" it to "Web Audio Mode" mid-playback once the high-fidelity buffer is decoded.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 1. The Dual-Path Strategy — **Fallback Resilience:** If Web Audio fails to decode or the context is suspended, the engine stays in HTML5 mode, ensuring playback never stops.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 2. Background Persistence — **Worker Heartbeat:** By binding to `gdar-worker-tick`, the engine's prefetch and progress logic bypasses the `requestAnimationFrame` (RAF) suspension that occurs when a mobile tab is hidden.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 2. Background Persistence — **Native Buffering:** Leverages the browser's own `<audio>` tag buffering, which is less likely to be reclaimed by the OS than custom JS memory buffers.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 1. High-Precision Scheduling — **Sample Accuracy:** Uses `AudioBufferSourceNode.start(time)` to schedule transitions in the future, bypassing the jitter inherent in the JavaScript event loop.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 1. High-Precision Scheduling — **Watchdog Logic:** A 500ms monitor ensures that if the browser misses a scheduled boundary (due to CPU spike or window throttling), the engine forcefully transitions to prevent a playback "hang."
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 2. The Decode Pipeline — **Dual-Tier Caching:**
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 2. The Decode Pipeline — **Compressed (`ArrayBuffer`)**: Kept during download to support partial progress reporting.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 2. The Decode Pipeline — **Decoded (`AudioBuffer`)**: Fully uncompressed PCM data ready for instant scheduling.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 2. The Decode Pipeline — **Memory Safety:** Implements `_evictOldBuffers` which strictly limits the uncompressed cache to `Current + 1` tracks, preventing browser crashes during long shows.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 1. Engine Roles — **Web Audio (Foreground):** Primary engine for sample-accurate 0ms transitions. Requires full track download/decode before start.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 1. Engine Roles — **HTML5 (Background/Fallback):** Primary engine for "Instant Start" and background longevity. Streams audio immediately without full decode.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 3. Fail-Safe Mechanisms — **5s Stall Recovery:** If Web Audio buffers for >5 seconds, the system triggers an "Escape Hatch" swap to HTML5 to prevent playback death.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 3. Fail-Safe Mechanisms — **Forced Suspension Handoff:** If the OS kills the Web Audio context, the engine immediately resumes playback via HTML5 at the last known position.
- 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 3. Fail-Safe Mechanisms — **Boundary Restoration:** When returning to the foreground, the engine defers the swap back to Web Audio until the next track boundary to ensure a hitch-free listener experience.

### CHECKLIST
- [ ] 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — Add widget tests for HUD chips (V, DFT) and drift stream rendering.
- [ ] 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — Add unit tests for drift calculation at 4Hz baseline and throttled scenarios.
- [ ] 2. Standard Engine (`just_audio`) Background Hardening — Add unit tests for survival heartbeat start/stop behavior in fallback engine.
- [ ] 1. Passive Engine (`passive_audio_engine.js`) — Add regression test or manual test plan for passive engine background survival.
- [ ] 2. HUD Diagnostic Upgrades (PWA Recovery) — Add widget tests for MDFT/CTX/V-DUR/RVC chip rendering and formatting.
- [ ] 3. HUD Visual Polish (High-Glance Debugging) — Add visual regression or golden test for HUD layout stability.
- [ ] 3. Proposed Mobile HUD Diagnostics — Add widget tests for H5-* diagnostic chips.
- [ ] 3. Proposed Desktop HUD Diagnostics — Add widget tests for MEM/DEC/SCH/SR diagnostics.
- [ ] ❌ NOT DONE ENHANCEMENTS > 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — Update `lib/services/gapless_player/gapless_player_web.dart` to add `_driftController` and `driftStream`.
- [ ] ❌ NOT DONE ENHANCEMENTS > 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — Add `V` (Visibility: VIS/HID) and `DFT` (Drift in seconds) telemetry chips.
- [ ] ❌ NOT DONE ENHANCEMENTS > 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — Wrap HUD build in a `StreamBuilder` for the `driftStream`.
- [ ] ❌ NOT DONE ENHANCEMENTS > 2. Standard Engine (`just_audio`) Background Hardening — Add JS interop for `_gdarHeartbeat`.
- [ ] ❌ NOT DONE ENHANCEMENTS > 2. Standard Engine (`just_audio`) Background Hardening — Implement `_startSurvival()` and `_stopSurvival()` helpers.
- [ ] ❌ NOT DONE ENHANCEMENTS > 2. Standard Engine (`just_audio`) Background Hardening — Modify `play()`, `pause()`, and `stop()` in the fallback path to trigger these survival heartbeats.
- [ ] ❌ NOT DONE ENHANCEMENTS > 2. Standard Engine (`just_audio`) Background Hardening — Implement `_startFallbackDriftTimer()` to provide `DFT` metrics and heartbeat pulses when custom JS engines are disabled.
- [ ] ❌ NOT DONE ENHANCEMENTS > 2. Standard Engine (`just_audio`) Background Hardening — Update `setHybridBackgroundMode()` to sync survival strategies (Video, Heartbeat, Audio) to the fallback engine.
- [ ] ❌ NOT DONE ENHANCEMENTS > 3. Audio Specifications (Source of Truth) — Update spec file `@.agent/specs/web_ui_audio_hud.md` with new spec defining HUD keys, interactive pop-up menus, and dynamic visual signals (Heartbeat Dot, Handoff Orange Alert).
- [ ] ❌ NOT DONE ENHANCEMENTS > 3. Audio Specifications (Source of Truth) — Update spec file `@.agent/specs/web_ui_audio_engines.md` with strict stability requirements for Engine [3] Standard and Engine [4] Passive.
- [ ] 📝 BACKLOG / PENDING HARDENING > 1. Passive Engine (`passive_audio_engine.js`) — Inject `window._gdarHeartbeat.startAudioHeartbeat()` into the engine's `play()` method.
- [ ] 📝 BACKLOG / PENDING HARDENING > 1. Passive Engine (`passive_audio_engine.js`) — Inject `window._gdarHeartbeat.stopHeartbeat()` into the `pause()` method.
- [ ] 📝 BACKLOG / PENDING HARDENING > 1. Passive Engine (`passive_audio_engine.js`) — Explicitly set `navigator.mediaSession.playbackState = 'playing'` during the `_onTrackEnded` transition phase.
- [ ] 📝 BACKLOG / PENDING HARDENING > 1. Passive Engine (`passive_audio_engine.js`) — Replace the internal `setInterval` polling with a listener for the `gdar-worker-tick` event.
- [ ] 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — Implement persistent `_maxDrift` tracking in `GaplessPlayerWeb`.
- [ ] 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — Expose the raw `AudioContext.state` string (Running, Suspended, Closed).
- [ ] 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — Enhance the `V` chip to track duration: `V:HID(12m)` or `V:VIS(4m)`.
- [ ] 📝 BACKLOG / PENDING HARDENING > 2. HUD Diagnostic Upgrades (PWA Recovery) — Track how many times the Hybrid engine's "Stall Recovery" or "Forced Suspension Handoff" have saved the session.
- [ ] 📝 BACKLOG / PENDING HARDENING > 3. HUD Visual Polish (High-Glance Debugging) — Replace the single dynamic dot with a vertical/horizontal stack of three dedicated indicators:
- [ ] 📝 BACKLOG / PENDING HARDENING > 3. HUD Visual Polish (High-Glance Debugging) — Apply explicit `width` or `constraints` to standard telemetry chips (ENG, AE, DFT, V).
- [ ] 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 3. Proposed Mobile HUD Diagnostics — Add HUD diagnostic `H5-EL` (Active Element) to indicate if the Relisten track is currently using `H5` (Streaming) or `WA` (Promoted Buffer).
- [ ] 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 3. Proposed Mobile HUD Diagnostics — Add HUD diagnostic `H5-SW` (Swap Ready) to confirm if the secondary "next" element is primed for a gapless transition.
- [ ] 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 3. Proposed Mobile HUD Diagnostics — Add HUD diagnostic `H5-PRE` (Preload Queue) to report which index the engine is currently pre-caching in the background.
- [ ] 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 3. Proposed Desktop HUD Diagnostics — Add HUD diagnostic `MEM` (Memory) to estimate JS heap usage to monitor uncompressed buffer overhead.
- [ ] 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 3. Proposed Desktop HUD Diagnostics — Add HUD diagnostic `DEC` (Decode Time) to report how long the last track took to decompress (indicates CPU bottleneck).
- [ ] 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 3. Proposed Desktop HUD Diagnostics — Add HUD diagnostic `SCH` (Schedule Window) to report the delta between current context time and the scheduled start of the next track.
- [ ] 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability) > 3. Proposed Desktop HUD Diagnostics — Add HUD diagnostic `SR` (Sample Rate) to report the active hardware sample rate (e.g., `48k`, `44.1k`) of the AudioContext.

## Section Prompts (Paste One at a Time)

### ❌ NOT DONE ENHANCEMENTS

#### 1. HUD Diagnostic: Visibility & Timer Drift Monitoring

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — **Logic:** Added a high-resolution drift monitor that calculates the delta between expected update intervals (250ms/4Hz) and actual execution time.
- 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — **Key Files:**
- 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — `lib/ui/widgets/playback/dev_audio_hud.dart`:
- 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — **Metric Interpretation:**
- 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — `DFT: 0.25s` = Healthy (4Hz updates).
- 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — `DFT: 1.00s+` = Throttled (1Hz background clamp).

**CHECKLIST**
- [ ] Add widget tests for HUD chips (V, DFT) and drift stream rendering.
- [ ] Add unit tests for drift calculation at 4Hz baseline and throttled scenarios.
- [ ] 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — Update `lib/services/gapless_player/gapless_player_web.dart` to add `_driftController` and `driftStream`.
- [ ] 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — Add `V` (Visibility: VIS/HID) and `DFT` (Drift in seconds) telemetry chips.
- [ ] 1. HUD Diagnostic: Visibility & Timer Drift Monitoring — Wrap HUD build in a `StreamBuilder` for the `driftStream`.

**ACCEPTANCE**
- HUD shows V and DFT chips with stable formatting.
- DFT reflects ~0.25s when visible and >=1.0s when throttled.

#### 2. Standard Engine (`just_audio`) Background Hardening

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 2. Standard Engine (`just_audio`) Background Hardening — **Logic:** Integrated the project's silent "heartbeat" infrastructure (audio/video loops) into the fallback path.
- 2. Standard Engine (`just_audio`) Background Hardening — **Key Files:**
- 2. Standard Engine (`just_audio`) Background Hardening — `lib/services/gapless_player/gapless_player_web.dart`:

**CHECKLIST**
- [ ] Add unit tests for survival heartbeat start/stop behavior in fallback engine.
- [ ] 2. Standard Engine (`just_audio`) Background Hardening — Add JS interop for `_gdarHeartbeat`.
- [ ] 2. Standard Engine (`just_audio`) Background Hardening — Implement `_startSurvival()` and `_stopSurvival()` helpers.
- [ ] 2. Standard Engine (`just_audio`) Background Hardening — Modify `play()`, `pause()`, and `stop()` in the fallback path to trigger these survival heartbeats.
- [ ] 2. Standard Engine (`just_audio`) Background Hardening — Implement `_startFallbackDriftTimer()` to provide `DFT` metrics and heartbeat pulses when custom JS engines are disabled.
- [ ] 2. Standard Engine (`just_audio`) Background Hardening — Update `setHybridBackgroundMode()` to sync survival strategies (Video, Heartbeat, Audio) to the fallback engine.

**ACCEPTANCE**
- Fallback engine starts/stops heartbeat on play/pause/stop as expected.

#### 3. Audio Specifications (Source of Truth)

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- None

**CHECKLIST**
- [ ] 3. Audio Specifications (Source of Truth) — Update spec file `@.agent/specs/web_ui_audio_hud.md` with new spec defining HUD keys, interactive pop-up menus, and dynamic visual signals (Heartbeat Dot, Handoff Orange Alert).
- [ ] 3. Audio Specifications (Source of Truth) — Update spec file `@.agent/specs/web_ui_audio_engines.md` with strict stability requirements for Engine [3] Standard and Engine [4] Passive.

### 📝 BACKLOG / PENDING HARDENING

#### 1. Passive Engine (`passive_audio_engine.js`)

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 1. Passive Engine (`passive_audio_engine.js`) — **Survival Triggers:**
- 1. Passive Engine (`passive_audio_engine.js`) — **MediaSession State Sync:**
- 1. Passive Engine (`passive_audio_engine.js`) — This prevents the OS from reclaiming the media session during the ~500ms gap where the `<audio>` element has no active `src`.
- 1. Passive Engine (`passive_audio_engine.js`) — **Worker Timer Integration:**
- 1. Passive Engine (`passive_audio_engine.js`) — This ensures the transition logic stays alive at 4Hz even when the main thread is clamped to 1Hz by the browser.

**CHECKLIST**
- [ ] Add regression test or manual test plan for passive engine background survival.
- [ ] 1. Passive Engine (`passive_audio_engine.js`) — Inject `window._gdarHeartbeat.startAudioHeartbeat()` into the engine's `play()` method.
- [ ] 1. Passive Engine (`passive_audio_engine.js`) — Inject `window._gdarHeartbeat.stopHeartbeat()` into the `pause()` method.
- [ ] 1. Passive Engine (`passive_audio_engine.js`) — Explicitly set `navigator.mediaSession.playbackState = 'playing'` during the `_onTrackEnded` transition phase.
- [ ] 1. Passive Engine (`passive_audio_engine.js`) — Replace the internal `setInterval` polling with a listener for the `gdar-worker-tick` event.

**ACCEPTANCE**
- Passive engine maintains MediaSession state across track boundaries.
- Worker tick drives transitions at 4Hz when tab is hidden.

#### 2. HUD Diagnostic Upgrades (PWA Recovery)

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 2. HUD Diagnostic Upgrades (PWA Recovery) — **`MDFT` (Max Observed Drift):**
- 2. HUD Diagnostic Upgrades (PWA Recovery) — Captures the "peak" drift (e.g., 8.0s) encountered while backgrounded, even after returning to foreground.
- 2. HUD Diagnostic Upgrades (PWA Recovery) — **`CTX` (Audio Context State):**
- 2. HUD Diagnostic Upgrades (PWA Recovery) — Critical for identifying "Silent Audio" caused by OS-level resource suspension.
- 2. HUD Diagnostic Upgrades (PWA Recovery) — **`V-DUR` (Visibility Duration):**
- 2. HUD Diagnostic Upgrades (PWA Recovery) — Helps correlate OS process killing with total background time.
- 2. HUD Diagnostic Upgrades (PWA Recovery) — **`RVC` (Recovery Count):**
- 2. HUD Diagnostic Upgrades (PWA Recovery) — Indicates engine resiliency in high-stress network or background scenarios.

**CHECKLIST**
- [ ] Add widget tests for MDFT/CTX/V-DUR/RVC chip rendering and formatting.
- [ ] 2. HUD Diagnostic Upgrades (PWA Recovery) — Implement persistent `_maxDrift` tracking in `GaplessPlayerWeb`.
- [ ] 2. HUD Diagnostic Upgrades (PWA Recovery) — Expose the raw `AudioContext.state` string (Running, Suspended, Closed).
- [ ] 2. HUD Diagnostic Upgrades (PWA Recovery) — Enhance the `V` chip to track duration: `V:HID(12m)` or `V:VIS(4m)`.
- [ ] 2. HUD Diagnostic Upgrades (PWA Recovery) — Track how many times the Hybrid engine's "Stall Recovery" or "Forced Suspension Handoff" have saved the session.

**ACCEPTANCE**
- MDFT preserves peak drift after returning to foreground.
- CTX displays raw AudioContext.state value.
- V chip shows duration formatting like V:HID(12m).
- RVC increments on recovery events.

#### 3. HUD Visual Polish (High-Glance Debugging)

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 3. HUD Visual Polish (High-Glance Debugging) — **"Traffic Light" Heartbeat (3-Dot Stack):**
- 3. HUD Visual Polish (High-Glance Debugging) — **Red:** Flashes ONLY when heartbeat is `Required` but `Not Active`.
- 3. HUD Visual Polish (High-Glance Debugging) — **Orange:** Solid when heartbeat is `Not Needed` by the current OS.
- 3. HUD Visual Polish (High-Glance Debugging) — **Green:** Flashes when heartbeat is `Active` and `Working`.
- 3. HUD Visual Polish (High-Glance Debugging) — **Dimmed State:** All three dots remain low-opacity when playback is paused.
- 3. HUD Visual Polish (High-Glance Debugging) — **Fixed-Width Layout (Jitter Prevention):**
- 3. HUD Visual Polish (High-Glance Debugging) — Prevents the HUD from "dancing" or resizing when values fluctuate (e.g., swapping between `DFT: 0.25s` and `DFT: 10.0s`).

**CHECKLIST**
- [ ] Add visual regression or golden test for HUD layout stability.
- [ ] 3. HUD Visual Polish (High-Glance Debugging) — Replace the single dynamic dot with a vertical/horizontal stack of three dedicated indicators:
- [ ] 3. HUD Visual Polish (High-Glance Debugging) — Apply explicit `width` or `constraints` to standard telemetry chips (ENG, AE, DFT, V).

**ACCEPTANCE**
- Traffic-light heartbeat indicators match required states.
- Telemetry chips remain fixed width during value changes.

### 📱 HTML5 ENGINE DEEP DIVE (Mobile & PWA Stability)

#### 1. The Dual-Path Strategy

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 1. The Dual-Path Strategy — **Promotion Logic:** The engine can start a track in "Streaming Mode" (HTML5) for zero-latency starts and "promote" it to "Web Audio Mode" mid-playback once the high-fidelity buffer is decoded.
- 1. The Dual-Path Strategy — **Fallback Resilience:** If Web Audio fails to decode or the context is suspended, the engine stays in HTML5 mode, ensuring playback never stops.

**CHECKLIST**
- [ ] None

#### 2. Background Persistence

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 2. Background Persistence — **Worker Heartbeat:** By binding to `gdar-worker-tick`, the engine's prefetch and progress logic bypasses the `requestAnimationFrame` (RAF) suspension that occurs when a mobile tab is hidden.
- 2. Background Persistence — **Native Buffering:** Leverages the browser's own `<audio>` tag buffering, which is less likely to be reclaimed by the OS than custom JS memory buffers.

**CHECKLIST**
- [ ] None

#### 3. Proposed Mobile HUD Diagnostics

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- None

**CHECKLIST**
- [ ] Add widget tests for H5-* diagnostic chips.
- [ ] 3. Proposed Mobile HUD Diagnostics — Add HUD diagnostic `H5-EL` (Active Element) to indicate if the Relisten track is currently using `H5` (Streaming) or `WA` (Promoted Buffer).
- [ ] 3. Proposed Mobile HUD Diagnostics — Add HUD diagnostic `H5-SW` (Swap Ready) to confirm if the secondary "next" element is primed for a gapless transition.
- [ ] 3. Proposed Mobile HUD Diagnostics — Add HUD diagnostic `H5-PRE` (Preload Queue) to report which index the engine is currently pre-caching in the background.

**ACCEPTANCE**
- H5-EL, H5-SW, H5-PRE display correct engine state labels.

#### 1. High-Precision Scheduling

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 1. High-Precision Scheduling — **Sample Accuracy:** Uses `AudioBufferSourceNode.start(time)` to schedule transitions in the future, bypassing the jitter inherent in the JavaScript event loop.
- 1. High-Precision Scheduling — **Watchdog Logic:** A 500ms monitor ensures that if the browser misses a scheduled boundary (due to CPU spike or window throttling), the engine forcefully transitions to prevent a playback "hang."

**CHECKLIST**
- [ ] None

#### 2. The Decode Pipeline

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 2. The Decode Pipeline — **Dual-Tier Caching:**
- 2. The Decode Pipeline — **Compressed (`ArrayBuffer`)**: Kept during download to support partial progress reporting.
- 2. The Decode Pipeline — **Decoded (`AudioBuffer`)**: Fully uncompressed PCM data ready for instant scheduling.
- 2. The Decode Pipeline — **Memory Safety:** Implements `_evictOldBuffers` which strictly limits the uncompressed cache to `Current + 1` tracks, preventing browser crashes during long shows.

**CHECKLIST**
- [ ] None

#### 3. Proposed Desktop HUD Diagnostics

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- None

**CHECKLIST**
- [ ] Add widget tests for MEM/DEC/SCH/SR diagnostics.
- [ ] 3. Proposed Desktop HUD Diagnostics — Add HUD diagnostic `MEM` (Memory) to estimate JS heap usage to monitor uncompressed buffer overhead.
- [ ] 3. Proposed Desktop HUD Diagnostics — Add HUD diagnostic `DEC` (Decode Time) to report how long the last track took to decompress (indicates CPU bottleneck).
- [ ] 3. Proposed Desktop HUD Diagnostics — Add HUD diagnostic `SCH` (Schedule Window) to report the delta between current context time and the scheduled start of the next track.
- [ ] 3. Proposed Desktop HUD Diagnostics — Add HUD diagnostic `SR` (Sample Rate) to report the active hardware sample rate (e.g., `48k`, `44.1k`) of the AudioContext.

**ACCEPTANCE**
- MEM/DEC/SCH/SR update with expected units and formatting.

#### 1. Engine Roles

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 1. Engine Roles — **Web Audio (Foreground):** Primary engine for sample-accurate 0ms transitions. Requires full track download/decode before start.
- 1. Engine Roles — **HTML5 (Background/Fallback):** Primary engine for "Instant Start" and background longevity. Streams audio immediately without full decode.

**CHECKLIST**
- [ ] None

#### 3. Fail-Safe Mechanisms

**TASK**
Implement the checklist items below, preserving intent and details.

**CONTEXT**
- 3. Fail-Safe Mechanisms — **5s Stall Recovery:** If Web Audio buffers for >5 seconds, the system triggers an "Escape Hatch" swap to HTML5 to prevent playback death.
- 3. Fail-Safe Mechanisms — **Forced Suspension Handoff:** If the OS kills the Web Audio context, the engine immediately resumes playback via HTML5 at the last known position.
- 3. Fail-Safe Mechanisms — **Boundary Restoration:** When returning to the foreground, the engine defers the swap back to Web Audio until the next track boundary to ensure a hitch-free listener experience.

**CHECKLIST**
- [ ] None

