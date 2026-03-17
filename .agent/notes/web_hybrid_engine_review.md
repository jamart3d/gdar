# Hybrid Web Audio Engine Review (2026-03-16)

Status update after web audio refresh work.

## Updated Behavior
- Hybrid start is now HTML5-first for instant start.
- Added `boundary` handoff mode (swap at next track boundary).
- `handoffMode: none` now stays on HTML5 (no Web Audio handoff).
- Track-boundary restore respects handoff disabled state.

## UI / Telemetry
- Track transition control removed from Playback settings and HUD menu.
- Standard/Passive engine options hidden in UI selectors.
- Detected profile tag (LOW/PWA/DESK/WEB) added to settings and HUD.

## Notes
- Handoff/background changes still require relaunch (by design).
- Track transition mode remains stored but is effectively gapless-only on web.
