import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:flutter/material.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/widgets/show_list/show_list_item.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:hive_ce/hive.dart';

class MockAudioProvider extends Mock implements AudioProvider {}

class MockShowListProvider extends Mock implements ShowListProvider {}

class MockCatalogService extends Mock implements CatalogService {}

class MockBoxRating extends Mock implements Box<Rating> {}

class MockBoxBool extends Mock implements Box<bool> {}

class ShowFake extends Fake implements Show {}

void main() {
  setUpAll(() {
    Provider.debugCheckInvalidValueType = null;
    registerFallbackValue(ShowFake());
    final mockCatalog = MockCatalogService();
    final mockRatingsBox = MockBoxRating();
    final mockHistoryBox = MockBoxBool();
    when(() => mockCatalog.ratingsListenable)
        .thenReturn(ValueNotifier(mockRatingsBox));
    when(() => mockCatalog.historyListenable)
        .thenReturn(ValueNotifier(mockHistoryBox));
    when(() => mockCatalog.isInitialized).thenReturn(true);
    when(() => mockCatalog.getRating(any())).thenReturn(0);
    when(() => mockCatalog.isPlayed(any())).thenReturn(false);
    CatalogService.setMock(mockCatalog);
  });
  testWidgets('ShowListItem isPlaying passes correctly to TvFocusWrapper',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs, isTv: true);
    final themeProvider = ThemeProvider(isTv: true);

    final deviceService = DeviceService(initialIsTv: true);

    final show = Show(
      name: 'Test Show',
      artist: 'Grateful Dead',
      date: '1977-05-08',
      venue: 'Barton Hall',
      location: 'Ithaca, NY',
      sources: [],
    );

    final audioProvider = MockAudioProvider();
    final showListProvider = MockShowListProvider();

    when(() => audioProvider.currentShow).thenReturn(show);
    when(() => audioProvider.currentSource).thenReturn(null);
    when(() => audioProvider.isPlaying).thenReturn(false);
    when(() => showListProvider.isShowLoading(any())).thenReturn(false);
    when(() => showListProvider.getShowKey(any())).thenReturn('key');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider),
          ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ChangeNotifierProvider<DeviceService>.value(value: deviceService),
          Provider<AudioProvider>.value(value: audioProvider),
          Provider<ShowListProvider>.value(value: showListProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ShowListItem(
              show: show,
              isExpanded: false,
              animation: const AlwaysStoppedAnimation(0.0),
              onTap: () {},
              onLongPress: () {},
              onSourceTap: (_) {},
              onSourceLongPress: (_) {},
              index: 0,
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 500));

    final tvFocusFinder = find.byType(TvFocusWrapper);
    expect(tvFocusFinder, findsOneWidget);

    final tvFocusWrapper = tester.widget<TvFocusWrapper>(tvFocusFinder);
    expect(tvFocusWrapper.isPlaying, isTrue,
        reason:
            'isPlaying should be true when audioProvider.currentShow == show');
  });
}
