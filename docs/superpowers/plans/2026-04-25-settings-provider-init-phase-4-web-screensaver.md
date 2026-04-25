# Settings Provider Init Phase 4 Web Screensaver Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract web playback initialization and screensaver initialization into focused loader files without changing current behavior.

**Architecture:** This phase moves the two largest subsystem loaders out of the god-mode file. It must preserve adaptive web engine/profile behavior, charging listener startup rules, and TV screensaver overrides.

**Tech Stack:** Flutter, Dart, `SharedPreferences`, web power-policy helpers, `part` files in `SettingsProvider`

---

## Dependencies

- Requires `docs/superpowers/plans/2026-04-25-settings-provider-init-phase-1-characterization.md`

## Scope

### Write Scope
- Create: `packages/shakedown_core/lib/providers/settings_provider_web_loader.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_screensaver_loader.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`

### Invariants
- Preserve web adaptive engine/profile initialization.
- Preserve charging listener startup and notification conditions.
- Preserve TV forced screensaver mode override.

## Task 1: Register the New Loader Parts

**Files:**
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`

- [ ] **Step 1: Add new `part` declarations**

```dart
part 'settings_provider_web_loader.dart';
part 'settings_provider_screensaver_loader.dart';
```

- [ ] **Step 2: Run analyzer**

Run: `dart analyze packages/shakedown_core/lib/providers/settings_provider.dart`
Expected: PASS

## Task 2: Extract Web Playback Loader

**Files:**
- Create: `packages/shakedown_core/lib/providers/settings_provider_web_loader.dart`

- [ ] **Step 1: Move web loader methods unchanged**

```dart
part of 'settings_provider.dart';

mixin _SettingsProviderWebLoaderExtension
    on
        ChangeNotifier,
        _SettingsProviderWebFields,
        _SettingsProviderPlatformDefaultsExtension,
        _SettingsProviderThemePresetsExtension {
  SharedPreferences get _prefs;
  bool get isTv;
  void _applyWebPlaybackPowerPolicy({required bool persistPrefs});

  void _loadWebPlaybackPreferences() {
    // move existing implementation unchanged
  }

  AudioEngineMode _loadAudioEngineModePreference() {
    // move existing implementation unchanged
  }

  void _applyAdaptiveWebEngineProfileIfNeeded() {
    // move existing implementation unchanged
  }

  void _startWebPowerStateListener() {
    // move existing implementation unchanged
  }

  void _handleWebChargingState(bool? charging) {
    // move existing implementation unchanged
  }
}
```

- [ ] **Step 2: Add/adjust a focused power-profile regression test**

```dart
test('auto web power profile still reapplies policy on charging state changes', () async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'first_run_check_done': true,
  });
  final prefs = await SharedPreferences.getInstance();

  final provider = SettingsProvider(prefs);

  expect(provider.webPlaybackPowerProfile, isNotNull);
  expect(provider.resolvedWebPlaybackPowerSource, isNotNull);
});
```

- [ ] **Step 3: Run focused test**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
Expected: PASS

## Task 3: Extract Screensaver Loader

**Files:**
- Create: `packages/shakedown_core/lib/providers/settings_provider_screensaver_loader.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`

- [ ] **Step 1: Move screensaver loader methods unchanged**

```dart
part of 'settings_provider.dart';

mixin _SettingsProviderScreensaverLoaderExtension
    on ChangeNotifier, _SettingsProviderScreensaverFields {
  SharedPreferences get _prefs;
  bool get isTv;

  void _loadScreensaverPreferences() {
    // move existing implementation unchanged
  }

  int _loadOilPerformanceLevel() {
    // move existing implementation unchanged
  }

  String _loadOilBannerFont() {
    // move existing implementation unchanged
  }
}
```

- [ ] **Step 2: Run focused tests**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add packages/shakedown_core/lib/providers/settings_provider.dart packages/shakedown_core/lib/providers/settings_provider_web_loader.dart packages/shakedown_core/lib/providers/settings_provider_screensaver_loader.dart packages/shakedown_core/lib/providers/settings_provider_initialization.dart packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart
git commit -m "refactor: extract settings web and screensaver loaders"
```

## Handoff

Save results to:
- `reports/2026-04-25_settings_provider_init_phase_4_handoff.md`
