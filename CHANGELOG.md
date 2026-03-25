# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.17+227] - 2026-03-24

### Added
- **TV Enhancement**: Refined the `InactivityDetector` logic to ignore phantom hardware input signals, ensuring more reliable screensaver activation on Google TV.
- **TV UI**: Hardened `GdarTvApp` to prevent anonymous system dialogs from inadvertently disabling the inactivity timer.
- **Maintenance**: Added a specialized `/screensaver_timeout_report` to track and debug inactivity detection thresholds.

### Fixed
- **Web UI (Fruit)**: Optimized vertical spacing in the Fruit theme playback screen, ensuring a consistent 5pt gap between the floating now-playing card and the bottom navigation bar across all device sizes.
- **Workflow**: Eliminated friction from the `/checkup` and `/shipit` workflows, authorizing automated versioning, building, and deployment without manual prompts.
- **Monorepo**: Pruned stale git worktrees and synchronized workspace verification status following successful health checks.

## [1.3.15+225] - 2026-03-23

### Fixed
- **Maintenance**: Completed a full monorepo-wide health check with successful analysis and 248+ passed tests across all targets (Mobile, TV, Web, and Core).
- **Verification**: Synchronized the workspace verification status and enforced strict formatting and linting standards.

## [1.3.14+224] - 2026-03-23

### Fixed
- **Maintenance**: Synchronized efficiency guardrails and auto-approval policies to ensure zero-friction monorepo orchestration for release and health workflows.
- **Workflow**: Formally authorized the `/shipit` and `/checkup` pipelines to ignore redundant verification steps and proceed with automated versioning and build tasks.

## [1.3.13+223] - 2026-03-23

### Fixed
- **Maintenance**: Stabilized monorepo test runs by enforcing sequential execution (`-j 1`) in the root `pubspec.yaml` to prevent resource contention.
- **Quality**: Successfully completed a comprehensive project-wide health check and registered new verification results.

## [1.3.12+222] - 2026-03-23


### Fixed
- **Testing**: Re-stabilized the `true_black_glow_test.dart` by increasing the viewport size to prevent layout overflows and ensuring strict "True Black" settings on initialization.
- **TV UI Testing**: Hardened `tv_dual_pane_layout_random_test.dart` by fully implementing the `FakeShowListProvider` interface, eliminating `noSuchMethod` flukes during automated random show selection tests.
- **Data (Song Hints)**: Fixed a track ID mapping error for "Cold Rain & Snow" to ensure correct metadata linking.

## [1.3.11+221] - 2026-03-23

### Added
- **TV UI**: Implemented conditional RGB highlighting—now only the active cursor has the moving rainbow border, while the currently playing track is clearly indicated by a playback icon and progress bar.
- **TV UI**: Added focus memory to the track list, preserving the last selected item when returning to the playback pane.
- **Web UI**: Added a "Crossfade Play/Pause" setting for the Fruit theme to provide smooth audio transitions and prevent pops.
- **Data**: Conducted a thorough audit of the Grateful Dead song structure hints, removing non-GD tracks and JGB side projects for a more accurate catalog.

### Fixed
- **Web UI**: Resolved size and placement issues for the "Rate Show" modal in the Fruit theme.
- **Data Quality**: Fixed leading space issues in several song titles in `grateful_dead_song_structure_hints.json`.
- **Testing**: Stabilized the screensaver regression tests by correctly configuring stereo capture requirements.

## [1.3.8+218] - 2026-03-22

### Added
- **Agent Architecture**: Implemented "Smart Verification Receipts" for the `shipit` workflow, eliminating redundant analyzer and test runs for identical worktree states.
- **Workflow**: Integrated verification receipts into the `/checkup` workflow to ensure cross-workflow hygiene persistence.

## [1.2.7+207] - 2026-03-22

### Fixed
- **Web UI HUD**: Resolved issue where `AE` (Active Engine) chip showed `WA` instead of `H5` at the start of Track 1 in Hybrid mode by correctly defaulting to the background engine for "Instant Start".
- **Web UI HUD**: Fixed missing `LG` (Last Gap) reports in Hybrid/HTML5 modes by implementing track transition gap tracking in the HTML5 audio engine.
- **Web UI HUD**: Resolved issue where `AE` chip showed a `+` suffix even when background survival was disabled by syncing background mode status to all underlying JS engines.
- **Background Survival**: Optimized low-power detection heuristics to align Dart and JS thresholds.

### Changed
- **Web Audio**: Updated default background survival for high-performance devices to use escalated heartbeat (audio then video after 60s).
- **Web Audio**: Updated default background survival for low-power devices to use immediate video heartbeat for maximum stability.

### Added
- **Docs**: Added comprehensive Web/PWA Audio Engine & Survival Analysis documentation.

## [1.2.6+206] - 2026-03-18
## [1.3.7+217] - 2026-03-22

### Added
- **TV Enhancement**: Implemented a dedicated `InactivityService` and `InactivityDetector` for more reliable inactivity tracking and screensaver triggering on Google TV.
- **TV Enhancement**: Updated `AndroidManifest.xml` to explicitly mark touchscreen as non-required and added Leanback support for better TV Play Store visibility.
- **Testing**: Added specialized regression tests for TV inactivity detection and automated screensaver activation.

### Fixed
- **TV UI**: Resolved a potential race condition where the screensaver might attempt to launch before the navigator was fully initialized.

## [1.3.6+216] - 2026-03-22

### Added
- **Core (Visualizer)**: Implemented new `StealGraph` display modes: EKG, Circular EKG, VU Meter, and Oscilloscope Scope.
- **TV Enhancement**: Added multi-algorithm beat detection and stereo L/R capture support for high-fidelity reactivity.

### Fixed
- **Web Audio**: Resolved a critical player hang condition in the Gapless Web Audio engine triggered by rapid play/pause transitions.
- **Testing**: Hardened `gdar_mobile` widget test suite by suppressing noisy framework-level teardown exceptions.
- **Documentation**: Finalized `audio_graph_modes.md` and updated screensaver audio audit records for 2026-03-21.

## [1.3.5+215] - 2026-03-22

### Added
- **Core**: Introduced `SongStructureHintService` and models for parsing track-specific metadata.

### Fixed
- **Testing**: Resolved `NoSuchMethodError` in `gdar_mobile` widget tests by hardening fakes.
- **Testing**: Fixed monorepo asset path resolution in `shakedown_core` service tests.

## [1.3.4+214] - 2026-03-21

### Added
- **Visualizer**: Implemented `beatSource` (PCM/FFT) in `VisualizerAudioReactor` to distinguish between capture sources in telemetry.
- **Android**: Enhanced `VisualizerPlugin.kt` with support for raw PCM capture, enabling higher fidelity reactivity on TV devices.
- **Documentation**: Finalized `audio_graph_modes.md` and conducted a detailed screensaver audio audit (2026-03-21).

### Fixed
- **Maintenance**: Resolved project-wide curly brace lint issues in `dev_audio_hud.dart` to maintain strict analysis standards.
- **Testing**: Hardened `gdar_mobile` widget tests by suppressing framework-level ancestor lookup exceptions during Provider tree teardown.
- **Core**: Added robust numeric parsing and clamping for visualizer telemetry to prevent overflow in HUD displays.


### Fixed
- **Testing**: Resolved text stream corruption in parallel test execution by configuring simplified logger output for test environments.
- **Testing**: Fixed state leakage in `true_black_glow_test.dart` caused by `SettingsProvider` performance mode interference.
- **Testing**: Updated assertion logic to align with new default audio reactivity states, achieving a clean passing suite.
## [1.3.2+212] - 2026-03-21

### Added
- **TV Enhancement**: Finalized infrastructure for true stereo L/R VU meters via `AudioPlaybackCapture` (API 29+).
- **TV Architecture**: Conducted a comprehensive screensaver audio audit (2026-03-21) to align native detector levels with visualizer telemetry.

### Changed
- **Documentation**: Updated audio graph modes, reactivity status, and tuning guides for advanced TV screensaver configuration.
- **Maintenance**: Synchronized codebase formatting and refined `HiddenSessionPreset` segmented button alignment in `playback_section.dart`.

### Added
- **TV Enhancement**: Implemented `StereoCapture` for the Android TV engine, providing high-fidelity PCM capture for real-time visualizers.
- **TV Architecture**: Added specialized TV banner assets and startup metadata configurations for enhanced Leanback visibility.

### Changed
- **Screensaver**: Optimized EKG spread and beat detection sensitivity in `default_settings.dart` for a more responsive reactive experience.
- **TV Debugging**: Expanded and refined the `TV_DEBUGGING.md` documentation with new deep-link automation sequences for rapid UI verification.

## [1.3.0+210] - 2026-03-19

### Changed
- **Maintenance**: Synchronized codebase with the latest monorepo standards and regenerated test mocks across all packages.
- **Hygiene**: Resolved unused imports in `fruit_tab_bar.dart` and synchronized cross-package message routing contract tests.
- **Agent Architecture**: Hardened release and auto-approve protocols to ensure zero-friction orchestration for discovery commands.

## [1.2.9+209] - 2026-03-19

### Changed
- **Hygiene**: Enforced strict codebase formatting across the monorepo to maintain high standards and readability (mostly test fakes and contract stubs).
- **Maintenance**: Verified and synchronized test stubs and contract tests following the latest provider API updates.
- **Auto-Save**: Synchronized session memory files and updated `.agent/rules/` to prune stale content and add new protocols.

## [1.2.8+208] - 2026-03-19

### Fixed
- **TV Bootstrap**: Standardized `SharedPreferences` injection in `GdarTvApp` to ensure consistent state initialization on TV devices.
- **Testing**: Hardened TV startup regression tests by addressing race conditions between specialized app navigation and inactivity timers.

### Fixed
- **Web Audio**: Hardened source switching logic in `AudioProvider` to ignore transient state mismatches during manual show transitions.
- **Web Audio**: Optimized `PlaybackScreen` list synchronization by adding safety guards to scroll and jump operations, preventing crashes when the view detaches on browser re-renders.
- **Architecture**: Improved navigation between Library and Playback screens in Fruit theme by routing through a unified `FruitTabHostScreen`.
- **UI**: Refined hit-testing and layout for the `FruitNowPlayingCard` to ensure controls remain responsive during rapid state updates.

### Added
- **Testing**: Added unit tests for `AudioProvider` focusing on pre-queueing and source synchronization stability.


## [1.2.6+206] - 2026-03-18

### Fixed
- **Web Audio**: Resolved a critical "player hung" issue during rapid play/pause toggling by implementing a playback intent guard in the `GaplessAudioEngine` decode chain.
- **Web Audio**: Fixed `InvalidAccessError` in the HTML5 fallback engine by hardening the `disconnect()` logic for non-active tracks.
- **Web Audio**: Throttled error notifications in `AudioProvider` to prevent UI thread starvation during Archive.org network failure spikes.
- **Hygiene**: Resolved `unawaited_futures` in `track_list_screen.dart`.
- **Performance**: Optimized the high-frequency state emission loop in the Web engines by caching User Agent detection results.

