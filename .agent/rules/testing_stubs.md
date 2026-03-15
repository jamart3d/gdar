# Testing Stubs & Helpers

### 1. Mandatory Stubs
When creating widget tests, you MUST provide mock stubs for these core provider methods. Failing to do so will result in `MissingStubError`.

* **MockSettingsProvider**:
  * `useNeumorphism` (bool)
  * `performanceMode` (bool)
  * `useTrueBlack` (bool)
* **MockAudioProvider**:
  * `isPlaying` (bool)
  * `playbackState` (Stream) - Required for progress bar updates.

### 2. Setup Pattern
Always use the `createTestableWidget` helper from your package's `test/helpers/` directory or the shared `packages/shakedown_core/test/helpers.dart`. This ensures a consistent `MultiProvider` tree.

```dart
// Example: Correct test setup
testWidgets('Renders Playback Controls', (tester) async {
  await tester.pumpWidget(createTestableWidget(
    child: const PlaybackControls(),
    settingsProvider: mockSettingsProvider,
  ));
});
```

### 3. Mock Regeneration
If the mock classes (e.g., `MockSettingsProvider`) are missing methods, run:
`dart run build_runner build --delete-conflicting-outputs`
from the package root where the mocks are defined.
