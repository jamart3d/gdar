# Fruit Car Mode Stat Font Size Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the web Fruit car mode playback stat-chip values as large and legible as possible without changing chip height, chip width, or the overall row layout.

**Architecture:** This change stays inside the web Fruit car mode stat chip widget in `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart`. The right approach is to reclaim the visible empty internal space by reducing vertical padding and the label-to-value gap, then raise the value text to the largest size that still fits representative long values inside the fixed-height chips.

**Tech Stack:** Flutter, Dart, Provider, existing widget tests in `packages/shakedown_core/test/screens/playback_screen_test.dart`

---

## File Map

- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart`
- Modify: `packages/shakedown_core/test/screens/playback_screen_test.dart`

## Constraints

- Keep Fruit structure and visuals intact. Do not introduce Material components or interaction changes.
- This applies only to the web Fruit car mode playback stat chips (`DFT`, `HD`, `NXT`, `LG`).
- Do not change `_fruitCarModeChipCardHeight`, label size, chip width, or inter-chip spacing.
- Use the apparent empty internal chip space by reducing vertical padding and the label-to-value gap before accepting a small font bump.
- Treat both vertical fit and horizontal fit as constraints because the chips live in a fixed-height, four-column `Row` with `Expanded` children.

### Task 1: Maximize the Stat Value Text Within the Existing Chip

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart`

- [ ] **Step 1: Confirm the current layout budget**

Read:

```dart
padding: EdgeInsets.symmetric(
  horizontal: 12 * scaleFactor,
  vertical: 12 * scaleFactor,
),
...
SizedBox(height: 8 * scaleFactor),
...
Text(
  value,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontFamily: FontConfig.resolve('Inter'),
    fontSize: 18 * scaleFactor,
    fontWeight: FontWeight.w900,
    color: accentColor,
  ),
),
```

Expected: the current web Fruit stat chip still leaves visible internal vertical slack while the value text remains too subtle.

- [ ] **Step 2: Reclaim internal space and raise the value font**

Update the stat card so it uses smaller vertical padding, a smaller label-to-value gap, and a larger value font. The shape of the change should be:

```dart
padding: EdgeInsets.symmetric(
  horizontal: 12 * scaleFactor,
  vertical: <smaller-than-12> * scaleFactor,
),
...
SizedBox(height: <smaller-than-8> * scaleFactor),
...
Text(
  value,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontFamily: FontConfig.resolve('Inter'),
    fontSize: <largest-fitting-size> * scaleFactor,
    fontWeight: FontWeight.w900,
    color: accentColor,
  ),
),
```

Expected: the numeric/value text becomes obviously larger than the current `18 * scaleFactor` while the label size, chip height, and row layout remain unchanged.

### Task 2: Add a Regression Test for the Larger Web Fruit Stat Typography

**Files:**
- Modify: `packages/shakedown_core/test/screens/playback_screen_test.dart`

- [ ] **Step 1: Add a widget test for the larger typography and long-value fit**

Add a test near the existing Fruit car mode playback tests:

```dart
testWidgets(
  'PlaybackScreen Fruit car mode stat chips use the largest fitting value typography without overflow',
  (WidgetTester tester) async {
    setLargeCarModeViewport(tester);
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);
    mockSettingsProvider.setCarMode(true);
    mockSettingsProvider.setShowDevAudioHud(false);

    final hud = HudSnapshot.empty().copyWith(
      drift: '1.25s',
      headroom: '+12s',
      nextBuffered: '00:34',
      lastGapMs: 1200,
    );

    when(mockAudioProvider.currentHudSnapshot).thenReturn(hud);

    await tester.pumpWidget(
      createTestableWidget(
        child: const PlaybackScreen(showFruitTabBar: false),
        themeProvider: MockFruitThemeProvider(),
      ),
    );
    await tester.pump();

    expect(find.text('1.25s'), findsOneWidget);
    expect(find.text('+12s'), findsOneWidget);
    expect(find.text('00:34'), findsOneWidget);
    expect(find.text('1200ms'), findsOneWidget);

    final Text gapText = tester.widget<Text>(find.text('1200ms'));
    expect(gapText.style?.fontSize, greaterThan(18.0));
    expect(tester.takeException(), isNull);
  },
);
```

Expected: representative longer values remain present, the value typography is visibly larger than `18.0`, and the frame does not throw an overflow exception.

- [ ] **Step 2: Run the targeted widget test**

Run:

```bash
flutter test packages/shakedown_core/test/screens/playback_screen_test.dart --plain-name "PlaybackScreen Fruit car mode stat chips use the largest fitting value typography without overflow"
```

Expected: `1` test passes.

### Task 3: Run Broader Verification

**Files:**
- Modify: none

- [ ] **Step 1: Run package analysis**

Run:

```bash
flutter analyze
```

Expected: exit code `0`.

- [ ] **Step 2: Run the full playback screen test file**

Run:

```bash
flutter test packages/shakedown_core/test/screens/playback_screen_test.dart
```

Expected: playback screen tests pass with no new overflows or regressions in web Fruit car mode.

- [ ] **Step 3: Manually verify web Fruit car mode**

Check:

```text
1. Open Fruit playback screen with car mode enabled on web.
2. Confirm DFT, HD, NXT, and LG values are obviously larger than the current subtle 18-point bump.
3. Re-check with UI Scale enabled.
4. Confirm chip height and external row spacing are unchanged.
5. Confirm longer values such as 1200ms still read cleanly.
```

Expected: substantially improved legibility with unchanged chip geometry.

## Open Questions

- After reclaiming internal spacing, what is the maximum stable value font that clears both normal scale and representative longer values?

## Decision Note

- The earlier `17 -> 18` change was too subtle to satisfy the visual goal. The follow-up should use the empty internal chip space to support a meaningfully larger value font, then stop at the largest size that passes the overflow test.
