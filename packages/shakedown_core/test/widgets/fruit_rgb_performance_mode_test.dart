import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/ui/widgets/show_list/show_list_card.dart';

import '../helpers/test_helpers.dart';
import '../mocks/fake_catalog_service.dart';

class _TestAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  bool get isPlaying => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    CatalogService.setMock(FakeCatalogService());
  });

  test(
    'performance mode keeps RGB highlight enabled while disabling glass',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final settingsProvider = SettingsProvider(prefs);

      settingsProvider.setHighlightPlayingWithRgb(true);
      settingsProvider.setFruitEnableLiquidGlass(true);
      settingsProvider.setPerformanceMode(true);

      expect(settingsProvider.performanceMode, isTrue);
      expect(settingsProvider.highlightPlayingWithRgb, isTrue);
      expect(settingsProvider.fruitEnableLiquidGlass, isFalse);
      expect(settingsProvider.glowMode, 0);
    },
  );

  testWidgets(
    'Fruit show card keeps RGB border when glass is off and performance mode is on',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final settingsProvider = SettingsProvider(prefs);
      final themeProvider = ThemeProvider();
      await themeProvider.initializationComplete;
      themeProvider.testOnlyOverrideFruitAllowed = true;
      themeProvider.setThemeStyle(ThemeStyle.fruit);

      settingsProvider.setHighlightPlayingWithRgb(true);
      settingsProvider.setFruitEnableLiquidGlass(true);
      settingsProvider.setPerformanceMode(true);

      final show = Show(
        name: '1990-03-29',
        artist: 'Grateful Dead',
        date: '1990-03-29',
        venue: 'Nassau Coliseum',
        sources: [Source(id: 'gd90-03-29.sbd', tracks: const [])],
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
            ChangeNotifierProvider<DeviceService>.value(
              value: MockDeviceService(),
            ),
            ChangeNotifierProvider<AudioProvider>(
              create: (_) => _TestAudioProvider(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: ShowListCard(
                show: show,
                isExpanded: false,
                isPlaying: true,
                isLoading: false,
                onTap: _noop,
                onLongPress: _noop,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(AnimatedGradientBorder), findsOneWidget);
      final border = tester.widget<AnimatedGradientBorder>(
        find.byType(AnimatedGradientBorder),
      );

      expect(border.allowInPerformanceMode, isTrue);
      expect(border.colors, isNotNull);
      expect(border.colors!.first, const Color(0xFFFF0000));
      expect(settingsProvider.fruitEnableLiquidGlass, isFalse);
      expect(settingsProvider.highlightPlayingWithRgb, isTrue);
      expect(show.sources.single.id, 'gd90-03-29.sbd');
    },
  );
}

void _noop() {}
