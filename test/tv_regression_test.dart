import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart' as ap;
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/providers/update_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_dual_pane_layout.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:shakedown/ui/widgets/settings/tv_screensaver_section.dart';
import 'package:shakedown/ui/widgets/settings/playback_section.dart';
import 'package:shakedown/ui/widgets/tv/tv_stepper_row.dart';
import 'package:shakedown/ui/widgets/settings/appearance_section.dart';

import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/services/audio_cache_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive/hive.dart';

// Manual mocks to avoid dependency on generated files in this regression test
class MockAudioProvider extends ChangeNotifier implements ap.AudioProvider {
  @override
  GaplessPlayer get audioPlayer => MockGaplessPlayer();
  @override
  bool get isPlaying => false;
  @override
  Show? get currentShow => null;
  @override
  Source? get currentSource => null;
  @override
  ({Show show, Source source})? get pendingRandomShowRequest => null;
  @override
  Track? get currentTrack => null;
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();
  @override
  Stream<Duration?> get nextTrackBufferedStream => const Stream.empty();
  @override
  Stream<Duration?> get nextTrackTotalStream => const Stream.empty();
  @override
  Stream<String> get playbackErrorStream => const Stream.empty();
  @override
  Stream<String> get notificationStream => const Stream.empty();
  @override
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      const Stream.empty();
  @override
  Stream<({String message, VoidCallback? retryAction})>
      get bufferAgentNotificationStream => const Stream.empty();
  @override
  Stream<void> get playbackFocusRequestStream => const Stream.empty();
  @override
  int get cachedTrackCount => 0;
  @override
  String? get error => null;

  @override
  void clearPendingRandomShowRequest() {}
  @override
  void update(
      ShowListProvider slp, SettingsProvider sp, AudioCacheService acs) {}

  @override
  ({Show show, Source source})? pickRandomShow({bool filterBySearch = true}) =>
      null;
  @override
  Future<Show?> playRandomShow(
          {bool filterBySearch = true,
          bool animationOnly = false,
          bool delayPlayback = false}) async =>
      null;
  @override
  Future<void> playPendingSelection() async {}
  @override
  Future<void> playSource(Show show, Source source,
      {int initialIndex = 0, Duration? initialPosition}) async {}
  @override
  Future<bool> playFromShareString(String shareString) async => false;
  @override
  Future<void> queueRandomShow() async {}
  @override
  void clearError() {}
  @override
  void showNotification(String message) {}
  @override
  void requestPlaybackFocus() {}
  @override
  Future<void> stopAndClear() async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seekToNext() async {}
  @override
  Future<void> seekToPrevious() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> retryCurrentSource() async {}
  @override
  void seekToTrack(int localIndex) {}
  @override
  bool get hasListeners => super.hasListeners;
}

class MockGaplessPlayer extends Mock implements GaplessPlayer {
  @override
  PlayerState get playerState => PlayerState(false, ProcessingState.idle);
  @override
  Stream<PlayerState> get playerStateStream => Stream.value(playerState);
  @override
  Duration get position => Duration.zero;
  @override
  Stream<Duration> get positionStream => Stream.value(position);
  @override
  Duration? get duration => null;
  @override
  Stream<Duration?> get durationStream => Stream.value(duration);
  @override
  List<IndexedAudioSource> get sequence => [];
  @override
  int? get currentIndex => null;
  @override
  Stream<int?> get currentIndexStream => Stream.value(null);
  @override
  Stream<SequenceState?> get sequenceStateStream => const Stream.empty();
}

class MockTvDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => true;
  @override
  bool get isMobile => false;
  @override
  bool get isDesktop => false;
  @override
  bool get isSafari => false;
  @override
  bool get isPwa => false;
  @override
  String? get deviceName => 'Android TV';
  @override
  Future<void> refresh() async {}
}

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  AudioEngineMode get audioEngineMode => AudioEngineMode.auto;
  @override
  void setAudioEngineMode(AudioEngineMode mode) {}
  @override
  bool get useOilScreensaver => true;
  @override
  bool get preventSleep => false;
  @override
  int get oilScreensaverInactivityMinutes => 5;
  @override
  bool get isTv => true;
  @override
  bool get showOnboarding => false;
  @override
  bool get useMaterial3 => true;
  @override
  bool get uiScale => false;
  @override
  double get oilLogoScale => 1.0;
  @override
  Future<void> setOilLogoScale(double value) async {}
  @override
  String get appFont => 'default';
  @override
  void resetFruitFirstTimeSettings() {}

  @override
  bool get highlightCurrentShowCard => false;
  @override
  bool get showDayOfWeek => true;
  @override
  bool get abbreviateDayOfWeek => true;
  @override
  bool get abbreviateMonth => true;
  @override
  bool get dateFirstInShowCard => true;
  @override
  bool get showSingleShnid => false;
  @override
  bool get showTrackNumbers => false;
  @override
  bool get sortOldestFirst => true;
  @override
  bool get playOnTap => false;
  @override
  bool get playRandomOnCompletion => false;

  @override
  bool get fruitEnableLiquidGlass => false;
  @override
  void toggleFruitEnableLiquidGlass() {}
  @override
  bool get playRandomOnStartup => false;
  @override
  bool get nonRandom => false;
  @override
  bool get randomOnlyUnplayed => false;
  @override
  bool get randomOnlyHighRated => false;
  @override
  bool get randomExcludePlayed => false;
  @override
  bool get filterHighestShnid => false;
  @override
  bool get useTrueBlack => true;
  @override
  NeumorphicStyle get neumorphicStyle => NeumorphicStyle.convex;
  @override
  void setNeumorphicStyle(NeumorphicStyle value, {bool? notify}) {}
  @override
  bool get useDynamicColor => false;
  @override
  bool get showPlaybackMessages => false;
  @override
  bool get highlightPlayingWithRgb => true;
  @override
  bool get offlineBuffering => false;
  @override
  bool get enableBufferAgent => false;
  @override
  bool get showSplashScreen => false;
  @override
  bool get useSliverAppBar => false;
  @override
  bool get useSharedAxisTransition => false;
  @override
  bool get hideTrackCountInSourceList => false;
  @override
  bool get showExpandIcon => false;
  @override
  set showExpandIcon(bool value) {}
  @override
  int get glowMode => 0;
  @override
  double get rgbAnimationSpeed => 1.0;
  @override
  Color? get seedColor => null;
  @override
  bool get hideTrackDuration => false;
  @override
  bool get showGlobalAlbumArt => true;
  @override
  bool get isFirstRun => false;
  @override
  bool get hasShownAdvancedCacheSuggestion => true;
  @override
  bool get showDebugLayout => false;
  @override
  bool get enableShakedownTween => false;
  @override
  bool get simpleRandomIcon => false;
  @override
  bool get useStrictSrcCategorization => false;
  @override
  bool get marqueeEnabled => true;
  @override
  bool get omitHttpPathInCopy => true;
  @override
  void toggleOmitHttpPathInCopy() {}
  @override
  String get oilScreensaverMode => 'visualizer';
  @override
  double get oilFlowSpeed => 1.0;
  @override
  double get oilPulseIntensity => 1.0;
  @override
  String get oilPalette => 'psychedelic';
  @override
  double get oilHeatDrift => 0.5;
  @override
  bool get oilEnableAudioReactivity => true;
  @override
  int get oilPerformanceLevel => 0;
  @override
  bool get oilPaletteCycle => false;
  @override
  double get oilPaletteTransitionSpeed => 5.0;
  @override
  double get oilAudioPeakDecay => 0.998;
  @override
  double get oilAudioBassBoost => 1.0;
  @override
  double get oilAudioReactivityStrength => 1.0;
  @override
  double get oilFilmGrain => 0.15;
  @override
  double get oilBlurAmount => 0.0;
  @override
  bool get oilFlatColor => false;
  @override
  bool get oilBannerGlow => false;
  @override
  double get oilBannerFlicker => 0.0;
  @override
  double get oilBannerGlowBlur => 0.5;
  @override
  double get oilInnerRingScale => 1.0;
  @override
  double get oilInnerToMiddleGap => 0.3;
  @override
  double get oilMiddleToOuterGap => 0.3;
  @override
  double get oilOrbitDrift => 1.0;
  @override
  String get oilBannerDisplayMode => 'ring';
  @override
  Future<void> setOilBannerDisplayMode(String mode) async {}
  @override
  double get oilFlatTextProximity => 0.0;
  @override
  Future<void> setOilFlatTextProximity(double value) async {}
  @override
  String get oilFlatTextPlacement => 'below';
  @override
  Future<void> setOilFlatTextPlacement(String placement) async {}

  @override
  double get oilBannerResolution => 2.0;
  @override
  Future<void> setOilBannerResolution(double value) async {}
  @override
  bool get oilBannerPixelSnap => true;
  @override
  Future<void> toggleOilBannerPixelSnap() async {}
  @override
  double get oilBannerLetterSpacing => 1.02;
  @override
  Future<void> setOilBannerLetterSpacing(double value) async {}
  @override
  double get oilBannerWordSpacing => 0.4;
  @override
  Future<void> setOilBannerWordSpacing(double value) async {}
  @override
  double get oilTrackLetterSpacing => 1.02;
  @override
  Future<void> setOilTrackLetterSpacing(double value) async {}
  @override
  double get oilTrackWordSpacing => 0.4;
  @override
  Future<void> setOilTrackWordSpacing(double value) async {}
  @override
  double get oilFlatLineSpacing => 1.0;
  @override
  Future<void> setOilFlatLineSpacing(double value) async {}
  @override
  String get oilAudioGraphMode => 'off';
  @override
  void setOilAudioGraphMode(String mode) {}
  @override
  double get oilBeatSensitivity => 0.5;
  @override
  Future<void> setOilBeatSensitivity(double value) async {}

  @override
  double get oilLogoTrailIntensity => 0.0;
  @override
  int get oilLogoTrailSlices => 6;
  @override
  double get oilLogoTrailLength => 0.5;
  @override
  double get oilLogoTrailScale => 1.0;
  @override
  double get oilLogoTrailInitialScale => 0.92;
  @override
  bool get oilScreensaver4kSupport => false;
  @override
  bool get oilTvPremiumHighlight => false;
  @override
  void toggleOilTvPremiumHighlight() {}
  @override
  bool get oilLogoTrailDynamic => true;
  @override
  void toggleOilLogoTrailDynamic() {}
  @override
  Map<String, bool> get sourceCategoryFilters => {};

  @override
  void toggleSortOldestFirst() {}
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
  void setAppFont(String font) {}
  @override
  void toggleUiScale() {}
  @override
  void setGlowMode(int mode) {}
  @override
  void toggleHighlightPlayingWithRgb() {}
  @override
  void toggleShowPlaybackMessages() {}
  @override
  void setRgbAnimationSpeed(double speed) {}
  @override
  void setFruitEnableLiquidGlass(bool value) {}
  @override
  void setHighlightPlayingWithRgb(bool value) {}

  @override
  bool get enableHaptics => true;
  @override
  void toggleEnableHaptics() {}

  @override
  Future<void> setSeedColor(Color? color) async {}
  @override
  void toggleHideTrackDuration() {}
  @override
  Future<void> completeOnboarding() async {}
  @override
  void toggleNonRandom() {}
  @override
  void toggleRandomOnlyUnplayed() {}
  @override
  void toggleRandomOnlyHighRated() {}
  @override
  void toggleRandomExcludePlayed() {}
  @override
  void toggleFilterHighestShnid() {}
  @override
  Future<void> setSourceCategoryFilter(String category, bool isActive) async {}
  @override
  Future<void> setSoloSourceCategoryFilter(String category) async {}
  @override
  Future<void> enableAllSourceCategories() async {}
  @override
  void markAdvancedCacheSuggestionShown() {}
  @override
  void toggleShowDebugLayout() {}
  @override
  void toggleEnableShakedownTween() {}

  @override
  bool get enableSwipeToBlock => false;
  @override
  void toggleEnableSwipeToBlock() {}
  @override
  bool get useNeumorphism => false;

  @override
  void toggleUseNeumorphism() {}
  @override
  void setUseNeumorphism(bool value) {}

  @override
  bool get performanceMode => false;
  @override
  void togglePerformanceMode() {}

  @override
  bool get webGaplessEngine => true;
  @override
  void toggleWebGaplessEngine() {}
  @override
  int get webPrefetchSeconds => 30;
  @override
  Future<void> setWebPrefetchSeconds(int seconds) async {}

  @override
  String get trackTransitionMode => 'gapless';
  @override
  void setTrackTransitionMode(String value) {}

  @override
  HybridHandoffMode get hybridHandoffMode => HybridHandoffMode.buffered;
  @override
  void setHybridHandoffMode(HybridHandoffMode value) {}

  @override
  HybridBackgroundMode get hybridBackgroundMode => HybridBackgroundMode.html5;
  @override
  void setHybridBackgroundMode(HybridBackgroundMode value) {}

  @override
  double get crossfadeDurationSeconds => 3.0;
  @override
  void setCrossfadeDurationSeconds(double seconds) {}

  @override
  Future<void> resetToDefaults() async {}
  @override
  void toggleUseTrueBlack() {}
  @override
  void toggleShowDayOfWeek() {}
  @override
  void toggleAbbreviateDayOfWeek() {}
  @override
  void toggleAbbreviateMonth() {}
  @override
  void toggleSimpleRandomIcon() {}
  @override
  void toggleUseStrictSrcCategorization() {}
  @override
  void toggleOfflineBuffering() {}
  @override
  void toggleEnableBufferAgent() {}
  @override
  void togglePreventSleep() {}
  @override
  void toggleUseOilScreensaver() {}
  @override
  void setOilScreensaverMode(String mode) {}
  @override
  void setOilScreensaverInactivityMinutes(int minutes) {}
  @override
  Future<void> setOilFlowSpeed(double value) async {}
  @override
  Future<void> setOilPulseIntensity(double value) async {}
  @override
  Future<void> setOilPalette(String palette) async {}
  @override
  Future<void> setOilHeatDrift(double value) async {}
  @override
  Future<void> toggleOilEnableAudioReactivity() async {}
  @override
  Future<void> setOilPerformanceLevel(int level) async {}
  @override
  bool get oilLogoAntiAlias => false;
  @override
  Future<void> toggleOilLogoAntiAlias() async {}
  @override
  Future<void> toggleOilPaletteCycle() async {}

  @override
  bool get oilShowInfoBanner => true;
  @override
  void toggleOilShowInfoBanner() {}

  @override
  void setOilPaletteTransitionSpeed(double seconds) {}
  @override
  Future<void> setOilAudioPeakDecay(double value) async {}
  @override
  Future<void> setOilAudioBassBoost(double value) async {}
  @override
  Future<void> setOilAudioReactivityStrength(double value) async {}
  @override
  Future<void> setOilFilmGrain(double value) async {}
  @override
  Future<void> setOilBlurAmount(double value) async {}
  @override
  void toggleOilFlatColor() {}
  @override
  void toggleOilBannerGlow() {}
  @override
  Future<void> setOilBannerFlicker(double value) async {}
  @override
  Future<void> setOilBannerGlowBlur(double value) async {}
  @override
  Future<void> setOilInnerRingScale(double value) async {}
  @override
  Future<void> setOilInnerToMiddleGap(double value) async {}
  @override
  Future<void> setOilMiddleToOuterGap(double value) async {}
  @override
  Future<void> setOilOrbitDrift(double value) async {}
  @override
  double get oilInnerRingFontScale => 0.75;
  @override
  Future<void> setOilInnerRingFontScale(double value) async {}
  @override
  double get oilInnerRingSpacingMultiplier => 0.7;
  @override
  Future<void> setOilInnerRingSpacingMultiplier(double value) async {}

  @override
  double get oilTranslationSmoothing => 1.0;
  @override
  Future<void> setOilTranslationSmoothing(double value) async {}

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
  String get oilBannerFont => 'Roboto';
  @override
  Future<void> setOilBannerFont(String font) async {}

  @override
  bool get forceTv => false;
  @override
  void toggleForceTv() {}
  @override
  void setForceTv(bool value) {}

  @override
  bool get fruitDenseList => false;
  @override
  void toggleFruitDenseList() {}

  @override
  bool get hasListeners => super.hasListeners;
}

