# Web Buffer Agent Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make web buffering recovery faster and user-visible by switching visible web sessions to a 10 second stall threshold and surfacing browser-blocked resume failures as a clear Fruit-safe playback message.

**Architecture:** Keep the existing split between the JS engine stale-tick watchdog and Dart `BufferAgent`. Narrow the change to three layers: a small Dart-side stall-threshold policy for `BufferAgent`, a dedicated JS-to-Dart `playBlocked` bridge on `GaplessPlayer`, and an `AudioProvider` message path that reuses the existing playback status line instead of introducing new Material UI.

**Tech Stack:** Flutter, Dart, `just_audio`, JS interop in `gapless_player_web.dart`, Flutter unit/widget tests, Mockito-generated mocks.

---

### Task 1: Make BufferAgent Use A Web-Specific Stall Threshold

**Files:**
- Create: `packages/shakedown_core/lib/services/buffer_agent_stall_policy.dart`
- Modify: `packages/shakedown_core/lib/services/buffer_agent.dart`
- Create: `packages/shakedown_core/test/services/buffer_agent_stall_policy_test.dart`
- Reference: `packages/shakedown_core/lib/services/gapless_player/web_tick_stall_policy.dart`

- [ ] **Step 1: Write the failing policy test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/buffer_agent_stall_policy.dart';

void main() {
  group('BufferAgentStallPolicy', () {
    test('uses 10s for visible web playback', () {
      expect(
        BufferAgentStallPolicy.stallThreshold(
          isWeb: true,
          isAppVisible: true,
        ),
        const Duration(seconds: 10),
      );
    });

    test('keeps 20s for hidden web playback', () {
      expect(
        BufferAgentStallPolicy.stallThreshold(
          isWeb: true,
          isAppVisible: false,
        ),
        const Duration(seconds: 20),
      );
    });

    test('keeps 20s for native playback', () {
      expect(
        BufferAgentStallPolicy.stallThreshold(
          isWeb: false,
          isAppVisible: true,
        ),
        const Duration(seconds: 20),
      );
    });
  });
}
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```bash
flutter test packages/shakedown_core/test/services/buffer_agent_stall_policy_test.dart
```

Expected before the implementation:

```text
Error when reading 'package:shakedown_core/services/buffer_agent_stall_policy.dart'
```

- [ ] **Step 3: Add the policy file**

```dart
class BufferAgentStallPolicy {
  static const Duration defaultThreshold = Duration(seconds: 20);
  static const Duration visibleWebThreshold = Duration(seconds: 10);

  static Duration stallThreshold({
    required bool isWeb,
    required bool isAppVisible,
  }) {
    if (isWeb && isAppVisible) {
      return visibleWebThreshold;
    }
    return defaultThreshold;
  }
}
```

- [ ] **Step 4: Update `BufferAgent` to use the policy instead of a hardcoded 20 second threshold**

```dart
import 'package:flutter/foundation.dart';
import 'package:shakedown_core/services/buffer_agent_stall_policy.dart';

bool get _isAppVisible {
  return _appLifecycleState == AppLifecycleState.resumed ||
      (kIsWeb && _appLifecycleState == AppLifecycleState.inactive);
}

Duration get _stallThreshold => BufferAgentStallPolicy.stallThreshold(
  isWeb: kIsWeb,
  isAppVisible: _isAppVisible,
);
```

Replace the current threshold check in `_startBufferingTimer()`:

```dart
if (bufferingDuration >= _stallThreshold && !_isRecovering) {
  logger.w(
    'BufferAgent: Buffering stalled for '
    '${bufferingDuration.inSeconds}s (threshold: '
    '${_stallThreshold.inSeconds}s), attempting recovery',
  );
  _attemptRecovery();
  timer.cancel();
}
```

- [ ] **Step 5: Run the policy test and the existing BufferAgent test suite**

Run:

```bash
flutter test packages/shakedown_core/test/services/buffer_agent_stall_policy_test.dart
flutter test packages/shakedown_core/test/services/buffer_agent_test.dart
```

Expected:

```text
All tests passed
```

- [ ] **Step 6: Commit the threshold policy change**

