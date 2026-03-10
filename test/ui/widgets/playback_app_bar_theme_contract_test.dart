import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/playback/playback_app_bar.dart';
import 'package:shakedown/ui/widgets/theme/fruit_icon_button.dart';

import '../../helpers/test_helpers.dart';
import '../../mocks/fake_catalog_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final track = Track(
    trackNumber: 1,
    title: 'Touch of Grey',
    duration: 360,
    url: 'https://archive.org/download/test/01.mp3',
    setName: 'Set 1',
  );

  final source = Source(
    id: 'gd1987-07-04.test',
    src: 'sbd',
    tracks: [track],
    location: 'Buffalo, NY',
  );

  final show = Show(
    name: '1987-07-04',
    artist: 'Grateful Dead',
    date: '1987-07-04',
    venue: 'Rich Stadium',
    location: 'Buffalo, NY',
    sources: [source],
  );

  setUp(() async {
    CatalogService.setMock(FakeCatalogService());
  });

  Future<Widget> buildHarness({
    required ThemeProvider themeProvider,
    required SettingsProvider settingsProvider,
  }) async {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<DeviceService>.value(value: MockDeviceService()),
      ],
      child: MaterialApp(
        home: Scaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: PlaybackAppBar(
              currentShow: show,
              currentSource: source,
              backgroundColor: Colors.black,
              panelPosition: 0.0,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
      'Android style does not render FruitIconButton in playback app bar action',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'theme_style_preference': 0,
    });
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs);
    final themeProvider = ThemeProvider();
    themeProvider.setThemeStyle(ThemeStyle.android);

    await tester.pumpWidget(await buildHarness(
      themeProvider: themeProvider,
      settingsProvider: settingsProvider,
    ));
    await tester.pump();

    expect(find.byType(FruitIconButton), findsNothing);
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);
  });

  testWidgets('Fruit style renders FruitIconButton in playback app bar action',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'theme_style_preference': 1,
    });
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs);
    final themeProvider = ThemeProvider();
    themeProvider.testOnlyOverrideFruitAllowed = true;
    themeProvider.setThemeStyle(ThemeStyle.fruit);

    await tester.pumpWidget(await buildHarness(
      themeProvider: themeProvider,
      settingsProvider: settingsProvider,
    ));
    await tester.pump();

    expect(find.byType(FruitIconButton), findsOneWidget);
  });
}
