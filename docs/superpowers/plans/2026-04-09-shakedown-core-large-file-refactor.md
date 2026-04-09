# Shakedown Core Large-File Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the 10 oversized `packages/shakedown_core/lib` files into focused, testable units while preserving behavior across mobile, TV, and Fruit web UX.

**Architecture:** Keep Clean Architecture boundaries intact by splitting monolithic UI and rendering files into feature-local components, helper modules, and pure logic utilities. Move side effects into small, explicit seams and push deterministic logic into pure functions with unit tests. Preserve existing platform contract and theme rules.

**Tech Stack:** Flutter (stable), Dart (null-safe), Provider, Flame, just_audio, flutter_test

---

## Target File Structure

### Existing files to decompose
- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart`
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/show_list/show_list_card_fruit_car_mode.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/interface_section.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/screensaver_screen.dart`
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_config.dart`
- Modify: `packages/shakedown_core/lib/utils/utils.dart`
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_background.dart`

### Proposed new files (feature-local)
- Create: `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_scaffold.dart`
- Create: `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_hud.dart`
- Create: `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_progress.dart`
- Create: `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_controls.dart`
- Create: `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_formatters.dart`
- Create: `packages/shakedown_core/lib/ui/screens/track_list/track_list_header_section.dart`
- Create: `packages/shakedown_core/lib/ui/screens/track_list/track_list_item_tile.dart`
- Create: `packages/shakedown_core/lib/ui/screens/track_list/track_list_actions.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/show_list/fruit_car_mode/fruit_card_layout.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/show_list/fruit_car_mode/fruit_track_progress.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/show_list/fruit_car_mode/fruit_track_pulse.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/settings/interface/interface_group_header.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/settings/interface/interface_tiles.dart`
- Create: `packages/shakedown_core/lib/providers/settings_init/settings_defaults.dart`
- Create: `packages/shakedown_core/lib/providers/settings_init/settings_pref_readers.dart`
- Create: `packages/shakedown_core/lib/providers/settings_init/settings_migrations.dart`
- Create: `packages/shakedown_core/lib/providers/settings_init/settings_screensaver_pref_readers.dart`
- Create: `packages/shakedown_core/lib/ui/screens/screensaver/audio_capture_controller.dart`
- Create: `packages/shakedown_core/lib/ui/screens/screensaver/microphone_permission_flow.dart`
- Create: `packages/shakedown_core/lib/ui/screens/screensaver/screensaver_banner_text.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/render/corner_hud_renderer.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/render/corner_vu_renderer.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/render/corner_led_renderer.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/render/render_math.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/background/trail_buffer.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/background/palette_utils.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/background/shader_uniforms.dart`
- Create: `packages/shakedown_core/lib/utils/messages/material_messages.dart`
- Create: `packages/shakedown_core/lib/utils/messages/fruit_messages.dart`
- Create: `packages/shakedown_core/lib/utils/duration_format.dart`
- Create: `packages/shakedown_core/lib/utils/url_launcher_helpers.dart`

### Tests to add/update
- Create: `packages/shakedown_core/test/ui/screens/playback_fruit_car_mode/fruit_car_mode_formatters_test.dart`
- Create: `packages/shakedown_core/test/ui/screens/track_list/track_list_actions_test.dart`
- Create: `packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`
- Create: `packages/shakedown_core/test/ui/screens/screensaver/microphone_permission_flow_test.dart`
- Create: `packages/shakedown_core/test/steal_screensaver/render/render_math_test.dart`
- Create: `packages/shakedown_core/test/steal_screensaver/background/palette_utils_test.dart`
- Create: `packages/shakedown_core/test/utils/duration_format_test.dart`
- Modify: `packages/shakedown_core/test/screens/screensaver_screen_test.dart`

---

### Task 1: Baseline And Safety Nets

**Files:**
- Modify: `packages/shakedown_core/lib/**` (no behavior change)
- Modify: `packages/shakedown_core/test/**`

- [ ] **Step 1: Capture baseline metrics for target files**
Run: `rg --files packages/shakedown_core/lib | rg "playback_screen_fruit_car_mode|steal_graph_render_corner|track_list_screen_build|settings_provider_initialization|show_list_card_fruit_car_mode|interface_section|screensaver_screen|steal_config|utils|steal_background"`
Expected: all 10 files listed with current paths.

