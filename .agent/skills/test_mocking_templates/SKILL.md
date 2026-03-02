---
name: test_mocking_templates
description: Standardized Mockito stubs and MultiProvider setup for GDAR Flutter tests.
---

# Test Mocking Templates

This skill provides a centralized repository of standardized mock stubs and provider setups. It is designed to be used by the `/test_fixer` workflow to quickly resolve `MissingStubError` and `ProviderNotFoundException`.

## 1. Standard MultiProvider Setup
When a test fails with `ProviderNotFoundException`, use this snippet to wrap the `MaterialApp`:

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

## 2. Common Mock Stubs

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

## 3. Usage with /test_fixer
1. Trigger `/test_fixer`.
2. The workflow will identify the missing stub or provider.
3. The workflow will refer to this skill to find the correct `when(...)` or `Provider` block.
4. The workflow will then apply the fix to the test file.
