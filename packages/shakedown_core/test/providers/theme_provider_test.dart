import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeProvider toggleTheme tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test(
      'toggleTheme(Brightness.dark) should switch to light when system is dark',
      () async {
        final provider = ThemeProvider(isTv: false);
        // Ensure preferences are loaded
        await provider.initializationComplete;

        // Default _themeModeIndex is 0 (System)
        expect(provider.selectedThemeMode, ThemeMode.system);

        // If system is dark, toggleTheme should move to Light mode
        provider.toggleTheme(currentBrightness: Brightness.dark);
        expect(provider.selectedThemeMode, ThemeMode.light);
      },
    );

    test(
      'toggleTheme(Brightness.light) should switch to dark when system is light',
      () async {
        final provider = ThemeProvider(isTv: false);
        await provider.initializationComplete;

        expect(provider.selectedThemeMode, ThemeMode.system);

        provider.toggleTheme(currentBrightness: Brightness.light);
        expect(provider.selectedThemeMode, ThemeMode.dark);
      },
    );

    test(
      'toggleTheme() without brightness should use isDarkMode fallback',
      () async {
        final provider = ThemeProvider(isTv: false); // isDarkMode = false
        await Future.delayed(Duration.zero);

        provider.toggleTheme();
        expect(provider.selectedThemeMode, ThemeMode.dark);
      },
    );
  });
}
