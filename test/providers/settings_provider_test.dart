import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/providers/settings_provider.dart';

void main() {
  late SettingsProvider settingsProvider;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({
      'first_run_check_done': true,
    });
    final prefs = await SharedPreferences.getInstance();
    settingsProvider = SettingsProvider(prefs);
  });

  group('SettingsProvider Shakedown Tween', () {
    test('initializes enableShakedownTween to false by default', () {
      expect(settingsProvider.enableShakedownTween, false);
    });

    test('toggleEnableShakedownTween toggles value and persists', () async {
      // Verify initial state
      expect(settingsProvider.enableShakedownTween, false);

      // Toggle ON
      settingsProvider.toggleEnableShakedownTween();
      expect(settingsProvider.enableShakedownTween, true);

      // Verify persistence
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('enable_shakedown_tween'), true);

      // Toggle OFF
      settingsProvider.toggleEnableShakedownTween();
      expect(settingsProvider.enableShakedownTween, false);
      expect(prefs.getBool('enable_shakedown_tween'), false);
    });

    test('initializes with true if saved in prefs', () async {
      SharedPreferences.setMockInitialValues({
        'first_run_check_done': true,
        'enable_shakedown_tween': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final provider = SettingsProvider(prefs);

      expect(provider.enableShakedownTween, true);
    });
  });
}
