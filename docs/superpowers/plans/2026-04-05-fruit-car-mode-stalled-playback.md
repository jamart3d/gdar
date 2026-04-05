# Fruit Car Mode Stalled Playback Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore reliable progress and duration updates in Fruit car mode on Web/PWA when playback continues but JS-to-Dart state delivery stalls.

**Architecture:** Treat this as a bridge recovery bug, not a Fruit-only UI bug. First prove whether the active web engine keeps advancing `getState().position` while Dart stops receiving `onStateChange` ticks, then add a narrow Dart-side resync path that uses the existing JS `getState()` bridge and only activates on visibility restore or confirmed stale-tick conditions.

**Tech Stack:** Flutter, Dart, `just_audio`, browser JS engines under `apps/gdar_web/web`, Node-based JS regression harness, Flutter widget/unit tests.

---

### Task 1: Reproduce The Stall At The Correct Boundary

**Files:**
- Create: `apps/gdar_web/web/tests/stalled_progress_regression.js`
- Modify: `apps/gdar_web/web/tests/mock_harness.js`
- Modify: `apps/gdar_web/web/tests/run_tests.js`
- Reference: `apps/gdar_web/web/tests/visibility_regression.js`
- Reference: `apps/gdar_web/web/hybrid_init.js`

- [ ] **Step 1: Write the failing JS regression test**

```js
/**
 * Regression: active engine position continues moving, but Dart-facing
 * state callbacks stop until a manual playlist reset.
 */
const fs = require('fs');
const path = require('path');

require('./mock_harness.js');

function loadScript(filename) {
  const filePath = path.join(__dirname, '..', filename);
  const code = fs.readFileSync(filePath, 'utf8');
  eval(code);
}

loadScript('audio_heartbeat.js');
loadScript('audio_scheduler.js');
loadScript('gapless_audio_engine.js');
loadScript('html5_audio_engine.js');
loadScript('hybrid_html5_engine.js');
loadScript('hybrid_audio_engine.js');

function assert(condition, message) {
  if (!condition) {
    console.error('FAILED:', message);
    process.exit(1);
  }
  console.log('PASSED:', message);
}

async function run() {
  const engine = global._html5Audio;
  let callbackCount = 0;

  engine.onStateChange(() => {
    callbackCount += 1;
  });

  engine.setPlaylist([{ url: 'http://test.mp3', duration: 300 }], 0);
  await engine.play();

  global.__advanceMockPlayback(10);
  const beforeFreeze = engine.getState().position;
  assert(beforeFreeze > 0, 'engine state should advance before freeze');

  global.__suspendStateCallbacks(true);
  global.__advanceMockPlayback(5);
  const afterFreeze = engine.getState().position;

  assert(afterFreeze > beforeFreeze, 'engine state should still advance while callbacks are frozen');
  assert(callbackCount > 0, 'state callback should have emitted before freeze');

  global.__resumeStateCallbacks();
  global.document.visibilityState = 'visible';
  global.document.dispatchEvent(new Event('visibilitychange'));

  setTimeout(() => {
    assert(callbackCount > 1, 'visibility restore should cause a fresh state emission');
    process.exit(0);
  }, 0);
}

run().catch((error) => {
  console.error(error);
  process.exit(1);
});
```

- [ ] **Step 2: Extend the mock harness with explicit freeze/resume controls**

```js
let __stateCallbacksSuspended = false;
let __mockPlaybackSeconds = 0;

global.__advanceMockPlayback = (seconds) => {
  __mockPlaybackSeconds += seconds;
  if (global.__mockAudioContextInstances) {
    global.__mockAudioContextInstances.forEach((ctx) => {
      ctx.currentTime += seconds;
    });
  }
};

global.__suspendStateCallbacks = (enabled) => {
  __stateCallbacksSuspended = enabled;
};

global.__resumeStateCallbacks = () => {
  __stateCallbacksSuspended = false;
};
```

