import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/ui/widgets/shnid_badge.dart';
import 'package:shakedown_core/ui/widgets/src_badge.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';

import 'playback_screen_test.mocks.dart';

class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;
  @override
  bool get isMobile => false;
  @override
  bool get isDesktop => true;
  @override
  bool get isSafari => false;
  @override
  bool get isPwa => false;
  @override
  String? get deviceName => 'Mock Device';
  @override
  bool get isLowEndTvDevice => false;
  @override
  Future<void> refresh() async {}
}

class MockFruitThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => ThemeStyle.fruit;

  @override
  bool get isFruitAllowed => true;

  @override
  Future<void> get initializationComplete => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSettingsProvider extends Mock implements SettingsProvider {
  bool _carMode = false;
  bool _fruitFloatingSpheres = false;
  bool _fruitEnableLiquidGlass = false;
  bool _showDevAudioHud = false;

  void setCarMode(bool value) {
    _carMode = value;
  }

  void setFruitFloatingSpheres(bool value) {
    _fruitFloatingSpheres = value;
  }

  @override
  void setFruitEnableLiquidGlass(bool value) {
    _fruitEnableLiquidGlass = value;
  }

  void setShowDevAudioHud(bool value) {
    _showDevAudioHud = value;
  }

  @override
  bool get sortOldestFirst => true;
  @override
  void toggleSortOldestFirst() {}

  @override
  bool get uiScale => false;
  @override
  bool get carMode => _carMode;
  @override
  bool get fruitFloatingSpheres => _fruitFloatingSpheres;
  @override
  bool get showSingleShnid => false;
  @override
  bool get showTrackNumbers => false;
  @override
  int get glowMode => 0;

  @override
  bool get useTrueBlack => false;
  @override
  bool get highlightPlayingWithRgb => false;
  @override
  bool get showPlaybackMessages => false;
  @override
  bool get showDevAudioHud => _showDevAudioHud;
  // useHandwritingFont removed
  @override
  bool get useDynamicColor => false;
  // halfGlowDynamic removed
  @override
  double get rgbAnimationSpeed => 1.0;
  @override
  Color? get seedColor => null;
  @override
  bool get showSplashScreen => false;
  @override
  bool get dateFirstInShowCard => true;
  @override
  bool get playOnTap => false;
  @override
  bool get playRandomOnCompletion => false;
  @override
  bool get playRandomOnStartup => false;
  @override
  AudioEngineMode get audioEngineMode => AudioEngineMode.auto;
  @override
  bool get useSliverAppBar => false;
  @override
  bool get useSharedAxisTransition => false;
  @override
  bool get hideTrackCountInSourceList => false;
  @override
  bool get highlightCurrentShowCard => false;
  @override
  bool get useMaterial3 => true;
  @override
  bool get showExpandIcon => false;
  @override
  set showExpandIcon(bool value) {}

  @override
  bool get oilLogoTrailDynamic => false;
  @override
  double get oilFlowSpeed => 0.5;
  @override
  String get oilPalette => 'classic';
  @override
  double get oilFilmGrain => 0.0;
  @override
  double get oilPulseIntensity => 0.5;
  @override
  double get oilHeatDrift => 0.5;
  @override
  bool get oilEnableAudioReactivity => false;
  @override
  int get oilPerformanceLevel => 0;
  @override
  double get oilLogoScale => 0.5;
  @override
  double get oilTranslationSmoothing => 0.5;
  @override
  double get oilBlurAmount => 0.0;
  @override
  bool get oilFlatColor => false;
  @override
  bool get oilBannerGlow => false;
  @override
  double get oilBannerFlicker => 0.0;
  @override
  bool get oilShowInfoBanner => true;
  @override
  bool get oilPaletteCycle => false;
  @override
  double get oilPaletteTransitionSpeed => 1.0;
  @override
  double get oilInnerRingScale => 1.0;
  @override
  double get oilInnerToMiddleGap => 0.5;
  @override
  double get oilMiddleToOuterGap => 0.5;
  @override
  double get oilOrbitDrift => 0.5;
  @override
  String get oilBannerDisplayMode => 'ring';
  @override
  String get oilBannerFont => 'default';
  @override
  double get oilLogoTrailIntensity => 0.0;
  @override
  int get oilLogoTrailSlices => 1;
  @override
  double get oilLogoTrailLength => 1.0;
  @override
  double get oilFlatTextProximity => 0.5;
  @override
  String get oilFlatTextPlacement => 'center';
  @override
  String get oilAudioGraphMode => 'off';
  @override
  double get oilBeatSensitivity => 0.5;
  @override
  double get oilInnerRingFontScale => 1.0;
  @override
  double get oilInnerRingSpacingMultiplier => 1.0;
  @override
  double get oilTrackLetterSpacing => 1.0;
  @override
  double get oilTrackWordSpacing => 1.0;
  @override
  bool get oilLogoAntiAlias => true;
  @override
  double get oilLogoTrailScale => 1.0;
  @override
  double get oilAudioPeakDecay => 0.9;
  @override
  double get oilAudioBassBoost => 1.0;
  @override
  double get oilAudioReactivityStrength => 1.0;

  // New Getters that were missing
  @override
  bool get showDayOfWeek => true;
  @override
  bool get abbreviateDayOfWeek => true;
  @override
  bool get abbreviateMonth => true;

  @override
  void toggleShowSplashScreen() {}
  @override
  void toggleShowTrackNumbers() {}
  @override
  void togglePlayOnTap() {}
  @override
  void toggleShowSingleShnid() {}
  @override
  void togglePlayRandomOnCompletion() {}
  @override
  void togglePlayRandomOnStartup() {}
  @override
  void toggleDateFirstInShowCard() {}
  @override
  void toggleUseDynamicColor() {}
  @override
  String get appFont => 'default';
  @override
  String get activeAppFont => 'default';
  @override
  void setAppFont(String font) {}
  @override
  void toggleUiScale() {}
  @override
  void setGlowMode(int mode) {}
  @override
  void toggleHighlightPlayingWithRgb() {}
  @override
  void toggleShowPlaybackMessages() {}
  // toggleHalfGlowDynamic removed
  @override
  void setRgbAnimationSpeed(double speed) {}
  @override
  Future<void> setSeedColor(Color? color) async {}

  @override
  bool get hideTrackDuration => false;
  @override
  bool get showGlobalAlbumArt => true;
  @override
  bool get isTv => false;
  @override
  bool get useNeumorphism => false;
  @override
  bool get performanceMode => false;
  @override
  bool get fruitDenseList => false;
  @override
  bool get marqueeEnabled => true;
  @override
  bool get fruitEnableLiquidGlass => _fruitEnableLiquidGlass;
  @override
  bool get fruitStickyNowPlaying => false;
  @override
  bool get oilTvPremiumHighlight => false;
}

