import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/ui/widgets/show_list/embedded_mini_player.dart';
import 'package:shakedown_core/ui/widgets/show_list/show_list_card.dart';
import 'package:shakedown_core/ui/widgets/src_badge.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import '../mocks/fake_catalog_service.dart';
import '../helpers/test_helpers.dart';

class SimpleAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  bool isPlaying = false;

  @override
  Show? currentShow;

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FruitThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => ThemeStyle.fruit;

  @override
  bool get isFruit => true;

  @override
  bool get isFruitAllowed => true;

  @override
  Future<void> get initializationComplete => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    CatalogService.setMock(FakeCatalogService());

    SharedPreferences.setMockInitialValues({
      'glow_mode': 0,
      'show_day_of_week': false,
      'abbreviate_month': true,
      'marquee_enabled': false,
      'highlight_playing_with_rgb': false,
    });
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await CatalogService().reset();
  });

  Show createDummyShow(
    String name,
    String date, {
    int sourceCount = 1,
    bool hasFeaturedTrack = false,
    String? primarySrc,
    String? sourceLocation,
  }) {
    return Show(
      name: name,
      artist: 'Grateful Dead',
      date: date,
      venue: name.split(' on ').first,
      sources: List.generate(
        sourceCount,
        (i) => Source(
          id: 'source$i',
          src: i == 0 ? primarySrc : null,
          tracks: const [],
          location: sourceLocation,
        ),
      ),
      hasFeaturedTrack: hasFeaturedTrack,
    );
  }

  Widget createTestableWidget({
    required Show show,
    bool isExpanded = false,
    bool isPlaying = false,
    bool isLoading = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    SettingsProvider? settingsProvider,
    ThemeProvider? themeProvider,
    MockDeviceService? deviceService,
  }) {
    final audioProvider = SimpleAudioProvider();
    audioProvider.isPlaying = isPlaying;
    audioProvider.currentShow = isPlaying ? show : null;
    final resolvedThemeProvider = themeProvider ?? ThemeProvider();
    final resolvedDeviceService = deviceService ?? MockDeviceService();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => settingsProvider ?? SettingsProvider(prefs),
        ),
        ChangeNotifierProvider<ThemeProvider>.value(
          value: resolvedThemeProvider,
        ),
        ChangeNotifierProvider<DeviceService>.value(
          value: resolvedDeviceService,
        ),
        ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ShowListCard(
            show: show,
            isExpanded: isExpanded,
            isPlaying: isPlaying,
            isLoading: isLoading,
            onTap: onTap ?? () {},
            onLongPress: onLongPress ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('ShowListCard displays venue and date', (
    WidgetTester tester,
  ) async {
    final dummyShow = createDummyShow('Venue A on 2025-01-15', '2025-01-15');
    final settingsProvider = SettingsProvider(prefs);

    await tester.pumpWidget(
      createTestableWidget(show: dummyShow, settingsProvider: settingsProvider),
    );

    expect(find.text(dummyShow.venue), findsOneWidget);
    expect(find.text('Jan 15, 2025'), findsOneWidget);
  });

  testWidgets('ShowListCard uses Fruit car mode layout on web Fruit car mode', (
    WidgetTester tester,
  ) async {
    final dummyShow = createDummyShow('Winterland Arena', '1974-10-20');
    dummyShow.location = 'San Francisco, CA';

    final settingsProvider = SettingsProvider(prefs);
    settingsProvider.toggleCarMode();

    await tester.pumpWidget(
      createTestableWidget(
        show: dummyShow,
        settingsProvider: settingsProvider,
        themeProvider: _FruitThemeProvider(),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fruit_show_list_car_mode_card')),
      findsOneWidget,
    );
    expect(find.text(dummyShow.location), findsOneWidget);
    expect(find.text('Oct 20, 1974'), findsOneWidget);
  });

  testWidgets(
    'ShowListCard Fruit car mode respects dateFirstInShowCard setting',
    (WidgetTester tester) async {
      final dummyShow = createDummyShow('Winterland Arena', '1974-10-20');
      dummyShow.location = 'San Francisco, CA';

      final settingsProvider = SettingsProvider(prefs);
      settingsProvider.toggleCarMode();

      await tester.pumpWidget(
        createTestableWidget(
          show: dummyShow,
          settingsProvider: settingsProvider,
          themeProvider: _FruitThemeProvider(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('Oct 20, 1974')).dy,
        lessThan(tester.getTopLeft(find.text(dummyShow.venue)).dy),
      );

      settingsProvider.toggleDateFirstInShowCard();
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text(dummyShow.venue)).dy,
        lessThan(tester.getTopLeft(find.text('Oct 20, 1974')).dy),
      );
    },
  );

  testWidgets(
    'ShowListCard Fruit car mode places src badge under rating and player right',
    (WidgetTester tester) async {
      final dummyShow = createDummyShow(
        'Winterland Arena',
        '1974-10-20',
        primarySrc: 'matrix',
        sourceLocation: 'San Francisco, CA',
      );
      dummyShow.location = 'San Francisco, CA';

      final settingsProvider = SettingsProvider(prefs);
      settingsProvider.toggleCarMode();

      await tester.pumpWidget(
        createTestableWidget(
          show: dummyShow,
          isPlaying: true,
          settingsProvider: settingsProvider,
          themeProvider: _FruitThemeProvider(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final ratingFinder = find.byType(RatingControl);
      final srcFinder = find.byType(SrcBadge);
      final playerFinder = find.byType(EmbeddedMiniPlayer);
      final cardFinder = find.byKey(
        const ValueKey('fruit_show_list_car_mode_card'),
      );

      expect(ratingFinder, findsOneWidget);
      expect(srcFinder, findsOneWidget);
      expect(playerFinder, findsOneWidget);
      expect(cardFinder, findsOneWidget);

      expect(
        tester.getTopLeft(srcFinder).dy,
        greaterThan(tester.getTopLeft(ratingFinder).dy),
      );
      expect(
        tester.getTopRight(cardFinder).dx - tester.getTopRight(playerFinder).dx,
        lessThan(40.0),
      );
      expect(tester.getSize(playerFinder).width, greaterThan(280.0));
    },
  );

  testWidgets('ShowListCard border color changes when isPlaying is true', (
    WidgetTester tester,
  ) async {
    final dummyShow = createDummyShow('Venue A on 2025-01-15', '2025-01-15');
    final settingsProvider = SettingsProvider(prefs);
    settingsProvider.setGlowMode(0);

    await tester.pumpWidget(
      createTestableWidget(
        show: dummyShow,
        isPlaying: true,
        settingsProvider: settingsProvider,
      ),
    );

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    final side = shape.side;

    expect(
      side.color,
      equals(Theme.of(tester.element(find.byType(Card))).colorScheme.primary),
    );
  });

  testWidgets('ShowListCard expand icon rotates when isExpanded is true', (
    WidgetTester tester,
  ) async {
    final dummyShow = createDummyShow('Venue A on 2025-01-15', '2025-01-15');
    final settingsProvider = SettingsProvider(prefs);
    settingsProvider.showExpandIcon = true;
    await tester.pumpWidget(
      createTestableWidget(
        show: dummyShow,
        isExpanded: true,
        settingsProvider: settingsProvider,
      ),
    );

    final animatedRotation = tester.widget<AnimatedRotation>(
      find.byType(AnimatedRotation),
    );
    expect(animatedRotation.turns, equals(0.5));
  });

  testWidgets(
    'ShowListCard shows CircularProgressIndicator when isLoading is true',
    (WidgetTester tester) async {
      final dummyShow = createDummyShow('Venue A on 2025-01-15', '2025-01-15');
      final settingsProvider = SettingsProvider(prefs);
      settingsProvider.showExpandIcon = true;
      await tester.pumpWidget(
        createTestableWidget(
          show: dummyShow,
          isLoading: true,
          settingsProvider: settingsProvider,
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    },
  );

  testWidgets('ShowListCard displays badge for multiple sources', (
    WidgetTester tester,
  ) async {
    final showWithMultipleSources = createDummyShow(
      'Venue B on 2025-02-20',
      '2025-02-20',
      sourceCount: 2,
    );
    await tester.pumpWidget(
      createTestableWidget(show: showWithMultipleSources),
    );

    expect(find.text('2 SOURCES'), findsOneWidget);
  });

  testWidgets('ShowListCard calls onTap when tapped', (
    WidgetTester tester,
  ) async {
    final dummyShow = createDummyShow('Venue A on 2025-01-15', '2025-01-15');
    bool tapped = false;
    await tester.pumpWidget(
      createTestableWidget(show: dummyShow, onTap: () => tapped = true),
    );

    await tester.tap(find.byType(ShowListCard));
    expect(tapped, isTrue);
  });

  testWidgets('ShowListCard calls onLongPress when long-pressed', (
    WidgetTester tester,
  ) async {
    final dummyShow = createDummyShow('Venue A on 2025-01-15', '2025-01-15');
    bool longPressed = false;
    await tester.pumpWidget(
      createTestableWidget(
        show: dummyShow,
        onLongPress: () => longPressed = true,
      ),
    );

    await tester.longPress(find.byType(ShowListCard));
    expect(longPressed, isTrue);
  });

  testWidgets('ShowListCard displays rating control for single source show', (
    WidgetTester tester,
  ) async {
    final dummyShow = createDummyShow('Venue A on 2025-01-15', '2025-01-15');
    await tester.pumpWidget(createTestableWidget(show: dummyShow));

    expect(find.byType(RatingControl), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
  });

  testWidgets('ShowListCard hides rating control for multi-source show', (
    WidgetTester tester,
  ) async {
    final showWithMultipleSources = createDummyShow(
      'Show B',
      '2025-01-01',
      sourceCount: 2,
    );

    await tester.pumpWidget(
      createTestableWidget(show: showWithMultipleSources),
    );

    expect(find.byType(RatingControl), findsNothing);
  });

  testWidgets('Tapping rating control opens dialog when playing', (
    WidgetTester tester,
  ) async {
    final show = createDummyShow('Show C', '2025-01-01');
    await tester.pumpWidget(createTestableWidget(show: show, isPlaying: true));

    final ratingControl = find.byType(RatingControl);
    expect(ratingControl, findsOneWidget);

    await tester.tap(ratingControl);
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Rate Show'), findsOneWidget);
    expect(find.byType(RatingBar), findsWidgets);
    expect(find.text('Block (Red Star)'), findsOneWidget);
    expect(find.text('Clear Rating'), findsOneWidget);
  });

  testWidgets('ShowListCard displays grey star for played but unrated show', (
    WidgetTester tester,
  ) async {
    final show = createDummyShow('Played Show', '2025-01-01');
    final settingsProvider = SettingsProvider(prefs);
    await CatalogService().markAsPlayed('source0');

    await tester.pumpWidget(
      createTestableWidget(show: show, settingsProvider: settingsProvider),
    );

    expect(find.byType(RatingControl), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
  });

  testWidgets(
    'ShowListCard displays empty stars for unplayed and unrated show',
    (WidgetTester tester) async {
      final show = createDummyShow('Unplayed Show', '2025-01-02');

      await tester.pumpWidget(createTestableWidget(show: show));

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.star), findsNothing);
    },
  );

  testWidgets('Tapping rating control does NOT open dialog when NOT playing', (
    WidgetTester tester,
  ) async {
    final multiSourceShow = createDummyShow(
      'Show 1',
      '2025-01-01',
      sourceCount: 2,
    );

    await tester.pumpWidget(
      createTestableWidget(show: multiSourceShow, isPlaying: false),
    );
    final ratingControl = find.byType(RatingControl);
    expect(ratingControl, findsNothing);
  });

  testWidgets('ShowListCard meets accessibility guidelines', (
    WidgetTester tester,
  ) async {
    final dummyShow = createDummyShow('Venue A on 2025-01-15', '2025-01-15');
    await tester.pumpWidget(createTestableWidget(show: dummyShow));
    await tester.pumpAndSettle();

    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
}