```bash
git add packages/shakedown_core/lib/services/buffer_agent.dart packages/shakedown_core/lib/services/buffer_agent_stall_policy.dart packages/shakedown_core/test/services/buffer_agent_stall_policy_test.dart
git commit -m "feat: shorten visible web buffer recovery threshold"
```

### Task 2: Bridge Browser `play()` Blocking From JS Into Dart

**Files:**
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart`
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_engine.dart`
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_api.dart`
- Modify: `packages/shakedown_core/lib/services/gapless_player/gapless_player_native.dart`
- Reference: `apps/gdar_web/web/html5_audio_engine.js`
- Reference: `apps/gdar_web/web/hybrid_html5_engine.js`

- [ ] **Step 1: Add a dedicated `playBlocked` callback to the JS interop surface**

In `gapless_player_web.dart`, extend the engine bridge:

```dart
@JS()
@anonymous
extension type _GdarAudioEngine(JSObject _) {
  external void onPlayBlocked(JSFunction callback);
}
```

Add a controller to `_GaplessPlayerBase`:

```dart
final _playBlockedController = StreamController<void>.broadcast();
```

- [ ] **Step 2: Register the callback in the web engine initializer**

In `gapless_player_web_engine.dart`, wire the already-existing JS engine callback into Dart:

```dart
gdar.onPlayBlocked((() {
  logger.w('GaplessPlayerWeb: browser blocked play()');
  _playBlockedController.add(null);
}).toJS);
```

Keep this separate from `_playbackEventController.addError(...)` so `BufferAgent`
does not interpret browser autoplay blocking as a generic transport error and
re-enter recovery.

- [ ] **Step 3: Expose the new stream from both web and native players**

In `gapless_player_web_accessors.dart`:

```dart
Stream<void> get playBlockedStream => _playBlockedController.stream;
```

In `gapless_player_native.dart`:

```dart
Stream<void> get playBlockedStream => const Stream.empty();
```

- [ ] **Step 4: Close the controller during web player disposal**

In `gapless_player_web_api.dart`:

```dart
await _playBlockedController.close();
```

- [ ] **Step 5: Regenerate Mockito mocks that depend on `GaplessPlayer`**

Run:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Expected:

```text
Succeeded after updating generated mock interfaces
```

- [ ] **Step 6: Commit the bridge change**

```bash
git add packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_web_engine.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_web_api.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_native.dart packages/shakedown_core/test/services/buffer_agent_test.mocks.dart packages/shakedown_core/test/providers/audio_provider_test.mocks.dart
git commit -m "feat: expose browser blocked-playback events to dart"
```

### Task 3: Surface A Resume Prompt Through AudioProvider

**Files:**
- Modify: `packages/shakedown_core/lib/providers/audio_provider.dart`
- Modify: `packages/shakedown_core/test/providers/audio_provider_test.dart`
- Modify: `packages/shakedown_core/test/ui/widgets/playback/playback_messages_test.dart`
- Reference: `packages/shakedown_core/lib/providers/audio_provider_diagnostics.dart`
- Reference: `packages/shakedown_core/lib/ui/widgets/playback/playback_messages.dart`

- [ ] **Step 1: Add a failing provider test for the blocked-playback message**

In `audio_provider_test.dart`, create a controller in `setUp()`:

```dart
late StreamController<void> playBlockedController;

playBlockedController = StreamController<void>.broadcast();
when(
  mockAudioPlayer.playBlockedStream,
).thenAnswer((_) => playBlockedController.stream);
```

Add the test:

```dart
test('playBlockedStream sets the browser resume agent message', () async {
  playBlockedController.add(null);
  await Future<void>.delayed(Duration.zero);

  final hud = audioProvider.currentHudSnapshot;
  expect(hud.signal, 'AGT');
  expect(hud.message, 'Playback paused by browser. Tap play to resume.');
});
```

- [ ] **Step 2: Run the provider test and verify it fails**

Run:

```bash
flutter test packages/shakedown_core/test/providers/audio_provider_test.dart --plain-name "playBlockedStream sets the browser resume agent message"
```

Expected before the implementation:

```text
Expected: 'AGT'
  Actual: '--'
