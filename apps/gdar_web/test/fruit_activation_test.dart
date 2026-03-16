import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';

void main() {
  group('Fruit Theme Activation Regression', () {
    late SettingsProvider settingsProvider;
    late ThemeProvider themeProvider;
    late SharedPreferences prefs;

    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();

      settingsProvider = SettingsProvider(prefs);
      themeProvider = ThemeProvider();
      themeProvider.testOnlyOverrideFruitAllowed = true;
      themeProvider.setSettingsProvider(settingsProvider);
    });

    test('resetFruitFirstTimeSettings flips correct flags', () {
      // Set to "dirty" states
      settingsProvider.toggleFruitDenseList(); // true
      settingsProvider.setGlowMode(2);
      settingsProvider.setHighlightPlayingWithRgb(true);

      expect(settingsProvider.fruitDenseList, true);
      expect(settingsProvider.glowMode, 2);
      expect(settingsProvider.highlightPlayingWithRgb, true);

      // Reset
      settingsProvider.resetFruitFirstTimeSettings();

      expect(settingsProvider.fruitDenseList, false);
      expect(settingsProvider.glowMode, 0);
      expect(settingsProvider.highlightPlayingWithRgb, false);
      expect(settingsProvider.performanceMode, true);
    });

    test(
      'ThemeProvider triggers reset exactly once when switching to Fruit',
      () async {
        // 1. Manually set some settings to true/glow
        settingsProvider.setGlowMode(3);
        expect(settingsProvider.glowMode, 3);

        // 2. Switch to Fruit
        themeProvider.setThemeStyle(ThemeStyle.fruit);

        // Allow for unawaited/async calls if any (though providers use notifyListeners)
        // The reset is triggered via _checkAndResetFruitSettings()

        // Since _checkAndResetFruitSettings is async and internal, we might need a small delay
        // or to await the result if it were public.
        // However, we can check the prefs directly or wait.
        await Future.delayed(Duration.zero);

        expect(
          settingsProvider.glowMode,
          0,
          reason: 'Glow should be reset on first Fruit activation',
        );

        // 3. Disable performance mode so we can set glow (resetFruitFirstTimeSettings sets it to true)
        settingsProvider.togglePerformanceMode();
        settingsProvider.setGlowMode(3);
        expect(settingsProvider.glowMode, 3);

        // 4. Toggle away and back to Fruit
        themeProvider.setThemeStyle(ThemeStyle.android);
        themeProvider.setThemeStyle(ThemeStyle.fruit);

        await Future.delayed(Duration.zero);

        expect(
          settingsProvider.glowMode,
          3,
          reason: 'Glow should NOT be reset on subsequent Fruit activations',
        );
      },
    );
  });
}
