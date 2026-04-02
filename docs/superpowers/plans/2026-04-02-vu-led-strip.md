# VU Meter LED Strip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a vertical stereo LED VU strip between the two analog VU meters in the `'vu'` audio graph mode, widening the gap so the meters no longer overlap.

**Architecture:** All changes are in `steal_graph.dart`. Widen the `gap` constant in `_renderVu` from `10.0` to `44.0`, insert a `_drawLedStrip` call between the two `_drawVuMeter` calls, and implement `_drawLedStrip` as a new private helper following the same pattern as `_drawVuMeter`. Reuses existing `_vuLeft`/`_vuRight`/`_vuPeakLeft`/`_vuPeakRight` state, zone colors, drift, and fast-mode guard.

**Tech Stack:** Flutter/Dart, Flame engine, Canvas API

---

## File Map

| File | Change |
|---|---|
| `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart` | Widen gap, insert `_drawLedStrip` call, add `_drawLedStrip` method |
| `packages/shakedown_core/test/steal_screensaver/steal_graph_test.dart` | No new tests needed — `_drawLedStrip` is a private Canvas method, untestable at unit level; visual verification on device |

> **Note on testing:** `StealGraph` renders onto a Flame canvas. The existing `steal_graph_test.dart` tests use `FlameTester` to verify mode/visibility state, not pixel output. `_drawLedStrip` has no testable return value or state side-effect — correctness is verified by visual inspection on device. No new tests are added.

---

## Task 1: Widen gap and insert LED strip call

**Files:**
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart` (lines 1229–1260)

- [ ] **Step 1: Read the current `_renderVu` method to confirm line numbers**

Read `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart` lines 1227–1260 and confirm:
- `const gap = 10.0;` is at line ~1233
- The two `_drawVuMeter` calls are at lines ~1238 and ~1249

- [ ] **Step 2: Replace `_renderVu` with the widened gap and LED strip call**

Replace the entire `_renderVu` method body (lines 1229–1260) with:

```dart
  void _renderVu(Canvas canvas) {
    final drift = _burnInDrift();
    final cx = game.size.x / 2 + drift.dx;
    final baseY = game.size.y - _bottomPadding + drift.dy;
    const gap = 44.0;
    final lRange = _hasRealStereo ? 'ST' : 'LO';
    final rRange = _hasRealStereo ? 'ST' : 'HI';

    _drawVuMeter(
      canvas,
      cx - _vuWidth - gap / 2,
      baseY,
      _vuLeft,
      _vuPeakLeft,
      _vuRawLeft,
      'L',
      lRange,
      _vuDrive,
    );
    _drawLedStrip(canvas, cx, baseY, drift);
    _drawVuMeter(
      canvas,
      cx + gap / 2,
      baseY,
      _vuRight,
      _vuPeakRight,
      _vuRawRight,
      'R',
      rRange,
      _vuDrive,
    );
  }
```

- [ ] **Step 3: Run analyze to catch any immediate issues**

```bash
cd C:/Users/jeff/StudioProjects/gdar && flutter analyze packages/shakedown_core/lib/steal_screensaver/steal_graph.dart 2>&1 | tail -5
```

Expected: compile error about `_drawLedStrip` not being defined (that's correct — we haven't added it yet).

- [ ] **Step 4: Commit the gap change stub**

```bash
git add packages/shakedown_core/lib/steal_screensaver/steal_graph.dart
git commit -m "feat(vu): widen gap to 44px and stub _drawLedStrip call"
```

---

## Task 2: Implement `_drawLedStrip`

**Files:**
- Modify: `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart` (insert after `_drawVuMeter` method, line ~1532)

- [ ] **Step 1: Add the new constants block after the existing VU constants**

After `static const double _vuSweepHalf = 1.1;` (line ~127), add:

```dart
  // ── LED strip constants ──────────────────────────────────────────────────
  static const double _ledStripWidth = 28.0;
  static const int _ledSegmentCount = 16;
  static const double _ledLabelReserve = 18.0;
  static const double _ledColGap = 2.0;
  static const double _ledSegGap = 1.5;
  static const double _ledHPad = 3.0;