- [ ] **Step 2: Run shakedown_core test baseline**
Run: `dart test packages/shakedown_core/test`
Expected: green baseline or known failures documented before refactor begins.

- [ ] **Step 3: Run analyzer baseline for package**
Run: `dart analyze packages/shakedown_core`
Expected: clean baseline or documented existing warnings not introduced by refactor.

- [ ] **Step 4: Commit baseline snapshot**
Run:
```bash
git add -A
git commit -m "chore: capture baseline before large-file refactor"
```

### Task 2: Refactor Fruit Playback Screen Builders

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart`
- Create: `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_scaffold.dart`
- Create: `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_hud.dart`
- Create: `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_progress.dart`
- Create: `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_controls.dart`
- Create: `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_formatters.dart`
- Test: `packages/shakedown_core/test/ui/screens/playback_fruit_car_mode/fruit_car_mode_formatters_test.dart`

- [ ] **Step 1: Extract pure formatter helpers first**
Move `_fruitCarModeDateText`, `_fruitCarModeUpcomingFontSize`, `_fruitCarModeUpcomingOpacity` into `fruit_car_mode_formatters.dart` with unit tests.

- [ ] **Step 2: Extract HUD subtree into dedicated widget builder**
Move `_buildFruitCarModeHud`, `_buildFruitCarModeHudMeta`, `_buildFruitCarModeMetaDetails`, `_buildFruitCarModeHudStats` into `fruit_car_mode_hud.dart`.

- [ ] **Step 3: Extract progress subtree into dedicated widget builder**
Move `_buildFruitCarModeProgress`, `_buildFruitCarModeProgressTrack`, `_buildFruitCarModeProgressSegment`, `_buildFruitCarModeProgressThumb`, `_buildFruitCarModeDurationText` into `fruit_car_mode_progress.dart`.

- [ ] **Step 4: Extract controls and upcoming track section**
Move `_buildFruitCarModeControls`, `_buildFruitCarModeUpcomingTracks`, `_handleFruitTabSelection` into `fruit_car_mode_controls.dart`.

- [ ] **Step 5: Leave orchestration method in source file**
Keep `_buildFruitCarModeScaffold` as composition entrypoint only; wire extracted modules with package imports.

- [ ] **Step 6: Verify behavior and commit**
Run:
```bash
dart test packages/shakedown_core/test/ui/screens/playback_fruit_car_mode/fruit_car_mode_formatters_test.dart
dart analyze packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart
```
Commit: `git commit -m "refactor: split fruit car mode playback screen builders"`

### Task 3: Refactor Track List And Show Card Fruit Builders

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart`
- Create: `packages/shakedown_core/lib/ui/screens/track_list/track_list_header_section.dart`
- Create: `packages/shakedown_core/lib/ui/screens/track_list/track_list_item_tile.dart`
- Create: `packages/shakedown_core/lib/ui/screens/track_list/track_list_actions.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/show_list/show_list_card_fruit_car_mode.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/show_list/fruit_car_mode/fruit_card_layout.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/show_list/fruit_car_mode/fruit_track_progress.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/show_list/fruit_car_mode/fruit_track_pulse.dart`
- Test: `packages/shakedown_core/test/ui/screens/track_list/track_list_actions_test.dart`

- [ ] **Step 1: Isolate track list play/navigation behavior**
Move `executePlayAndNavigate` and `handleTrackTap` into `track_list_actions.dart` and unit test decision branches.

- [ ] **Step 2: Extract track list header builders**
Move `_buildShowHeader`, `_buildSetHeader` into `track_list_header_section.dart`.

- [ ] **Step 3: Extract item tile builders**
Move `_buildTrackItem` and render-only helpers into `track_list_item_tile.dart`.

- [ ] **Step 4: Extract fruit show card composition**
Move `_buildFruitCarModeCardContent` and trailing-control builder into `fruit_card_layout.dart`.

- [ ] **Step 5: Keep pulse animation isolated**
Move `_FruitCarModeTrackPulse` and state class into `fruit_track_pulse.dart` unchanged behavior.

