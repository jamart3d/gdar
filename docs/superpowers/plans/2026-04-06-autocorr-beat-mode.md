# Autocorr Beat Detector Mode Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an `autocorr` beat detector mode to the TV screensaver with beat/logo sub-variants, stored settings, native autocorr-grid handling, and screensaver logo-scale behavior.

**Architecture:** Extend the existing TV beat-detector settings flow instead of creating a parallel feature path. Persist the new variants in `SettingsProvider`, push them through the existing `AudioReactor.updateConfig()` method-channel payload, synthesize an autocorr beat grid in native when `beatDetectorMode == 'autocorr'`, and let the screensaver rendering read the new config fields to decide whether beat pulse, BPM-locked sine, or both should drive logo scale.

**Tech Stack:** Flutter, Dart, Provider, SharedPreferences, platform MethodChannel, Kotlin Android visualizer plugins, widget/unit tests.

---

### Task 1: Settings and UI contracts

**Files:**
- Modify: `packages/shakedown_core/test/providers/settings_provider_defaults_contract_test.dart`
- Modify: `packages/shakedown_core/test/ui/widgets/settings/tv_screensaver_section_test.dart`
- Modify: `packages/shakedown_core/test/helpers/fake_settings_provider.dart`

- [ ] Add failing defaults tests for `oilAutocorrBeatVariant` and `oilAutocorrLogoVariant`.
- [ ] Add failing widget tests that prove the two autocorr sub-rows render only when `oilBeatDetectorMode == 'autocorr'`.
- [ ] Add failing widget tests that tapping the sub-row segments updates the backing fake settings provider.

### Task 2: Dart settings and TV UI

**Files:**
- Modify: `packages/shakedown_core/lib/config/default_settings.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_screensaver.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section_audio_build.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section_controls.dart`

- [ ] Add new defaults and settings-provider keys/getters/setters for the autocorr beat/logo variants.
- [ ] Add the `autocorr` segment and description to the beat detector UI.
- [ ] Render the two autocorr sub-rows only when `settings.oilBeatDetectorMode == 'autocorr'`.

### Task 3: Reactor/config plumbing

**Files:**
- Modify: `packages/shakedown_core/lib/visualizer/audio_reactor.dart`
- Modify: `packages/shakedown_core/lib/visualizer/visualizer_audio_reactor.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/screensaver_screen.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_preview_panel.dart`
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_config.dart`
- Modify: `packages/shakedown_core/test/steal_screensaver/steal_graph_test.dart`

- [ ] Add failing config-plumbing assertions where practical.
- [ ] Thread `autocorrBeatVariant` and `autocorrLogoVariant` through the reactor payload and the preview/live screensaver push caches.
- [ ] Add matching fields to `StealConfig` serialization and equality helpers.

### Task 4: Native autocorr grid synthesis

**Files:**
- Modify: `apps/gdar_tv/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`
- Modify: `apps/gdar_mobile/android/app/src/main/kotlin/com/jamart3d/shakedown/VisualizerPlugin.kt`

- [ ] Parse the two new config values from `updateConfig`.
- [ ] Add `autocorr` detector selection behavior.
- [ ] Synthesize a native autocorr beat grid/phase when autocorr BPM is available so `Grid` and `Both` use a true autocorr-driven metronome.
- [ ] Force autocorr second-pass behavior at runtime for `autocorr` mode without mutating saved prefs.

### Task 5: Screensaver logo-scale behavior

**Files:**
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_game.dart`
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_background.dart`

- [ ] Keep pulse behavior aligned with the selected beat source.
- [ ] Override sine-drive enable/frequency from autocorr BPM when the autocorr logo variant is `sine` or `both`.
- [ ] Preserve existing manual sine settings when autocorr mode is off.

### Task 6: Verification

**Files:**
- Modify as needed: tests above only

- [ ] Run targeted widget/unit tests for settings/UI/config.
- [ ] Run targeted Dart analysis on edited shared-package files.
- [ ] Report any remaining native verification gap if Kotlin behavior cannot be exercised from existing tests.
