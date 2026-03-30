# Hybrid Audio HUD Decision Tree

## Context
The hybrid web engine starts with HTML5 for instant playback, then decides
whether to hand off to Web Audio based on the resolved runtime strategy, the
selected handoff mode, and the current track length/buffer state.

The branch that matters for the HUD is:

- if the engine is still in the HTML5 instant-start phase, `AE` should read
  `H5`
- if Web Audio has actually become active, `AE` should read `WA`
- while a foreground restore is in progress, the HUD should keep showing
  `H5` until the handoff settles

That ordering explains the observed `ENG=hyb`, `HF=off`, `BG=off`, `STB=bal`
session: the engine should stay on HTML5 when handoff is disabled, and it
should continue reporting HTML5 while the restore loop is active.

## Decision Tree

### 1. Startup routing

`apps/gdar_web/web/hybrid_audio_engine.js`

- `syncState()` and `setPlaylist()` both compute:
  - `pure = _isPureWebAudio()`
  - `allowHandoff = _handoffMode !== 'none'`
  - `useHtml5 = !pure || !allowHandoff`
- `useHtml5 === true` selects `_bgEngine` and marks the session as HTML5
  instant-start.
- `useHtml5 === false` selects `_fgEngine` immediately.

### 2. Instant-start handoff path

`apps/gdar_web/web/hybrid_audio_engine.js`

- `_attemptHandoff()` exits early when:
  - `handoffMode === 'none'`
  - the track is short (`duration < 15`)
- Otherwise it keeps HTML5 active, prepares the foreground engine, and then
  chooses one of three handoff subpaths:
  - `immediate`: swap to Web Audio as soon as foreground is ready
  - `boundary`: stay on HTML5 and defer the swap to the next track boundary
  - `buffered`: stay on HTML5 until buffer exhaustion is near, then swap

### 3. Buffered handoff decision

`apps/gdar_web/web/hybrid_audio_engine.js`

- When `duration > 223`, the engine registers worker-tick checks.
- If `buffered - position <= 10`, the HUD receives a countdown state.
- If `buffered - position <= 5`, `_executeForegroundRestore()` is called and
  the active engine swaps to Web Audio.
- If the track fits in the initial HTML5 buffer, the engine stays on HTML5 and
  pre-decodes the next track in Web Audio.

### 4. HUD state ordering

`apps/gdar_web/web/hybrid_audio_engine.js`

- `_forwardState()` and `getState()` derive the `AE` chip from the active
  engine.
- While `_handoffInProgress` is true and `_activeEngine === _fgEngine`, the
  code forces the tech suffix back to `H5`.
- `_handoffInProgress` is cleared only after the foreground state has been
  forwarded, which prevents the HUD from briefly advertising `WA` before the
  restore loop has settled.

## Key References

- `apps/gdar_web/web/hybrid_audio_engine.js:616-638`
- `apps/gdar_web/web/hybrid_audio_engine.js:426-527`
- `apps/gdar_web/web/hybrid_audio_engine.js:192-205`
- `apps/gdar_web/web/hybrid_audio_engine.js:824-840`
- `packages/shakedown_core/lib/providers/audio_provider.dart:478-496`
- `packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud.dart:748-811`

## Diagnostic Log Flow

The current engine logs already line up with the decision tree:

- `syncState: Choosing HTML5 (Background) for Instant Start`
- `setPlaylist: Choosing HTML5 (Background) for Instant Start`
- `Launching INSTANT START (HTML5)`
- `Handoff Mode is none. Staying on HTML5.`
- `Track X is LONG ... Waiting for buffer exhaustion to hand off.`
- `HTML5 Buffer Exhausted ... Swapping to WebAudio.`
- `HANDOFF COMPLETE ...`

These messages are the easiest way to verify the flag ordering during a live
playback session.