## [1.2.5+205] - 2026-03-18

### Changed
- **Screensaver (TV)**: Enhanced auto-spacing for track information to better account for long titles. Increased horizontal compression depth and implemented "Squish-to-fit" logic to prevent text from bleeding off-screen in both Ring and Flat modes.
- **Playback UI**: Hardened constrained-height playback header/layout behavior to avoid overflow in compact panel states.
- **TV Bootstrap**: Standardized TV startup through `SplashScreen` while preserving the no-onboarding TV boot path.
- **Monorepo/Test Coverage**: Replaced brittle startup and shared-widget regressions with smaller contract-focused tests and aligned stale test fakes with current provider/widget APIs.
- **Docs**: Updated monorepo planning/rules docs and refreshed the 2026-03-18 scorecards.


## [1.2.4+204] - 2026-03-16

### Added
- **Icons**: Branded launcher icons for Android, iOS, and Web platforms.
- **Melos**: New `melos run icons` script for unified launcher icon regeneration across the workspace.

## [1.2.3+203] - 2026-03-15

### Added
- **HUD**: Unified Diagnostics HUD with real-time `HudSnapshot` streaming for transparent audio engine telemetry.

### Changed
- **Architecture**: Refactored `PlaybackMessages` and `DevAudioHud` to use stream-based updates, improving UI responsiveness and architectural clarity.
- **Provider**: Consolidated `AudioProvider` cleanup logic and unified the diagnostics snapshot generation process.

### Fixed
- **UI**: Resolved a bug where playback status text was visible even when "Show Playback Messages" was disabled in Settings.
- **Maintenance**: Fixed a duplicate `dispose()` method conflict in `AudioProvider`.

## [1.2.1+201] - 2026-03-15

### Changed
- **Infrastructure**: Relocated `verify.dart` from `tool/` to `scripts/` and synchronized its default analysis targets with the new monorepo structure (`apps/`, `packages/`, `scripts/`).

### Fixed
- **TV UI**: Resolved launch failure where the app would hang at the onboarding screen; unified navigation directly to `TvDualPaneLayout` when in TV mode.
- **TV Fonts**: Restored consistent 'Rock Salt' branding on TV by enforcing the TV-specific font override across all screens and widgets.
- **Web UI**: Fixed FastScrollbar year chip positioning on Web by hardening coordinate mapping and removing stale frame scheduling logic.
- **Web UI**: Defaulted onboarding to "completed" for Web apps to ensure a direct-to-list experience consistent with previous versions.

## [1.2.0+200] - 2026-03-14

### Changed
- **Architecture**: Migrated to a Dart workspace monorepo. The single-package `shakedown` root is now `gdar_root` with independent app targets (`gdar_mobile`, `gdar_tv`, `gdar_web`) and shared packages (`shakedown_core`, `gdar_android`, `gdar_fruit`).
- **Versioning**: Reset build number to `+200` to mark the new monorepo era. Previous single-app lineage ended at `1.1.70+170`.

## [1.1.69+169] - 2026-03-12

### Added
- Updated `device_info_plus` to v12.3.0 and `app_links` to v7.0.0.
- Migrated to `hive_ce` (Community Edition) for improved Dart 3.7+ support.
- Updated `flame` to v1.36.0 for 2026 Game Jam compatibility.

### Changed
- Updated `sliding_up_panel` to `sliding_up_panel2` for better stability.

### Fixed
- Fixed Fruit theme activation regression where `glowMode` wasn't resetting correctly during the first-time switch due to `performanceMode` guard interference in tests.
- Resolved Android compilation error by regenerating `GeneratedPluginRegistrant.java` after dependency upgrades.


## [1.1.68+168] - 2026-03-12

### Fixed
- Resolved `MissingStubError` in `playback_alignment_test.dart` by stubbing `fruit` theme settings (`fruitStickyNowPlaying`, `fruitDenseList`, `fruitEnableLiquidGlass`) and `AudioProvider` streams.
- Fixed track title alignment stability test for Material 3.


## [1.1.67+167] - 2026-03-12

### Added
- **UI/UX (HUD)**: Implemented interactive popup menus for developer HUD chips (ENG, TX, HF, BG, STB) on Web, allowing direct adjustment of engine and hybrid modes.
- **UI/UX (HUD)**: Added a new "STB" (Session Preset) chip to the HUD to show and control the `HiddenSessionPreset` (Stability, Balanced, Max Gapless).
- **UI/UX (HUD)**: Optimized long message display in the HUD using animated Marquee text.
- **UI/UX (Settings)**: Added automated "Relaunch Required" notifications using `showRestartMessage` for critical engine and stability settings (Audio Engine, Handoff, Background Strategy, etc.).
- **Deep Links**: Added a new `force_tv=true` deep link parameter for testing the TV UI on non-TV devices, including a confirmation dialog and automated app restart.

### Fixed
- Resolved layout overflow in `PlaybackPanel` using scale-to-fit logic for venue metadata.
- Removed redundant playback state indicator from `PlaybackProgressBar` to clean up the UI and prevent duplicate status reporting when HUD is active.
- Mirrored duration alignment in `PlaybackProgressBar` (Elapsed: Left, Total: Right) for a cleaner, balanced aesthetic.
- Refactored `PlaybackProgressBar` to a stacked layout, allowing the seeker bar to expand to full width while moving timestamps to a secondary row.
- Resolved linting issues in `DevAudioHud` by enforcing block enclosures for conditional statements.
- **Testing (Regression)**: Resolved `NoSuchMethodError` and `TestFailure` in `tv_regression_test.dart` by synchronizing `FakeSettingsProvider` with the latest `SettingsProvider` API (Oil screensaver sine wave and EKG settings).
- **Testing (Regression)**: Fixed the "Flow Speed" text finder in TV regression tests to match the updated UI wording.


## [1.1.66+166] - 2026-03-11

### Added
- **UI/UX (Debug)**: Implemented "Smart Coloring" for the debug layout, applying distinct functional colors to Venue, Metadata, Progress, and Control sections to improve developer scannability.
- **UI/UX (Debug)**: Added granular debug outlines to internal components of `PlaybackProgressBar` and `PlaybackControls` for high-precision layout inspection.

### Fixed
- **UI/UX (HUD)**: Refined the heartbeat dot in the developer HUD—relocated it immediately before the background chip and enforced strict hidden state when inactive or stopped to reduce visual clutter.
- **Verification**: Verified project health and enforced strict formatting/analysis standards via `tool/verify.dart`.

## [1.1.65+165] - 2026-03-10

### Added
- **Web**: Added custom JavaScript error logger `web_error_logger.js` and custom `flutter_bootstrap.js` to capture and dump unhandled WebAssembly errors to the DOM for easier debugging on mobile.

### Fixed
- **Web**: Removed `--wasm` requirement from the production deployment pipeline to temporarily bypass Skwasm `RuntimeError: function signature mismatch` crashes on certain devices.

## [1.1.64+164] - 2026-03-10

### Added
- **Screensaver**: Implemented "Advanced Audio Reactivity" with 8-band frequency isolation.
- **Screensaver**: Added "Woodstock Every Hour" hidden easter egg functionality.
- **Infrastructure**: Added Puppeteer hybrid stress test suite for Web/Wasm stability verification.

### Fixed
- **UI/UX (TV)**: Resolved playback message overflow by gating web-only buffering indicators.
- **UI/UX (TV)**: Refined premium focus highlights with softer glow (0.65 -> 0.45) and reduced width to prevent neighbor clipping.
- **UI/UX (TV)**: Standardized Show List card metrics; increased star size to 28 for 10-foot UI legibility and unified metadata badges into a single row.
- **Testing**: Resolved `Null` pointer errors in `screensaver_screen_test.dart` via mock recruitment and stub synchronization.
- **Web/Wasm**: Resolved critical UI freezes during playback and tab switching by implementing strict JS interop primitive types and non-finite number guards.
- **Web/Wasm**: Fixed "Provider not found" crashes during asynchronous state updates by refactoring Provider access patterns in `PlaybackMessages`.
- **Infrastructure**: Resolved Wasm initialization failure caused by inadvertent `dart:io` imports in `ShowListProvider` and `AudioCacheService`.


## [1.1.63+163] - 2026-03-08

### Added
- **Testing**: Enhanced `tv_settings_screen_test.dart` with robust `MockAudioProvider` and stabilized `AboutSection` tests by replacing flaky `pumpAndSettle` calls with periodic `pump` cycles.

### Fixed
- **UI/UX (TV)**: Hidden "Haptic Feedback" and "Swipe to Block" settings from the TV interface, adhering to platform interaction rules (`tv_rules.md`).

## [1.1.62+162] - 2026-03-07
 
### Fixed
- **Audio (State)**: Hardened `AudioProvider` transition logic to properly clear stale "pending" show state when the player synchronizes with the new track source. This ensures track titles and metadata (like screensaver rings) update correctly during automated show transitions.

## [1.1.61+161] - 2026-03-08

### Fixed
- **UI/UX (ShnidBadge)**: Overhauled `ShnidBadge` with a consistent HTML-style link behavior (onTap + underline) across all platforms.
- **UI/UX (RatingDialog)**: Resolved a regression where the "Internet Archive" link was missing the `sourceUrl` when rating shows from the list view.
- **UI/UX (Fruit)**: Refined hit-testing on Fruit-style cards to ensure glass and neumorphic overlays don't intercept badge link taps.
- **Layout**: Stabilized `TrackListScreen` header by removing layout-squashing `Flexible` wrappers, ensuring badge links remain accessible.

### Changed
- **UI/UX (Fruit)**: Reverted the experimental global mini-player for Fruit style to restore the original browsing layout as requested.

## [1.1.60+160] - 2026-03-07

### Added
- **Infrastructure**: Added `tool/verify.dart` for automated cross-platform formatting and analysis checks.
- **UI/UX (TV)**: Added audio-reactivity hint cards under screensaver controls (Logo Scale, Pulse Intensity) when reactivity is active.
- **Web/Performance**: Implemented a low-power web heuristic to auto-enable performance mode on resource-constrained devices.

### Changed
- **UI/UX (Web/Fruit)**: Refined Now Playing card by removing the leading dot from the track title.
- **UI/UX (Web/Fruit)**: Upgraded Track List screen header with a theme toggle and removed redundant rating/source badges.
- **Screensaver**: Decoupled track info motion from audio reactivity for smoother, independent translation behavior.
- **Screensaver**: Optimized graph visuals with performance-aware glow, gradients, peak-hold caps, and a new HUD panel for Corner mode.
- **Default Settings**: Adjusted audio reactivity defaults (Strength 1.1, Bass Boost 1.6, Peak Decay 0.996, Sensitivity 0.55) for a more responsive initial experience.

### Fixed
- **Screensaver**: Hardened initialization and disposal cycles to prevent race conditions and memory leaks.
- **Screensaver**: Fixed `StealGame` reset behavior to immediately clear energy and graph data when the reactor is removed.
- **Visualizer**: Refined native Android beat detection to use pre-boost bass and historical thresholds for more accurate triggers.
- **Web/Performance**: Reduced rebuild costs in glass wrappers and optimized track list scroll reaction churn.

