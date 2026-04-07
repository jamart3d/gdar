# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]

### Fixed
- **Hybrid engine: playback controls/HUD disappear on tab visibility restore after WA→HTML5 handoff**
  - Root cause: `appendTracks` in `hybrid_audio_engine.js` only updated the active engine. When WA was active (post-handoff) and `queueRandomShow()` appended the next show's tracks, HTML5 never received them. Any subsequent WA→HTML5 handoff (fence, OS suspension, seek) called `bgEngine.syncState(index)` with an out-of-range index. HTML5's `_queue.currentTrack` returned `undefined`, `_translateState(undefined)` returned `index: -1`, Dart mapped that to `_currentIndex = null`, and every widget guarding on `currentTrack == null` hid.
  - Fix: `appendTracks` now always calls both `_fgEngine.appendTracks` and `_bgEngine.appendTracks` so both sub-engines always have the complete playlist.
  - File: `apps/gdar_web/web/hybrid_audio_engine.js`

- **Hybrid engine: auto-random-play after show end silently fails after WA→HTML5 handoff**
  - Same root cause as above. With HTML5 at an invalid index, it emitted `processingState: 'idle'` instead of `'completed'`, so `_listenForProcessingState` never triggered `playRandomShow()`.
  - Resolved by the same `appendTracks` fix above.

- **Web engine: double `processingState.completed` emission per state tick**
  - `_onJsStateChange` in `gapless_player_web_engine.dart` called `_processingStateController.add` twice — once early (before `_playing` was updated in Dart) and once at the end. Both were synchronous, so `_listenForProcessingState` fired twice per show completion, launching two concurrent `playRandomShow()` futures. The `_playbackRequestSerial` guard suppressed the first, but two random shows were picked per transition.
  - Fix: removed the premature early emission; the single end-of-function add remains.
  - File: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_engine.dart`

- **Fruit web car-mode show card: current-show date had too much leading inset and truncated on narrow cards**
  - Root cause: the active/current Fruit car-mode show card used a larger symmetric horizontal inset than the idle cards, which reduced the available headline width for the date-first layout.
  - Fix: reduced the leading inset for the active date-first card and updated the text width calculations to use asymmetric padding consistently.
  - File: `packages/shakedown_core/lib/ui/widgets/show_list/show_list_card_fruit_car_mode.dart`

- **Fruit web settings screen: added header car-mode shortcut button**
  - Added a Fruit-style car action button to the settings header, positioned immediately left of the dark/light theme toggle.
  - Behavior: enabling from the header now turns on `carMode`, `preventSleep`, `fruitFloatingSpheres`, and `fruitEnableLiquidGlass`; disabling from the header turns off only `carMode` and `preventSleep`, leaving spheres/glass unchanged.
  - File: `packages/shakedown_core/lib/ui/screens/settings_screen.dart`

- **Fruit web settings screen: removed tooltip from the header car button**
  - Root cause: the Fruit tooltip for the new car button could hover partially offscreen in light theme.
  - Fix: removed the tooltip from that control while keeping its semantic label for accessibility and test coverage.
  - File: `packages/shakedown_core/lib/ui/screens/settings_screen.dart`

- **Web PWA: HTML splash color flash on theme transition eliminated**
  - Root cause: `index.html` splash hardcoded `#00E676` for the Shakedown title and progress bar, matching only the Fruit sophisticate dark palette. Users on any other palette or light mode saw a visible color flash when the HTML splash handed off to the Flutter `SplashScreen`.
  - Fix: CSS vars `--splash-primary` and `--splash-bg` now drive all splash colors. A synchronous IIFE in `<head>` reads `flutter.fruit_color_option_preference`, `flutter.theme_mode_preference`, and `flutter.theme_style_preference` from `localStorage` and overrides those vars before the splash div is painted. Covers all three Fruit palettes × dark/light, Android theme, system-mode OS detection, and NaN/unavailable-localStorage fallbacks.
  - File: `apps/gdar_web/web/index.html`

### Tests Added
- `apps/gdar_web/web/tests/append_tracks_regression.js` — 4-case JS regression covering both-engine update for `appendTracks` in HTML5-active and WA-active scenarios, including the out-of-bounds index guard
- `apps/gdar_web/web/tests/run_tests.js` — wired in new regression as a standalone run
- `packages/shakedown_core/test/services/gapless_player_web_js_contract_test.dart` — static guard asserting exactly 2 `_processingStateController.add` calls in the web engine (error handler + single end-of-tick)
- `packages/shakedown_core/test/widgets/show_list_card_test.dart` — Fruit car-mode regression covering the tighter leading inset for the current-show date headline on narrow cards
- `packages/shakedown_core/test/ui/screens/settings_screen_test.dart` — Fruit settings header regression covering the new car-mode button behavior and confirming the button has no Fruit tooltip
