# Fruit Car Mode And Steal Graph Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor Fruit car-mode playback UI assembly and Steal graph corner rendering so both files are smaller, more readable, and easier to maintain without intentionally changing behavior.

**Architecture:** Keep both features in their current ownership boundaries and extract only feature-local helpers. The Fruit refactor will separate styling and progress derivation from widget composition, while the Steal graph refactor will separate panel chrome, text painting, and repeated paint construction from top-level render flow.

**Tech Stack:** Flutter, Dart 3, Provider, just_audio, Flame, flutter_test

---

### Task 1: Extract Fruit Car Mode Progress And Text Helpers

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart`
- Test: `packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart`

- [ ] **Step 1: Write the failing unit tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';

void main() {
  group('computeFruitCarModePendingCue', () {
    test('shows pending cue while loading', () {
      expect(
        computeFruitCarModePendingCue(
          isLoading: true,
          isBuffering: false,
          bufferedPositionMs: 0,
          positionMs: 0,
          durationMs: 0,
        ),
        isTrue,
      );
    });

    test('hides pending cue when enough buffer headroom exists', () {
      expect(
        computeFruitCarModePendingCue(
          isLoading: false,
          isBuffering: false,
          bufferedPositionMs: 9000,
          positionMs: 8000,
          durationMs: 20000,
        ),
        isFalse,
      );
    });

    test('shows pending cue near the current position when headroom is thin', () {
      expect(
        computeFruitCarModePendingCue(
          isLoading: false,
          isBuffering: false,
          bufferedPositionMs: 8200,
          positionMs: 8000,
          durationMs: 20000,
        ),
        isTrue,
      );
    });
  });

  group('computeFruitCarModeProgressMetrics', () {
    test('clamps progress values into valid ranges', () {
      final metrics = computeFruitCarModeProgressMetrics(
        position: const Duration(seconds: 15),
        buffered: const Duration(seconds: 40),
        total: const Duration(seconds: 30),
      );

      expect(metrics.totalMs, 30000);
      expect(metrics.positionMs, 15000);
      expect(metrics.bufferedMs, 30000);
      expect(metrics.progress, 0.5);
      expect(metrics.bufferedProgress, 1.0);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run from `packages/shakedown_core`:

```bash
flutter test test/screens/playback_screen_fruit_car_mode_test.dart
```

Expected: FAIL with missing symbols such as
`computeFruitCarModePendingCue` and `computeFruitCarModeProgressMetrics`.

- [ ] **Step 3: Write the minimal implementation**

Add the two visible-for-testing helpers near
`computeFruitFloatingNowPlayingBottomOffset` in
`packages/shakedown_core/lib/ui/screens/playback_screen.dart`:

```dart
@visibleForTesting
bool computeFruitCarModePendingCue({
  required bool isLoading,
  required bool isBuffering,
  required int bufferedPositionMs,
  required int positionMs,
  required int durationMs,
}) {
  final int remainingMs = durationMs - positionMs;
  final bool hasPlayableTail = durationMs <= 0 || remainingMs > 900;
  final bool hasVisibleBufferHeadroom =
      bufferedPositionMs > (positionMs + 350);
  return isLoading ||
      isBuffering ||
      (hasPlayableTail && !hasVisibleBufferHeadroom);
}

@visibleForTesting
FruitCarModeProgressMetrics computeFruitCarModeProgressMetrics({
  required Duration position,
  required Duration buffered,
  required Duration total,
}) {
  final totalMs = total.inMilliseconds;
  final maxPositionMs = totalMs > 0 ? totalMs : 0;
  final positionMs = position.inMilliseconds.clamp(0, maxPositionMs);
  final bufferedMs = buffered.inMilliseconds.clamp(0, maxPositionMs);

  return FruitCarModeProgressMetrics(
    totalMs: totalMs,
    positionMs: positionMs,
    bufferedMs: bufferedMs,
    progress: totalMs <= 0 ? 0.0 : positionMs / totalMs,
    bufferedProgress: totalMs <= 0 ? 0.0 : bufferedMs / totalMs,
  );
}

class FruitCarModeProgressMetrics {
  const FruitCarModeProgressMetrics({
    required this.totalMs,
    required this.positionMs,
    required this.bufferedMs,
    required this.progress,
    required this.bufferedProgress,
  });