class MockShowListProvider extends ChangeNotifier implements ShowListProvider {
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  String get searchQuery => '';
  @override
  String? get expandedShowKey => null;
  @override
  String? get loadingShowKey => null;
  @override
  List<Show> get allShows => [];
  @override
  List<Show> get filteredShows => [];
  @override
  bool get isArchiveReachable => true;
  @override
  bool get hasCheckedArchive => true;
  @override
  bool get hasUsedRandomButton => false;
  @override
  bool get isSearchVisible => false;
  @override
  bool get isChoosingRandomShow => false;
  @override
  int get totalShnids => 0;
  @override
  String getShowKey(Show show) => show.key;
  @override
  void setArchiveStatus(bool isReachable) {}
  @override
  Set<String> get availableCategories => {};
  @override
  Set<String> getCategoriesForSource(Source source) => {};
  @override
  bool isSourceAllowed(Source source) => true;
  @override
  void setPlayingShow(String? showName, String? sourceId) {}
  @override
  Future<void> fetchShows(SharedPreferences prefs) async {}
  @override
  Future<void> checkArchiveStatus() async {}
  @override
  void setSearchQuery(String query) {}
  @override
  bool isShowExpanded(String key) => false;
  @override
  bool isShowLoading(String key) => false;
  @override
  void toggleShowExpansion(String key) {}
  @override
  void setLoadingShow(String? key) {}
  @override
  void expandShow(String key) {}
  @override
  void collapseCurrentShow() {}
  @override
  void dismissShow(Show show) {}
  @override
  void dismissSource(Show show, String sourceId) {}
  @override
  void update(SettingsProvider settings) {}
  @override
  Show? getShow(String key) => null;
  @override
  Future<void> init(SharedPreferences prefs) async {}
  @override
  Future<void> get initializationComplete => Future.value();
  @override
  void markRandomButtonUsed() {}
  @override
  void setIsChoosingRandomShow(bool value) {}
  @override
  void setSearchVisible(bool visible) {}
  @override
  void toggleSearchVisible() {}
}