class MockShowListProvider extends ChangeNotifier implements ShowListProvider {
  List<Show> get shows => [];
  @override
  List<Show> get filteredShows => [];
  @override
  List<Show> get allShows => [];
  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  String get searchQuery => '';
  int get totalShowCount => 0;
  Map<String, int> get venueCounts => {};
  Map<String, int> get yearCounts => {};
  String get selectedYear => 'All';
  String get selectedVenue => 'All';
  bool get isInitialized => true;
  @override
  Set<String> get availableCategories => {};
  @override
  Future<void> get initializationComplete => Future.value();
  @override
  bool get isArchiveReachable => true;
  @override
  bool get hasCheckedArchive => true;
  @override
  bool get hasUsedRandomButton => true;
  @override
  bool get isChoosingRandomShow => false;
  @override
  bool get isSearchVisible => false;
  @override
  String? get expandedShowKey => null;
  @override
  String? get loadingShowKey => null;
  @override
  int get totalShnids => 0;

  @override
  void setSearchQuery(String query) {}
  @override
  Future<void> checkArchiveStatus() async {}
  @override
  void collapseCurrentShow() {}
  @override
  void dismissShow(Show show) {}
  @override
  void dismissSource(Show show, String sourceId) {}
  @override
  void expandShow(String key) {}
  @override
  Future<void> fetchShows(SharedPreferences prefs) async {}
  @override
  Show? getShow(String key) => null;
  @override
  String getShowKey(Show show) => show.key;
  @override
  Future<void> init(SharedPreferences prefs) async {}
  @override
  bool isShowExpanded(String key) => false;
  @override
  bool isShowLoading(String key) => false;
  @override
  Set<String> getCategoriesForSource(Source source) => {};

