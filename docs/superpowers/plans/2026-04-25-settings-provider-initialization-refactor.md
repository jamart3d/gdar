# Settings Provider Initialization Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce the “god mode” scope of `settings_provider_initialization.dart` by splitting initialization, preset-reset, lifecycle wiring, and subsystem loaders into focused files while preserving current `SettingsProvider` behavior exactly.

**Architecture:** Keep `SettingsProvider` as the public API and keep constructor order unchanged (`_init()` then `_setupUiScaleChannel()`). Move internal logic out of the current 789-line initialization mixin into focused `part` files organized by responsibility, and lock existing behavior down with characterization tests before moving code.

**Tech Stack:** Flutter, Dart, `SharedPreferences`, `ChangeNotifier`, existing `SettingsProvider` test suite under `packages/shakedown_core/test/providers`

---

## Scope

### In Scope
- Split `packages/shakedown_core/lib/providers/settings_provider_initialization.dart` by responsibility.
- Add characterization coverage for current initialization behavior before large code moves.
- Preserve all persisted preference keys, constructor behavior, and runtime side effects.

### Explicit Non-Goals
- Do not change public `SettingsProvider` API.
- Do not change first-run rules, car-mode corrective writes, web adaptive engine/profile rules, or TV-specific overrides.
- Do not rename persisted preference keys.
- Do not change `notifyListeners()` behavior.

### Behavior Invariants
- `SettingsProvider(this._prefs, {this.isTv = false})` must continue to call:
  - `_init()`
  - `_setupUiScaleChannel()`
- `resetAndroidFirstTimeSettings()` and `resetFruitFirstTimeSettings()` must continue to mutate prefs and call `notifyListeners()`.
- `_initializeFirstRunState()` must continue to write `first_run_check_done`.
- Car mode must continue to force the same corrective writes in `_loadCorePreferences()`.
- Web adaptive engine/power initialization must continue to apply only under the same conditions.
- TV must continue to force `_oilScreensaverMode = TvDefaults.oilScreensaverMode`.

## Subagent Phases

### Phase 1: Characterization Tests
- Safe for one worker.
- Purpose: lock current behavior before file moves.

### Phase 2: Pure Structural Extraction
- Can be split across two workers after Phase 1:
  - Worker A: bootstrap/presets/ui-scale channel
  - Worker B: loader extraction (core/source filters/web/screensaver)

### Phase 3: Integration Cleanup
- Single worker after both Phase 2 slices land.
- Purpose: reconcile imports, remove dead code, run full verification.

## File Structure

### Existing Files To Modify
- `packages/shakedown_core/lib/providers/settings_provider.dart`
- `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`
- `packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`
- `packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
- `packages/shakedown_core/test/providers/settings_provider_test.dart`

### New Files To Create
- `packages/shakedown_core/lib/providers/settings_provider_bootstrap.dart`
  - `_init()` orchestration and `_initializeFirstRunState()`
- `packages/shakedown_core/lib/providers/settings_provider_theme_presets.dart`
  - `resetAndroidFirstTimeSettings()`, `resetFruitFirstTimeSettings()`, `_resetWebPlaybackSettings()`
- `packages/shakedown_core/lib/providers/settings_provider_platform_defaults.dart`
  - `_dBool()`, `_dStr()`
- `packages/shakedown_core/lib/providers/settings_provider_ui_scale_channel.dart`
  - `_setupUiScaleChannel()`, `_setUiScale()`
- `packages/shakedown_core/lib/providers/settings_provider_core_loader.dart`
  - `_loadCorePreferences()`, `_loadLegacyCoreMigrations()`, `_loadAppearancePreferences()`, `_loadBehaviorPreferences()`, `_loadDebugPreferences()`
- `packages/shakedown_core/lib/providers/settings_provider_source_filter_loader.dart`
  - `_loadSourceFilterPreferences()`
- `packages/shakedown_core/lib/providers/settings_provider_web_loader.dart`
  - `_loadWebPlaybackPreferences()`, `_loadAudioEngineModePreference()`, `_applyAdaptiveWebEngineProfileIfNeeded()`, `_startWebPowerStateListener()`, `_handleWebChargingState()`
- `packages/shakedown_core/lib/providers/settings_provider_screensaver_loader.dart`
  - `_loadScreensaverPreferences()` and its helper loaders
- `packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
  - characterization tests for constructor/init/reset behavior

## Task 1: Add Characterization Tests Before Refactor

**Files:**
- Create: `packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`

- [ ] **Step 1: Add a constructor-order characterization test**

```dart
test('constructor initialization preserves first-run marker and uiScale bootstrap', () async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final prefs = await SharedPreferences.getInstance();

  final provider = SettingsProvider(prefs);

  expect(provider, isNotNull);
  expect(prefs.getBool('first_run_check_done'), isTrue);
  expect(provider.uiScale, equals(prefs.getBool('ui_scale')));
});
```

