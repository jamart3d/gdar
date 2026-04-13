# Web Position Interpolation Timer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a Dart-side position interpolation timer to `GaplessPlayer` that emits synthetic position ticks between JS engine state callbacks, keeping the progress bar and current-time display smooth when JS ticks are throttled or slow (PWA backgrounding, Android Chrome, audio context stalls).

**Architecture:** A `Timer.periodic(250ms)` runs inside `_GaplessPlayerWebEngine` while playing. On each tick it computes an interpolated position from `_positionSec + elapsed_since_last_tick`, clamps to `[0, _durationSec]`, and adds to `_positionController` — but only when the elapsed time since the last real JS tick is above a minimum gap (250ms) to avoid double-emitting while the JS engine is active. The guard logic lives in `WebTickStallPolicy` (already the home of stall-related decisions). The timer starts/stops with playing state, not on construction.

**Tech Stack:** Dart `dart:async` Timer, existing `_GaplessPlayerBase`/`_GaplessPlayerWebEngine` mixin pattern, `web_tick_stall_policy.dart` (pure Dart, testable without JS).

---

## File Map

| File | Change |
|---|---|
| `packages/shakedown_core/lib/services/gapless_player/web_tick_stall_policy.dart` | Add `shouldInterpolate()` static method |
| `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart` | Add `_interpolationTimer` field + `_interpolationInterval` constant to `_GaplessPlayerBase` |
| `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_engine.dart` | Add `_startInterpolationTimer()`, `_stopInterpolationTimer()`, `_emitInterpolatedPosition()` methods; wire into play/pause/state-change |
| `packages/shakedown_core/test/services/web_tick_stall_policy_test.dart` | Add `shouldInterpolate` test cases |

---

### Task 1: Add `shouldInterpolate` to `WebTickStallPolicy`

**Files:**
- Modify: `packages/shakedown_core/lib/services/gapless_player/web_tick_stall_policy.dart`
- Test: `packages/shakedown_core/test/services/web_tick_stall_policy_test.dart`

The policy method answers: "given that we are playing and the last real JS tick was `elapsed` ago, should the Dart timer emit a synthetic position update?"

Rules:
- Returns `false` if not playing
- Returns `false` if `lastTickAt` is null (engine never started)
- Returns `false` if `elapsed < minGapBeforeInterpolate` (JS tick was recent enough — avoid double-emit)
- Returns `true` otherwise (JS tick is overdue; interpolate)

- [ ] **Step 1: Write the failing tests**

Add a new `group('shouldInterpolate', ...)` block in `packages/shakedown_core/test/services/web_tick_stall_policy_test.dart`:

```dart
group('shouldInterpolate', () {
  final now = DateTime(2026, 4, 13, 10);
  const minGap = Duration(milliseconds: 250);

  test('returns true when playing and tick is overdue', () {
    expect(
      WebTickStallPolicy.shouldInterpolate(
        playing: true,
        lastTickAt: now.subtract(const Duration(milliseconds: 300)),
        minGapBeforeInterpolate: minGap,
        now: now,
      ),
      isTrue,
    );
  });

  test('returns false when not playing', () {
    expect(
      WebTickStallPolicy.shouldInterpolate(
        playing: false,
        lastTickAt: now.subtract(const Duration(milliseconds: 300)),
        minGapBeforeInterpolate: minGap,
        now: now,
      ),
      isFalse,
    );
  });

  test('returns false when lastTickAt is null', () {
    expect(
      WebTickStallPolicy.shouldInterpolate(
        playing: true,
        lastTickAt: null,
        minGapBeforeInterpolate: minGap,
        now: now,
      ),
      isFalse,
    );
  });

  test('returns false when tick was recent (under minGap)', () {
    expect(
      WebTickStallPolicy.shouldInterpolate(
        playing: true,
        lastTickAt: now.subtract(const Duration(milliseconds: 100)),
        minGapBeforeInterpolate: minGap,
        now: now,
      ),
      isFalse,
    );
  });

  test('returns true exactly at minGap boundary', () {
    expect(
      WebTickStallPolicy.shouldInterpolate(
        playing: true,
        lastTickAt: now.subtract(minGap),
        minGapBeforeInterpolate: minGap,
        now: now,
      ),
      isTrue,
    );
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
flutter test packages/shakedown_core/test/services/web_tick_stall_policy_test.dart -v
```

Expected: 5 new test failures — `shouldInterpolate` not defined.

- [ ] **Step 3: Implement `shouldInterpolate` in `web_tick_stall_policy.dart`**

