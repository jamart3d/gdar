import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_header.dart';
import 'package:shakedown/ui/widgets/tv/tv_dual_pane_layout.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/services/audio_cache_service.dart';
import 'package:shakedown/models/rating.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart';

// Manual Mock definitions to avoid code generation dependency for this quick test
class MockAudioProvider extends ChangeNotifier implements AudioProvider {
  final _randomShowRequestController =
      StreamController<({Show show, Source source})>.broadcast();
  int playRandomShowCallCount = 0;
  int playPendingSelectionCallCount = 0;
  int playSourceCallCount = 0;

  @override
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      _randomShowRequestController.stream;

  bool _isPlaying = false;
  @override
  bool get isPlaying => _isPlaying;

  Show? _currentShow = Show(
    date: '1977-05-08',
    venue: 'Cornell',
    name: 'Cornell 77',
    artist: 'Grateful Dead',
    sources: [
      Source(id: '123', tracks: [
        Track(
          trackNumber: 1,
          title: 'Track 1',
          duration: 180,
          url: 'http://example.com/track.mp3',
          setName: 'Set 1',
        )
      ])
    ],
  );

  @override
  Show? get currentShow => _currentShow;
  @override
  Source? get currentSource => _currentShow?.sources.first;
  @override
  Track? get currentTrack => _currentShow?.sources.first.tracks.first;
  @override
  String? get error => null;

  ({Show show, Source source})? _pendingRequest;
  @override
  ({Show show, Source source})? get pendingRandomShowRequest => _pendingRequest;

  @override
  Future<Show?> playRandomShow({
    bool filterBySearch = true,
    bool animationOnly = false,
    bool delayPlayback = false,
  }) async {
    playRandomShowCallCount++;
    if (delayPlayback) {
      _pendingRequest = (show: currentShow!, source: currentSource!);
      _randomShowRequestController
          .add((show: currentShow!, source: currentSource!));
    }
    notifyListeners();
    return currentShow;
  }

  @override
  Future<void> playPendingSelection() async {
    playPendingSelectionCallCount++;
    if (_pendingRequest != null) {
      await playSource(_pendingRequest!.show, _pendingRequest!.source);
      _pendingRequest = null;
    }
  }

  @override
  Future<void> playSource(Show show, Source source,
      {int initialIndex = 0, Duration? initialPosition}) async {
    playSourceCallCount++;
    _isPlaying = true;
    _currentShow = show;
    notifyListeners();
  }

  @override
  Stream<String> get playbackErrorStream => const Stream.empty();
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<void> get playbackFocusRequestStream => const Stream.empty();
  @override
  Stream<String> get notificationStream => const Stream.empty();
  @override
  late final GaplessPlayer audioPlayer = GaplessPlayer();

  @override
  void update(
      ShowListProvider slp, SettingsProvider sp, AudioCacheService acs) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get showPlaybackMessages => false;
  @override
  bool get useTrueBlack => false;
  @override
  bool get highlightCurrentShowCard => false;
  @override
  bool get uiScale => false;
  @override
  bool get isTv => true;
  @override
  String get appFont => 'Roboto';
  @override
  bool get showTrackNumbers => true;
  @override
  bool get highlightPlayingWithRgb => false;
  @override
  double get rgbAnimationSpeed => 1.0;
  @override
  int get glowMode => 0;
  @override
  bool get marqueeEnabled => true;
  @override
  bool get enableShakedownTween => true;
  @override
  bool get playRandomOnStartup => false;
  @override
  bool get hideTrackDuration => false;
  @override
  double get oilLogoTrailIntensity => 0.0;
  @override
  int get oilLogoTrailSlices => 6;
  @override
  double get oilLogoTrailLength => 0.5;
  @override
  double get oilLogoTrailScale => 0.1;
  @override
  double get oilLogoTrailInitialScale => 0.92;

  @override
  Future<void> setOilLogoTrailIntensity(double value) async {}
  @override
  Future<void> setOilLogoTrailSlices(int value) async {}
  @override
  Future<void> setOilLogoTrailLength(double value) async {}
  @override
  Future<void> setOilLogoTrailScale(double value) async {}
  @override
  Future<void> setOilLogoTrailInitialScale(double value) async {}
  @override
  bool get useNeumorphism => true;
  @override
  bool get useOilScreensaver => false;
  @override
  int get oilScreensaverInactivityMinutes => 5;
  @override
  bool get useDynamicColor => false;
  @override
  bool get useMaterial3 => true;
  @override
  Color? get seedColor => null;
  @override
  bool get showSplashScreen => false;
  @override
  bool get showOnboarding => false;
  @override
  bool get performanceMode => false;
  @override
  bool get fruitDenseList => false;
  @override
  bool get oilTvPremiumHighlight => false;

