# Web/PWA Audio Engine Deep Dive

Date: 2026-03-09
Scope: Engine selection and background gapless playback options for PWA on
modern and slightly older phones.

## Current Architecture

- Engine dispatcher: `web/hybrid_init.js`
- Dart bridge: `lib/services/gapless_player/gapless_player_web.dart`
- Engines:
  - `web/gapless_audio_engine.js` (Web Audio, true 0ms gapless)
  - `web/html5_audio_engine.js` (Relisten HTML5 queue, near-gapless)
  - `web/hybrid_audio_engine.js` (orchestrator: HTML5 instant start +
    WebAudio foreground restore)
  - `web/passive_audio_engine.js` (single `<audio>`, strongest survival,
    non-gapless)

## Selection Behavior Today

- Mobile/PWA defaults to `html5` on auto detection.
- Desktop defaults to `webAudio`.
- User override via `audio_engine_mode` in localStorage.
- Hidden session presets:
  - `stability` -> `hybrid + buffered + video`
  - `balanced` -> `hybrid + buffered + heartbeat`
  - `maxGapless` -> `webAudio + immediate + heartbeat`

## Findings

1. `AudioProvider.update()` syncs prefetch and handoff mode, but does not sync
   hybrid background mode to the active player instance.
2. `SettingsProvider.setHybridHandoffMode()` and
   `SettingsProvider.setHybridBackgroundMode()` create `GaplessPlayer()`
   directly, which can register callbacks on a fresh wrapper instance instead
   of routing through the active player.
3. Transition settings are partially wired:
   - UI exposes transition and crossfade controls.
   - Runtime path does not fully propagate transition mode end-to-end.
   - JS API naming mismatch exists for crossfade method.
4. `setWebPrefetchSeconds()` in `SettingsProvider` is now no-op while other
   layers still reference prefetch change propagation.

## Recommended Runtime Profiles

### Modern phones

- Default: `hybrid`
- Handoff mode: `buffered`
- Background mode: `heartbeat` (fallback to `video` for devices that still
  suspend aggressively)
- Why: best startup feel and strong hidden-tab survival with good continuity.

### Slightly older phones

- Default: `html5` (or `passive` for users prioritizing robustness over gaps)
- Why: lower decode pressure, lower memory churn, stronger long-background
  reliability.

### Power users seeking max continuity

- `webAudio` preset is valid for foreground quality, but should clearly warn
  that background suspension risk is higher.

## Suggested Improvements

1. Route all engine config changes through active `AudioProvider.audioPlayer`.
2. In `AudioProvider.update()`, sync:
   - `hybridBackgroundMode`
   - `trackTransitionMode`
   - `crossfadeDurationSeconds`
3. Normalize JS/Dart API names for crossfade and transition methods.
4. Either implement crossfade fully or hide crossfade option until complete.
5. Add first-run adaptive profile:
   - modern web mobile -> hybrid balanced
   - low-power/older web mobile -> html5 stability

## Candidate Rollout Plan

1. Wire settings sync safely via active player instance only.
2. Add telemetry/logging tags around engine switches, hidden handoff outcome,
   and resume failures.
3. Ship with current defaults, then enable adaptive profile behind a flag.
4. Run visibility regression and long-session soak test before broad release.

