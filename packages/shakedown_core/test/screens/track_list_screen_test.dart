import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/screens/track_list_screen.dart';

import '../helpers/test_helpers.dart';
import '../mocks/fake_catalog_service.dart';

class _IdleAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  Show? get currentShow => null;

  @override
  Track? get currentTrack => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Source _buildSource() {
  return Source(
    id: 'gd77-05-08.sbd',
    tracks: [
      Track(
        trackNumber: 1,
        title: 'Bertha',
        duration: 365,
        url: 'https://archive.org/1.mp3',
        setName: 'Set 1',
      ),
      Track(
        trackNumber: 2,
        title: 'Drums',
        duration: 420,
        url: 'https://archive.org/2.mp3',
        setName: 'Encore',
      ),
      Track(
        trackNumber: 3,
        title: 'U.S. Blues',
        duration: 310,
        url: 'https://archive.org/3.mp3',
        setName: 'Set 1',
      ),
    ],
  );
}

Show _buildShow(Source source) {
  return Show(
    name: '1977-05-08',
    artist: 'Grateful Dead',
    date: '1977-05-08',
    venue: 'Barton Hall',
    location: 'Ithaca, NY',
    sources: [source],
  );
}

void main() {
  setUp(() async {
    CatalogService.setMock(FakeCatalogService());
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    await CatalogService().reset();
  });

  testWidgets(
    'TrackListScreen preserves contiguous set headers in screen body',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final source = _buildSource();
      final show = _buildShow(source);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>(
              create: (_) => SettingsProvider(prefs),
            ),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<DeviceService>.value(
              value: MockDeviceService(),
            ),
            ChangeNotifierProvider<AudioProvider>(
              create: (_) => _IdleAudioProvider(),
            ),
            ChangeNotifierProvider<ShowListProvider>(
              create: (_) => ShowListProvider(),
            ),
          ],
          child: MaterialApp(
            home: TrackListScreen(show: show, source: source),
          ),
        ),
      );

      await tester.pump();

      final setOneFinder = find.text('SET 1');
      final encoreFinder = find.text('ENCORE');

      expect(setOneFinder, findsNWidgets(2));
      expect(encoreFinder, findsOneWidget);

      final firstSetOneY = tester.getTopLeft(setOneFinder.first).dy;
      final encoreY = tester.getTopLeft(encoreFinder).dy;
      final secondSetOneY = tester.getTopLeft(setOneFinder.last).dy;

      expect(firstSetOneY, lessThan(encoreY));
      expect(encoreY, lessThan(secondSetOneY));
    },
  );
}