Add the corresponding guard where mock engine callbacks are invoked:

```js
if (__stateCallbacksSuspended) {
  return;
}
callback(payload);
```

- [ ] **Step 3: Register the new regression in the test runner**

```js
require('./stalled_progress_regression.js');
```

If `run_tests.js` is too stateful to safely append to, keep this test standalone and document the direct invocation instead of forcing it into the aggregate harness.

- [ ] **Step 4: Run the JS regression and verify it fails first**

Run:

```bash
node apps/gdar_web/web/tests/stalled_progress_regression.js
```

Expected before the fix:

```text
FAILED: visibility restore should cause a fresh state emission
```

- [ ] **Step 5: Record the observed failing engine**

Capture and paste the exact engine under test and state snapshot fields:

```js
console.log({
  engineType: engine.engineType,
  state: engine.getState(),
});
```

The implementation must proceed only after confirming whether the failing path is `html5`, `hybrid`, or `webAudio`.

### Task 2: Add Narrow Dart-Side Resync Using Existing `getState()`

**Files:**
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart`
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_engine.dart`
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_api.dart`
- Reference: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_accessors.dart`

- [ ] **Step 1: Add a failing pure-Dart contract test target by extracting the resync policy**

Create a small helper in the web player layer so the recovery decision can be tested without browser interop:

```dart
class WebTickStallPolicy {
  static bool shouldResync({
    required bool playing,
    required bool visible,
    required DateTime? lastTickAt,
    required Duration stallThreshold,
    required DateTime now,
  }) {
    if (!playing || !visible || lastTickAt == null) return false;
    return now.difference(lastTickAt) >= stallThreshold;
  }
}
```

Add a matching test file:

```dart
test('resyncs only when visible, playing, and tick gap exceeds threshold', () {
  final now = DateTime(2026, 4, 5, 12);

  expect(
    WebTickStallPolicy.shouldResync(
      playing: true,
      visible: true,
      lastTickAt: now.subtract(const Duration(seconds: 3)),
      stallThreshold: const Duration(seconds: 2),
      now: now,
    ),
    isTrue,
  );
});
```

- [ ] **Step 2: Add a bridge method that pulls JS state on demand**

In `gapless_player_web_engine.dart`, add a method that reuses the existing `getState()` interop:

```dart
void _resyncFromJsState({String reason = 'manual'}) {
  if (!_useJsEngine) return;

  _callEngine((engine) {
    try {
      final state = engine.getState();
      logger.i('GaplessPlayerWeb: resyncFromJsState reason=$reason');
      _onJsStateChange(state);
    } catch (error, stackTrace) {
      logger.w('GaplessPlayerWeb: resync failed: $error\n$stackTrace');
    }
  });
}
```

- [ ] **Step 3: Trigger resync when the page becomes visible again**

Update the visibility listener so it does more than emit the `VIS/HID` string:

```dart
if (_isVisible) {
  _resyncFromJsState(reason: 'visibility_visible');
}
```

Keep the existing `_visibilityController.add(_visibilityStatus);` behavior intact.

- [ ] **Step 4: Add a low-frequency Dart watchdog timer**

Extend `_GaplessPlayerBase` with timer state:

```dart
Timer? _staleTickTimer;
static const _staleTickThreshold = Duration(seconds: 2);
static const _staleTickPollInterval = Duration(seconds: 1);
```

Start it when the JS engine initializes:

```dart
void _startStaleTickWatchdog() {
  _staleTickTimer ??= Timer.periodic(_staleTickPollInterval, (_) {
    if (
        WebTickStallPolicy.shouldResync(
          playing: _playing,
          visible: _isVisible,
          lastTickAt: _lastTickAt,
          stallThreshold: _staleTickThreshold,
          now: DateTime.now(),
        )) {
      _resyncFromJsState(reason: 'stale_tick');
    }
  });
}
```

Cancel it in `dispose()`:

