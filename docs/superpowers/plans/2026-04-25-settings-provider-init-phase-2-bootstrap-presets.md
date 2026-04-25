# Settings Provider Init Phase 2 Bootstrap Presets Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract bootstrap, theme preset reset logic, platform default helpers, and UI-scale channel lifecycle out of `settings_provider_initialization.dart` into focused files.

**Architecture:** This phase is structural refactor only. It must preserve constructor call order, persisted keys, and `notifyListeners()` behavior while moving logic into new `part` files.

**Tech Stack:** Flutter, Dart, `SharedPreferences`, `ChangeNotifier`, `part` files in `SettingsProvider`

---

## Dependencies

- Requires `docs/superpowers/plans/2026-04-25-settings-provider-init-phase-1-characterization.md`

## Scope

### Write Scope
- Create: `packages/shakedown_core/lib/providers/settings_provider_bootstrap.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_theme_presets.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_platform_defaults.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_ui_scale_channel.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`

### Invariants
- Constructor must still call `_init()` then `_setupUiScaleChannel()`.
- `resetAndroidFirstTimeSettings()` and `resetFruitFirstTimeSettings()` must remain behavior-identical.
- `_initializeFirstRunState()` must preserve first-run writes.

## Task 1: Register New Part Files

**Files:**
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`

- [ ] **Step 1: Add new `part` declarations**

```dart
part 'settings_provider_bootstrap.dart';
part 'settings_provider_theme_presets.dart';
part 'settings_provider_platform_defaults.dart';
part 'settings_provider_ui_scale_channel.dart';
```

- [ ] **Step 2: Run analyzer on `settings_provider.dart`**

Run: `dart analyze packages/shakedown_core/lib/providers/settings_provider.dart`
Expected: PASS

## Task 2: Extract Bootstrap and Platform Defaults

**Files:**
- Create: `packages/shakedown_core/lib/providers/settings_provider_bootstrap.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_platform_defaults.dart`

- [ ] **Step 1: Move `_dBool()` and `_dStr()` into the platform defaults file**

```dart
part of 'settings_provider.dart';

mixin _SettingsProviderPlatformDefaultsExtension
    on ChangeNotifier, _SettingsProviderCoreFields {
  bool get isTv;

  bool _dBool(bool webVal, bool tvVal, bool phoneVal) {
    if (isTv) return tvVal;
    if (kIsWeb) return webVal;
    return phoneVal;
  }

  String _dStr(String webVal, String tvVal, String phoneVal) {
    if (isTv) return tvVal;
    if (kIsWeb) return webVal;
    return phoneVal;
  }
}
```

- [ ] **Step 2: Move `_init()` and `_initializeFirstRunState()` into the bootstrap file unchanged**

```dart
part of 'settings_provider.dart';

mixin _SettingsProviderBootstrapExtension
    on
        ChangeNotifier,
        _SettingsProviderCoreFields,
        _SettingsProviderWebFields,
        _SettingsProviderScreensaverFields,
        _SettingsProviderSourceFiltersFields,
        _SettingsProviderCoreLoaderExtension,
        _SettingsProviderWebLoaderExtension,
        _SettingsProviderScreensaverLoaderExtension,
        _SettingsProviderSourceFilterLoaderExtension {
  SharedPreferences get _prefs;
  bool get isTv;

  void _init() {
    _initializeFirstRunState();
    _loadCorePreferences();
    _loadWebPlaybackPreferences();
    _loadScreensaverPreferences();
    _loadSourceFilterPreferences();
  }

  void _initializeFirstRunState() {
    // move existing implementation unchanged
  }
}
```

- [ ] **Step 3: Run focused tests**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

## Task 3: Extract Theme Presets and UI-Scale Channel Lifecycle

**Files:**
- Create: `packages/shakedown_core/lib/providers/settings_provider_theme_presets.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_ui_scale_channel.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`

- [ ] **Step 1: Move preset reset logic into `settings_provider_theme_presets.dart`**

```dart
part of 'settings_provider.dart';

mixin _SettingsProviderThemePresetsExtension
    on
        ChangeNotifier,
        _SettingsProviderCoreFields,
        _SettingsProviderWebFields,
        _SettingsProviderPlatformDefaultsExtension {
  SharedPreferences get _prefs;
  bool get isTv;
  void setHiddenSessionPreset(
    HiddenSessionPreset preset, {
    bool markPowerProfileCustom = true,
  });
  void setGlowMode(int mode);
  void setHighlightPlayingWithRgb(bool value);

  void resetAndroidFirstTimeSettings() {
    // move existing implementation unchanged
  }

  void resetFruitFirstTimeSettings() {
    // move existing implementation unchanged
  }

  void _resetWebPlaybackSettings() {
    // move existing implementation unchanged
  }
}
```

- [ ] **Step 2: Move `_setupUiScaleChannel()` and `_setUiScale()` into `settings_provider_ui_scale_channel.dart`**

```dart
part of 'settings_provider.dart';

mixin _SettingsProviderUiScaleChannelExtension
    on ChangeNotifier, _SettingsProviderCoreFields {
  SharedPreferences get _prefs;

  void _setupUiScaleChannel() {
    // move existing implementation unchanged
  }

  Future<void> _setUiScale(bool enabled) async {
    // move existing implementation unchanged
  }
}
```

- [ ] **Step 3: Run analysis and focused tests**

Run: `dart analyze packages/shakedown_core/lib/providers/settings_provider.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add packages/shakedown_core/lib/providers/settings_provider.dart packages/shakedown_core/lib/providers/settings_provider_bootstrap.dart packages/shakedown_core/lib/providers/settings_provider_theme_presets.dart packages/shakedown_core/lib/providers/settings_provider_platform_defaults.dart packages/shakedown_core/lib/providers/settings_provider_ui_scale_channel.dart packages/shakedown_core/lib/providers/settings_provider_initialization.dart
git commit -m "refactor: extract settings bootstrap and preset lifecycle"
```

## Handoff

Save results to:
- `reports/2026-04-25_settings_provider_init_phase_2_handoff.md`
