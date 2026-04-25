# Settings Provider Init Phase 1 Characterization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lock current `SettingsProvider` initialization behavior down with characterization tests before any structural extraction begins.

**Architecture:** This phase adds or extends tests only. It must preserve existing runtime behavior and create a safety net for later file moves out of `settings_provider_initialization.dart`.

**Tech Stack:** Flutter, Dart, `flutter_test`, `SharedPreferences`, existing settings provider tests

---

## Scope

### Write Scope
- Create: `packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`

### Invariants
- Do not modify production code in this phase unless a test fixture import absolutely requires it.
- Do not change `SettingsProvider` constructor behavior.

## Task 1: Characterize Constructor Bootstrap

**Files:**
- Create: `packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`

- [ ] **Step 1: Write a constructor bootstrap characterization test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/providers/settings_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('constructor initialization preserves first-run marker and uiScale bootstrap', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    final provider = SettingsProvider(prefs);

    expect(provider, isNotNull);
    expect(prefs.getBool('first_run_check_done'), isTrue);
    expect(provider.uiScale, equals(prefs.getBool('ui_scale')));
  });
}
```

- [ ] **Step 2: Run the new test**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

## Task 2: Characterize Preset Reset Behavior

**Files:**
- Modify: `packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`

- [ ] **Step 1: Add a Fruit preset reset characterization test**

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

- [ ] **Step 2: Run the updated test file**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

## Task 3: Characterize Source Filter and Existing Initialization Coverage

**Files:**
- Modify: `packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`

- [ ] **Step 1: Add a source-filter fallback characterization test**

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

- [ ] **Step 2: Run the focused settings tests**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add packages/shakedown_core/test/providers/settings_provider_initialization_test.dart packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart
git commit -m "test: characterize settings initialization behavior"
```

## Handoff

Save results to:
- `reports/2026-04-25_settings_provider_init_phase_1_handoff.md`
