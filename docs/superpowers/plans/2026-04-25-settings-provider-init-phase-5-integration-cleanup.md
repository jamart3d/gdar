# Settings Provider Init Phase 5 Integration Cleanup Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finalize the refactor by removing or shrinking the original god-mode initialization file, updating `SettingsProvider` mixin composition, and verifying the full settings surface.

**Architecture:** This phase assumes earlier extraction phases are complete. It performs the final integration cleanup and package-level verification only; it should not introduce behavior changes.

**Tech Stack:** Flutter, Dart, `SettingsProvider`, `flutter test`, `dart analyze`

---

## Dependencies

- Requires:
  - `docs/superpowers/plans/2026-04-25-settings-provider-init-phase-1-characterization.md`
  - `docs/superpowers/plans/2026-04-25-settings-provider-init-phase-2-bootstrap-presets.md`
  - `docs/superpowers/plans/2026-04-25-settings-provider-init-phase-3-core-source-filters.md`
  - `docs/superpowers/plans/2026-04-25-settings-provider-init-phase-4-web-screensaver.md`

## Scope

### Write Scope
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`
- Modify: `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
- Modify: `packages/shakedown_core/test/providers/settings_provider_test.dart`

### Invariants
- Public `SettingsProvider` API unchanged.
- Constructor order unchanged.
- Full settings tests must pass.

## Task 1: Finalize Mixin Composition

**Files:**
- Modify: `packages/shakedown_core/lib/providers/settings_provider.dart`

- [ ] **Step 1: Replace the old initialization mixin dependency with the extracted mixins**

```dart
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

- [ ] **Step 2: Remove the old `part 'settings_provider_initialization.dart';` or reduce the file to a tiny compatibility shim**

Run: `dart analyze packages/shakedown_core/lib/providers/settings_provider.dart`
Expected: PASS

## Task 2: Run the Focused Settings Test Surface

- [ ] **Step 1: Run initialization-focused tests**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart`
Expected: PASS

- [ ] **Step 2: Run power/default/core settings tests**

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_defaults_contract_test.dart`
Expected: PASS

Run: `flutter test packages/shakedown_core/test/providers/settings_provider_test.dart`
Expected: PASS

## Task 3: Run Package-Level Verification

- [ ] **Step 1: Analyze the settings provider**

Run: `dart analyze packages/shakedown_core/lib/providers/settings_provider.dart`
Expected: PASS

- [ ] **Step 2: Run the full package test suite**

Run: `flutter test packages/shakedown_core`
Expected: PASS

- [ ] **Step 3: Commit**

```bash
git add packages/shakedown_core/lib/providers/settings_provider.dart packages/shakedown_core/lib/providers/settings_provider_initialization.dart packages/shakedown_core/test/providers/settings_provider_initialization_test.dart packages/shakedown_core/test/providers/settings_provider_initialization_refactor_test.dart packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart packages/shakedown_core/test/providers/settings_provider_test.dart
git commit -m "refactor: split settings provider initialization responsibilities"
```

## Handoff

Save results to:
- `reports/2026-04-25_settings_provider_init_phase_5_handoff.md`
