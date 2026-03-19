# Test Mocking Templates

This document provides standardized mock stubs and `MultiProvider` setup
patterns for GDAR Flutter tests. Use it during test repair work to resolve
`MissingStubError` and `ProviderNotFoundException` with minimal drift.

## Standard MultiProvider Setup
When a test fails with `ProviderNotFoundException`, use this snippet to wrap the
`MaterialApp`:

```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
    ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
    ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
    ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
    ChangeNotifierProvider<ShowListProvider>.value(value: mockShowListProvider),
  ],
  child: MaterialApp(home: child),
)
```

## Common Mock Stubs

### SettingsProvider
```dart
when(mockSettingsProvider.useNeumorphism).thenReturn(true);
when(mockSettingsProvider.performanceMode).thenReturn(false);
when(mockSettingsProvider.useTrueBlack).thenReturn(false);
when(mockSettingsProvider.uiScale).thenReturn(1.0);
when(mockSettingsProvider.appFont).thenReturn('Outfit');
when(mockSettingsProvider.hideTrackDuration).thenReturn(false);
```

### AudioProvider
```dart
when(mockAudioProvider.isPlaying).thenReturn(false);
when(mockAudioProvider.currentTrack).thenReturn(null);
when(mockAudioProvider.currentShow).thenReturn(null);
when(mockAudioProvider.currentSource).thenReturn(null);
```

### ThemeProvider
```dart
when(mockThemeProvider.themeStyle).thenReturn(ThemeStyle.fruit);
when(mockThemeProvider.isDarkMode).thenReturn(true);
```

## Usage
1. Identify the missing stub or provider in the failing test.
2. Use this doc to find the correct `when(...)` or `Provider` block.
3. Apply the smallest fix that restores the test's intended coverage.