class MockCatalogService extends Mock implements CatalogService {
  @override
  bool get isInitialized => true;

  @override
  ValueListenable<Box<Rating>> get ratingsListenable =>
      ValueNotifier(MockBox<Rating>());

  @override
  ValueListenable<Box<bool>> get historyListenable =>
      ValueNotifier(MockBox<bool>());

  @override
  ValueListenable<Box<int>> get playCountsListenable =>
      ValueNotifier(MockBox<int>());

  @override
  bool isPlayed(String sourceId) => false;

  @override
  Future<void> togglePlayed(String sourceId) async {}

  @override
  int getRating(String sourceId) => 0;

  @override
  Future<void> setRating(String sourceId, int rating) async {}
}

class MockBox<T> extends Mock implements Box<T> {
  ValueListenable<Box<T>> listenable({List<dynamic>? keys}) =>
      ValueNotifier(this);
}

@GenerateMocks([AudioProvider, GaplessPlayer])
void main() {
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockGaplessPlayer mockAudioPlayer;
  late MockDeviceService mockDeviceService;
  late MockShowListProvider mockShowListProvider;

  // Dummy data
  final dummyTrack1 = Track(
    trackNumber: 1,
    title: 'Track 1',
    duration: 100,
    url: '',
    setName: 'Set 1',
  );
  final dummyTrack2 = Track(
    trackNumber: 2,
    title: 'Track 2',
    duration: 120,
    url: '',
    setName: 'Set 1',
  );
  final dummyTrack3 = Track(
    trackNumber: 3,
    title: 'Track 3',
    duration: 140,
    url: '',
    setName: 'Set 1',
  );
  final dummySource = Source(
    id: 'source1',
    src: 'sbd',
    tracks: [dummyTrack1, dummyTrack2, dummyTrack3],
  );
  final dummyShow = Show(
    name: 'Venue A on 2025-01-15',
    artist: 'Grateful Dead',
    date: '2025-01-15',
    venue: 'Venue A',
    sources: [dummySource],
  );

  void setLargeCarModeViewport(WidgetTester tester) {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(1400, 1200);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  setUp(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '.';
        });

    CatalogService.setMock(MockCatalogService());

    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockAudioPlayer = MockGaplessPlayer();
    mockDeviceService = MockDeviceService();
    mockShowListProvider = MockShowListProvider();

    // Stub the audio player on the audio provider
    when(mockAudioProvider.audioPlayer).thenReturn(mockAudioPlayer);
    when(mockAudioPlayer.currentIndex).thenReturn(0);
    when(mockAudioPlayer.position).thenReturn(Duration.zero);
    when(mockAudioPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(mockAudioPlayer.duration).thenReturn(const Duration(seconds: 100));
    when(
      mockAudioPlayer.playerState,
    ).thenReturn(PlayerState(false, ProcessingState.idle));

    // Stub default return values for streams to avoid null errors
    when(
      mockAudioProvider.playerStateStream,
    ).thenAnswer((_) => Stream.value(PlayerState(false, ProcessingState.idle)));
    when(
      mockAudioProvider.currentIndexStream,
    ).thenAnswer((_) => Stream.value(0));
    when(
      mockAudioProvider.durationStream,
    ).thenAnswer((_) => Stream.value(const Duration(seconds: 100)));
    when(
      mockAudioProvider.positionStream,
    ).thenAnswer((_) => Stream.value(Duration.zero));
    when(
      mockAudioProvider.bufferedPositionStream,
    ).thenAnswer((_) => Stream.value(Duration.zero));
    when(
      mockAudioProvider.playbackErrorStream,
    ).thenAnswer((_) => Stream.value(''));
    when(mockAudioProvider.isPlaying).thenReturn(false);
    when(mockAudioPlayer.sequence).thenReturn([]);
    when(
      mockAudioPlayer.sequenceStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(mockAudioProvider.currentTrack).thenReturn(null);
    when(mockAudioProvider.currentShow).thenReturn(null);
    when(mockAudioProvider.currentSource).thenReturn(null);
    when(
      mockAudioProvider.bufferAgentNotificationStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockAudioProvider.notificationStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockAudioProvider.nextTrackBufferedStream,
    ).thenAnswer((_) => Stream.value(null));
    when(
      mockAudioProvider.nextTrackTotalStream,
    ).thenAnswer((_) => Stream.value(null));
    when(
      mockAudioProvider.heartbeatActiveStream,
    ).thenAnswer((_) => Stream.value(false));
    when(
      mockAudioProvider.heartbeatNeededStream,
    ).thenAnswer((_) => Stream.value(false));
    when(
      mockAudioProvider.engineStateStringStream,
    ).thenAnswer((_) => Stream.value('idle'));
    when(
      mockAudioProvider.engineContextStateStream,
    ).thenAnswer((_) => Stream.value('idle'));
    when(
      mockAudioProvider.playbackFocusRequestStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockAudioProvider.hudSnapshotStream,
    ).thenAnswer((_) => const Stream.empty());
    when(mockAudioProvider.currentHudSnapshot).thenReturn(HudSnapshot.empty());

    // Also stub missing audioPlayer streams used by widgets
    when(
      mockAudioPlayer.engineStateStringStream,
    ).thenAnswer((_) => Stream.value('idle'));
    when(
      mockAudioPlayer.engineContextStateStream,
    ).thenAnswer((_) => Stream.value('idle'));
    when(mockAudioPlayer.playingStream).thenAnswer((_) => Stream.value(false));
    when(
      mockAudioPlayer.nextTrackBufferedStream,
    ).thenAnswer((_) => Stream.value(null));
  });

  Widget createTestableWidget({
    required Widget child,
    ThemeProvider? themeProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: mockSettingsProvider,
        ),
        ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
        ChangeNotifierProvider<ShowListProvider>.value(
          value: mockShowListProvider,
        ),
        ChangeNotifierProvider<ThemeProvider>.value(
          value: themeProvider ?? ThemeProvider(),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  testWidgets(
    'PlaybackScreen shows "No show selected" when currentShow is null',
    (WidgetTester tester) async {
      when(mockAudioProvider.currentShow).thenReturn(null);
      when(mockAudioProvider.currentSource).thenReturn(null);

      await tester.pumpWidget(
        createTestableWidget(child: const PlaybackScreen()),
      );

      expect(find.text('No show selected.'), findsOneWidget);
    },
  );

  testWidgets('PlaybackScreen displays show and track information', (
    WidgetTester tester,
  ) async {
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);

    await tester.pumpWidget(
      createTestableWidget(child: const PlaybackScreen()),
    );

    // Venue is displayed twice (at least): AppBar and Panel
    // Date is displayed twice (at least): AppBar and Panel
    // Date is displayed twice (at least): AppBar and Panel
    // Date is displayed (formatted)
    expect(find.textContaining('15, 2025'), findsAtLeastNWidgets(1));

    // The track title is displayed in the list and in the bottom controls
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == dummyTrack1.title,
      ),
      findsAtLeastNWidgets(1),
    );
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Text && widget.data == dummyTrack2.title,
      ),
      findsAtLeastNWidgets(1),
    );
  });

  testWidgets('Tapping a non-playing track seeks to it', (
    WidgetTester tester,
  ) async {
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(
      mockAudioPlayer.currentIndex,
    ).thenReturn(0); // Currently playing the first track
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);

    await tester.pumpWidget(
      createTestableWidget(child: const PlaybackScreen()),
    );

    await tester.ensureVisible(find.text(dummyTrack2.title));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text(dummyTrack2.title));

    verify(mockAudioProvider.seekToTrack(1)).called(1);
  });

  testWidgets('PlaybackScreen displays rating control', (
    WidgetTester tester,
  ) async {
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);

    await tester.pumpWidget(
      createTestableWidget(child: const PlaybackScreen()),
    );

    // Verify basic content is present (Date should be visible)
    expect(
      find.textContaining('2025'),
      findsAtLeastNWidgets(1),
      reason: 'Date should be visible',
    );

    // Verify RatingControl is present
    expect(
      find.byType(RatingControl),
      findsAtLeastNWidgets(1),
      reason: 'RatingControl widget should be present',
    );

    // Should find 3 star_rounded icons (RatingControl default is 0, appearing in AppBar)
    // Note: If finding icons fails but RatingControl is present, check flutter_rating_bar implementation
    expect(find.byIcon(Icons.star_rounded), findsAtLeastNWidgets(3));
  });

  testWidgets('PlaybackScreen uses Fruit car mode layout when enabled', (
    WidgetTester tester,
  ) async {
    setLargeCarModeViewport(tester);
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);
    mockSettingsProvider.setCarMode(true);
    mockSettingsProvider.setShowDevAudioHud(false);

    await tester.pumpWidget(
      createTestableWidget(
        child: const PlaybackScreen(showFruitTabBar: false),
        themeProvider: MockFruitThemeProvider(),
      ),
    );

    expect(find.byKey(const ValueKey('fruit_car_mode_layout')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fruit_car_mode_chip_row')),
      findsOneWidget,
    );
    expect(find.text('Driving Mode'), findsNothing);
    expect(find.text('Track 2'), findsOneWidget);
    expect(find.text('Track 3'), findsOneWidget);
    expect(find.text('Venue'), findsNothing);
    expect(find.text('Source'), findsNothing);
  });

  testWidgets(
    'PlaybackScreen Fruit car mode shows all remaining upcoming tracks',
    (WidgetTester tester) async {
      setLargeCarModeViewport(tester);
      final longTracks = List.generate(
        7,
        (index) => Track(
          trackNumber: index + 1,
          title: 'Long Track ${index + 1}',
          duration: 100 + (index * 10),
          url: 'track-${index + 1}',
          setName: 'Set 1',
        ),
      );
      final longSource = Source(
        id: 'long_source',
        src: 'sbd',
        tracks: longTracks,
        location: 'Oakland, CA',
      );
      final longShow = Show(
        name: 'Oakland-Alameda County Coliseum on 1989-12-31',
        artist: 'Grateful Dead',
        date: '1989-12-31',
        venue: 'Oakland-Alameda County Coliseum',
        sources: [longSource],
      );

      when(mockAudioProvider.currentShow).thenReturn(longShow);
      when(mockAudioProvider.currentSource).thenReturn(longSource);
      when(mockAudioProvider.currentTrack).thenReturn(longTracks.first);
      when(mockAudioPlayer.currentIndex).thenReturn(0);
      mockSettingsProvider.setCarMode(true);
      mockSettingsProvider.setShowDevAudioHud(false);

      await tester.pumpWidget(
        createTestableWidget(
          child: const PlaybackScreen(showFruitTabBar: false),
          themeProvider: MockFruitThemeProvider(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final controlsFinder = find.byKey(
        const ValueKey('fruit_car_mode_controls_row'),
      );
      final scrollFinder = find.byKey(
        const ValueKey('fruit_car_mode_upcoming_scroll'),
      );

      expect(controlsFinder, findsOneWidget);
      expect(scrollFinder, findsOneWidget);

      final controlsTopBefore = tester.getTopLeft(controlsFinder).dy;

      expect(find.text('Long Track 2'), findsOneWidget);
      expect(find.text('Long Track 5'), findsOneWidget);
      expect(find.text('Long Track 7'), findsOneWidget);

      await tester.drag(scrollFinder, const Offset(0, -220));
      await tester.pump();

      expect(tester.getTopLeft(controlsFinder).dy, controlsTopBefore);
      await tester.ensureVisible(find.text('Long Track 7'));
      await tester.pump();
    },
  );

  testWidgets(
    'PlaybackScreen stacks src over shnid in Fruit car mode meta hud without chip badges',
    (WidgetTester tester) async {
      setLargeCarModeViewport(tester);
      when(mockAudioProvider.currentShow).thenReturn(dummyShow);
      when(mockAudioProvider.currentSource).thenReturn(dummySource);
      when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);
      mockSettingsProvider.setCarMode(true);
      mockSettingsProvider.setShowDevAudioHud(false);

      await tester.pumpWidget(
        createTestableWidget(
          child: const PlaybackScreen(showFruitTabBar: false),
          themeProvider: MockFruitThemeProvider(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('fruit_car_mode_chip_row')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final srcText = find.byKey(const ValueKey('fruit_car_mode_src_label'));
      final shnidText = find.byKey(
        const ValueKey('fruit_car_mode_shnid_label'),
      );

      expect(
        find.byKey(const ValueKey('fruit_car_mode_meta_stack')),
        findsOneWidget,
      );
      expect(srcText, findsOneWidget);
      expect(shnidText, findsOneWidget);
      expect(find.text('SBD'), findsOneWidget);
      expect(find.byType(SrcBadge), findsNothing);
      expect(find.byType(ShnidBadge), findsNothing);
      expect(
        tester.getTopLeft(shnidText).dy,
        greaterThan(tester.getTopLeft(srcText).dy),
      );
    },
  );

  testWidgets(
    'PlaybackScreen opens rating dialog from Fruit car mode rating zone',
    (WidgetTester tester) async {
      setLargeCarModeViewport(tester);
      when(mockAudioProvider.currentShow).thenReturn(dummyShow);
      when(mockAudioProvider.currentSource).thenReturn(dummySource);
      when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);
      mockSettingsProvider.setCarMode(true);
      mockSettingsProvider.setShowDevAudioHud(false);

      await tester.pumpWidget(
        createTestableWidget(
          child: const PlaybackScreen(showFruitTabBar: false),
          themeProvider: MockFruitThemeProvider(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      await tester.tap(find.byKey(const ValueKey('fruit_car_mode_chip_row')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final ratingZone = find.byKey(
        const ValueKey('fruit_car_mode_rating_zone'),
      );

      expect(ratingZone, findsOneWidget);
      expect(tester.getSize(ratingZone).width, greaterThan(200.0));

      await tester.tapAt(tester.getCenter(ratingZone));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(RatingDialog), findsOneWidget);
    },
  );

  testWidgets(
    'PlaybackScreen shows floating spheres in Fruit car mode when enabled',
    (WidgetTester tester) async {
      setLargeCarModeViewport(tester);
      when(mockAudioProvider.currentShow).thenReturn(dummyShow);
      when(mockAudioProvider.currentSource).thenReturn(dummySource);
      when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);
      mockSettingsProvider.setCarMode(true);
      mockSettingsProvider.setFruitFloatingSpheres(true);

      await tester.pumpWidget(
        createTestableWidget(
          child: const PlaybackScreen(showFruitTabBar: false),
          themeProvider: MockFruitThemeProvider(),
        ),
      );

      expect(
        find.byKey(const ValueKey('fruit_car_mode_floating_spheres')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'PlaybackScreen Fruit car mode shows a magnified value lens when glass is enabled',
    (WidgetTester tester) async {
      setLargeCarModeViewport(tester);
      when(mockAudioProvider.currentShow).thenReturn(dummyShow);
      when(mockAudioProvider.currentSource).thenReturn(dummySource);
      when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);
      mockSettingsProvider.setCarMode(true);
      mockSettingsProvider.setFruitEnableLiquidGlass(true);
      mockSettingsProvider.setShowDevAudioHud(false);

      final hud = HudSnapshot.empty().copyWith(
        drift: '1.25s',
        headroom: '+12s',
        nextBuffered: '00:34',
        lastGapMs: 1200,
      );

      when(mockAudioProvider.currentHudSnapshot).thenReturn(hud);

      await tester.pumpWidget(
        createTestableWidget(
          child: const PlaybackScreen(showFruitTabBar: false),
          themeProvider: MockFruitThemeProvider(),
        ),
      );
      await tester.pump();

      expect(find.text('1.25s'), findsOneWidget);
      expect(find.text('+12s'), findsOneWidget);
      expect(find.text('00:34'), findsOneWidget);
      expect(find.text('1200ms'), findsOneWidget);

      final Text gapText = tester.widget<Text>(find.text('1200ms'));
      expect(gapText.style?.fontSize, 24.0);
      expect(
        find.byKey(const ValueKey('fruit_car_mode_stat_value_lens')),
        findsNWidgets(4),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('PlaybackScreen freezes Fruit car mode stat chips while paused', (
    WidgetTester tester,
  ) async {
    setLargeCarModeViewport(tester);
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);
    mockSettingsProvider.setCarMode(true);
    mockSettingsProvider.setShowDevAudioHud(false);

    final playerStateController = StreamController<PlayerState>.broadcast();
    final hudController = StreamController<HudSnapshot>.broadcast();
    addTearDown(playerStateController.close);
    addTearDown(hudController.close);

    final playingHud = HudSnapshot.empty().copyWith(
      drift: '1.25s',
      headroom: '+12s',
      nextBuffered: '00:34',
      lastGapMs: 47,
    );
    final pausedHud = HudSnapshot.empty().copyWith(
      drift: '8.50s',
      headroom: '+1s',
      nextBuffered: '00:02',
      lastGapMs: 212,
    );

    when(
      mockAudioProvider.hudSnapshotStream,
    ).thenAnswer((_) => hudController.stream);
    when(mockAudioProvider.currentHudSnapshot).thenReturn(playingHud);
    when(
      mockAudioProvider.playerStateStream,
    ).thenAnswer((_) => playerStateController.stream);
    when(
      mockAudioPlayer.playerState,
    ).thenReturn(PlayerState(true, ProcessingState.ready));

    await tester.pumpWidget(
      createTestableWidget(
        child: const PlaybackScreen(showFruitTabBar: false),
        themeProvider: MockFruitThemeProvider(),
      ),
    );
    await tester.pump();

    expect(find.text('1.25s'), findsOneWidget);
    expect(find.text('+12s'), findsOneWidget);
    expect(find.text('00:34'), findsOneWidget);
    expect(find.text('47ms'), findsOneWidget);

    when(
      mockAudioPlayer.playerState,
    ).thenReturn(PlayerState(false, ProcessingState.ready));
    playerStateController.add(PlayerState(false, ProcessingState.ready));
    hudController.add(pausedHud);
    await tester.pump();

    expect(find.text('1.25s'), findsOneWidget);
    expect(find.text('+12s'), findsOneWidget);
    expect(find.text('00:34'), findsOneWidget);
    expect(find.text('47ms'), findsOneWidget);
    expect(find.text('8.50s'), findsNothing);
    expect(find.text('+1s'), findsNothing);
    expect(find.text('00:02'), findsNothing);
    expect(find.text('212ms'), findsNothing);
  });
}
