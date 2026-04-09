import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
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
  final Stream<Duration> _positionStream = Stream<Duration>.value(
    const Duration(minutes: 1, seconds: 30),
  ).asBroadcastStream();
  final Stream<Duration?> _durationStream = Stream<Duration?>.value(
    const Duration(minutes: 5),
  ).asBroadcastStream();
  final Stream<Duration> _bufferedPositionStream = Stream<Duration>.value(
    const Duration(minutes: 2),
  ).asBroadcastStream();
  final Stream<PlayerState> _playerStateStream = Stream<PlayerState>.value(
    PlayerState(true, ProcessingState.ready),
  ).asBroadcastStream();

  @override
  bool isPlaying = false;

  @override
  Show? currentShow;

  @override
  Track? currentTrack;

  @override
  Stream<PlayerState> get playerStateStream => _playerStateStream;

  @override
  Stream<Duration> get positionStream => _positionStream;

  @override
  Stream<Duration?> get durationStream => _durationStream;

  @override
  Stream<Duration> get bufferedPositionStream => _bufferedPositionStream;

  @override
  GaplessPlayer get audioPlayer => _MockGaplessPlayer();

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _MockGaplessPlayer extends Fake implements GaplessPlayer {
  @override
  Duration get position => Duration.zero;

  @override
  Duration? get duration => const Duration(minutes: 5);

  @override
  Duration get bufferedPosition => const Duration(minutes: 2);

  @override
  ProcessingState get processingState => ProcessingState.ready;

  @override
  bool get playing => true;

  @override
  PlayerState get playerState => PlayerState(true, ProcessingState.ready);
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
    Track? currentTrack,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    SettingsProvider? settingsProvider,
    ThemeProvider? themeProvider,
    MockDeviceService? deviceService,
  }) {
    final audioProvider = SimpleAudioProvider();
    audioProvider.isPlaying = isPlaying;
    audioProvider.currentShow = isPlaying ? show : null;
    audioProvider.currentTrack = currentTrack;
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
      if (!settingsProvider.dateFirstInShowCard) {
        settingsProvider.toggleDateFirstInShowCard();
      }

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
    'ShowListCard Fruit car mode keeps idle cards shorter than active cards',
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

      final idleHeight = tester
          .getSize(find.byKey(const ValueKey('fruit_show_list_car_mode_card')))
          .height;

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

      final activeHeight = tester
          .getSize(find.byKey(const ValueKey('fruit_show_list_car_mode_card')))
          .height;

      expect(idleHeight, lessThan(activeHeight));
      expect(activeHeight - idleHeight, greaterThan(25.0));
    },
  );

  testWidgets('ShowListCard Fruit car mode idle cards stay compact', (
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

    final idleHeight = tester
        .getSize(find.byKey(const ValueKey('fruit_show_list_car_mode_card')))
        .height;

    expect(idleHeight, lessThan(160.0));
  });

  testWidgets('ShowListCard Fruit car mode idle layout does not overflow', (
    WidgetTester tester,
  ) async {
    final dummyShow = createDummyShow(
      'Oakland-Alameda County Coliseum',
      '1989-12-28',
      primarySrc: 'matrix',
      sourceLocation: 'Oakland, CA',
    );
    dummyShow.location = 'Oakland, CA';

    final settingsProvider = SettingsProvider(prefs);
    settingsProvider.toggleCarMode();

    final overflowErrors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('RenderFlex overflowed')) {
        overflowErrors.add(details);
      }
    };

    await tester.pumpWidget(
      createTestableWidget(
        show: dummyShow,
        settingsProvider: settingsProvider,
        themeProvider: _FruitThemeProvider(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    FlutterError.onError = oldHandler;

    expect(overflowErrors, isEmpty);
  });

  testWidgets('ShowListCard Fruit car mode active layout does not overflow', (
    WidgetTester tester,
  ) async {
    final dummyShow = createDummyShow(
      'Oakland-Alameda County Coliseum',
      '1989-12-28',
      primarySrc: 'matrix',
      sourceLocation: 'Oakland, CA',
    );
    dummyShow.location = 'Oakland, CA';

    final settingsProvider = SettingsProvider(prefs);
    settingsProvider.toggleCarMode();

    final overflowErrors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('RenderFlex overflowed')) {
        overflowErrors.add(details);
      }
    };

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

    FlutterError.onError = oldHandler;

    expect(overflowErrors, isEmpty);
  });

  testWidgets('ShowListCard Fruit car mode omits weekday on narrow cards', (
    WidgetTester tester,
  ) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final dummyShow = createDummyShow(
      'Winterland Arena',
      '1972-05-11',
      sourceLocation: 'San Francisco, CA',
    );
    dummyShow.location = 'San Francisco, CA';

    final settingsProvider = SettingsProvider(prefs);
    settingsProvider.toggleCarMode();
    settingsProvider.toggleShowDayOfWeek();

    await tester.pumpWidget(
      createTestableWidget(
        show: dummyShow,
        settingsProvider: settingsProvider,
        themeProvider: _FruitThemeProvider(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('May 11, 1972'), findsOneWidget);
    expect(find.text('Thursday, May 11, 1972'), findsNothing);
    expect(find.text('Thu, May 11, 1972'), findsNothing);
  });

  testWidgets(
    'ShowListCard Fruit car mode current show shows compact progress and pulse below the track title',
    (WidgetTester tester) async {
      final currentTrack = Track(
        trackNumber: 1,
        title: 'Scarlet Begonias',
        duration: 622,
        url: 'https://archive.org/scarlet.mp3',
        setName: 'Set 2',
      );
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
          currentTrack: currentTrack,
          settingsProvider: settingsProvider,
          themeProvider: _FruitThemeProvider(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final ratingFinder = find.byType(RatingControl);
      final srcFinder = find.byType(SrcBadge);

      expect(ratingFinder, findsOneWidget);
      expect(srcFinder, findsOneWidget);
      expect(find.byType(EmbeddedMiniPlayer), findsNothing);
      expect(
        find.byKey(const ValueKey('fruit_show_list_car_mode_track_progress')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fruit_show_list_car_mode_track_pulse')),
        findsOneWidget,
      );
      expect(find.text(currentTrack.title), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(currentTrack.title)).dy,
        lessThan(
          tester
              .getTopLeft(
                find.byKey(
                  const ValueKey('fruit_show_list_car_mode_track_progress'),
                ),
              )
              .dy,
        ),
      );
    },
  );

  testWidgets(
    'ShowListCard Fruit car mode current show grows to allow venue wrapping when needed',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final currentTrack = Track(
        trackNumber: 1,
        title: 'Playing in the Band',
        duration: 640,
        url: 'https://archive.org/pitb.mp3',
        setName: 'Set 2',
      );
      final dummyShow = createDummyShow(
        'Oakland-Alameda County Coliseum Arena and Exhibition Hall',
        '1989-12-28',
        primarySrc: 'matrix',
        sourceLocation: 'Oakland, CA',
      );
      dummyShow.location = 'Oakland, CA';

      final settingsProvider = SettingsProvider(prefs);
      settingsProvider.toggleCarMode();

      await tester.pumpWidget(
        createTestableWidget(
          show: dummyShow,
          isPlaying: true,
          currentTrack: currentTrack,
          settingsProvider: settingsProvider,
          themeProvider: _FruitThemeProvider(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final cardFinder = find.byKey(
        const ValueKey('fruit_show_list_car_mode_card'),
      );

      expect(find.text(dummyShow.venue), findsOneWidget);
      expect(tester.getSize(cardFinder).height, greaterThan(232.0));
    },
  );

  testWidgets(
    'ShowListCard Fruit car mode current show uses a tighter leading inset for the date headline',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(360, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final currentTrack = Track(
        trackNumber: 1,
        title: 'Dark Star',
        duration: 1400,
        url: 'https://archive.org/darkstar.mp3',
        setName: 'Set 2',
      );
      final dummyShow = createDummyShow(
        'Fillmore East',
        '1970-09-19',
        primarySrc: 'matrix',
        sourceLocation: 'New York, NY',
      );
      dummyShow.location = 'New York, NY';

      final settingsProvider = SettingsProvider(prefs);
      settingsProvider.toggleCarMode();

      await tester.pumpWidget(
        createTestableWidget(
          show: dummyShow,
          isPlaying: true,
          currentTrack: currentTrack,
          settingsProvider: settingsProvider,
          themeProvider: _FruitThemeProvider(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final cardFinder = find.byKey(
        const ValueKey('fruit_show_list_car_mode_card'),
      );
      final dateFinder = find.text('Sep 19, 1970');

      final double leadingInset =
          tester.getTopLeft(dateFinder).dx - tester.getTopLeft(cardFinder).dx;

      expect(leadingInset, lessThanOrEqualTo(14.0));
    },
  );

  testWidgets(
    'ShowListCard Fruit car mode current show grows to allow venue wrapping when date-first is off',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final currentTrack = Track(
        trackNumber: 1,
        title: 'Playing in the Band',
        duration: 640,
        url: 'https://archive.org/pitb.mp3',
        setName: 'Set 2',
      );
      final dummyShow = createDummyShow(
        'Oakland-Alameda County Coliseum Arena and Exhibition Hall',
        '1989-12-28',
        primarySrc: 'matrix',
        sourceLocation: 'Oakland, CA',
      );
      dummyShow.location = 'Oakland, CA';

      final settingsProvider = SettingsProvider(prefs);
      settingsProvider.toggleCarMode();
      settingsProvider.toggleDateFirstInShowCard();

      await tester.pumpWidget(
        createTestableWidget(
          show: dummyShow,
          isPlaying: true,
          currentTrack: currentTrack,
          settingsProvider: settingsProvider,
          themeProvider: _FruitThemeProvider(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));

      final cardFinder = find.byKey(
        const ValueKey('fruit_show_list_car_mode_card'),
      );

      expect(find.text(dummyShow.venue), findsOneWidget);
      expect(tester.getSize(cardFinder).height, greaterThan(232.0));
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

  testWidgets(
    'ShowListCard Fruit car mode aligns multi-source badge with location row when date-first is on',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final showWithMultipleSources = createDummyShow(
        'Venue C on 2025-02-21',
        '2025-02-21',
        sourceCount: 3,
        sourceLocation: 'Oakland, CA',
      );
      showWithMultipleSources.location = 'Oakland, CA';

      final settingsProvider = SettingsProvider(prefs);
      settingsProvider.toggleCarMode();
      if (!settingsProvider.dateFirstInShowCard) {
        settingsProvider.toggleDateFirstInShowCard();
      }

      await tester.pumpWidget(
        createTestableWidget(
          show: showWithMultipleSources,
          settingsProvider: settingsProvider,
          themeProvider: _FruitThemeProvider(),
        ),
      );
      await tester.pumpAndSettle();

      final locationFinder = find.text('Oakland, CA');
      final badgeFinder = find.text('3 SOURCES');

      expect(locationFinder, findsOneWidget);
      expect(badgeFinder, findsOneWidget);
      // Badge is to the right of location text (right-aligned in location row).
      expect(
        tester.getTopLeft(badgeFinder).dx,
        greaterThan(tester.getTopLeft(locationFinder).dx),
      );
      // Badge right edge is near the card right edge (right-aligned, not left).
      expect(tester.getTopRight(badgeFinder).dx, greaterThan(350.0));
      // Badge is vertically on the same row as the location text.
      expect(
        (tester.getTopLeft(badgeFinder).dy -
                tester.getTopLeft(locationFinder).dy)
            .abs(),
        lessThan(24.0),
      );
    },
  );

  testWidgets(
    'ShowListCard Fruit car mode places multi-source badge on date row when date-first is off',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final showWithMultipleSources = createDummyShow(
        'Venue C on 2025-02-21',
        '2025-02-21',
        sourceCount: 3,
        sourceLocation: 'Oakland, CA',
      );
      showWithMultipleSources.location = 'Oakland, CA';

      final settingsProvider = SettingsProvider(prefs);
      settingsProvider.toggleCarMode();
      if (settingsProvider.dateFirstInShowCard) {
        settingsProvider.toggleDateFirstInShowCard();
      }

      await tester.pumpWidget(
        createTestableWidget(
          show: showWithMultipleSources,
          settingsProvider: settingsProvider,
          themeProvider: _FruitThemeProvider(),
        ),
      );
      await tester.pumpAndSettle();

      final locationFinder = find.text('Oakland, CA');
      final badgeFinder = find.text('3 SOURCES');

      expect(locationFinder, findsOneWidget);
      expect(badgeFinder, findsOneWidget);
      // Badge must be below the location row (on the date row), not inline.
      expect(
        tester.getTopLeft(badgeFinder).dy,
        greaterThan(tester.getBottomLeft(locationFinder).dy - 4.0),
      );
    },
  );

  testWidgets(
    'ShowListCard Fruit car mode places src badge below location row when date-first is off',
    (WidgetTester tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(430, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final showWithSrc = createDummyShow(
        'Fox Theater',
        '1978-12-17',
        sourceCount: 1,
        primarySrc: 'SBD',
        sourceLocation: 'Tampa, FL',
      );
      showWithSrc.location = 'Tampa, FL';

      final settingsProvider = SettingsProvider(prefs);
      settingsProvider.toggleCarMode();
      if (settingsProvider.dateFirstInShowCard) {
        settingsProvider.toggleDateFirstInShowCard();
      }

      await tester.pumpWidget(
        createTestableWidget(
          show: showWithSrc,
          settingsProvider: settingsProvider,
          themeProvider: _FruitThemeProvider(),
        ),
      );
      await tester.pumpAndSettle();

      final locationFinder = find.text('Tampa, FL');
      final badgeFinder = find.text('SBD');

      expect(locationFinder, findsOneWidget);
      expect(badgeFinder, findsOneWidget);
      // Badge must be below the location row, not inline with it.
      expect(
        tester.getTopLeft(badgeFinder).dy,
        greaterThan(tester.getBottomLeft(locationFinder).dy - 4.0),
      );
    },
  );

  testWidgets(
    'ShowListCard taps multi-source badge like the card expand action',
    (WidgetTester tester) async {
      final showWithMultipleSources = createDummyShow(
        'Venue C on 2025-02-21',
        '2025-02-21',
        sourceCount: 2,
      );
      bool tapped = false;

      await tester.pumpWidget(
        createTestableWidget(
          show: showWithMultipleSources,
          themeProvider: _FruitThemeProvider(),
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.text('2 SOURCES'));

      expect(tapped, isTrue);
    },
  );

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