```

- [ ] **Step 3: Listen to `playBlockedStream` in `AudioProvider`**

Add a constructor listener next to the existing engine-state listener:

```dart
_audioPlayer.playBlockedStream.listen((_) {
  _setAgentMessage('Playback paused by browser. Tap play to resume.');
});
```

This intentionally reuses the existing diagnostics/HUD message pipeline instead
of introducing a separate popup or Material snackbar, which would violate the
Fruit screen contract.

- [ ] **Step 4: Add a widget test that proves the message renders in the existing playback status line**

In `playback_messages_test.dart`:

```dart
testWidgets('displays browser resume prompt from agent signal', (tester) async {
  when(mockAudioProvider.currentHudSnapshot).thenReturn(
    HudSnapshot.empty().copyWith(
      signal: 'AGT',
      message: 'Playback paused by browser. Tap play to resume.',
      processing: 'BUF',
    ),
  );

  await tester.pumpWidget(createWidgetUnderTest());

  expect(
    find.text('Playback paused by browser. Tap play to resume.'),
    findsOneWidget,
  );
  expect(find.text('Buffering...'), findsNothing);
});
```

- [ ] **Step 5: Run the provider and widget tests**

Run:

```bash
flutter test packages/shakedown_core/test/providers/audio_provider_test.dart --plain-name "playBlockedStream sets the browser resume agent message"
flutter test packages/shakedown_core/test/ui/widgets/playback/playback_messages_test.dart
```

Expected:

```text
All tests passed
```

- [ ] **Step 6: Commit the provider/UI message path**

```bash
git add packages/shakedown_core/lib/providers/audio_provider.dart packages/shakedown_core/test/providers/audio_provider_test.dart packages/shakedown_core/test/ui/widgets/playback/playback_messages_test.dart packages/shakedown_core/test/providers/audio_provider_test.mocks.dart packages/shakedown_core/test/ui/widgets/playback/playback_messages_test.mocks.dart
git commit -m "feat: show browser resume prompt after blocked recovery"
```

### Task 4: Verify The Full Web Recovery Path

**Files:**
- Reference: `packages/shakedown_core/lib/services/buffer_agent.dart`
- Reference: `packages/shakedown_core/lib/services/gapless_player/gapless_player_web_engine.dart`
- Reference: `packages/shakedown_core/lib/providers/audio_provider.dart`
- Reference: `reports/2026-04-05_16-07_v1.3.61+271_buffer_agent_web_ui.md`

- [ ] **Step 1: Format the touched Dart files**

Run:

```bash
dart format packages/shakedown_core/lib/services/buffer_agent.dart packages/shakedown_core/lib/services/buffer_agent_stall_policy.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_web_engine.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_web_api.dart packages/shakedown_core/lib/services/gapless_player/gapless_player_native.dart packages/shakedown_core/lib/providers/audio_provider.dart packages/shakedown_core/test/services/buffer_agent_stall_policy_test.dart packages/shakedown_core/test/providers/audio_provider_test.dart packages/shakedown_core/test/ui/widgets/playback/playback_messages_test.dart
```

Expected:

```text
Formatted 10 files
```

- [ ] **Step 2: Run the focused regression suite**

Run:

```bash
flutter test packages/shakedown_core/test/services/buffer_agent_stall_policy_test.dart
flutter test packages/shakedown_core/test/services/buffer_agent_test.dart
flutter test packages/shakedown_core/test/providers/audio_provider_test.dart --plain-name "playBlockedStream sets the browser resume agent message"
flutter test packages/shakedown_core/test/ui/widgets/playback/playback_messages_test.dart
flutter test packages/shakedown_core/test/services/web_tick_stall_policy_test.dart
```

Expected:

```text
All tests passed
```

- [ ] **Step 3: Run the package analysis gate**

Run:

```bash
flutter analyze packages/shakedown_core
```

Expected:

```text
No issues found
```

- [ ] **Step 4: Smoke-test the user-visible behavior in web**

Run the web app, then manually verify:

```text
1. Visible web buffering waits 10 seconds before BufferAgent recovery.
2. Hidden-tab buffering does not spam visible retry notices.
3. If the browser blocks resume, the playback status line shows:
   "Playback paused by browser. Tap play to resume."
4. Pressing the existing play control resumes playback without a page reload.
```