- [ ] **Step 2: Add a preset-reset characterization test**

```dart
test('resetFruitFirstTimeSettings persists Fruit first-run defaults', () async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'first_run_check_done': true,
    'fruit_dense_list': true,
    'performance_mode': false,
    'oil_banner_glow': true,
  });
  final prefs = await SharedPreferences.getInstance();
  final provider = SettingsProvider(prefs);

  provider.resetFruitFirstTimeSettings();

  expect(provider.performanceMode, isTrue);
  expect(provider.fruitDenseList, isFalse);
  expect(provider.oilBannerGlow, isFalse);
  expect(prefs.getBool('performance_mode'), isTrue);
});
```

- [ ] **Step 3: Add a source-filter initialization characterization test**

```dart
test('invalid source filter json falls back to defaults', () async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'first_run_check_done': true,
    'source_category_filters': '{not valid json',
  });
  final prefs = await SharedPreferences.getInstance();

  final provider = SettingsProvider(prefs);

  expect(
    provider.sourceCategoryFilters,
    equals(DefaultSettings.sourceCategoryFilters),
  );
});
```

- [ ] **Step 4: Run the focused settings tests**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/test/providers/settings_provider_initialization_test.dart packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart
git commit -m "test: characterize settings initialization behavior"
```

## Task 2: Extract Bootstrap, Presets, and UI-Scale Lifecycle

**Files:**
- Create: `packages/shakedown_core/lib/providers/settings_provider_bootstrap.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_theme_presets.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_platform_defaults.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_ui_scale_channel.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`

- [ ] **Step 1: Add new `part` declarations to `settings_provider.dart`**

```dart
part 'settings_provider_bootstrap.dart';
part 'settings_provider_theme_presets.dart';
part 'settings_provider_platform_defaults.dart';
part 'settings_provider_ui_scale_channel.dart';
```

- [ ] **Step 2: Move bootstrap methods into `settings_provider_bootstrap.dart`**

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
    final firstRunCheckDone = _prefs.getBool('first_run_check_done') ?? false;
    _uiScale =
        _prefs.getBool(_uiScaleKey) ?? DefaultSettings.uiScaleDesktopDefault;
    if (firstRunCheckDone) return;
    // existing logic moved intact
  }
}
```

- [ ] **Step 3: Move theme preset reset helpers into `settings_provider_theme_presets.dart`**

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

- [ ] **Step 4: Move `_dBool()`, `_dStr()`, `_setupUiScaleChannel()`, and `_setUiScale()` into their new files unchanged**

Run: `dart analyze packages/shakedown_core/lib/providers/settings_provider.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/providers/settings_provider.dart packages/shakedown_core/lib/providers/settings_provider_bootstrap.dart packages/shakedown_core/lib/providers/settings_provider_theme_presets.dart packages/shakedown_core/lib/providers/settings_provider_platform_defaults.dart packages/shakedown_core/lib/providers/settings_provider_ui_scale_channel.dart packages/shakedown_core/lib/providers/settings_provider_initialization.dart
git commit -m "refactor: extract settings bootstrap and preset lifecycle"
```

## Task 3: Extract Core and Source-Filter Loaders

**Files:**
- Create: `packages/shakedown_core/lib/providers/settings_provider_core_loader.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_source_filter_loader.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_test.dart`

- [ ] **Step 1: Move core loader methods into `settings_provider_core_loader.dart`**

```dart
part of 'settings_provider.dart';

mixin _SettingsProviderCoreLoaderExtension
    on
        ChangeNotifier,
        _SettingsProviderCoreFields,
        _SettingsProviderWebFields,
        _SettingsProviderScreensaverFields,
        _SettingsProviderPlatformDefaultsExtension {
  SharedPreferences get _prefs;
  bool get isTv;

  void _loadCorePreferences() {
    // move existing implementation unchanged
  }

  void _loadLegacyCoreMigrations() {
    // move existing implementation unchanged
  }

  void _loadAppearancePreferences() {}
  void _loadBehaviorPreferences() {}
  void _loadDebugPreferences() {}
}
```

- [ ] **Step 2: Move source filter loading into `settings_provider_source_filter_loader.dart`**

```dart
part of 'settings_provider.dart';

mixin _SettingsProviderSourceFilterLoaderExtension
    on ChangeNotifier, _SettingsProviderSourceFiltersFields {
  SharedPreferences get _prefs;

  void _loadSourceFilterPreferences() {
    // move existing implementation unchanged
  }
}
```

- [ ] **Step 3: Add/adjust a focused test for car-mode corrective writes and source-filter fallback**

