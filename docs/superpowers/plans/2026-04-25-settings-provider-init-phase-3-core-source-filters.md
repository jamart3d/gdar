# Settings Provider Init Phase 3 Core Source Filters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extract core, appearance, behavior, debug, and source-filter loading out of `settings_provider_initialization.dart` into focused loader files.

**Architecture:** This phase is structural extraction only. It must preserve car-mode corrective writes, legacy migration behavior, malformed source-filter fallback, and current pref write side effects.

**Tech Stack:** Flutter, Dart, `SharedPreferences`, `part` files in `SettingsProvider`

---

## Dependencies

- Requires `docs/superpowers/plans/2026-04-25-settings-provider-init-phase-1-characterization.md`

## Scope

### Write Scope
- Create: `packages/shakedown_core/lib/providers/settings_provider_core_loader.dart`
- Create: `packages/shakedown_core/lib/providers/settings_provider_source_filter_loader.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_test.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`

### Invariants
- Preserve car-mode coercion of dependent prefs.
- Preserve legacy migration behavior for app font and oil screensaver.
- Preserve malformed source-filter JSON fallback behavior.

## Task 1: Register the New Loader Parts

**Files:**
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`

- [ ] **Step 1: Add new `part` declarations**

```dart
part 'settings_provider_core_loader.dart';
part 'settings_provider_source_filter_loader.dart';
```

- [ ] **Step 2: Run analyzer**

Run: `dart analyze packages/shakedown_core/lib/providers/settings_provider.dart`
Expected: PASS

## Task 2: Extract Core Loaders

**Files:**
- Create: `packages/shakedown_core/lib/providers/settings_provider_core_loader.dart`

- [ ] **Step 1: Move core-loading methods unchanged**

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

  void _loadAppearancePreferences() {
    // move existing implementation unchanged
  }

  void _loadBehaviorPreferences() {
    // move existing implementation unchanged
  }

  void _loadDebugPreferences() {
    // move existing implementation unchanged
  }
}
```

- [ ] **Step 2: Add a car-mode regression test**

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

- [ ] **Step 3: Run focused tests**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_test.dart`
Expected: PASS

## Task 3: Extract Source Filter Loader

**Files:**
- Create: `packages/shakedown_core/lib/providers/settings_provider_source_filter_loader.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`

- [ ] **Step 1: Move source-filter loading unchanged**

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

- [ ] **Step 2: Run focused tests**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add packages/shakedown_core/lib/providers/settings_provider.dart packages/shakedown_core/lib/providers/settings_provider_core_loader.dart packages/shakedown_core/lib/providers/settings_provider_source_filter_loader.dart packages/shakedown_core/lib/providers/settings_provider_initialization.dart packages/shakedown_core/test/providers/settings_provider_test.dart packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart
git commit -m "refactor: extract settings core and source filter loaders"
```

## Handoff

Save results to:
- `reports/2026-04-25_settings_provider_init_phase_3_handoff.md`
