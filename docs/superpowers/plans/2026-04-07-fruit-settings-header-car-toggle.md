# Fruit Settings Header Car Toggle Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Fruit-style car toggle button to the settings header that controls the requested web Fruit car-mode shortcuts without affecting other screens.

**Architecture:** Keep the shortcut logic in `SettingsScreen` and reuse the existing Fruit header action button pattern. Drive the change with a focused widget test that covers both enable and disable behavior against `SettingsProvider`.

**Tech Stack:** Flutter widget tests, Provider, SharedPreferences-backed `SettingsProvider`, Fruit header controls

---

### Task 1: Document the Fruit settings header toggle contract

**Files:**
- Create: `docs/superpowers/specs/2026-04-07-fruit-settings-header-car-toggle-design.md`
- Create: `docs/superpowers/plans/2026-04-07-fruit-settings-header-car-toggle.md`

- [ ] **Step 1: Write the approved design note**

Document the scope, button placement, and toggle rules:

```text
Fruit settings header only.
Enable path: car mode + prevent sleep + spheres + liquid glass.
Disable path: car mode off + prevent sleep off; spheres/glass unchanged.
```

- [ ] **Step 2: Save the execution plan**

Record the TDD order and the exact files under test:

```text
Test first in packages/shakedown_core/test/ui/screens/settings_screen_test.dart.
Implement in packages/shakedown_core/lib/ui/screens/settings_screen.dart.
Verify with flutter test on the settings screen test file.
```

### Task 2: Add the failing widget regression test

**Files:**
- Modify: `packages/shakedown_core/test/ui/screens/settings_screen_test.dart`
- Test: `packages/shakedown_core/test/ui/screens/settings_screen_test.dart`

- [ ] **Step 1: Write the failing test**

Add a Fruit-path widget test that:

```dart
expect(settingsProvider.carMode, isFalse);
expect(settingsProvider.preventSleep, isFalse);
expect(settingsProvider.fruitFloatingSpheres, isFalse);
expect(settingsProvider.fruitEnableLiquidGlass, isFalse);

await tester.tap(find.byTooltip('Enable Car Mode'));
await tester.pump();

expect(settingsProvider.carMode, isTrue);
expect(settingsProvider.preventSleep, isTrue);
expect(settingsProvider.fruitFloatingSpheres, isTrue);
expect(settingsProvider.fruitEnableLiquidGlass, isTrue);
```

- [ ] **Step 2: Run the targeted test and verify it fails**

Run: `flutter test packages/shakedown_core/test/ui/screens/settings_screen_test.dart`
Expected: failure because the Fruit settings header does not yet expose the new car button/behavior.

- [ ] **Step 3: Extend the test with the disable-path assertion**

Add a second tap:

```dart
await tester.tap(find.byTooltip('Disable Car Mode'));
await tester.pump();

expect(settingsProvider.carMode, isFalse);
expect(settingsProvider.preventSleep, isFalse);
expect(settingsProvider.fruitFloatingSpheres, isTrue);
expect(settingsProvider.fruitEnableLiquidGlass, isTrue);
```

- [ ] **Step 4: Re-run the targeted test**

Run: `flutter test packages/shakedown_core/test/ui/screens/settings_screen_test.dart`
Expected: still failing until the header button is implemented.

### Task 3: Implement the Fruit settings header button

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/settings_screen.dart`
- Test: `packages/shakedown_core/test/ui/screens/settings_screen_test.dart`

- [ ] **Step 1: Add a local header toggle helper**

Implement a helper in `SettingsScreen` that composes existing provider toggles:

```dart
void _toggleFruitHeaderCarMode(SettingsProvider settingsProvider) {
  final bool enabling = !settingsProvider.carMode;
  settingsProvider.toggleCarMode();
  if (settingsProvider.preventSleep != enabling) {
    settingsProvider.togglePreventSleep();
  }
  if (enabling && !settingsProvider.fruitFloatingSpheres) {
    settingsProvider.toggleFruitFloatingSpheres();
  }
  if (enabling && !settingsProvider.fruitEnableLiquidGlass) {
    settingsProvider.toggleFruitEnableLiquidGlass();
  }
}
```

- [ ] **Step 2: Insert the Fruit header button**

Add a new button in the header row immediately before the dark/light button:

```dart
_buildFruitHeaderButton(
  context,
  icon: LucideIcons.car,
  tooltip: settingsProvider.carMode ? 'Disable Car Mode' : 'Enable Car Mode',
  color: settingsProvider.carMode
      ? Theme.of(context).colorScheme.primary
      : null,
  onPressed: () => _toggleFruitHeaderCarMode(settingsProvider),
),
```

- [ ] **Step 3: Keep the existing header structure intact**

Preserve:

```text
Back button | centered Settings title | new car button | light/dark button
```

- [ ] **Step 4: Run the targeted test and verify it passes**

Run: `flutter test packages/shakedown_core/test/ui/screens/settings_screen_test.dart`
Expected: pass with the new header toggle behavior covered.

### Task 4: Verify and format

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/settings_screen.dart`
- Modify: `packages/shakedown_core/test/ui/screens/settings_screen_test.dart`

- [ ] **Step 1: Format the touched files**

Run:

```bash
dart format packages/shakedown_core/lib/ui/screens/settings_screen.dart \
  packages/shakedown_core/test/ui/screens/settings_screen_test.dart
```

- [ ] **Step 2: Run the focused verification command**

Run: `flutter test packages/shakedown_core/test/ui/screens/settings_screen_test.dart`
Expected: all tests passed.

- [ ] **Step 3: Report the exact scope**

State explicitly that the change is limited to the Fruit settings header and
that no other app bars were changed.
