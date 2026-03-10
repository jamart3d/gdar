# Hybrid Web Audio Engine – Gaps vs Spec (2026-03-09)

Findings while comparing `web/hybrid_audio_engine.js` to the spec in `.agent/specs/web_ui_audio_engines.md` and observed behavior.

## Issues

1. Hidden startup doesn’t assert heartbeat/video before priming engines.
   - Spec §3.1: start survival heartbeat *before* priming when `document.hidden`.
   - Code: `syncState()` primes without heartbeat; only `play()` applies strategy when hidden.

2. No handoff when tab goes hidden mid-track (Web Audio suspension risk).
   - Spec: Hybrid should survive background; HTML5 should take over if Web Audio is suspended.
   - Code: `visibilitychange` only toggles heartbeat/video, never triggers handoff. If Chrome suspends Web Audio, playback can stall until boundary or user action.

3. Suspension doesn’t trigger escape hatch.
   - Stall timer only watches for `processingState === 'buffering'` while playing.
   - When the browser marks Web Audio `suspended`, no recovery is attempted; spec requires reporting `suspended_by_os` and avoiding silent stall.

4. Survival tricks not reasserted after settings changes while hidden.
   - Spec: heartbeat/video must remain active during background sessions.
   - Code: applied once on `visibilitychange` to hidden; if settings/preset change while hidden, tricks may remain stale.

5. Preset/setting changes don’t live-sync to JS engine without reload.
   - Dart is source of truth, but `hybrid_audio_engine.js` reads background/handoff modes from localStorage only during `init`.
   - Changing Hidden Session Preset in settings updates prefs but JS engine keeps old modes until reload.

## Suggested fixes (minimal, spec-aligned)

- Hidden startup guard: in `syncState()`, if `document.hidden`, call `_applyHiddenSurvivalStrategy()` before priming engines.
- Hidden visibility handoff: on `visibilitychange`→hidden while Web Audio is active and playing, set `_instantHandoffPending` and call `_attemptHandoff(_currentIndex, true)` to move to HTML5 before suspension.
- Suspension escape: in state forwarding, if `_activeEngine === _fgEngine` and `processingState === 'suspended'`, either map to `suspended_by_os` and trigger `_executeFailureHandoff()` when playing, or start a timer similar to stall recovery.
- Survival reassert: expose a small helper to reapply heartbeat/video when settings change; invoke from settings sync path while hidden.
- Live settings propagation: when SettingsProvider updates hybrid background/handoff modes or preset, push values into JS engine immediately via `gapless_player_web` setters (no reload required).

Notes:
- No changes proposed to HTML5 or Web Audio engine internals; focus is orchestrator behavior.
- Keep escape hatch timeout at 5s unless spec updates it.
