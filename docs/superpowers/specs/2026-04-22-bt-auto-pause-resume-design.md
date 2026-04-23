# Web/PWA Bluetooth Route Monitor — Auto-Pause / Timed Auto-Resume

**Status:** Spec — Finalized 2026-04-22.
**Target:** Web UI (PWA) on Android Chrome, iOS Safari, and Desktop.

## Problem
When a Bluetooth or wired audio device disconnects mid-playback on the PWA, audio often continues through the device's internal speaker. This is especially prevalent in GDAR's Web Audio-based engines (Gapless/Hybrid) which may lose the OS-level "becoming noisy" pause binding. Additionally, the OS never auto-resumes on reconnect, which is a desired user convenience.

## Design Decisions

- **Detection Strategy:** Use the `navigator.mediaDevices.ondevicechange` event to monitor the number of `audiooutput` devices via `enumerateDevices()`. Filter strictly on `kind === 'audiooutput'` — do not use total device count, as `devicechange` fires for all device types (microphone, camera, etc.).
- **iOS Safari:** `ondevicechange` support is unreliable on iOS Safari. The monitor degrades gracefully — feature is silently inactive; no error is thrown. This is not considered a defect.
- **Pause-on-Disconnect:** 
    - If the count of `audiooutput` devices **decreases** while the engine is `playing`, debounce **400ms** then call `engine.pause()`.
    - Stamp the time of pause as `_autoPausedAt`.
    - The 400ms debounce prevents false pauses during Bluetooth A2DP codec renegotiation (e.g. AAC → aptX handoff), which briefly drops and re-adds the output device.
- **Resume-on-Reconnect:** 
    - If the count **increases** within **3 minutes** of an auto-pause, call `engine.play()`.
    - **Override:** If the user manually taps Play or Pause (or presses the headset Play button) in the interim, the auto-resume window is discarded and the monitor transitions to `idle`.
- **Settings Gate:** 
    - Key: `pause_on_output_disconnect` (Default: `true` for Web/PWA, `false` for TV/Native).
    - Location: **Settings > Playback Section**.
- **MediaSession Integration:** 
    - Standard Bluetooth controls (Play/Pause/Skip/Seek) are handled by the existing `audio_mediasession.js`.
    - The monitor will listen to engine state changes; if the user pauses via their headset button, the monitor will see the state transition and clear its auto-resume timer.

## Technical Architecture

### 1. The Monitor (`audio_route_monitor.js`)
A standalone JS sidecar loaded in `index.html`. 
- **API:** `window._gdarRouteMonitor.attach(engine, strategy)` called by `hybrid_init.js`.
- **State Machine:**
    - `idle`: No active playback (initial state, manual pause, or auto-resume window expired/discarded). On entry, clear `_autoPausedAt`.
    - `armed`: Playback active; snapshotting `audiooutput` device count.
    - `auto-paused`: Disconnect detected; waiting for reconnect within 3 minutes or for window expiry.
    - **Transitions:** `armed` → `idle` on manual pause (do not leave a stale `_autoPausedAt`); `armed` → `auto-paused` on disconnect debounce; `auto-paused` → `idle` on manual Play/Pause or headset Play; `auto-paused` → `armed` on reconnect + auto-resume.

### 2. Dart Integration
- **SettingsProvider:** Add `pauseOnOutputDisconnect` bool.
- **UI:** Add a toggle in `PlaybackSection` in the general Web section — **not** inside `_buildWebGaplessSection`. The monitor is engine-agnostic and must be visible regardless of which web engine is active.

## Implementation Plan

### Phase 1: Diagnostic Probe
Modify `hybrid_init.js` temporarily to log:
- `devicechange` event firing.
- `enumerateDevices()` count and labels (for verification only).
- Verify behavior in the background (tab hidden).

### Phase 2: Core Logic
1.  Create `apps/gdar_web/web/audio_route_monitor.js`.
2.  Insert `<script>` tag in `apps/gdar_web/web/index.html`. **Load order:** after `audio_utils.js`, before `hybrid_init.js` (monitor must be defined before init attaches it).
3.  Inject monitor attachment in `apps/gdar_web/web/hybrid_init.js`.

### Phase 3: Dart UI
1.  Add field to `SettingsProvider`.
2.  Add `SwitchListTile` to `PlaybackSection` in `playback_section_web.dart`.

## Verification Criteria
1.  **Disconnect:** Play audio → Unplug/Disconnect → Audio pauses within 1s.
2.  **Reconnect:** Disconnect → Reconnect within 120s → Audio resumes automatically. (Window is 3 minutes; 120s is the test threshold.)
3.  **Expiry:** Disconnect → Wait 4 minutes → Reconnect → Audio stays paused.
4.  **Manual Override:** Disconnect → Tap Pause on phone → Reconnect → Audio stays paused.
5.  **Settings Toggle:** Disable in settings → Disconnect → Audio continues through speaker (verify opt-out works).
