# Session Todo — web audio update

## Hybrid Engine Behavior
- Updated hybrid start to always use HTML5.
- Added `boundary` handoff mode (swap at next track boundary).
- `handoffMode: none` now means “stay on HTML5.”
- File(s):
- `apps/gdar_web/web/hybrid_audio_engine.js`

## Settings UI
- Removed “Force HTML5 start” toggle.
- Removed Track Transition Mode selector.
- Hidden `Standard` and `Passive` engine options in web selector.
- File(s):
- `packages/shakedown_core/lib/ui/widgets/settings/playback_section.dart`

## Engine Selection / Defaults
- Web default engine is now `auto` (hybrid‑first).
- File(s):
- `packages/shakedown_core/lib/config/default_settings.dart`

## HUD / Telemetry
- Removed Track Transition Mode menu from HUD.
- Hidden `Standard` and `Passive` engine options in HUD menu.
- Added detected profile indicator (`LOW/PWA/DESK/WEB`) in HUD and settings.
- File(s):
- `packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud.dart`
- `packages/shakedown_core/lib/providers/audio_provider.dart`
- `packages/shakedown_core/lib/models/hud_snapshot.dart`
- `packages/shakedown_core/lib/ui/widgets/settings/playback_section.dart`
- `packages/shakedown_core/lib/utils/pwa_detection.dart`

## Documentation
- Added `docs/web_ui_audio_engines.md` (engines, HUD, settings).
- Updated `.agent/notes/web_hybrid_engine_review.md` with current status.
- File(s):
- `docs/web_ui_audio_engines.md`
- `.agent/notes/web_hybrid_engine_review.md`

## Notes / Cleanup
- Removed stale `.agent/notes/web_hybrid_engine_plan.md`.
- Set web app title to “Shakedown.”
- File(s):
- `.agent/notes/web_hybrid_engine_plan.md`
- `apps/gdar_web/lib/main.dart`

## Related Docs
- `docs/web_ui_audio_engines.md`
- `.agent/notes/session_handoff.md`
- `.agent/notes/web_hybrid_engine_review.md`

## Follow-ups
- Defaulted auto selection to hybrid on desktop in `apps/gdar_web/web/hybrid_init.js` (auto now hybrid-first; mobile remains HTML5).
- Removed legacy `hybrid_force_html5_start` sync in `apps/gdar_web/web/hybrid_init.js`.
- Fixed undefined `allowHandoff` in `apps/gdar_web/web/hybrid_audio_engine.js` (now uses `_handoffMode !== 'none'`).