```

- [ ] **Step 2: Insert `_drawLedStrip` after `_drawVuMeter` ends (line ~1532)**

Add this method immediately after the closing `}` of `_drawVuMeter`:

```dart
  void _drawLedStrip(Canvas canvas, double cx, double baseY, Offset drift) {
    final stripLeft = cx - _ledStripWidth / 2 + drift.dx;
    const stripHeight = _vuHeight;
    const usableHeight = stripHeight - _ledLabelReserve;
    const segH =
        (usableHeight - (_ledSegmentCount - 1) * _ledSegGap) / _ledSegmentCount;
    const colW = (_ledStripWidth - _ledHPad * 2 - _ledColGap) / 2;

    // Panel background (skipped in fast mode).
    if (!_isFast) {
      final panelRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(stripLeft, baseY - stripHeight, _ledStripWidth, stripHeight),
        const Radius.circular(4),
      );
      canvas.drawRRect(
        panelRect,
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.05)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRRect(
        panelRect,
        Paint()
          ..color = const Color(0xFFFFFFFF)
              .withValues(alpha: 0.12 + _beatFlash * 0.06)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // Compute active segment indices (0 = bottom).
    final leftActive = (_vuLeft.clamp(0.0, 1.0) * (_ledSegmentCount - 1)).round();
    final rightActive = (_vuRight.clamp(0.0, 1.0) * (_ledSegmentCount - 1)).round();
    final leftPeakIdx = _vuPeakLeft > 0.02
        ? (_vuPeakLeft.clamp(0.0, 1.0) * (_ledSegmentCount - 1)).round()
        : -1;
    final rightPeakIdx = _vuPeakRight > 0.02
        ? (_vuPeakRight.clamp(0.0, 1.0) * (_ledSegmentCount - 1)).round()
        : -1;

    for (int seg = 0; seg < _ledSegmentCount; seg++) {
      // Zone color.
      final Color zoneColor;
      if (seg >= 13) {
        zoneColor = const Color(0xFFFF4444);
      } else if (seg >= 10) {
        zoneColor = const Color(0xFFFFE66D);
      } else {
        zoneColor = const Color(0xFF4AF3C6);
      }

      // Y position: seg 0 is at the bottom, seg 15 at the top.
      final segBottom =
          baseY - _ledLabelReserve - seg * (segH + _ledSegGap);
      final segTop = segBottom - segH;

      // Left column.
      final lColLeft = stripLeft + _ledHPad;
      final lIsActive = seg <= leftActive;
      final lIsPeak = seg == leftPeakIdx;
      _drawLedSegment(
        canvas,
        Rect.fromLTRB(lColLeft, segTop, lColLeft + colW, segBottom),
        zoneColor,
        lIsActive,
        lIsPeak,
      );

      // Right column.
      final rColLeft = stripLeft + _ledHPad + colW + _ledColGap;
      final rIsActive = seg <= rightActive;
      final rIsPeak = seg == rightPeakIdx;
      _drawLedSegment(
        canvas,
        Rect.fromLTRB(rColLeft, segTop, rColLeft + colW, segBottom),
        zoneColor,
        rIsActive,
        rIsPeak,
      );
    }

    // Bottom labels.
    final lLabelX = stripLeft + _ledHPad + colW / 2;
    final rLabelX = stripLeft + _ledHPad + colW + _ledColGap + colW / 2;
    for (final entry in [('L', lLabelX), ('R', rLabelX)]) {
      _textPainter.text = TextSpan(
        text: entry.$1,
        style: const TextStyle(
          color: Color(0xFF445566),
          fontSize: 6,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.0,
          fontFamily: 'RobotoMono',
        ),
      );
      _textPainter.layout();
      _textPainter.paint(
        canvas,
        Offset(
          entry.$2 - _textPainter.width / 2,
          baseY - _ledLabelReserve + 4,
        ),
      );
    }
  }

  void _drawLedSegment(
    Canvas canvas,
    Rect rect,
    Color zoneColor,
    bool isActive,
    bool isPeak,
  ) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(1));
    // Fill.
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = zoneColor.withValues(alpha: isActive ? 0.85 : 0.08)
        ..style = PaintingStyle.fill,
    );
    // Peak hold outline.
    if (isPeak) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = zoneColor.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8,
      );
    }
  }
```

- [ ] **Step 3: Run analyze — must pass clean**

```bash
cd C:/Users/jeff/StudioProjects/gdar && flutter analyze packages/shakedown_core/lib/steal_screensaver/steal_graph.dart 2>&1 | tail -5
```

Expected: `No issues found!`

- [ ] **Step 4: Run existing test suite**

```bash
flutter test packages/shakedown_core/test/steal_screensaver/steal_graph_test.dart -v 2>&1 | tail -10
```

Expected: all existing tests pass (visibility test + audio energy test).

- [ ] **Step 5: Run full shakedown_core test suite**

```bash
flutter test packages/shakedown_core/ --reporter=compact 2>&1 | tail -5
```

Expected: all tests pass (known pre-existing failure `verify_data_integrity_test.dart` is acceptable).

- [ ] **Step 6: Commit**

```bash
git add packages/shakedown_core/lib/steal_screensaver/steal_graph.dart
git commit -m "feat(vu): add vertical stereo LED strip between analog VU meters"
```

---

## Manual Smoke Test (on device)

After both tasks are committed:

1. Open TV settings → Screensaver → enable Shakedown Screen Saver
2. Enable Audio Reactivity
3. Set Audio Graph to `VU`
4. Verify:
   - Two analog meters are visibly separated (no overlap)
   - A narrow two-column LED strip appears centered between them
   - Bottom of strip shows "L" and "R" labels
   - Left column tracks the L channel needle, right column tracks R
   - Active segments light teal → yellow → red from bottom to top
   - A peak segment outline holds briefly at the high-water mark before decaying
   - In fast mode (`performanceLevel = 2`), panel background is absent but segments still render

---