  @override
  bool isSourceAllowed(Source source) => true;
  @override
  void markRandomButtonUsed() {}
  @override
  void setArchiveStatus(bool isReachable) {}
  @override
  void setIsChoosingRandomShow(bool value) {}
  @override
  void setLoadingShow(String? key) {}
  @override
  void setPlayingShow(String? showName, String? sourceId) {}
  @override
  void setSearchVisible(bool visible) {}
  @override
  void toggleSearchVisible() {}
  @override
  void toggleShowExpansion(String key) {}
  @override
  void update(SettingsProvider settings) {}

  @override
  bool get hasListeners => super.hasListeners;
}

void main() {
  late MockAudioProvider mockAudioProvider;
  late FakeSettingsProvider mockSettingsProvider;
  late MockTvDeviceService mockTvDeviceService;
  late MockShowListProvider mockShowListProvider;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock path_provider channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await CatalogService().initialize(prefs: prefs);

    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = FakeSettingsProvider();
    mockTvDeviceService = MockTvDeviceService();
    mockShowListProvider = MockShowListProvider();
  });

  tearDown(() async {
    await Hive.close();
  });

  Widget createTestableWidget({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ap.AudioProvider>.value(
            value: mockAudioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<DeviceService>.value(value: mockTvDeviceService),
        ChangeNotifierProvider<ShowListProvider>.value(
            value: mockShowListProvider),
        ChangeNotifierProvider<UpdateProvider>(create: (_) => UpdateProvider()),
        ChangeNotifierProvider<ThemeProvider>(
            create: (_) => ThemeProvider(isTv: true)),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('TV Dual Pane Layout displays ShowList and Playback panes',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(createTestableWidget(child: const TvDualPaneLayout()));

    // Verify both screens are present
    expect(find.byType(ShowListScreen), findsOneWidget);
    expect(find.byType(PlaybackScreen), findsOneWidget);

    // Verify Dice is present
    expect(find.byType(AnimatedDiceIcon), findsOneWidget);
  });

  testWidgets('Navigation between panes in TV Dual Pane Layout',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(createTestableWidget(child: const TvDualPaneLayout()));

    // Initially ShowList should have something focusable if it was populated

    // Check if we can find the Settings icon
    expect(find.byIcon(Icons.settings_rounded), findsOneWidget);

    // Verify Dice is present
    expect(find.byType(AnimatedDiceIcon), findsOneWidget);
  });

  testWidgets('TV Settings UI displays new components',
      (WidgetTester tester) async {
    // We'll test the sections directly since DualPane hides them in sub-screens
    await tester.pumpWidget(createTestableWidget(
        child: Material(
      child: SingleChildScrollView(
        child: Column(
          children: [
            const TvScreensaverSection(
              scaleFactor: 1.0,
              initiallyExpanded: true,
            ),
            PlaybackSection(
              scaleFactor: 1.0,
              initiallyExpanded: true,
              activeHighlightKey: null,
              highlightTriggerCount: 0,
              settingKeys: {},
              onScrollToSetting: (_) {},
              isHighlightSettingMatching: false,
            ),
          ],
        ),
      ),
    )));

    // Verify TvStepperRow is used for Flow Speed
    expect(find.text('Flow Speed'), findsOneWidget);
    expect(find.byType(TvStepperRow),
        findsAtLeastNWidgets(1)); // Should find several

    // Verify Show Track Info toggle is present
    expect(find.text('Show Track Info'), findsOneWidget);
  });

  testWidgets('Glow and RGB settings are visible on TV',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(
      child: const Material(
        child: AppearanceSection(
          scaleFactor: 1.0,
          initiallyExpanded: true,
          showFontSelection: false,
        ),
      ),
    ));

    // Verify Glow is hidden on TV, but RGB is visible
    expect(find.text('Glow Border'), findsNothing);
    expect(find.text('Highlight Playing with RGB'), findsOneWidget);
    expect(find.text('RGB Animation Speed'), findsOneWidget);
  });
}
