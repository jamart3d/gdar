---
trigger: audio, playback, state, native, background
policy_domain: Audio Architecture
---
# Audio Architecture & Native Engine Directives

### 1. State Isolation
- Never mix UI rendering logic with core audio playback state.
- Keep media control events (play, pause, seek) strictly separated from visual layout code.
- Never use `Future.delayed` to synchronize UI with audio engine state — use `currentIndexStream` or `MediaItem` tag streams.

### 2. Native Engine & Queue
- Use `just_audio` for the primary playback engine on native targets.
- Use `just_audio_background` for OS-level media notifications and background persistence.
- Sync track metadata to the OS media controller on every track change.
- Use **Hive** for show metadata caching and persistent play counts on native/desktop.
- Use a flattened `AudioSource` list for queue management.
- **NEVER use `ConcatenatingAudioSource`** — causes synchronization/shuffle bugs.

### 3. Web Engine Architecture
JS files live in `apps/gdar_web/web/`. Load order in `index.html` matters.

**Required load order:**
1. `audio_utils.js` — defines `window._gdarIsHeartbeatNeeded()`. Must load before all engines.
2. `audio_scheduler.js` — SharedWorker-based background tick; dispatches `gdar-worker-tick` events.
3. Engine files: `gapless_audio_engine.js`, `hybrid_audio_engine.js`, `html5_audio_engine.js`, `hybrid_html5_engine.js`, `passive_audio_engine.js`
4. `hybrid_init.js` — bootstrap dispatcher; selects the active engine based on UA + touch heuristic.

**Engine selection strategy** (`hybrid_init.js`):
- Low-power mobile (UA + DPR-aware core count) → `html5` / `passive`
- Capable desktop/modern phone → `hybrid` or `webAudio`
- `auto` stored mode resolves via `audioPlayer.activeMode` at runtime

**Key constraints:**
- Never share an `AudioContext` across tracks.
- All high-precision audio timing must use the `audio_scheduler.js` worker, not Dart `Timer` or `Future.delayed`.
- Assume 6x CPU slowdown (Chrome throttling). Schedule events look-ahead on `AudioContext.currentTime`, not just-in-time.
- `window._gdarIsHeartbeatNeeded()` caches its result in `window._gdarHeartbeatNeeded` after the first call.

### 4. Resolved vs Stored Mode
`sp.audioEngineMode` may be `AudioEngineMode.auto`. Always get the live mode from:
```dart
audioProvider.audioPlayer.activeMode
```
Gate all UI controls (hybrid handoff, background mode selectors) on the resolved mode, not the stored enum.

### 5. localStorage Keys (Web)
SharedPreferences keys use the `flutter.` prefix. Raw GDAR JS keys: `audio_engine_mode`, `allow_hidden_web_audio`. When clearing settings (e.g., `?flush=true`), only remove `flutter.*` and known raw GDAR keys — never `localStorage.clear()`.