## [1.1.59+159] - 2026-03-07

### Added
- **PWA Dynamic Branding**: Synchronized browser `theme_color` with the application background. Respects "True Black" and Light/Dark themes for both Android and Fruit styles.

### Changed
- **Navigation (Web)**: Restored fixed bottom navigation bar to the Track List screen and optimized list padding.
- **Documentation**: Updated `ANTIGRAVITY_SETUP.md` with the optimal `flub` alias for web-server development.

### Fixed
- **UI/UX (Fruit)**: Resolved non-functional "NOW" navigation button in the Settings screen tab bar.
- **UI/UX (Fruit)**: Removed redundant mini-player from the Track List screen for a cleaner layout.
- **Theme Consistency**: Enforced `performanceMode` (Simple Theme) constraints on the `FruitTabBar` and page headers.

## [1.1.58+158] - 2026-03-07

### Fixed
- **Screensaver**: Refined "Text Pixel Snapping" to use anchor-level alignment. This resolves the observation where individual letters would jitter/crawl independently during extremely slow animations.

## [1.1.57+157] - 2026-03-07

### Added
- **Screensaver**: Added "Text Pixel Snapping" toggle to settings to eliminate sub-pixel text jitter during slow animations (`oilBannerPixelSnap`).

### Fixed
- **Testing**: Resolved critical test regressions in `playback_screen_test.dart` by updating manual `MockSettingsProvider` stubs for new `oil*` settings.
- **Testing**: Fixed `ScreensaverScreen` timer leaks by implementing a 600ms catch-up `pump` to clear `initState` delays.
- **Theme**: Hardened `SettingsProvider` to ensure "Fruit" (Liquid Glass) features (Dense List, Simple Icons, Glow) are strictly disabled on first-time activation.
- **Infrastructure**: Regenerated all platform mocks via `build_runner` to synchronize with the latest Provider APIs.

### Changed
- **Testing Strategy**: Codified the "Inner Loop" vs. "Outer Loop" distinction. Arlo now handles targeted local checks (< 5 files) via `/checkup`, while full regression suites are offloaded to Jules.
- **Rules**: Updated `efficiency_guardrails.md` with explicit testing thresholds to conserve tokens and improve performance.
- **Workflows**: Modified `/checkup` and `/audit` to enforce the 5-file local testing limit and provide a "Jules Handoff" prompt.
### Documentation
- **Agent Environment**: Finalized `docs/AGENT_ENVIRONMENT.md` with comprehensive guides for ADB, Deep Links, and Chromebook developer setups. Uses generic placeholders (`com.user.myapp`, `myapp://`) for universal template utility.
- **Automation**: Integrated `tools/verify_fonts.py` as a template for automating UI verification via ADB and Deep Links, featuring automated HTML contact sheet generation.

<-- slide -->
## [1.1.56+156] - 2026-03-06

### Fixed
- **UI/UX (Fruit)**: Fixed infinite-width crash in segmented controls by dynamically calculating width boundaries and optimizing horizontal scrolling.
- **UI/UX (Fruit)**: Upgraded Settings screen header with premium "Liquid Glass" translucency and `FruitIconButton` styling.
- **UI/UX (Fruit)**: Integrated `FruitTabBar` bottom navigation directly into the Settings screen for deeper context retention.
- **Workflows**: Addressed PowerShell pipe compatibility in agent TODOs.
## [1.1.55+155] - 2026-03-06

### Added
- **UI/UX (TV Settings)**: Added "Consider Donating to the Internet Archive" link to the About section with a matching **PulsingHeartIcon**.
- **UI/UX (TV)**: Implemented "Switch Pane" shortcut (Tab/S), Back-to-master navigation, and dimming visual indicators for inactive panes.
- **Architectural**: Extracted `PulsingHeartIcon` into a reusable widget for consistent aesthetic across all platforms.
- **UI/UX (Web/PWA)**: Created `docs/fruit_theme_spec.md` to formally define the "Fruit" (Liquid Glass) aesthetic for Web/PWA platforms.
- **Testing**: Created `test/prompts/master_audit.md` as the unified pre-release standard (Phases 1-7).
- **Infrastructure**: Initialized `size_guard` skill for ongoing app size and asset optimization audits.

### Changed
- **UI/UX (TV)**: Relocated "TV Safe Area" and "Default Screensaver Settings" to Backlog/Low Priority to focus on core performance.
- **UI/UX (TV)**: Dimmed inactive headers in the TV dual-pane layout for clearer focus indication.

### Fixed
- **UI/UX (TV)**: Synchronized list keying with `ValueKey(currentSource.id)` and updated alignment to fully eliminate "bounce scroll" glitches.
- **Theme**: Surgically gated "Fruit" theme logic to ensure it only applies to Web/PWA, strictly enforcing Material 3 on Native and TV.
 
## [1.1.54+154] - 2026-03-05
 
### Added
- **UI/UX (TV)**: Implemented "Switch Pane" shortcut (Tab/S), Back-to-master navigation, and dimming visual indicators for inactive panes.
- **UI/UX (Web/PWA)**: Created `docs/fruit_theme_spec.md` to formally define the "Fruit" (Liquid Glass) aesthetic for Web/PWA platforms.
- **Testing**: Added "Phase 4: CPU Throttling & Timer Drift" to `jules_audit.md` for stress-testing the JS audio scheduler on Web/PWA.
- **Infrastructure**: Initialized `size_guard` skill for ongoing app size and asset optimization audits.
 
### Changed
- **UI/UX (TV)**: Relocated "TV Safe Area" and "Default Screensaver Settings" to Backlog/Low Priority to focus on core performance.
- **UI/UX (TV)**: Dimmed inactive headers in the TV dual-pane layout for clearer focus indication.
 
### Fixed
- **UI/UX (TV)**: Synchronized list keying with `ValueKey(currentSource.id)` and updated alignment to fully eliminate "bounce scroll" glitches.
- **Theme**: Surgically gated "Fruit" theme logic to ensure it only applies to Web/PWA, strictly enforcing Material 3 on Native and TV.
 

## [1.1.53+153] - 2026-03-05

### Added
- **UI/UX (TV)**: Implemented "Surgical Stabilization" for Premium Highlights. The widget tree now remains structurally identical whether highlights are on or off, preventing focus loops and "wacky flow" during navigation.
- **UI/UX (TV)**: Added "Safe-Zone Scrolling" to the track list. Intelligent visibility checks now prevent unnecessary list movement, only scrolling when the focused item reaches the viewport edges.

### Fixed
- **UI/UX (TV)**: Resolved "leftover highlights" bug by implementing an explicit unfocus broadcast across all track nodes before a new focus is granted.
- **UI/UX (TV)**: Fixed layout shifting caused by mounting/unmounting `AnimatedGradientBorder` by ensuring it stays mounted and uses zero-padding when features are disabled.
- **UI/UX (TV)**: Added a zero-cost performance short-circuit to the RGB border painter when the border width is zero.

## [1.1.52+152] - 2026-03-05

### Added
- **UI/UX (TV)**: Implemented auto-scrolling for the left panel Show List to keep focused items visible.

### Changed
- **UI/UX (TV)**: Updated "Premium Highlight" to use the RGB rainbow spectrum, matching the playing track border aesthetic.
- **UI/UX (TV)**: Refined playing track border to be a crisp RGB line without glow, reserving the intense glow exclusively for the active focus.
- **UI/UX (TV)**: Changed playback header rating stars to filled yellow icons (Colors.amber) for better visibility and consistency.

### Fixed
- **UI/UX (TV)**: Resolved focus looping bug in the track list by introducing container focus guards and gentle visibility-only scrolling.
- **UI/UX (TV)**: Fixed stale focus node cleanup to prevent memory leaks and "ghost" highlights without dropping active focus.
- **UI/UX (TV)**: Prevented playing shows from "stealing" the premium glow from the user's active cursor.
- **Stability**: Added `isAttached` safety guards to the TV scroll controller to prevent crashes during rapid pane switching.

## [1.1.51+151] - 2026-03-05

### Added
- **Agent**: Added `windows_shell.md` and `linux_shell.md` rules for platform-safe command execution.
- **Agent**: Added `/audit` workflow for comprehensive codebase baselining.

### Changed
- **UI/UX (TV)**: `TvHeader` now scales icons, padding, and title via `FontLayoutConfig` to respect the 1.35x TV UI boost.
- **Settings (TV)**: `uiScale` is now automatically enabled on first run for TV devices, ensuring 10-foot UI standards out of the box.

### Fixed
- **UI/UX (Fruit)**: `SectionCard` now maintains `LiquidGlassWrapper` aesthetic in Fruit mode even when Neumorphism is disabled, preventing raw Material Card fallback.

## [1.1.50+150] - 2026-03-05

### Fixed
- **UI/UX (TV)**: Resolved "Premium Highlight" persistence issue by refining highlight prioritization and `glowMode` logic in `TvFocusWrapper`.
- **UI/UX (TV)**: Fixed layout shifting (jumping UI) in `AnimatedGradientBorder` by ensuring consistent padding when `usePadding` is true.
- **UI/UX (TV)**: Restored visibility of the non-glow RGB border for the active track by fixing the `showGlow` master render switch in `TvFocusWrapper`.
- **UI/UX (TV)**: Fixed structural bug where the left panel Show List RGB border was padded incorrectly and invisible. Restored tight internal bounding for playing shows.
- **UI/UX (TV)**: Bridged explicit focus navigation gap between the Show List and the Playback pane track list.
- **UI/UX (TV)**: Fixed issue where the Show List playing highlight appeared swapped (Neon vs Rainbow) by prioritizing `showPlayingRgb` over `showPremium` in `TvFocusWrapper`.
- **Audio (TV)**: Fixed random show playback regression where clicking the dice while playing would sometimes fail to trigger the new tracks.
- **Audio**: Hardened `currentTrack` validation to ensure the player correctly reports the active track during rapid source transitions.


## [1.1.49+149] - 2026-03-05

### Added
- **UI/UX (Fruit)**: Implemented "Living List" layout for Playback Screen—centered header and integrated Now Playing card directly into the tracklist.
- **UI/UX (Fruit)**: Upgraded Now Playing card with circular neumorphic controls and polished progress bar.
- **Infrastructure**: Finalized `env_doctor.py` v4.2.0 for automated environment health checks and agent rule validation.

### Changed
- **UI/UX (Fruit)**: Refined header spacing and dark mode backgrounds to precisely match premium design mocks.
- **UI/UX (AMOLED)**: Hardened True Black depth—preserved subtle shadows in glow mode to maintain UI hierarchy.

### Fixed
- **Settings**: Enforced strict "Default Off" policy for Premium Highlight, Liquid Glass, and Dense List features.
- **UI/UX (Fruit)**: Restored Fruit Card aesthetics and fixed tracklist scrolling logic.

## [1.1.48+148] - 2026-03-04

