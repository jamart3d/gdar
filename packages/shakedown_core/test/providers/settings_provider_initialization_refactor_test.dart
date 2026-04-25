import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/config/default_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('constructor initialization preserves first-run marker and uiScale bootstrap', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();

    final provider = SettingsProvider(prefs);

    expect(provider, isNotNull);
    expect(prefs.getBool('first_run_check_done'), isTrue);
    // uiScale defaults to false, but isn't persisted to prefs unless view detection triggers
    expect(provider.uiScale, isFalse);
    expect(prefs.getBool('ui_scale'), isNull);
  });

  test('resetFruitFirstTimeSettings persists Fruit first-run defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'first_run_check_done': true,
      'fruit_dense_list': true,
      'performance_mode': false,
      'oil_banner_glow': true,
    });
    final prefs = await SharedPreferences.getInstance();
    final provider = SettingsProvider(prefs);

    provider.resetFruitFirstTimeSettings();

    expect(provider.performanceMode, isTrue);
    expect(provider.fruitDenseList, isFalse);
    expect(provider.oilBannerGlow, isFalse);
    expect(prefs.getBool('performance_mode'), isTrue);
  });

  test('invalid source filter json falls back to defaults', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'first_run_check_done': true,
      'source_category_filters': '{not valid json',
    });
    final prefs = await SharedPreferences.getInstance();

    final provider = SettingsProvider(prefs);

    expect(
      provider.sourceCategoryFilters,
      equals(DefaultSettings.sourceCategoryFilters),
    );
  });
}