- [ ] **Step 6: Verify and commit**
Run:
```bash
dart test packages/shakedown_core/test/ui/screens/track_list/track_list_actions_test.dart
dart analyze packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart
dart analyze packages/shakedown_core/lib/ui/widgets/show_list/show_list_card_fruit_car_mode.dart
```
Commit: `git commit -m "refactor: split track list and fruit show-card builders"`

### Task 4: Refactor Settings Initialization And Interface Section

**Files:**
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`
- Create: `packages/shakedown_core/lib/providers/settings_init/settings_defaults.dart`
- Create: `packages/shakedown_core/lib/providers/settings_init/settings_pref_readers.dart`
- Create: `packages/shakedown_core/lib/providers/settings_init/settings_migrations.dart`
- Create: `packages/shakedown_core/lib/providers/settings_init/settings_screensaver_pref_readers.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/interface_section.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/settings/interface/interface_group_header.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/settings/interface/interface_tiles.dart`
- Test: `packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`

- [ ] **Step 1: Extract default-resolution helpers**
Move `_dBool`, `_dStr`, `_dInt` into `settings_defaults.dart` as top-level pure helpers.

- [ ] **Step 2: Extract preference reader groups**
Move `_loadCorePreferences`, `_loadBehaviorPreferences`, `_loadDebugPreferences`,
`_loadWebPlaybackPreferences`, `_loadScreensaver*` methods into dedicated reader files.

- [ ] **Step 3: Keep lifecycle flow in original mixin**
Retain `_init`, `_initializeFirstRunState`, `_setupUiScaleChannel` orchestration in
`settings_provider_initialization.dart`.

- [ ] **Step 4: Split interface section view composition**
Keep `InterfaceSection` as root widget, move group-header and tile-render methods to
new interface subfiles.

- [ ] **Step 5: Add unit tests for setting fallback matrix**
Cover platform-specific defaults and migration idempotency.

- [ ] **Step 6: Verify and commit**
Run:
```bash
dart test packages/shakedown_core/test/providers/settings_provider_initialization_test.dart
dart analyze packages/shakedown_core/lib/providers/settings_provider_initialization.dart
dart analyze packages/shakedown_core/lib/ui/widgets/settings/interface_section.dart
```
Commit: `git commit -m "refactor: modularize settings initialization and interface section"`

### Task 5: Refactor Screensaver Screen Controller Seams

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/screensaver_screen.dart`
- Create: `packages/shakedown_core/lib/ui/screens/screensaver/audio_capture_controller.dart`
- Create: `packages/shakedown_core/lib/ui/screens/screensaver/microphone_permission_flow.dart`
- Create: `packages/shakedown_core/lib/ui/screens/screensaver/screensaver_banner_text.dart`
- Modify: `packages/shakedown_core/test/screens/screensaver_screen_test.dart`
- Create: `packages/shakedown_core/test/ui/screens/screensaver/microphone_permission_flow_test.dart`

- [ ] **Step 1: Extract microphone permission flow**
Move `_getMicrophonePermissionStatus`, `_requestMicrophonePermission`, and defer logic
into `microphone_permission_flow.dart` with unit tests.

- [ ] **Step 2: Extract audio capture orchestration**
Move `_syncStereoCapture`, `_stopStereoCapture`, `_createStartedAudioReactor`,
and `_initAudioReactor` helpers into `audio_capture_controller.dart`.

- [ ] **Step 3: Extract banner text composition**
Move `_composeBannerText`, `_composeVenue`, `_composeDate` into
`screensaver_banner_text.dart`.

- [ ] **Step 4: Keep state lifecycle and widget build in screen file**
Maintain `State` lifecycle methods and navigation key handling in
`screensaver_screen.dart`.

- [ ] **Step 5: Verify and commit**
Run:
```bash
dart test packages/shakedown_core/test/screens/screensaver_screen_test.dart
dart test packages/shakedown_core/test/ui/screens/screensaver/microphone_permission_flow_test.dart
dart analyze packages/shakedown_core/lib/ui/screens/screensaver_screen.dart
```
Commit: `git commit -m "refactor: split screensaver permission and audio controllers"`

### Task 6: Refactor Steal Screensaver Render And Background Stack

