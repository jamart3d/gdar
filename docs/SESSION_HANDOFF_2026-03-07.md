# Session Handoff (Screensaver + Web UI)

Updated: 2026-03-07 (America/Los_Angeles)
Workspace: C:\Users\jeff\StudioProjects\gdar

## What was done

### Web/Fruit UI
- Playback now-playing card: removed the small leading dot from title in playback card only.
  - File: `lib/ui/widgets/playback/fruit_now_playing_card.dart`
- Track list screen header adjusted:
  - Removed rating stars + source badges from top header.
  - Added/kept stars in show card.
  - Top-right button switched to theme toggle (instead of gear) to match show list behavior.
  - Play icon in show card adjusted to a more fruit-style treatment.
  - File: `lib/ui/screens/track_list_screen.dart`

### Web/perf behavior
- Reduced unnecessary rebuild/blur cost in Fruit glass wrappers and headers.
  - Files:
    - `lib/ui/widgets/theme/liquid_glass_wrapper.dart`
    - `lib/ui/widgets/show_list/show_list_shell.dart`
- Track list scroll behavior reduced post-frame churn by only reacting to actual index changes.
  - File: `lib/ui/widgets/playback/fruit_track_list.dart`
- Web audio logger defaults made less chatty.
  - File: `web/audio_logger.js`
- Added low-power web heuristic helper + wiring to auto-enable performance mode only when not explicitly set by user.
  - Files:
    - `lib/utils/web_perf_hint.dart`
    - `lib/utils/web_perf_hint_web.dart`
    - `lib/utils/web_perf_hint_noop.dart`
    - `lib/providers/settings_provider.dart`

### Screensaver lifecycle/reactivity fixes
- Screensaver reactor init/dispose race hardening:
  - Added in-flight init guard and ensured proper cleanup.
  - Dispose path now clears reactor and cached pushed config.
  - File: `lib/ui/screens/screensaver_screen.dart`
- Config push optimization:
  - `_pushAudioConfig` now accepts current settings and only pushes changed values.
  - File: `lib/ui/screens/screensaver_screen.dart`
- `StealGame` reset behavior:
  - When reactor removed, reset energy/beat and graph energy immediately.
  - File: `lib/steal_screensaver/steal_game.dart`
- `VisualizerAudioReactor` teardown safety:
  - Await event subscription cancel before stop/release.
  - Dispose closes stream in safe async path.
  - File: `lib/visualizer/visualizer_audio_reactor.dart`

### Track info movement requirement
- Track info motion is now independent of audio reactivity while keeping smooth translation behavior.
  - File: `lib/steal_screensaver/steal_banner.dart`

### Beat detection improvements (native Android visualizer)
- Beat detection now uses pre-boost bass (`beatBass`) so `bassBoost` no longer changes beat trigger frequency.
- Beat threshold compares against prior history; current frame is added after detection.
- Corrected sensitivity comment to match formula.
- File: `android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`

### Graph visuals (tech/glow pass)
- Added performance-aware glow/gradient treatment, peak-hold caps, beat flash accent, and subtle HUD panel for corner mode.
- Includes balanced/fast fallback behavior.
- File: `lib/steal_screensaver/steal_graph.dart`

### Audio-reactivity defaults + settings hints
- Updated defaults (new installs/reset only):
  - `oilAudioReactivityStrength`: `1.1`
  - `oilAudioBassBoost`: `1.6`
  - `oilAudioPeakDecay`: `0.996` (fixes prior out-of-range default)
  - `oilBeatSensitivity`: `0.55`
  - File: `lib/config/default_settings.dart`
- Added TV-theme `Audio reactive` hint cards under impacted controls (Logo Scale, Pulse Intensity).
  - File: `lib/ui/widgets/settings/tv_screensaver_section.dart`

### Tooling
- Added cross-platform verify runner:
  - File: `tool/verify.dart`
  - Runs `dart format` + `dart analyze` (default targets `lib test tool`), with flags:
    - `--no-format`
    - `--no-analyze`

## Validation done
- Targeted `dart format`/`dart analyze` were run on modified files in batches and passed where executed.
- `tool/verify.dart` executed successfully on itself:
  - `dart run tool/verify.dart tool/verify.dart`

## Known environment note
- In this Codex environment, sandboxed `dart` commands often timeout.
- Re-running with escalation completed quickly and successfully.

## Suggested next checks (manual)
1. On Android TV, verify beat response consistency across low and bass-heavy tracks.
2. Toggle audio reactivity ON/OFF while screensaver active; confirm no stale pulses.
3. Compare graph visuals in performance levels High/Balanced/Fast for readability/perf.
4. Run full project check:
   - `dart run tool/verify.dart`
   - your full Flutter test/build pipeline.

## Open / optional follow-ups
- Optional adaptive beat cooldown (tempo-aware) instead of fixed 200ms.
- Optional setting to reduce graph glow independently from global performance level.