```dart
test('car mode still forces dependent settings during initialization', () async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    'first_run_check_done': true,
    'car_mode': true,
    'ui_scale': true,
  });
  final prefs = await SharedPreferences.getInstance();

  final provider = SettingsProvider(prefs);

  expect(provider.carMode, isTrue);
  expect(provider.uiScale, isFalse);
  expect(provider.showDayOfWeek, isFalse);
  expect(provider.settingsScreenUiScale, isTrue);
});
```

- [ ] **Step 4: Run focused tests**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/providers/settings_provider_core_loader.dart packages/shakedown_core/lib/providers/settings_provider_source_filter_loader.dart packages/shakedown_core/lib/providers/settings_provider.dart packages/shakedown_core/test/providers/settings_provider_test.dart packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart
git commit -m "refactor: extract settings core and source filter loaders"
```

## Task 4: Extract Web and Screensaver Loaders

**Files:**
- Create: `packages/shakedown_core/lib/providers/settings_provider_web_loader.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_screensaver_loader.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`

- [ ] **Step 1: Move web playback loader and listener methods into `settings_provider_web_loader.dart`**

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

- [ ] **Step 2: Move screensaver loader methods into `settings_provider_screensaver_loader.dart`**

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

- [ ] **Step 3: Add/adjust a focused web-power-profile regression test**

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

- [ ] **Step 4: Run focused tests**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/providers/settings_provider_web_loader.dart packages/shakedown_core/lib/providers/settings_provider_screensaver_loader.dart packages/shakedown_core/lib/providers/settings_provider.dart packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart
git commit -m "refactor: extract settings web and screensaver loaders"
```

## Task 5: Delete the God-Mode File and Verify Full Settings Surface

**Files:**
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`

- [ ] **Step 1: Reduce `settings_provider_initialization.dart` to either a tiny compatibility shell or remove it from `settings_provider.dart`**

```dart
// Remove:
part 'settings_provider_initialization.dart';

// Ensure class mixins are updated to:
class SettingsProvider extends ChangeNotifier
    with
        _SettingsProviderCoreFields,
        _SettingsProviderWebFields,
        _SettingsProviderScreensaverFields,
        _SettingsProviderSourceFiltersFields,
        _SettingsProviderCoreExtension,
        _SettingsProviderWebExtension,
        _SettingsProviderScreensaverExtension,
        _SettingsProviderSourceFiltersExtension,
        _SettingsProviderPlatformDefaultsExtension,
        _SettingsProviderThemePresetsExtension,
        _SettingsProviderCoreLoaderExtension,
        _SettingsProviderSourceFilterLoaderExtension,
        _SettingsProviderWebLoaderExtension,
        _SettingsProviderScreensaverLoaderExtension,
        _SettingsProviderBootstrapExtension,
        _SettingsProviderUiScaleChannelExtension {
```

- [ ] **Step 2: Run targeted settings test suite**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_defaults_contract_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_test.dart`
Expected: PASS

- [ ] **Step 3: Run repo-level verification for the package**

Run: `dart analyze packages/shakedown_core/lib/providers/settings_provider.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core`
Expected: PASS

- [ ] **Step 4: Commit**

```bash
git add packages/shakedown_core/lib/providers/settings_provider.dart packages/shakedown_core/lib/providers/settings_provider_initialization.dart packages/shakedown_core/test/providers/settings_provider_initialization_test.dart packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart packages/shakedown_core/test/providers/settings_provider_test.dart
git commit -m "refactor: split settings provider initialization responsibilities"
```

## Suggested Subagent Assignment

### Agent A: Phase 1 + Phase 2
- owns:
  - `settings_provider_bootstrap.dart`
  - `settings_provider_theme_presets.dart`
  - `settings_provider_platform_defaults.dart`
  - `settings_provider_ui_scale_channel.dart`
  - characterization tests

### Agent B: Phase 3 + Phase 4
- starts only after Phase 1 lands
- owns:
  - `settings_provider_core_loader.dart`
  - `settings_provider_source_filter_loader.dart`
  - `settings_provider_web_loader.dart`
  - `settings_provider_screensaver_loader.dart`
  - related settings tests

### Agent C: Phase 5
- cleanup/integration only after A and B are approved
- owns:
  - final `settings_provider.dart` mixin list
  - removal/shrinking of `settings_provider_initialization.dart`
  - full-package verification

## Self-Review

### Spec Coverage
- This plan treats the work as behavior-preserving refactor only.
- All identified responsibility clusters are assigned to extracted files.
- No behavior-changing work is introduced.

### Placeholder Scan
- No `TODO` or deferred “implement later” instructions.
- Each task includes exact files and explicit verification commands.

### Type Consistency
- `SettingsProvider` remains the public entry point.
- `_init()` and `_setupUiScaleChannel()` stay constructor-owned.
- Extracted mixin names remain consistent across tasks.