### Changed
- **UI/UX (Web)**: Refined the Fruit theme "Show List" screen on Web/PWA to match the premium "Stitch" vertical card design.
- **UI/UX (Web)**: Updated the Fruit Web app bar to a centered layout featuring the "ShakeDown" title in the Rock Salt font.
- **Settings**: Added a "Dense Show List" toggle in Appearance settings exclusively for the Fruit theme to fit more shows on screen.

### Fixed
- **UI/UX (AMOLED)**: Fixed shadow visibility in True Black mode when glow mode is active.
- **UI/UX (Phone)**: Resolved a double-padding issue on the PlaybackScreen AppBar in phone UI.
- **Tests**: Stabilized multiple regression test suites by resolving dependency ripples in mock providers.

## [1.1.47+147] - 2026-03-04

### Added
- **UI/UX (Phone/Tablet)**: Implemented new "Fruit UI" layout for the `PlaybackScreen` for non-TV platforms, providing a cleaner, more focused mobile experience.
- **Settings**: Added a "Dense Show List" toggle in Appearance settings exclusively for the Fruit theme to fit more shows on screen.

### Changed
- **UI/UX (Web)**: Refined the Fruit theme "Show List" screen on Web/PWA to match the premium "Stitch" vertical card design.
- **UI/UX (Web)**: Updated the Fruit Web app bar to a centered layout featuring the "ShakeDown" title in the Rock Salt font.

### Fixed
- **UI/UX (Phone)**: Resolved a double-padding issue on the `PlaybackScreen` AppBar where it was being redundant offset by the system status bar height.
- **Tests**: Updated several test mocks to support the new `fruitDenseList` property in `SettingsProvider`.

## [1.1.46+146] - 2026-03-04

### Added
- **Screensaver (TV)**: Added `Trail Initial Scale` setting — controls the starting size of the logo trail effect relative to the logo scale (default 92%, range 50–200%), enabling smoother trail-to-logo size relationships.

### Fixed
- **Tests**: Fixed `tv_focus_wrapper_repro_test.dart` — replaced hand-written `ChangeNotifier` stub with proper Mockito `Mock`, added `MockDeviceService`, and disabled `Provider.debugCheckInvalidValueType` to prevent false-positive provider type errors.
- **Tests**: Fixed `tv_regression_test.dart` — restored missing `@override` on `oilScreensaverMode` and `toggleUseNeumorphism`; removed non-existent method stubs (`hapticFeedback`, `customSeedColor`, etc.) that were producing "doesn't override" lint errors.
- **Tests**: Fixed `settings_provider_test.dart` — added missing `await` for `toggleOilEnableAudioReactivity()` to match its `Future<void>` signature.
- **Screensaver**: Fixed `screensaver_screen.dart` — added `mounted` guard before `BuildContext` access after async `Permission.microphone.request()` call to satisfy lint (`use_build_context_synchronously`).

## [1.1.45+145] - 2026-03-04

### Added
- **Infrastructure**: Introduced `env_doctor.py` v4.1.0 for one-shot environment bootstrapping, migrations, and health checking.
- **Agent Workflows**: Added new slash-commands for AI automation: `/screenshot_audit`, `/mock_regen`, `/image_to_code`, and `/session_debrief`.
- **Agent Skills**: Injected specialized skills: `audio_engine_diagnostics`, `dev_tools` (ADB screenshot/logs), and `shipit` (autonomous release pipeline).
- **Static Configs**: Standardized `.editorconfig`, `.gitattributes`, and `.vscode/settings.json` across platforms (Windows/ChromeOS).

### Changed
- **Documentation**: Migrated `docs/RELEASE_NOTES.txt` to root `CHANGELOG.md` (Keep a Changelog format).
- **Agent Rules**: Standardized large monolithic rules into granular, trigger-based modules (e.g., `tv_ui_flow.md`, `fruit_theme.md`, `native_audio.md`).
- **Release Management**: Retired `docs/RELEASE_NOTES.txt`. All history now lives in `CHANGELOG.md`.



### Legacy History (migrated 2026-03-04 from docs/RELEASE_NOTES.txt)