Replace the entire file content:

```dart
class WebTickStallPolicy {
  static bool shouldResync({
    required bool playing,
    required bool visible,
    required DateTime? lastTickAt,
    required Duration stallThreshold,
    required DateTime now,
  }) {
    if (!playing || !visible || lastTickAt == null) {
      return false;
    }
    return now.difference(lastTickAt) >= stallThreshold;
  }

  static bool shouldInterpolate({
    required bool playing,
    required DateTime? lastTickAt,
    required Duration minGapBeforeInterpolate,
    required DateTime now,
  }) {
    if (!playing || lastTickAt == null) {
      return false;
    }
    return now.difference(lastTickAt) >= minGapBeforeInterpolate;
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
flutter test packages/shakedown_core/test/services/web_tick_stall_policy_test.dart -v
```

Expected: All tests pass (both old `shouldResync` tests and new `shouldInterpolate` tests).

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/services/gapless_player/web_tick_stall_policy.dart packages/shakedown_core/test/services/web_tick_stall_policy_test.dart
git commit -m "feat(web): add WebTickStallPolicy.shouldInterpolate for Dart-side position interpolation guard"
```

---

### Task 2: Add interpolation timer fields to `_GaplessPlayerBase`

**Files:**
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart`

Add two members to `_GaplessPlayerBase` alongside the existing `_staleTickTimer` and `_staleTickThreshold` constants (around line 276).

- [ ] **Step 1: Add timer field and interval constant to `_GaplessPlayerBase`**

In `gapless_player_web.dart`, locate the block:

```dart
  Timer? _staleTickTimer;

  static const _staleTickThreshold = Duration(seconds: 2);
  static const _staleTickPollInterval = Duration(seconds: 1);
```

Replace with:

```dart
  Timer? _staleTickTimer;
  Timer? _interpolationTimer;

  static const _staleTickThreshold = Duration(seconds: 2);
  static const _staleTickPollInterval = Duration(seconds: 1);
  static const _interpolationInterval = Duration(milliseconds: 250);
  static const _interpolationMinGap = Duration(milliseconds: 250);
```

- [ ] **Step 2: Verify analyze passes**

```bash
flutter analyze packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart
```

Expected: No errors or new warnings.

- [ ] **Step 3: Commit**

```bash
git add packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart
git commit -m "feat(web): add _interpolationTimer field and interval constants to _GaplessPlayerBase"
```

---

### Task 3: Implement interpolation timer methods in `_GaplessPlayerWebEngine`

**Files:**
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_engine.dart`

Add three methods: `_startInterpolationTimer`, `_stopInterpolationTimer`, `_emitInterpolatedPosition`. Wire `_startInterpolationTimer` into `_emitPlayerState` (already called at the end of every `_onJsStateChange`). Wire `_stopInterpolationTimer` into pause/stop paths.

**How interpolation works:**
- `_positionSec` is the last position reported by JS
- `_lastTickAt` is when that JS tick arrived
- Interpolated position = `_positionSec + elapsed_since_last_tick_in_seconds`
- Clamped to `[0.0, _durationSec]` (never exceed track end)
- Only emitted when `WebTickStallPolicy.shouldInterpolate(...)` returns true

- [ ] **Step 1: Add `_emitInterpolatedPosition` method**

At the bottom of `gapless_player_web_engine.dart`, before the closing `}` of the mixin, add:

```dart
  void _emitInterpolatedPosition() {
    if (!_playing || _lastTickAt == null || _durationSec <= 0) {
      return;
    }
    if (!WebTickStallPolicy.shouldInterpolate(
      playing: _playing,
      lastTickAt: _lastTickAt,
      minGapBeforeInterpolate: _GaplessPlayerBase._interpolationMinGap,
      now: DateTime.now(),
    )) {
      return;
    }
    final elapsedSec =
        DateTime.now().difference(_lastTickAt!).inMicroseconds / 1e6;
    final interpolated =
        (_positionSec + elapsedSec).clamp(0.0, _durationSec);
    _positionController.add(
      Duration(milliseconds: (interpolated * 1000).round()),
    );
  }
```

- [ ] **Step 2: Add `_startInterpolationTimer` and `_stopInterpolationTimer` methods**

Immediately after `_emitInterpolatedPosition`, add:

```dart
  void _startInterpolationTimer() {
    if (_interpolationTimer != null) {
      return;
    }
    _interpolationTimer = Timer.periodic(
      _GaplessPlayerBase._interpolationInterval,
      (_) => _emitInterpolatedPosition(),
    );
  }

  void _stopInterpolationTimer() {
    _interpolationTimer?.cancel();
    _interpolationTimer = null;
  }