**Files:**
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/render/corner_hud_renderer.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/render/corner_vu_renderer.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/render/corner_led_renderer.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/render/render_math.dart`
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_background.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/background/trail_buffer.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/background/palette_utils.dart`
- Create: `packages/shakedown_core/lib/steal_screensaver/background/shader_uniforms.dart`
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_config.dart`
- Test: `packages/shakedown_core/test/steal_screensaver/render/render_math_test.dart`
- Test: `packages/shakedown_core/test/steal_screensaver/background/palette_utils_test.dart`

- [ ] **Step 1: Extract deterministic math helpers first**
Move `softClip`, waveform/path math, LED geometry helpers to `render_math.dart` with
unit tests.

- [ ] **Step 2: Split renderer concerns by subpanel**
Move HUD panel methods, VU meter methods, and LED strip methods into dedicated render
modules.

- [ ] **Step 3: Extract trail and palette helpers from background**
Move `_getTrailPositions`, `_tickTrailBuffer` and `_getPaletteColors` logic into
`trail_buffer.dart` and `palette_utils.dart`.

- [ ] **Step 4: Isolate shader uniform mutation**
Move `_updateShaderUniforms` responsibilities into `shader_uniforms.dart`.

- [ ] **Step 5: Normalize config model boundaries**
Move serializable config mapping and validation helpers in `steal_config.dart` into
small pure helpers while preserving schema compatibility.

- [ ] **Step 6: Verify and commit**
Run:
```bash
dart test packages/shakedown_core/test/steal_screensaver/render/render_math_test.dart
dart test packages/shakedown_core/test/steal_screensaver/background/palette_utils_test.dart
dart analyze packages/shakedown_core/lib/steal_screensaver
```
Commit: `git commit -m "refactor: split steal screensaver render and background modules"`

### Task 7: Refactor Shared Utils Module

**Files:**
- Modify: `packages/shakedown_core/lib/utils/utils.dart`
- Create: `packages/shakedown_core/lib/utils/duration_format.dart`
- Create: `packages/shakedown_core/lib/utils/url_launcher_helpers.dart`
- Create: `packages/shakedown_core/lib/utils/messages/material_messages.dart`
- Create: `packages/shakedown_core/lib/utils/messages/fruit_messages.dart`
- Test: `packages/shakedown_core/test/utils/duration_format_test.dart`

- [ ] **Step 1: Move pure duration formatting helper**
Extract `formatDuration` into `duration_format.dart` and add unit coverage.

- [ ] **Step 2: Split launch helpers from UI messaging**
Move `launchArchivePage` and `launchArchiveDetails` into `url_launcher_helpers.dart`.

- [ ] **Step 3: Split material snackbar and fruit overlay paths**
Move `_showMaterialSnackBar*` to `material_messages.dart` and fruit overlay lifecycle
helpers to `fruit_messages.dart`.

- [ ] **Step 4: Keep thin compatibility facade**
Leave `utils.dart` as exports plus temporary forwarding methods to minimize churn.

- [ ] **Step 5: Verify and commit**
Run:
```bash
dart test packages/shakedown_core/test/utils/duration_format_test.dart
dart analyze packages/shakedown_core/lib/utils
```
Commit: `git commit -m "refactor: decompose shared utils into focused modules"`

### Task 8: Final Integration Verification

**Files:**
- Modify: `packages/shakedown_core/lib/**`
- Modify: `packages/shakedown_core/test/**`

- [ ] **Step 1: Format all touched files**
Run: `dart format packages/shakedown_core/lib packages/shakedown_core/test`
Expected: no formatting diffs after second run.

- [ ] **Step 2: Analyze package**
Run: `dart analyze packages/shakedown_core`
Expected: zero new analyzer issues.

- [ ] **Step 3: Run full package tests**
Run: `dart test packages/shakedown_core/test`
Expected: green.

- [ ] **Step 4: File-size acceptance gate**
Run a line-count check and ensure each original target file is now below 350 lines,
or has a justified exception documented in PR notes.

- [ ] **Step 5: Final commit**
Run:
```bash
git add -A
git commit -m "refactor: complete shakedown_core large-file decomposition"
```

---

## Acceptance Criteria
- All 10 target files are split into smaller cohesive modules.
- No behavior regressions in existing tests.
- New tests cover extracted pure logic and critical branching behavior.
- Package-import rule is preserved (no cross-library relative imports).
- Fruit UI contract remains Fruit-native (no Material 3 substitutions in Fruit paths).
- `dart analyze` and `dart test` pass for `packages/shakedown_core`.