```dart
_staleTickTimer?.cancel();
_staleTickTimer = null;
```

- [ ] **Step 5: Run the new Dart test and ensure the JS regression still fails or passes for the right reason**

Run:

```bash
flutter test packages/shakedown_core/test/services/web_tick_stall_policy_test.dart
```

Expected:

```text
All tests passed!
```

Then rerun:

```bash
node apps/gdar_web/web/tests/stalled_progress_regression.js
```

Expected after the bridge change:

```text
PASSED: visibility restore should cause a fresh state emission
```

### Task 3: Protect The UI Contract And Verify No Regressions

**Files:**
- Modify: `packages/shakedown_core/test/services/web_gapless_adapter_test.dart`
- Modify: `packages/shakedown_core/test/screens/playback_screen_test.dart`
- Reference: `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart`

- [ ] **Step 1: Add a Dart-side adapter contract test for resumed position delivery**

Append a test to `web_gapless_adapter_test.dart`:

```dart
testWidgets('position updates continue after a stalled interval resumes', (
  WidgetTester tester,
) async {
  await tester.runAsync(() async {
    final values = <Duration>[];
    final subscription = audioProvider.positionStream.listen(values.add);

    positionController.add(const Duration(seconds: 10));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await Future<void>.delayed(const Duration(milliseconds: 100));

    positionController.add(const Duration(seconds: 16));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(values, contains(const Duration(seconds: 10)));
    expect(values, contains(const Duration(seconds: 16)));

    await subscription.cancel();
  });
});
```

- [ ] **Step 2: Add a playback screen regression for Fruit progress text refresh**

In `playback_screen_test.dart`, add a test that pumps the Fruit car mode screen with a mock player and emits two position values separated by an artificial gap:

```dart
testWidgets('Fruit car mode progress text refreshes after delayed stream resume', (
  WidgetTester tester,
) async {
  await pumpPlaybackScreen(
    tester,
    forceFruitCarMode: true,
  );

  positionController.add(const Duration(minutes: 1, seconds: 5));
  await tester.pump();

  expect(find.text('1:05'), findsOneWidget);

  positionController.add(const Duration(minutes: 1, seconds: 11));
  await tester.pump();

  expect(find.text('1:11'), findsOneWidget);
});
```

- [ ] **Step 3: Run the focused Dart regressions**

Run:

```bash
flutter test packages/shakedown_core/test/services/web_gapless_adapter_test.dart
flutter test packages/shakedown_core/test/screens/playback_screen_test.dart
```

Expected:

```text
All tests passed!
```

- [ ] **Step 4: Run the web engine regressions**

Run:

```bash
node apps/gdar_web/web/tests/visibility_regression.js
node apps/gdar_web/web/tests/stalled_progress_regression.js
```

Expected:

```text
All Universal Visibility & PWA Intent tests passed.
PASSED: visibility restore should cause a fresh state emission
```

- [ ] **Step 5: Run repository-level validation for touched areas**

Run:

```bash
flutter test packages/shakedown_core/test/services/web_gapless_adapter_test.dart
flutter test packages/shakedown_core/test/screens/playback_screen_test.dart
dart format packages/shakedown_core/lib/services/gapless_player packages/shakedown_core/test/services packages/shakedown_core/test/screens
```

Expected:

```text
All tests passed!
Changed <n> files
```

## Self-Review

- Spec coverage:
  This plan covers reproduction, engine identification, bridge resync, visibility recovery, stale-tick recovery, and Dart/UI regression protection. It intentionally does not include `AudioProviderPlayback` changes because the provider is not the stream source for this bug.
- Placeholder scan:
  No `TODO`, `TBD`, or “handle appropriately” placeholders remain. Commands, files, and minimal code samples are included for each task.
- Type consistency:
  The plan uses a single bridge entrypoint name, `_resyncFromJsState`, and a single policy helper name, `WebTickStallPolicy`, across all tasks.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-05-fruit-car-mode-stalled-playback.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