```

- [ ] **Step 3: Wire timer start/stop into `_emitPlayerState`**

Find `_emitPlayerState` in `gapless_player_web_engine.dart`. It is called at the end of every `_onJsStateChange`. Add timer management based on playing state.

Current `_emitPlayerState` method (locate it — it should look something like):

```dart
  void _emitPlayerState() {
    _playerStateController.add(PlayerState(_playing, _processingState));
  }
```

Replace with:

```dart
  void _emitPlayerState() {
    _playerStateController.add(PlayerState(_playing, _processingState));
    if (_playing) {
      _startInterpolationTimer();
    } else {
      _stopInterpolationTimer();
    }
  }
```

- [ ] **Step 4: Verify analyze passes**

```bash
flutter analyze packages/shakedown_core/lib/services/gapless_player/gapless_player_web_engine.dart
```

Expected: No errors or new warnings.

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/services/gapless_player/gapless_player_web_engine.dart
git commit -m "feat(web): add Dart-side position interpolation timer to GaplessPlayerWebEngine"
```

---

### Task 4: Cancel interpolation timer on dispose

**Files:**
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_api.dart` (or wherever `dispose()` lives)

- [ ] **Step 1: Find where `_staleTickTimer` is cancelled on dispose**

```bash
grep -n "_staleTickTimer\|dispose\|cancel" packages/shakedown_core/lib/services/gapless_player/gapless_player_web_api.dart
```

Find the `dispose` method that cancels `_staleTickTimer`.

- [ ] **Step 2: Add `_stopInterpolationTimer()` call alongside stale tick cancel**

In the `dispose` method, alongside the line that cancels `_staleTickTimer`, add:

```dart
    _stopInterpolationTimer();
```

- [ ] **Step 3: Verify analyze passes**

```bash
flutter analyze packages/shakedown_core/lib/services/gapless_player/
```

Expected: No errors or new warnings.

- [ ] **Step 4: Commit**

```bash
git add packages/shakedown_core/lib/services/gapless_player/gapless_player_web_api.dart
git commit -m "fix(web): cancel interpolation timer on GaplessPlayer dispose"
```

---

### Task 5: Smoke-test in browser

This is not an automated test — it is a manual verification step because the JS bridge cannot be exercised in unit tests.

- [ ] **Step 1: Build web and serve**

```bash
cd apps/gdar_web && flutter run -d chrome
```

- [ ] **Step 2: Open car mode and play a track**

Navigate to car mode (PWA Fruit theme). Verify:
- Progress bar advances smoothly (not jumpy) during normal playback
- Current time text ticks every ~250ms

- [ ] **Step 3: Throttle JS ticks in DevTools to simulate a stall**

In Chrome DevTools → Console, run:
```javascript
// Temporarily override onStateChange to slow to 1 tick/5s
const orig = window._gdarAudio.onStateChange.bind(window._gdarAudio);
let _cb;
window._gdarAudio.onStateChange = (cb) => { _cb = cb; orig(cb); };
setInterval(() => { if (_cb) _cb(window._gdarAudio.getState()); }, 5000);
```

Expected: Progress bar and time continue advancing smoothly between the 5s JS ticks (interpolation fills the gap).

- [ ] **Step 4: Verify no double-emit jitter during normal playback**

With DevTools Performance panel, confirm no burst of position events faster than 250ms when JS ticks are at normal cadence.

- [ ] **Step 5: Commit final**

```bash
git add .
git commit -m "chore: no-op — manual smoke test only, no code changes"
```

(Skip this step if no code changes were needed after smoke testing. If fixes were required, commit them with a descriptive message instead.)

---

## Self-Review Checklist

- [x] **Spec coverage:** interpolation fills gap between JS ticks ✓, clamps to duration ✓, guard prevents double-emit ✓, timer starts/stops with playing state ✓, dispose cancels timer ✓
- [x] **No placeholders:** all code blocks are complete
- [x] **Type consistency:** `_GaplessPlayerBase._interpolationMinGap` and `_GaplessPlayerBase._interpolationInterval` defined in Task 2, referenced in Task 3 ✓; `_stopInterpolationTimer()` defined in Task 3, referenced in Task 4 ✓
- [x] **`WebTickStallPolicy.shouldInterpolate` parameters** match between Task 1 definition and Task 3 call site ✓