  @override
  void setGlowMode(int value) {}
  @override
  void setHighlightPlayingWithRgb(bool value) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockShowListProvider extends ChangeNotifier implements ShowListProvider {
  @override
  bool get isChoosingRandomShow => false;
  @override
  List<Show> get allShows => [];
  @override
  List<Show> get filteredShows => [];

  @override
  bool get isSearchVisible => false;

  @override
  bool get hasUsedRandomButton => false;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  void setIsChoosingRandomShow(bool value) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => true;
  @override
  bool get isMobile => false;
  @override
  bool get isDesktop => true;
  @override
  String? get deviceName => 'Test TV';
  @override
  bool get isSafari => false;
  @override
  bool get isPwa => false;
  @override
  Future<void> refresh() async {}
}

class MockCatalogService extends CatalogService {
  MockCatalogService() : super.internal();

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
  int getRating(String sourceId) => 0;
  @override
  bool isPlayed(String sourceId) => false;
  @override
  int getPlayCount(String sourceId) => 0;

  @override
  bool get isInitialized => true;
}

class MockThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  bool testOnlyOverrideFruitAllowed = false;

  @override
  ThemeStyle get themeStyle => ThemeStyle.android;
  @override
  FruitColorOption get fruitColorOption => FruitColorOption.sophisticate;
  @override
  ThemeMode get currentThemeMode => ThemeMode.dark;
  @override
  bool get isDarkMode => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockAudioCacheService implements AudioCacheService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockBox<T> extends ChangeNotifier implements Box<T> {
  @override
  T? get(dynamic key, {T? defaultValue}) => null;
  @override
  bool get isOpen => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
      'TvDualPaneLayout debouncing fails to prevent double playback if playback starts early',
      (WidgetTester tester) async {
    // Set TV size
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockCatalogService = MockCatalogService();
    CatalogService.setMock(mockCatalogService);

    final mockAudioProvider = MockAudioProvider();
    final mockSettingsProvider = MockSettingsProvider();
    final mockShowListProvider = MockShowListProvider();
    final mockDeviceService = MockDeviceService();
    final mockThemeProvider = MockThemeProvider();

    // Set TV size to avoid layout overflow
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<CatalogService>.value(value: mockCatalogService),
          ChangeNotifierProvider<AudioCacheService>.value(
              value: MockAudioCacheService()),
          ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: mockSettingsProvider),
          ChangeNotifierProvider<ShowListProvider>.value(
              value: mockShowListProvider),
          ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ],
        child: const MaterialApp(
          home: TvDualPaneLayout(),
        ),
      ),
    );

    // Initial state
    expect(mockAudioProvider.playRandomShowCallCount, 0);
    expect(mockAudioProvider.playSourceCallCount, 0);

    // Trigger the callback directly to ensure logic is tested
    // UI hit-testing in TV layouts can be finicky in tests
    final tvHeader = tester.widget<TvHeader>(find.byType(TvHeader));
    tvHeader.onRandomPlay();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(mockAudioProvider.playRandomShowCallCount, 1);

    // 1.2s delay for Show List
    await tester.pump(const Duration(milliseconds: 1200));

    // 2.0s delay for Pane Switch (Track List Focus)
    await tester.pump(const Duration(milliseconds: 2000));

    // SIMULATE PREMATURE PLAYBACK (e.g. from accidental focus trigger)
    // We manually call playSource as if the system triggered it.
    await mockAudioProvider.playSource(
        mockAudioProvider.currentShow!, mockAudioProvider.currentSource!);
    expect(mockAudioProvider.playSourceCallCount, 1);

    // 2.0s delay for Playback Start (Timer finishes)
    await tester.pump(const Duration(milliseconds: 2000));

    // Clear the 500ms safety buffer timer
    await tester.pump(const Duration(milliseconds: 500));

    // Check call count. If 2, then the bug exists (it tried to play again).
    // The bug we want to fix is that it SHOULD be 1 (TvDualPaneLayout should catch it).
    expect(mockAudioProvider.playSourceCallCount, 1,
        reason: 'Double playback prevented!');
  });
}
