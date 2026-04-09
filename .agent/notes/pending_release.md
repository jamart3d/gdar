# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]

### Refactor
- Large-file refactor across `packages/shakedown_core` using parallel subagents with disjoint ownership.
- Split Fruit playback screen into focused modules under `lib/ui/screens/playback_fruit_car_mode/` and kept `playback_screen_fruit_car_mode.dart` as orchestration entrypoint.
- Split track list and Fruit show-card builders into focused modules under:
  - `lib/ui/screens/track_list/`
  - `lib/ui/widgets/show_list/fruit_car_mode/`
- Split screensaver logic into focused modules under `lib/ui/screens/screensaver/`:
  - `audio_capture_controller.dart`
  - `microphone_permission_flow.dart`
  - `screensaver_banner_text.dart`
- Split settings/utils responsibilities into focused modules:
  - `lib/providers/settings_init/`
  - `lib/ui/widgets/settings/interface/`
  - `lib/utils/messages/`, `lib/utils/duration_format.dart`, `lib/utils/url_launcher_helpers.dart`
- Split steal screensaver background/render math helpers into:
  - `lib/steal_screensaver/background/`
  - `lib/steal_screensaver/render/`
- Resolved `part`-library integration constraints by wiring parent libraries:
  - `playback_screen.dart`, `track_list_screen.dart`, `show_list_card.dart`, `settings_provider.dart`.
- Completed runtime wiring for corner-render helper extraction by integrating render helpers through `steal_graph.dart` and updating `steal_graph_render_corner.dart` call sites.

### Agent Workflow / Notes
- Preserved requested `.agent/*` workflow edits from this session:
  - `.agent/workflows/checkup.md`
  - `.agent/workflows/toolchain_preflight.md`
  - `.agent/rules/sandbox_preflight_fallback.md`
  - `.agent/notes/verification_status.json`
- Removed transient local tooling/cache artifacts generated during verification (`.codex-appdata`, `.tmp_appdata`).

### Verification
- Full monorepo verification completed successfully (outside sandbox due sandbox timeout/hang behavior):
  - `dart run melos run format` (clean on rerun)
  - `dart run melos run analyze` (clean)
  - `dart run melos run test` (all passing)
