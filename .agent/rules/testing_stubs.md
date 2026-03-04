---
trigger: when_modifying_tests
---

# GDAR Testing & Mocking Requirements

To prevent regression failures and "ProviderNotFoundException" errors, you MUST ensure that all mock providers used in widget tests implement the core set of properties required by the UI components.

### 1. SettingsProvider Stubs
Any `MockSettingsProvider` or `FakeSettingsProvider` MUST stub the following getters, as they are watched by high-level wrappers like `TvFocusWrapper` and `AnimatedGradientBorder`:
* `useNeumorphism` (bool)
* `performanceMode` (bool)
* `glowMode` (int)
* `rgbAnimationSpeed` (double)

### 2. AudioProvider Stubs
Any `MockAudioProvider` MUST stub:
* `isPlaying` (bool) - Used by the `MiniPlayer` and `PlaybackAppBar`.
* `playbackState` (Stream) - Required for progress bar updates.

### 3. Setup Pattern
Always use the `createTestableWidget` helper from `test_helpers.dart` when setting up widget tests. This ensures a consistent `MultiProvider` tree.

```dart
// Example: Correct test setup
await tester.pumpWidget(
  createTestableWidget(
    child: MyWidget(),
    settingsProvider: mockSettings,
    audioProvider: mockAudio,
    deviceService: mockDevice,
  ),
);
```
