# Web Gapless Playback — Open Items Plan
Date: 2026-02-24 1:45 PM

## Open Bugs

### 1. Two tracks playing simultaneously during gapless transitions
**Symptom**: Overlapping audio — old `AudioBufferSourceNode` not stopped when new one starts.

**Likely Root Causes**:
- `_onTrackEnded()` promotes `_scheduledSource` to `_currentSource` but never explicitly stops the old `_currentSource` (it relies on `onended` having already fired, but if the watchdog triggers instead, the old source may still be audible).
- `_checkWatchdog()` nullifies `_currentSource` but only calls `.onended = null` — it does not call `.stop()` on the missed source, leaving it potentially still connected to the `GainNode`.

**Fix** (in `gapless_audio_engine.js`):
- In `_checkWatchdog()`: call `missedSrc.stop()` after nullifying `onended`.
- In `_onTrackEnded()` scheduled-source branch: explicitly `_stopCurrentSource()` before promoting `_scheduledSource`.
- In `_onTrackEnded()` fallback branch: ensure `_stopCurrentSource()` is called before `_decode().then(...)`.

**Files**: `web/gapless_audio_engine.js`

---

### 2. Mini player track title not updating on track change
**Symptom**: Title stays on previous track even after JS engine advances.

**Likely Root Cause**:
- The mini player's title `StreamBuilder` listens to `sequenceStateStream`, but `_emitSequenceState()` is only called from the `onTrackChange` callback in `gapless_player_web.dart`.
- The `onTrackChange` JS callback receives `{from, to}` but the Dart side casts the raw object as `_GdarState` (which expects `playing`, `index`, `position`, `duration` fields). The `index` field maps to `to` only by coincidence — this casting is fragile and may silently fail.

**Fix** (in `gapless_player_web.dart`):
- Create a proper `_JsTrackChangeEvent` extension type with `from` and `to` fields.
- In the `onTrackChange` callback, cast to `_JsTrackChangeEvent`, update `_currentIndex`, and call `_emitSequenceState()` + `_emitPlayerState()`.
- Also call `_emitSequenceState()` from `_onJsStateChange()` when the index changes.

**Files**: `lib/services/gapless_player/gapless_player_web.dart`

---

### 3. Mini player play/pause button state not syncing
**Symptom**: Button shows wrong state (play vs pause) relative to actual playback.

**Likely Root Cause**:
- Same stream propagation issue as Bug #2. The `PlayerState` stream is emitted correctly from `_onJsStateChange`, but if the `playing` field in `_GdarState` is stale or the callback frequency is low, the UI can lag behind.
- The `pause()` method suspends the `AudioContext` and then calls `_stopCurrentSource()` inside the `.then()`. If the UI reads the state between `_playing = false` and the suspend completing, there could be a visual desync.

**Fix**:
- Ensure `_emitState()` is called in the JS engine **immediately** after `_playing` changes (before any async work).
- In `gapless_player_web.dart`, make `_onJsStateChange` always emit `_playingController` when `_playing` differs from `wasPlaying` (this is already done but verify it fires).
- Add a `processingState` field to the JS `_emitState()` payload and consume it on the Dart side to distinguish `buffering` from `ready`.

**Files**: `web/gapless_audio_engine.js`, `lib/services/gapless_player/gapless_player_web.dart`

---

### 4. Loading spinner while track is buffering/decoding
**Symptom**: No visual feedback during fetch+decode (can be 2–5s on slow connections).

**Root Cause**: The JS engine never emits a `buffering`/`loading` processing state. It only emits `idle` or `ready`.

**Fix**:
- Add a `processingState` string field to `_emitState()` in the JS engine (`'idle'`, `'loading'`, `'buffering'`, `'ready'`, `'completed'`).
- Set state to `'loading'` when starting `_decode()` or `_fetchCompressed()`, and back to `'ready'` when the track starts playing.
- In `gapless_player_web.dart`, map the string to `ProcessingState` enum values.
- The mini player already has spinner logic for `ProcessingState.loading` and `ProcessingState.buffering` — no UI changes needed.

**Files**: `web/gapless_audio_engine.js`, `lib/services/gapless_player/gapless_player_web.dart`

---

## Open Manual Verification Items
- [ ] `flutter run -d chrome` → play segue show → confirm 0ms transitions
- [ ] Chrome DevTools `window._gdarAudio.getState()` → confirm state is accurate
- [ ] Toggle Gapless Engine OFF → verify fallback to `<audio>` element
- [ ] Background tab 10 min → no stall (re-verify after fixes)

## Suggested Priority Order
1. **Bug #1** (overlapping audio) — most impactful, pure JS fix
2. **Bug #2** (track title) — fixes the JS→Dart bridge properly
3. **Bug #3** (play/pause) — closely related to #2, likely fixed together
4. **Bug #4** (spinner) — enhancement, builds on the `processingState` field added in #3