  final int totalMs;
  final int positionMs;
  final int bufferedMs;
  final double progress;
  final double bufferedProgress;
}
```

Then simplify
`packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart`
so `_buildFruitCarModeProgress` consumes the new helper and replace repeated
`TextStyle` creation with feature-local helpers like:

```dart
TextStyle _fruitCarModeTextStyle(
  BuildContext context, {
  required double fontSize,
  required FontWeight fontWeight,
  required Color color,
  double height = 1.0,
  double letterSpacing = 0.0,
}) {
  return TextStyle(
    fontFamily: FontConfig.resolve('Inter'),
    fontSize: fontSize,
    fontWeight: fontWeight,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}
```

- [ ] **Step 4: Run the focused tests**

Run from `packages/shakedown_core`:

```bash
flutter test test/screens/playback_screen_fruit_car_mode_test.dart
flutter test test/screens/playback_screen_fruit_inset_test.dart
```

Expected: PASS for the new helper coverage and the existing inset coverage.

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/ui/screens/playback_screen.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart packages/shakedown_core/test/screens/playback_screen_fruit_inset_test.dart
git commit -m "refactor: split fruit car mode progress helpers"
```

### Task 2: Decompose Fruit Car Mode Section Builders

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart`

- [ ] **Step 1: Write the failing structural refactor diff**

Make the existing long methods fail locally only by first rewriting the file in
small steps and ensuring every extraction compiles. Start by replacing repeated
inline style/math expressions with small helpers such as:

```dart
EdgeInsets _fruitCarModePagePadding(BuildContext context, double scaleFactor) {
  final topPadding = MediaQuery.paddingOf(context).top;
  return EdgeInsets.fromLTRB(
    16 * scaleFactor,
    math.max(8.0, topPadding * 0.15),
    16 * scaleFactor,
    0,
  );
}

String _fruitCarModeDateText(Show currentShow) {
  try {
    return DateFormat('MMMM d, y').format(DateTime.parse(currentShow.date));
  } catch (_) {
    return currentShow.formattedDate;
  }
}
```

- [ ] **Step 2: Run analysis to surface extraction mistakes early**

Run from repo root:

```bash
dart analyze packages/shakedown_core/lib/ui/screens/playback_screen.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart
```

Expected: either no issues or concrete extraction errors such as missing helper
signatures that you then fix immediately.

- [ ] **Step 3: Finish the minimal implementation**

Restructure the Fruit car-mode file so the top-level methods mostly compose
smaller helpers. Keep stream ownership in place, but move repeated local
expressions into helpers such as:

```dart
Widget _buildFruitCarModeHudStats({
  required BuildContext context,
  required AudioProvider audioProvider,
  required double scaleFactor,
}) { ... }

Widget _buildFruitCarModeMetaDetails({
  required BuildContext context,
  required Source currentSource,
  required double scaleFactor,
}) { ... }

Widget _buildFruitCarModeDurationText(
  BuildContext context,
  String text,
  double scaleFactor,
) { ... }
```

Also keep the rating dialog and tab-navigation behavior unchanged.

- [ ] **Step 4: Run targeted analysis again**

Run from repo root:

```bash
dart analyze packages/shakedown_core/lib/ui/screens/playback_screen.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/ui/screens/playback_screen.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart
git commit -m "refactor: decompose fruit car mode builders"
```

### Task 3: Extract Steal Graph Render Helpers

**Files:**
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart`

- [ ] **Step 1: Write the structural extraction**

Start by extracting repeated text and panel setup into private helpers that stay
inside the `StealGraph` extension file:

```dart
TextStyle _monoLabelStyle({
  required Color color,
  required double fontSize,
  required FontWeight fontWeight,
  double letterSpacing = 1.0,
}) {
  return TextStyle(
    color: color,
    fontSize: fontSize,
    fontWeight: fontWeight,
    letterSpacing: letterSpacing,
    fontFamily: 'RobotoMono',
  );
}

void _paintMonoLabel(Canvas canvas, String text, Offset offset, TextStyle style) {
  _textPainter
    ..text = TextSpan(text: text, style: style)
    ..layout();
  _textPainter.paint(canvas, offset);
}
```

- [ ] **Step 2: Run targeted analysis**

Run from repo root:

```bash
dart analyze packages/shakedown_core/lib/steal_screensaver/steal_graph.dart packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart
```

Expected: either no issues or helper-signature errors that you fix before
continuing.

- [ ] **Step 3: Finish the minimal implementation**

Refactor `_renderCorner`, `_renderScope`, `_drawVuMeter`, and `_drawLedStrip`
to call extracted helpers for repeated panel chrome, label painting, and paint
construction. Keep all render math unchanged where practical. Useful helper
shapes include:

```dart
void _drawHudPanel(Canvas canvas, RRect panelRect) { ... }

Paint _glowFillPaint({
  required Color color,
  required double alpha,
  required double sigma,
}) { ... }

Paint _strokePaint({
  required Color color,
  required double width,
  StrokeCap strokeCap = StrokeCap.round,
}) { ... }
```

- [ ] **Step 4: Run targeted analysis again**

Run from repo root:

```bash
dart analyze packages/shakedown_core/lib/steal_screensaver/steal_graph.dart packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart packages/shakedown_core/test/steal_screensaver/steal_graph_test.dart
```

Expected: `No issues found!`

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart packages/shakedown_core/lib/steal_screensaver/steal_graph.dart packages/shakedown_core/test/steal_screensaver/steal_graph_test.dart
git commit -m "refactor: simplify steal graph corner rendering"
```

### Task 4: Format, Analyze, And Run Focused Verification

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart`
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart`
- Test: `packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart`
- Test: `packages/shakedown_core/test/screens/playback_screen_fruit_inset_test.dart`
- Test: `packages/shakedown_core/test/steal_screensaver/steal_graph_test.dart`

- [ ] **Step 1: Format the touched files**

Run from repo root:

```bash
dart format packages/shakedown_core/lib/ui/screens/playback_screen.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart packages/shakedown_core/test/screens/playback_screen_fruit_inset_test.dart packages/shakedown_core/test/steal_screensaver/steal_graph_test.dart
```

Expected: formatter updates style only.

- [ ] **Step 2: Run targeted analysis**

Run from repo root:

```bash
dart analyze packages/shakedown_core/lib/ui/screens/playback_screen.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart packages/shakedown_core/test/screens/playback_screen_fruit_inset_test.dart packages/shakedown_core/test/steal_screensaver/steal_graph_test.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Run the focused test suite**

Run from `packages/shakedown_core`:

```bash
flutter test test/screens/playback_screen_fruit_car_mode_test.dart
flutter test test/screens/playback_screen_fruit_inset_test.dart
flutter test test/steal_screensaver/steal_graph_test.dart
```

Expected: PASS for all three test files.

- [ ] **Step 4: Review git diff**

Run from repo root:

```bash
git diff -- packages/shakedown_core/lib/ui/screens/playback_screen.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart
```

Expected: only the intended refactor and focused tests are present.

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/ui/screens/playback_screen.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart
git commit -m "refactor: clean up fruit car mode and steal graph helpers"
```