```text
Release 1.1.44+144:
- **Audio Reactivity (TV)**: Fixed default `oilPulseIntensity` (0.0 -> 1.0) so audio-driven movement is visible by default when enabled.
- **Settings (TV)**: Implemented "auto-nudge" logic in `SettingsProvider`—enabling audio reactivity now automatically boosts pulse intensity if it was previously off.
- **UI/UX (TV)**: Exposed Letter and Word spacing controls for the "Flat" banner style, allowing for granular text layout adjustments.
- **UI/UX (TV)**: Relaxed default letter spacing (0.5 -> 1.0) and word spacing (0.05 -> 0.2) in `DefaultSettings` to prevent the "squeezed" look in Flat mode.
- **Documentation**: Conducted a deep architectural audit of the Android Visualizer API and permission requirements for screensaver reactivity.

Release 1.1.43+143:
- **UI/UX (Web/PWA)**: Implemented direct support for the Web Vibration API (`navigator.vibrate`), delivering more reliable haptic feedback across all mobile browsers and PWA installations.
- **UI/UX (Architecture)**: Enforced "Walled Architecture" for the Fruit theme—strictly restricted to Web/PWA platforms. Native Mobile (Phone/Tablet) and TV now force the Android/Material 3 theme for platform consistency.
- **UI/UX (Settings)**: Intelligently hid the theme "Style" selection on native platforms to prevent out-of-spec configuration.
- **UI/UX (TV)**: Refined TV platform gate to allow haptic testing in PWA "Force TV UI" mode while strictly adhering to TV hardware specifications.
- **Fixed**: Resolved compilation and runtime failures in `tv_regression_test.dart` and `onboarding_screen_test.dart` following theme architecture updates.

Release 1.1.42+142:
- **UI/UX (TV)**: Implemented "Tight Border" RGB styling for TvInteractionModal buttons to eliminate visual gaps.
- **UI/UX (TV)**: Standardized modal button radii (12.0) to match main track list highlight aesthetics.
- **UI/UX (TV)**: Added `usePadding` flag to `AnimatedGradientBorder` for high-precision border alignment.
- **Settings**: Adjusted default screensaver inactivity timeout to 1 minute for faster testing and better protection.

Release 1.1.41+141:
- **UI/UX (TV)**: Implemented Global Media Key shortcuts for remote buttons (Play/Pause, Next, Previous) to enhance lean-back control.
- **UI/UX (TV)**: Rerouted system snackbars to the high-visibility `PlaybackMessages` overlay in the top-right to prevent overscan issues.
- **UI/UX (Web/PWA)**: Codified **Stacked Layout** as the mandatory default for PWAs and narrow mobile browsers to ensure optimal touch targets.
- **UI/UX (TV)**: Refined `MiniPlayer` behavior to hide playback controls on full-screen track lists, reducing visual redundancy.
- **Documentation**: Generated a comprehensive TV UI Flow comparison report (`v135` vs `v140`).

Release 1.1.40+140:
- **UI/UX (Web/Fruit)**: Upgraded Mini Player track title with premium "Liquid Glass" and Neumorphism (inset glass etching effect).
- **UI/UX (Web/Fruit)**: Applied "Liquid Glass" recessed glass aesthetic to Date and Venue rows in Show List cards.
- **UI/UX (AppBar)**: Standardized settings icon alignment and refined horizontal padding across all screen AppBars in the Fruit theme.
- **UI/UX (Show List)**: Applied premium Liquid Glass and Neumorphism treatment to rating stars and badges in stacked layout for Web.

Release 1.1.39+139:
- **Workflows**: Converted manual skills into actionable slash-command workflows (`/shipit`, `/inject_debug_tools`, `/test_fixer`, `/glass_audit`, `/tv_flow_audit`).
- **UI/UX (Audit)**: Enhanced `/glass_audit` to be context-aware, specifically detecting Material 3 "leakage" in the Liquid Glass (Fruit) aesthetic.
- **UI/UX (TV)**: Introduced a specialized `/tv_flow_audit` for deep D-Pad focus validation, scale verification, and remote button mapping.
- **Testing**: Added the `test_mocking_templates` skill to the `/test_fixer` workflow for automated resolution of `MissingStubError` and `ProviderNotFoundException`.
- **Optimization**: Refactored the `/checkup` workflow to use token-efficient Dart MCP tools for faster and cleaner code hygiene.

Release 1.1.38+138:
- **UI/UX (Web)**: Generalized `useMobileLayout` to support both Android and Fruit themes on narrow Web viewports.
- **UI/UX (Web)**: Aligned Mini Player controls (play/pause) with the Fruit theme on Web, using glass-styling and pixel-perfect Lucide icons.
- **UI/UX (Web)**: Adjusted relative scaling of playback controls between the Mini Player and full Player Drawer for better visual hierarchy.
- **UI/UX (Web)**: Fixed venue/date text alignment in stacked Android theme cards on Web.
- **Fixed**: Resolved `RenderFlex` overflow in `SourceListItem` during testing.
- **Fixed**: Corrected `SimpleDialog` -> `Dialog` expectation in widget tests.
- **Fixed**: Resolved `ProviderNotFoundException` for `ThemeProvider` in widget tests.

Release 1.1.37+137:
- **UI/UX**: Refined the "Fruit" theme aesthetic to provide a highly curated Apple-style Liquid Glass look and feel.
- **UI/UX**: Introduced Apple Inter Typography styles with sophisticated alpha-transparency matching Dark/Light modes.
- **Settings**: Disabled contradictory "Dynamic Color" (Material You) and custom seed colors automatically when the Fruit aesthetic is active to preserve brand integrity.
- **Audio Player**: Overhauled the Audio Player Drawer, replacing the standard sliding drawer with a translucent frosted-glass pane `LiquidGlassWrapper` matching the Fruit aesthetic.
- **Audio Player**: Changed the player typography to utilize precise sizes and scaling matching premium interfaces and added Apple-style spring physics scaling (bounce back on-tap) to the player's Play/Pause and Skip buttons.
- **Maintenance**: Resolved several minor UI lint errors in the playback stack for a cleaner build.

Release 1.1.36+136:
- **Refactor**: Defined explicit Audio Engine design specs ensuring isolation between Gapless, HTML5, Standard, Passive, and Hybrid implementations.
- **Refactor**: Replaced outdated `.agent/workflows/` directory with the new `SKILL.md` architecture for checkup and release processes.
- **Fixed**: Corrected Hybrid Audio Engine initialization loop issues between foreground and background modes.
- **Testing**: Added rigorous regression tests to enforce audio engine strict specifications and Web Audio stability.

Release 1.1.35+135:
- **Visualizer**: Implemented a noise gate in the Android visualizer to eliminate low-level jitter during silent passages.
- **Visualizer**: Optimized peak tracking to reset after silence, preventing normalization artifacts.
- **Cleanup**: Removed deprecated `PositionAudioReactor` and related dead code.
- **Fixed**: Null safety improvements in `ScreensaverScreen` to prevent initialization race conditions.

Release 1.1.34+134:
- **Audio**: Default engine set to HTML5 for Web/PWA builds, improving background longevity and memory efficiency.
- **Audio**: Hybrid Engine remained as an selectable mode for foreground/background orchestration.
- **Fixed**: Closed leaked StreamControllers in Hybrid and Passive engine Dart wrappers.
- **Documentation**: Comprehensive update to `HYBRID_ENGINE_REPORT.md` reflecting 15 audit issue resolutions.

Release 1.1.33+133:
- **Screensaver**: Implemented beat detection with onset analysis and adjustable Beat Sensitivity slider.
- **Screensaver**: Added Circular EQ visualization mode (8-band radial) alongside upgraded 8-bar Corner EQ.
- **Screensaver**: Graph mode selector (Off / Corner / Circular) replaces the old toggle.
- **Screensaver**: Beat-driven logo pulse effect tied to bass energy detection.
- **Screensaver**: Added Inner Ring Font Scale and Inner Ring Spacing controls for tighter date ring text.
- **Fixed**: PositionAudioReactor `_sine()` now uses `dart:math.sin()` instead of broken modulo.
- **Quality**: All 170 tests passing, zero analysis errors.

Release 1.1.32+132:
- **Fixed**: Proportional text spacing for screensaver rings; fixed large gaps around narrow characters.
- **Internal**: Comprehensive documentation of Hybrid Audio Engine background/restoration behavior.

Release 1.1.31+131:
- **Fixed**: Audio graph visibility issue in Google TV screensaver.
- **Improved**: Inner Ring scale limit adjusted to 0.1 for more granular sizing.
- **Internal**: Resolved test suite regressions and mock stubs for new settings.

Release 1.1.30+130:
- Settings: Implemented system-aware theme selection (System, Light, Dark) for Web, PWA, and Mobile devices.
- TV Settings: Retained the original "Dark Mode" toggle for Google TV to ensure UI consistency.
- Screensaver: Adjusted the inner ring scale range to 0.1 - 1.0 (defaulting to 0.2) in TV Settings.
- UI: Fixed an issue where expanding/collapsing settings sections would retrigger highlight animations.
- Quality: Verified codebase integrity with 100% test pass rate and zero analysis warnings.

Release 1.1.29+129:
- UI: Centered and scaled splash screen checklist items for improved visual balance on all devices.
- Playback: Hardcoded gapless prefetch duration to 30 seconds for optimal stability and performance.
- Web: Implemented dynamic scaling for audio engine segmented button labels to prevent layout overflow.
- Quality: Completed comprehensive codebase checkup; all 170 unit and widget tests passing.

Release 1.1.28+128:
- Settings: Added a hidden setting `omitHttpPathInCopy` (enabled by default) to exclude the Archive.org URL from track detail copies.
- UI: Modified the playback screen's clipboard copy function to respect the new omission setting.
- Engineering: Updated test suites and mocks to maintain 100% pass rate after API changes.

Release 1.1.27+127:
- Screensaver: Implemented dynamic text ring compression to gracefully fit long track titles.
- Screensaver: Added configurable "Letter Spacing" and "Word Spacing" for outer/inner rings.
- Screensaver: Added "Above/Below" placement options and adjustable "Line Spacing" for Flat Mode text.
- Screensaver: Introduced a real-time, 4-bar Audio Reactivity Graph (Bass, Mid, Treble, Overall) powered by Flame.

Release 1.1.26+126:
- UI: Refined splash screen checklist alignment (centered block, left-aligned content).
- UI: Stabilized splash screen checkbox positioning during numeric animations by enforcing fixed-width anchors.
- Web/PWA Settings: Left-aligned "Web Audio Engine" segmented button and label to match setting tile aesthetics.
- Web/PWA Settings: Implemented automatic scaling for audio engine labels to prevent overflow on mobile.
- Maintenance: Integrated Dart MCP for advanced codebase analysis and health checks.

Release 1.1.25+125:
- Web/PWA: Added hamburger back-navigation to Playback Screen for improved desktop/browser flow.
- PWA: Implemented "Smart Splash" logic — splash screen now auto-toggles off after the first run for faster subsequent startups.
- Web: Optimized default source category filters to "Matrix only" for a focused initial experience.
- UI: Stabilized splash screen numeric animations by enforcing monospaced "tabular" figures and fixed layout anchors.
- UI: Refined RGB animation speed button with pixel-perfect border alignment and fixed web rendering artifacts.

Release 1.1.24+124:
- Screensaver: Optimized text and logo motion smoothness by implementing high-quality bicubic filtering.
- Screensaver: Added performance-aware filtering logic that respects "Performance Mode" for Google TV stability.

Release 1.1.23+123:
- Screensaver: Implemented high-fidelity supersampling for text rendering to ensure ultra-sharp track information on 4K/1080p TV displays.
- Screensaver: Added adjustable "Text Resolution" setting (1.0x to 4.0x) in TV Settings for custom clarity control.
- Screensaver: Optimized glyph caching to automatically re-rasterize Sharpness, Font, or Glow changes.

Release 1.1.22+122:
- PWA: Fixed visibility of playback messages on narrow screens using isolated scaling (FittedBox).
- PWA: Improved "Next" track indicator visibility logic to prevent UI jumping.
- Web: Optimized HTML5 engine transitions to significantly reduce silent gaps between songs.
- Web: Implemented buffer hand-off in HTML5 engine to prevent "Buffered: 0:00" display reset on track start.

Release 1.1.21+121:
- Web: Fixed a critical regression in Web Audio gapless playback where transitioned tracks were being skipped by the watchdog.
- Web: Increased the gapless prefetch window to 90 seconds to improve reliability on slower connections.
- Web: Fixed UI bug where the main buffering bar would reset to 0% after a gapless transition.
- Web: Renamed "Relisten Engine" to "HTML5 Audio Engine" for architectural clarity.
- Core: Hardened BufferAgent to prevent infinite recovery loops in browser environments.
- Backlog: Documented "Hybrid Audio Engine" concept for future instant-start gapless playback.

Release 1.1.20+120:
- Web: Implemented Hybrid Audio Architecture — desktop uses GDAR Web Audio API (0ms gapless) and mobile auto-switches to Relisten-style HTML5 dual-<audio> streaming engine.
- Web: New relisten_audio_engine.js delivers near-gapless playback on mobile via dual HTMLAudioElement swap, saving RAM/data and preventing browser tab kills.
- Web: New hybrid_init.js auto-detects mobile vs desktop via userAgent + touch points and routes window._gdarAudio transparently — no Dart interop changes required.
- Settings: "Gapless Engine" toggle now shows "HTML5 Audio Engine" on mobile viewports with context-aware subtitle; toggling shows a SnackBar requiring page reload.
- Settings: Prefetch Ahead setting now controls load timing for both strategies.

Release 1.1.19+119:
- UI (Web & Mobile): Updated the playback messages (buffered time and next time indicator) to use the default Roboto font for better legibility.
- UI (TV): Fixed an issue where the Steal Screensaver text font setting was not being correctly applied due to a font family name mismatch.

Release 1.1.18+118:
- Web: Fixed UI sync issue where playback progress and metadata were stale in the mini-player.
- Testing: Implemented 8 new regression tests for the Web Player adapter's stream contract.
- Documentation: Major overhaul of README and TODOs for TV UI, Web Gapless, and PWA features.
- Quality: Full test suite (170 tests) verified passing with zero analysis errors.

Release 1.1.17+117:
- Screensaver: Optimized rendering for Google TV by removing redundant black drop shadows and simplifying neon glow (removed expensive atmospheric layer).
- Maintenance: Added regression testing and Web UI sync roadmap to project backlog.
- Quality: Unified health check passing (0 analysis errors, 162/162 tests, formatting verified).

Release 1.1.16+116:
- Web: Implemented true gapless playback for Web using a low-latency JavaScript GaplessAudioEngine (Web Audio API).
- UI: Fixed playback controls scaling on small phones/high UI scales by making panel height responsive.
- Quality: Unified health check passing (0 analysis errors, 162/162 tests, formatting verified).

Release 1.1.15+115:
- Screensaver: Implemented font selection (Roboto vs. Rock Salt) for the TV screensaver's track information display.
- Security: Isolated Firebase credentials into gitignored firebase-config.js.
- Verification: Unified health check passing (0 analysis errors, 162/162 tests, formatting verified).

Release 1.1.14+114:
- Web: Fixed background playback stall by implementing visibility-based context resume, eager prefetching, and an audio watchdog timer.
- Web: Dice playback now triggers audio immediately on show selection (autofocus policy fix).
- Verification: 162/162 tests passing, zero analysis errors.

Release 1.1.13+113:
- Web: Fixed startup crash by loading gapless_audio_engine.js in index.html (TypeError: null is not a JSObject).
- Web: Bypassed archive.org CORS-blocked reachability check; audio streaming via <audio> elements is unaffected.
- Verification: 162/162 tests passing, zero analysis errors.

Release 1.1.12+112:
- Screensaver: Implemented custom text proximity and placement (Below/Right) for flat mode.
- SDK: Updated minimum Dart SDK to 3.3.0 to support modern language features.
- Maintenance: Resolved project-wide static analysis warnings and enforced strict formatting.
- Verification: 100% pass rate across 162 unit and widget tests.

Release 1.1.11+111:
- Screensaver: Implemented high-precision stability for flat mode, eliminating timing skew between update/render cycles.
- Visuals: Added time-corrected motion smoothing for jitter-free logo tracking at any frame rate.
- Layout: Dynamic ring scaling now tracks logoScale for proportional orbiting at all sizes.
- Polished: Refined flat mode text spacing and optimized internal banner logic.

Release 1.1.9+109:
- Quality: Resolved project-wide unawaited_futures lint errors for improved code predictability.
- Architecture: Refactored AudioProvider playback methods (play, pause, etc.) to return Future<void> for consistent async handling.
- Stability: Synchronized test mocks with new AudioProvider signatures to ensure suite integrity.
- Verification: Completed successful release build with 0 analysis errors.

Release 1.1.8+108:
- Visuals: Implemented secondary smoothing and sub-pixel precision for "flat" screensaver mode to eliminate residual jitter.
- UI: Refined system bar transparency handling by relying on Material 3 theme defaults.
- Settings: Optimized TV screensaver section by hiding experimental Trail Effect controls.

Release 1.1.7+107:
- Quality: Successfully completed a comprehensive codebase health check.
- Testing: All 162 unit and widget tests passing.
- Stability: Verified mock stability and formatting consistency.

Release 1.1.6+106:
- Stability: Finalized mock regeneration for MockSettingsProvider to resolve TypeError failures.
- Verification: 162/162 unit and widget tests passing consistently.
- Service: Confirmed BufferAgent robustness against simulated network errors.
- Quality: Comprehensive health check passed with zero analysis errors.

Release 1.1.5+105:
- Feature: Added "Enable Swipe to Block" toggle in Settings -> Interface -> Gestures.
- UI: Show list gestures now respect the "Swipe to Block" setting to prevent accidental blocks.
- Stability: Resolved mock deficiencies in screensaver tests for improved consistency.
- Quality: Passed comprehensive health check with zero analysis errors and 160+ passing tests.

Release 1.1.4+104:
- Verification: Comprehensive health check passed with 160 unit/widget tests.
- Style: Enforced consistent Dart formatting across the entire codebase.

Release 1.1.3+103:
- Verification: Unified health check passing (0 analysis errors, 160/160 tests, formatting verified).
- Maintenance: Finalized session logs and internal documentation updates.

Release 1.1.2+102:
- Android 15: Implemented Phase 1 Edge-to-Edge compliance with transparent system bars.
- UI: Enforced system navigation bar contrast while preserving True Black AMOLED mode.
- Verification: Unified health check passing (0 analysis errors, 160/160 tests, formatting verified).

Release 1.1.0+101:
- Stability: Resolved `RangeError` in Screensaver background by ensuring immediate color initialization and adding index guards.
- Stability: Fixed duplicate recovery bug in `BufferAgent` by implementing atomic locking for recovery operations.
- Verification: 100% test pass rate across all 160 unit and widget tests.

Release 1.1.0:
- Verification: Unified codebase health check passing with 160 unit and widget tests.
- Internal: Resolved latent regression in SettingsProvider default values.
- Internal: Finalized specialized neon flicker pattern logic in StealBanner.
- Workflow: Standardized production health checks using Dart MCP.

Release 1.0.99:
- Steal Screensaver: Enhanced Neon Flicker effect with desynchronized buzzing, dropout, and recovery phases.
- Checkup Workflow: Upgraded to use Dart MCP tools for structured analysis, formatting, and testing.

Release 1.0.98:
- UI: Refined `FastScrollbar` with Material 3 expressive design and smoother animation.
- Stability: Hardened `AudioCacheService` to prevent race conditions during directory iteration.
- Stability: Fixed `FakeSettingsProvider` compliance for TV playback tests.
- Verification: Completed full project-wide health check with 160+ passing tests.

Release 1.0.97:
- UI (Show List): Implemented M3 expressive `FastScrollbar` with year-chip overlay and spring-loaded thumb.
- Stability: Added comprehensive widget tests for `FastScrollbar` and resolved timer lifecycle leaks.
- Verification: Verified 100% test pass rate across 160+ unit and widget tests.

Release 1.0.96:
- Stability: Hardened `AudioCacheService` to prevent race conditions during cache directory iteration (fixes `PathNotFoundException`).
- Stability: Resolved `ProviderNotFoundException` in playback message tests by properly mocking `DeviceService`.
- Stability: Synchronized screensaver test mocks with the 3-ring visualizer model to resolve null errors.
- Internal: Refined `steal_banner.dart` casting and cleaned up lint warnings in TV settings components.

Release 1.0.95:
- UI (Screensaver): Added "Ring Controls" for deep customization of the text rings (Scale, Gap, and Orbit Drift).
- UI (Screensaver): Increased default ring sizes for improved legibility on large TV displays.
- UI (TV): Exposed new visualizer ring parameters in the Settings menu under Info Banner options.
- Stability: Resolved test regressions in TV dual-pane and playback screen mocks.

Release 1.0.94:
- UI (Screensaver): Added Blur Amount and Flat Color modes for deeper visual customization.
- UI (Screensaver): Implemented professional Neon Glow and Flicker effects for the circular banner.
- UI (TV): Redesigned palette selection as a sleek, high-contrast list with live color previews.
- UI (TV): Exposed high-precision Audio Reactivity tuning (Peak Decay, Bass Boost, Strength).
- UI (Playback): Rating stars now always display (showing outlines for unrated shows) for better feedback.
- Stability: Refined shader color padding to prevent edge-case interpolation artifacts.

Release 1.0.93:
- UI (Playback): Refined header layout with Rating stars and Source badge stacked in a clean right-aligned column.
- UI (Playback): Native `SrcBadge` styling matched to the show list "shnid" look for visual consistency.
- UI (Screensaver): Precision dual-ring metadata display with clockwise/counter-clockwise motion.

Release 1.0.92:
- UI (Screensaver): Dual-ring metadata display. Outer ring (Venue/Date) and Inner ring (Track) now rotate in opposite directions with smooth fade-through transitions.
- UI (Playback): Redesigned header with reactive Rating stars, stadium icons, and location details.
- UI (TV): Improved font rendering in Playback Messages by forcing standard system fonts.
- UI (TV): Cleaner Collection Statistics view with streamlined category rows.

Release 1.0.91:
- Test Regression Cleanup: Fixed palette fallback and mock stubs.
- Verfication: Confirmed stability of Woodstock Mode detector.

Release 1.0.90:
- Feature: Woodstock Mode — A special 4:20 PM easter egg with a gold and green psychedelic theme.
- UI (Screensaver): The text banner now orbits the logo in a meditative Lissajous path.
- UI (Screensaver): Implemented automated, meditative palette cycling logic in the core visualizer.
- UI (TV): Added a setting to toggle Source Category Details for a cleaner Collection Statistics view.
- Maintenance: Removed all references to outdated `oilFilmGrain` setting and optimized shader performance.

Release 1.0.88:
- UI (TV): Improved `TvStepperRow` with repeat-key support, allowing for rapid adjustment when holding down D-pad Left/Right.
- UI (TV): Refactored `StealBanner` for more efficient and robust rendering of circular show/track metadata.
- UI (TV): Fixed tracked metadata visibility in the screensaver banner to correctly respect the "Show Track Info" setting.

Release 1.0.87:
- UI (TV): Implemented smooth, buttery palette transitions in the Shakedown Screensaver using color interpolation.
- UI (TV): Added "Logo Scale" control to Screensaver settings for fine-tuning the visual impact.
- UI (TV): Standardized Screensaver settings pane with consistent `TvStepperRow` controls.
- Stability: Fixed a critical GLSL shader compilation error in `steal.frag` (stray brace).
- Stability: Fixed mock providers in unit tests to match latest SettingsProvider interface.

Release 1.0.86:
- UI (TV): Enabled the expressive "flying" Hero animation for the "Shakedown" title during app initialization.
- UI (TV): Reorganized Screensaver settings, centralizing "Prevent Sleep" and "Inactivity Timeout" for better ergonomics.
- UI (TV): Set the Screensaver to be enabled by default for new installations.
- UI (TV): Fixed a text clipping issue on the Splash Screen affecting "Archive.org reachable" status labels.
- Screensaver: Implemented the missing "Heat Drift" shader effect, enabling functional wavy distortion controls.
- Stability: Resolved a critical unit test regression in the onboarding flow related to recent ThemeProvider updates.

Release 1.0.85:
- UI (TV): Refined left navigation flow from scrollbars in both Show List and Track List to intelligently focus the middle visible item without scrolling.
- UI (TV): Fixed focus stability in Track List by ensuring robust mounting of dynamically created focus nodes.
- UI (TV): Standardized Track List header with 'RockSalt' font branding (Date, Venue, Location).
- UI (TV): Decluttered Playback settings by removing the manual Color Palette selector and redundant toggle sections.

Release 1.0.84:
- UI (TV): Finalized `TvStepperRow` integration across all screensaver parameters for precise D-Pad control.
- UI (TV): Added a "Show Track Info" toggle to the Playback settings section.
- Stability: Resolved critical unit test regressions in `ShakedownTitle` (mock services) and TV UI (Material ancestor requirements).

Release 1.0.83:
- UI (TV): Introduced `TvStepperRow`, a native TV control for numeric settings (Flow Speed, Strength, etc.) featuring D-Pad focus and arrow-key repeat support.
- Focus: Improved navigation in TV Screensaver settings with `FocusTraversalGroup` and `autofocus` on selected palettes.
- UI: Unified palette selection logic in `PlaybackSection` with haptics and consistent focus wrapping.

Release 1.0.82:
- Stability: Resolved a critical issue where the screensaver could re-trigger and stack multiple instances (white screen bug) by silencing inactivity detection during active playback.
- Defaults: Updated default application font to "Rock Salt" and the screensaver palette to "Acid Green" for a cleaner initial experience.
- UI (TV): Standardized "Shakedown" branding on Google TV to always use the "Rock Salt" font regardless of global settings (Header, Splash, and About screens).
- Internal: Migrated seed color serialization to `toARGB32()` to resolve Flutter deprecation warnings.

Release 1.0.81:
- Stability Fix: Resolved screensaver stacking/white-screen bug by properly pausing the inactivity service via a state-guarded lifecycle.
- UI Refinements: Migrated all playback settings to the "Steal" branding and added audio reactivity sliders to the unified playback section.
- Native Improvements: Hardened app orientation for TV devices and finalized the migration to native black themes.

Release 1.0.80:
- Screensaver Logic: Fixed an issue where the screensaver could re-trigger and stack multiple instances by correctly managing the InactivityService lifecycle.
- App Hardening: Streamlined main navigation and theme logic, ensuring clean transitions and stable orientation handling on TV hardware.

Release 1.0.79:
- Native Black Themes: Updated styles.xml to use Theme.Black for both LaunchTheme and NormalTheme, eliminating initialization flashes on all devices.
- Screensaver Robustness: Refined StealBackground to use canvas.drawPaint for more robust fallback rendering and cleaned up engine lifecycle handling.

- Screensaver Hardening: Migrated StealBackground to HasGameReference and utilized rootBundle for texture loading to bypass Flame cache path issues.
- Rendering Stability: Added numeric clamping to shader uniforms and safe-region checks to prevent initialization flashes or crashes on low-spec hardware.

- Visualizer Live Tuning: Introduced real-time adjustment of Peak Decay, Bass Boost, and Reactivity Strength in the native Android engine.
- Google TV Screensaver Settings: Added a dedicated settings section with sliders for flow speed, pulse intensity, film grain, and audio reactivity.
- Performance Enhancements: Optimized shader complexity and improved lifecycle management for the Screensaver on TV devices.
- Test Stability: Fixed mock implementations to align with the expanded SettingsProvider interface.

Release 1.0.76:
- Visualizer Engine Upgrade: Implemented RMS logic, rolling peak normalization (AGC), and exponential smoothing in VisualizerPlugin.kt for a smoother, more responsive reactive experience.
- Screensaver Migration: Fully migrated ScreensaverScreen to use the high-fidelity StealVisualizer, removing legacy OilSlide components.
- TV Stability: Hardened keyboard event handling and wakelock lifecycle for more reliable performance on Google TV hardware.

Release 1.0.75:
- Added black loadingBuilder to GameWidget in StealVisualizer to eliminate the brief white flash during engine initialization.
- Verified screensaver stability and asset loading on TV-spec hardware.

Release 1.0.74:
- Added explicit black background to GameWidget in StealVisualizer to prevent white screen flickers on Google TV.
- Overrode backgroundColor in StealGame to ensure consistent black backdrop during game initialization.
- Hardened screensaver components against unexpected transparency or color overflow.

Release 1.0.73:
- Fix "White Screen" issue on Google TV screensaver via shader hardening.
- Implement high-precision floats and robust guards in visualizer shader.
- Defensive color normalization for cross-version Flutter compatibility.

1.0.72:
- **Simplified**: Screensaver has been simplified to the "Steal Your Face" mode only (Lava Lamp and Silk modes removed).
- **Audit**: Completed a comprehensive Dead Code Audit, removing 9+ diagnostic files and cleaning up legacy comments.
- **Fixed**: Resolved all IDE deprecation warnings in the screensaver (HasGameReference, Color getters) and updated test mocks.
- **Improved**: Standardized naming conventions in internal comments for better maintainability.

Release 1.0.71:
- **Internal**: Implemented full-screen solid color diagnostics (Green=Steal, Blue=Lava, Yellow=Silk, Red=Error) to isolate hardware-specific rendering issues.

Release 1.0.70:
- **Internal**: Added diagnostic rendering modes to the screensaver to troubleshoot "White Screen" issues on specific hardware.
- **Fixed**: Hardened Dart-side component rendering to prevent initialization with zero resolution.
- **Improved**: Added color output clamping to the shader to prevent over-exposure.

Release 1.0.69:
- **Fixed**: Resolved a "White Screen" issue on the screensaver by hardening the visualizer's resize handling and adding shader-level safeguards.
- **Improved**: Added division-by-zero protection to the `oil_slide` shader for better hardware compatibility and stability.
- **Improved**: Enhanced visual mode detection in the shader for more reliable rendering across different platforms.

Release 1.0.68:
- **Improved**: Replaced the screensaver inactivity timeout slider with a discrete `SegmentedButton` (1, 5, 15 min) for better TV navigation.
- **Fixed**: Enforced valid timeout values in `SettingsProvider` to ensure data integrity.
- **Polished**: Verified screensaver timeout logic and focus handling with new unit tests.

Release 1.0.67:
- **Fixed**: Resolved a critical "Focus Loop" on Google TV where exiting the screensaver would immediately re-trigger it.
- **Improved**: Hardened `TvFocusWrapper` to ensure tactile events only trigger when button press sequences match.
- **Internal**: Stabilized automated test suite by resolving environmental hangs and improving mock reliability.

Release 1.0.66:
- **Fixed**: Resolved a persistent hang in the automated test suite related to shader/texture loading.
- **Fixed**: Verified 100% pass rate for Screensaver and TV Playback logic after component refactoring.
- **Internal**: Hardened test mocks and added timeouts to prevent CI/CD pipeline stalls.

Release 1.0.65:
- **Visuals**: Switched to a high-fidelity screensaver texture (`t_steal_ss.png`) for the "Steal Your Face" mode.
- **Improved**: Optimized logo rendering to use native 192px resolution for maximum clarity on 4K and 1080p screens.
- **Internal**: Fixed an SkSL shader compilation error related to dynamic loop limits, ensuring compatibility with all Flutter renderers.
- **Fixed**: Removed temporary test files and resolved IDE mock generation issues.

Release 1.0.64:
- **Restricted**: Screensaver execution is now strictly limited to Google TV devices only.
- **Restricted**: Screensaver settings (Style, Timeout) are now hidden on non-TV platforms, even in debug mode.
- **Internal**: Fixed unit test compatibility issues and updated deprecated mock handlers for modern Flutter support.

Release 1.0.63:
- **Optimized**: Significant performance improvements for Google TV screensavers (Lava, Silk, Standard).
- **Improved**: Automatic "Performance Mode" detection for TV hardware.
- **Improved**: Reduced shader complexity (FBM octaves, metaballs, shading) for smoother frame rates.
- **Fixed**: Resolved issue where onboarding was incorrectly showing on Google TV.
- **Fixed**: Synchronized boot-up sequence for reliable TV status detection.

Release 1.0.62:
- **Fixed**: Resolved black screensaver on Google TV by ensuring fallback texture binding and consistent image sampler usage.
- **Fixed**: Added "Start Screensaver" button to TV Settings for manual trigger.
- **Improved**: Suppressed experimental lint warnings in `AudioCacheService` for a cleaner build.
- **Polished**: Verified screensaver robustness with passing unit tests.

Release 1.0.61:
- **Fixed**: Resolved double-trigger of random show playback on TV devices.
- **Fixed**: Resolved shader compilation error for `oil_slide.frag` and added regression testing.
- **Fixed**: Corrected focus handling for "Visual Style" and "App Mode" settings on TV; users can now cycle options with D-pad.
- **Refined**: "Steal Your Face" screensaver now applies color cycling to the logo instead of the background for a cleaner look.

Release 1.0.60:
- **Hotfix**: Restored Android TV support by marking microphone requirement as optional, while keeping the Visualizer active for supported devices. 

Release 1.0.58:
- **Visuals**: Introduced "Lava Lamp" and "Silk" visual modes for the screensaver with high-fidelity effects.
- **Improved**: Screensaver now supports vertical convection for Lava Lamp and flowing ribbon simulation for Silk.
- **Fixed**: Resolved `WakelockPlus` platform channel issues to ensure robust audio playback reliability.
- **Tests**: Enhanced test coverage for `AudioProvider` and `ScreensaverScreen` to prevent regressions.

Release 1.0.57:
- **TV Reliability**: Integrated specific "Network issue" notifications into the playback UI, ensuring users are informed of buffer recovery attempts.
- **Unit Tests**: Added comprehensive test suite for `PlaybackMessages` to verify buffer agent notification logic.
- **Fixed**: Resolved compilation errors in `AudioProvider` and `TvSettingsScreen` for a stable build.
- **Polished**: Removed duplicate imports and cleaned up code based on lint feedback.

Release 1.0.55:
- **TV Rated Shows Grid**: Implemented a high-density 5-column grid for the Rated Shows Library on Google TV, allowing users to see 25+ shows at once.
- **Unified Library Section**: Consolidated Collection Statistics and Rated Shows management into a new 'Library' section across both mobile and TV apps.
- **TV Tabbed Layout**: Standardized the Rated Shows screen on TV with a top-level tabbed navigation (Played, Stars, Blocked), matching the mobile flow but scaled for the big screen.
- **Premium Aesthetics**: Enhanced TV tab labels and indicators with larger typography and optimized D-pad focus management for a seamless "lean-back" experience.
- **TV Track List Progress**: Added a slim progress and buffer indicator to the active track in the list view (TV only) to improve playback visibility from a distance.
- **Default Visuals**: The "RGB Border" for the currently playing track is now **Enable by Default** for a more dynamic initial experience.

Release 1.0.54:
- **Unified Library Category**: Reorganized Google TV settings to include a dedicated "Library" category, consolidating the Rated Shows link and Collection Statistics.
- **TV Interaction Modal**: Added a specialized "Play or Rate" choice when long-pressing shows or sources on TV, optimized for remote controls.
- **Optimized Rating Dialog**: Re-engineered the rating interface for Google TV, supporting D-pad horizontal adjustment and tactile feedback.
- **TV Playback Visuals**: Added venue/location icons and integrated operational messages into the track list header for a cleaner, unified aesthetic.

Release 1.0.53:
- **TV Navigation Refinement**: Implemented "Wrap + Anchor" focus logic for both Track List and Show List. Focus now wraps at boundaries on initial press and stays anchored during button holds to prevent unintended jumps.
- **Improved Show List Scrolling**: Lateral navigation from the show list scrollbar now intelligently focuses the middle-visible item.
- **Resolved Focus Traps**: Full D-pad control restored for Appearance settings (Intensity Slider and RGB Speed SegmentedButton).
- **Clean TV UI**: Clarified playback status with persistent per-track indicators (Spinner/Play/Pause) instead of a global bar.
- **Visual Polish**: Increased contrast for TV vertical dividers and deepened inactive pane dimming for better focus clarity.

Release 1.0.52:
- **TV Visuals**: Implemented RGB animated border for the currently playing track on TV, matching the mobile experience.
- **TV Navigation**: Improved focus styles on TV for tracks and show list items (border-only highlight).
- **TV Controls**: Center D-pad (Select) now toggles Play/Pause on the currently playing track.
- **TV Polish**: Replaced "TRACK LIST" header with Show Date and Venue, and fixed the blurry TV launcher icon.

Release 1.0.51:
- **TV UI Density**: Optimized list sizing for 10-foot UI to show more items (10+).
- **Focus Navigation**: Improved D-pad navigation flow and "High Contrast" focus indicators.
- **Performance**: Removed focus scaling on track lists to prevent layout shifts.
- **Verification**: Comprehensive test suite passed with no regressions.

Release 1.0.50:
- **Navigation**: Implemented "leak-proof" circular navigation for TV—focus now wraps seamlessly between edges and vertical layers.
- **TV Controls**: Upgraded the Playback Bar with an intuitive "staircase" vertical flow (Progress ↔ Play/Pause ↔ Content).
- **Settings**: Standardized premium focus indicators across all settings sections using new TV-optimized list tiles.
- **Improved**: Optimized TV Header by removing unused elements and ensuring direct Dice-to-Settings navigation.

Release 1.0.49:
- **New**: Circular Navigation Wrap-Around—Focus now jumps between far-left and far-right elements for a "leak-proof" TV experience.
- **Improved**: Settings Focus Safety—Upgraded all interactive settings sections (Appearance, Data, About) with premium focus indicators.
- **Polished**: Consistent Focus Logic—Introduced `TvListTile` and `TvRadioListTile` to ensure high-quality tactile feedback across the TV UI.

Release 1.0.48:
- **Polished**: Synchronized Random Play dice animations across all mobile and TV screens.
- **Improved**: TV Main Screen—Floating playback bar now stays hidden until music is actively loaded.
- **Fixed**: TV Long Press—Resolved issues with D-pad repeat events to ensure reliable long-press detection.
- **Cleaned**: Refined dual-pane layout logic and synchronized state management for a smoother TV experience.

Release 1.0.47:
- **Visuals**: Cleaned up the Google TV main screen by disabling the unwanted shadow glow on focused items.
- **Improved**: Playback Navigation—Fixed the "stuck" progress slider; Left/Right now seeks while Up/Down moves focus normally.
- **Navigation**: Enhanced TV Scrollbars—You can now scroll lists using Up/Down while focused on the scrollbar, and Left/Right switches panes.
- **Stability**: Implemented multi-layer guards to ensure the onboarding flow is always skipped on TV devices.

Release 1.0.46:
- **New**: Google TV Settings Overhaul—Implemented a dedicated split-view layout for faster navigation on large screens.
- **Improved**: D-pad accessibility—All usage instructions and filter badges are now focusable and interactive via the TV remote.
- **Visuals**: Enhanced TV focus states with customizable highlight colors and refined "Pill" card aesthetics.
- **Polished**: Integrated TvSwitchListTile and TvFocusWrapper across the settings screen for a premium, native TV experience.

Release 1.0.45:
- **New**: Multi-Source Focus—D-pad now correctly highlights and selects individual sources in the show details.
- **Convenience**: Long-press any show on Google TV to play immediately; the app automatically finds the highest-rated source for you.
- **Smart Onboarding**: Application now intelligently skips the initial setup when running on a TV for a faster "Leaning Back" entry.
- **Visuals**: Refined Dual-Pane layout with 48dp horizontal breathing room, improved inactive pane dimming (40% opacity), and a more subtle glass divider.
- **Improved**: Significantly increased Show List Card height (76.0) and vertical spacing (12.0) for better visibility on large screens.
- **Polished**: Enhanced Material 3 focus rings with smoother spring-based scaling animations and optimized text scaling.

Release 1.0.44:
- **Polished**: Enhanced TV Show List visuals with authoritative "Scale Fit" typography for Venue and Date.
- **Improved**: Increased Show List Card height and vertical spacing on TV for a more spacious, premium feel.
- **Visuals**: Added a subtle vertical glass divider and expanded horizontal margins (24.0) to frame the 50/50 dual-pane layout.
- **Dynamic**: Implemented inactive pane dimming (60% opacity) to clearly guide the user's focus during navigation.

Release 1.0.43:
- **Improved**: Refined Google TV UI scaling by reducing the global multiplier (1.5x -> 1.2x) for a cleaner, high-density experience.
- **Fixed**: Resolved "Duplicate AppBar" issue on Google TV where the Header appeared twice in dual-pane mode.
- **Polished**: Standardized Show List card scaling on TV to maintain visual harmony with the Playback pane.

Release 1.0.42:
- **Improved**: Hardened Screen Tests by implementing robust `DeviceService` mocking, resolving all provider-related failures.
- **Stability**: Verified 100% test pass rate for all Providers and Screen components.
- **Optimized**: Finalized Google TV UI optimizations for a premium "Leaning Back" experience.

Release 1.0.41:
- **New**: Side-by-side Onboarding layout optimized for landscape Google TV screens.
- **New**: Long-click support for remote control "Select" buttons to trigger secondary actions (Quick Play/Shuffle).
- **Refined**: Restored missing Header on TV Show List screens, enabling Search and Settings access.
- **Premium**: Enhanced Dual-Pane layout with optimized 3:7 flex ratio and relaxed paddings for a more expansive experience.

Release 1.0.40:
- **New**: Optimized Google TV Onboarding—The app now supports Landscape orientation for cinematic TV experience.
- **Improved**: Tailored D-pad navigation on TV—"Next" button now correctly responds to the remote control "Select" click.

Release 1.0.39:
- **Internal**: Targeted Android 15 (API Level 35) to comply with updated Google Play Store requirements.

Release 1.0.38:
- **Fixed**: Restored support for Phone and Tablet devices. 1.0.37 inadvertently limited support to TV devices only.

Release 1.0.37:
- **New**: Google TV / Android TV Support! Experience the app on the big screen with a tailored "10-foot UI".
- **New**: TV Dual-Pane Layout—Show browsing on the left, immersive playback on the right.
- **Premium**: Integrated Material 3 Focus states with spring-based scaling and glow borders for D-pad navigation.
- **Improved**: Adaptive Typography—Font sizes now scale up by 1.5x on TV for maximum legibility from a distance.
- **Polished**: Glassmorphism and Backdrop Blur effects applied across the TV interface for a premium, modern feel.
- **Feature**: Full Onboarding and Splash Screen support on TV with D-pad focus management.
- **Hardened**: Targeted Android 14 (API 34) for modern platform compatibility and performance.

Release 1.0.36:
- **New**: Smart Pre-Load Agent for "Advanced Cache"—show tracks are now gracefully pre-loaded in the background.
- **Improved**: Playback stability during transitions; pre-loading begins automatically for the next show in the queue.
- **Audit**: Refined `AUDIO_CACHE_AUDIT.md` to reflect full-source graceful caching behavior.
- **Internal**: Hardened `AudioCacheService` with sequential download logic and robust cancellation support.

Release 1.0.32:
- **Audit**: Completed a comprehensive Release & Optimization audit.
- **Performance**: Verified build size (23MB) and asset health; identified key optimization targets.
- **Quality**: Confirmed 100% test pass rate (122/122) and verified code linting/formatting.
- **Stability**: Hardened Offline Buffering and Buffer Agent logic with comprehensive regression tests.
- **Audit**: Completed a technical audit of the SHA-256 audio cache implementation and LRU cleanup strategy.
- **Improved**: Hardened dependency management and identified discontinued packages for future migration.

Release 1.0.31:
- **New**: Deep Link Manifest workflow (`/report_deep_links`) for generating comprehensive documentation.
- **Improved**: Consolidated agent configuration and workflows into a unified `.agent` directory.
- **Security**: Hardened production builds by restricting internal navigation and configuration deep links to debug mode only.
- **Polished**: Refined Onboarding pages with clearer instructions and improved Gemini Assistant usage tips.
- **Improved**: Aligned Android build configuration with AGP 8.9.1 and Kotlin 2.1.0 for modern dependency compatibility.

Release 1.0.30:
- **Improved**: Refactored the app update mechanism to redirect users directly to the Google Play Store for a smoother, native update experience.
- **Fixed**: Resolved a critical Android compilation error caused by stale plugin registration files.
- **Internal**: Regenerated test mocks and verified consistency across the entire project.

Release 1.0.29:
- **GA Readiness**: Completed a full clinical audit and cleanup of the codebase for production.
- **Production Hardening**: Strictly guarded all debug-only deep links (UI scaling, font selection, reset tools) for secure release builds.
- **Improved**: Standardized internal documentation to explain "Why" over "What" logic across core providers and the main entry point.
- **Stability**: Verified 100% test success (121/121) across the entire suite.
- **Optimized**: Confirmed native WebP support for iOS 14+; initiated release asset footprint reduction roadmap.

Release 1.0.28:
- **Restored**: Swipe-to-block is now available for ALL shows on the main list.
- **Improved**: Blocking a multi-source show from the main list now specifically blocks the representative source.
- **Fixed**: Resolved a critical crash where the missing CatalogService provider prevented swiping functionality.
- **Unified**: SnackBar feedback now correctly shows "ROLL" or "NEXT" based on your playback settings.

Release 1.0.27:
- **Polished**: Update banner now immediately shows "Waiting to download..." upon confirmation, providing instant feedback.

Release 1.0.26:
- **Fixed**: Resolved issue where update notifications could be missed if the app was closed during a download.
- **Improved**: Update checks now persist and resume status correctly on cold start.
- **Polished**: Refined usage instructions with better clarity on source filtering and deep link pasting.

Release 1.0.25:
- **Fixed**: Resolved issue where "Advanced Cache" description was not updating track counts.
- **Improved**: Isolated audio cache to a dedicated directory for faster and safer file management.
- **Improved**: Implemented robust SHA-256 regex scanner for identifying cached tracks.

Release 1.0.24:
- **Improved**: Polished Splash Screen checklist items for better brevity.
- **Fixed**: Updated Archive.org connection labels.

Release 1.0.23:
- **Refactor**: Premium M3 Expressive Playback UI overhaul with a layered architecture and immersive scrolling.
- **Improved**: Standardized Playback App Bar height to 56.0 (kToolbarHeight) for visual consistency with the main show list.
- **Improved**: Compacted Playback App Bar by removing redundant venue information and centering key metadata (Date, Source, Rating).
- **New**: Implemented "Top Area Stabilizers" to ensure smooth visual transitions and hide track list artifacts during edge-to-edge scrolling.

Release 1.0.22:
- **Improved**: Aligned styling for "About App" and "Rated Shows" sections in Settings for visual consistency.
- **Improved**: Completed integration of the update banner in the Settings screen.
- **Fixed**: Ensured update availability is visible even if onboarding is skipped.

Release 1.0.21:
- **Audit**: Completed a comprehensive file size and storage audit.
- **Improved**: Identified and documented high-impact optimization targets (>1MB icons and 8.8MB JSON).
- **New**: Added a "Storage & Optimization" roadmap to the project's long-term tasks.
- **Fixed**: Hardened app startup initialization logic and resolved several UI scaling inconsistencies.

Release 1.0.20:
- **Refactor**: Major architectural overhaul of the Show List screen—extracted UI into modular "Shell" and "Body" components and moved business logic to a dedicated Mixin.
- **Improved**: Significantly reduced file complexity and improved maintainability of the main browse screen.
- **Fixed**: Hardened random playback logic with better background deferral and timer management, resolving several edge-case failures.
- **Internal**: Expanded test coverage for the refactored Show List architecture and lifecycle stability.

Release 1.0.19:
- **Improved**: Standardized rating UI scaling across all screens using responsive font tokens.
- **Improved**: Refined the "Random Play" dice animation.
- **New**: Improved "Swipe to Block" feedback with a simplified "Blocked" notification.
- **New**: Added "Undo & Resume" logic to the block action—accidentally blocked a show? Tapping Undo now instantly restores the show and resumes playback at the exact second you left off.

Release 1.0.18:
- **Internal**: Performed comprehensive codebase cleanup, removing over 50+ redundant comments for improved maintainability.
- **Improved**: Verified UI alignment and rendering across all font/scale configurations using automated visual regression tests.

Release 1.0.17:
- **Refactor**: Comprehensive modularization of Settings and Playback screens into specialized widgets.
- **New**: Introduced `RandomShowSelector` service for improved random playback logic.
- **Improved**: Optimized `AudioProvider` cache management and background service interactions.
- **Internal**: Expanded test suite to cover new settings components and random show logic.

Release 1.0.16:
- **Improved**: Enhanced Settings navigation with Material 3 expressive transitions for "Manage Rated Shows" and "About App".
- **Improved**: Navigation now features smooth scale + fade animations for a more premium feel.

Release 1.0.15:
- **New**: Completed comprehensive Haptic Feedback Audit. All interactive elements now provide premium tactile feedback.
- **Improved**: Redesigned "Collection Statistics" for visual consistency with the Playback section.
- **Fixed**: Resolved "Interface" section expansion bug by implementing unique widget keys.
- **Improved**: Fine-tuned "Rock Salt" font spacing and legibility across settings.

Release 1.0.14:
- **Fixed**: Resolved visual text wrapping issues in Settings Screen when "UI Scale" is enabled.
- **Improved**: Strengthened automated testing for playback alignment stability.
- **Improved**: Refined Onboarding Screen for better small-screen responsiveness.

Release 1.0.13:
- **Fixed**: Refactored Onboarding Screen to use UI scaling logic instead of scrolling for improved small-screen experience.
- **Improved**: Refined Playback Panel layout to prevent unintended scrolling when UI Scale is enabled.

Release 1.0.12:
- **Fixed**: Resolved visual overlap between "Venue" and "Location" text in Playback Panel on small screens.
- **Improved**: Fine-tuned layout offsets in Sliding Panel for better spacing.

Release 1.0.11:
- **Internal**: Maintenance release to verify build pipeline consistency.
- **Fixed**: Playback Panel "sliding" issue resolved (included in 1.0.10).

Release 1.0.10:
- **Fixed**: Playback Panel "sliding" issue resolved; content now scales to fit instead of scrolling.
- **Improved**: Playback Panel layout balanced by reducing bottom padding.
- **New**: Added Archive.org connectivity check with visual status on Splash and Onboarding screens.

Release 1.0.9:
- **Improved**: Smoother splash screen transition with tuned timing (1.9s) for a more majestic entry.
- **Fixed**: Onboarding screen layout issues on some device sizes.
- **Internal**: Updated test suite for better stability.
```

