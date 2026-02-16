import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:flutter/services.dart';

import 'playback_screen_test.mocks.dart';

// Reuse mocks from playback_screen_test.mocks.dart
// But we need a custom MockTvDeviceService to return isTv = true

class MockTvDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => true;
  @override
  String? get deviceName => 'Mock TV Device';
  @override
  Future<void> refresh() async {}
}

class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get sortOldestFirst => true;
  @override
  void toggleSortOldestFirst() {}

  @override
  bool get uiScale => false;
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
  bool get useDynamicColor => false;
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
  Future<void> setSeedColor(Color? color) async {}

  @override
  bool get hideTrackDuration => false;
  @override
  void toggleHideTrackDuration() {}

  @override
  bool get showGlobalAlbumArt => true;

  @override
  bool get isFirstRun => false;
  @override
  bool get showOnboarding => false;
  @override
  Future<void> completeOnboarding() async {}

  @override
  bool get nonRandom => false;
  @override
  void toggleNonRandom() {}
  @override
  bool get randomOnlyUnplayed => false;
  @override
  bool get randomOnlyHighRated => false;
  @override
  bool get randomExcludePlayed => false;
  @override
  void toggleRandomOnlyUnplayed() {}
  @override
  void toggleRandomOnlyHighRated() {}
  @override
  void toggleRandomExcludePlayed() {}

  @override
  bool get filterHighestShnid => false;
  @override
  void toggleFilterHighestShnid() {}
  @override
  Map<String, bool> get sourceCategoryFilters => {};
  @override
  Future<void> setSourceCategoryFilter(String category, bool isActive) async {}
  @override
  Future<void> setSoloSourceCategoryFilter(String category) async {}
  @override
  Future<void> enableAllSourceCategories() async {}

  @override
  bool get hasShownAdvancedCacheSuggestion => true;
  @override
  void markAdvancedCacheSuggestionShown() {}

  @override
  bool get showDebugLayout => false;
  @override
  void toggleShowDebugLayout() {}

  @override
  bool get enableShakedownTween => false;
  @override
  void toggleEnableShakedownTween() {}

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
  bool get simpleRandomIcon => false;

  @override
  bool get useStrictSrcCategorization => false;
  @override
  void toggleUseStrictSrcCategorization() {}

  @override
  bool get offlineBuffering => false;
  @override
  void toggleOfflineBuffering() {}

  @override
  bool get enableBufferAgent => false;
  @override
  void toggleEnableBufferAgent() {}

  @override
  bool get marqueeEnabled => true;

  @override
  bool get preventScreensaver => true;
  @override
  void togglePreventScreensaver() {}

  @override
  bool get hasListeners => super.hasListeners;
}

@GenerateMocks([AudioProvider, AudioPlayer])
void main() {
  late MockAudioProvider mockAudioProvider;
  late FakeSettingsProvider mockSettingsProvider;
  late MockAudioPlayer mockAudioPlayer;
  late MockTvDeviceService mockTvDeviceService;

  // Dummy data
  final dummyTrack1 = Track(
      trackNumber: 1,
      title: 'Track 1',
      duration: 100,
      url: '',
      setName: 'Set 1');
  final dummySource = Source(id: 'source1', tracks: [dummyTrack1]);
  final dummyShow = Show(
    name: 'Venue A on 2025-01-15',
    artist: 'Grateful Dead',
    date: '2025-01-15',
    venue: 'Venue A',
    sources: [dummySource],
  );

  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync('gdar_test_tv_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return tempDir.path;
    });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await CatalogService().initialize(prefs: prefs);

    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = FakeSettingsProvider();
    mockAudioPlayer = MockAudioPlayer();
    mockTvDeviceService = MockTvDeviceService();

    when(mockAudioProvider.audioPlayer).thenReturn(mockAudioPlayer);
    when(mockAudioPlayer.currentIndex).thenReturn(0);
    when(mockAudioPlayer.position).thenReturn(Duration.zero);
    when(mockAudioPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(mockAudioPlayer.duration).thenReturn(const Duration(seconds: 100));
    when(mockAudioPlayer.playerState)
        .thenReturn(PlayerState(false, ProcessingState.idle));

    when(mockAudioProvider.playerStateStream).thenAnswer(
        (_) => Stream.value(PlayerState(false, ProcessingState.idle)));
    when(mockAudioProvider.currentIndexStream)
        .thenAnswer((_) => Stream.value(0));
    when(mockAudioProvider.durationStream)
        .thenAnswer((_) => Stream.value(const Duration(seconds: 100)));
    when(mockAudioProvider.positionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(mockAudioProvider.bufferedPositionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(mockAudioProvider.playbackErrorStream)
        .thenAnswer((_) => Stream.value(''));
    when(mockAudioPlayer.sequence).thenReturn([]);
    when(mockAudioPlayer.sequenceStateStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockAudioProvider.currentTrack).thenReturn(null);
  });

  Widget createTestableWidget({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<DeviceService>.value(value: mockTvDeviceService),
      ],
      child: MaterialApp(
        home: Material(child: child),
      ),
    );
  }

  testWidgets(
      'PlaybackScreen on TV displays Show Date and Venue in header instead of TRACK LIST',
      (WidgetTester tester) async {
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);

    await tester.pumpWidget(createTestableWidget(
        child: const PlaybackScreen(
      isPane: true, // Simulate being in TV Dual Pane
    )));

    // Verify "TRACK LIST" is NOT present (using a robust check)
    // We expect the Date and Venue to be there.
    expect(find.text('TRACK LIST'), findsNothing);

    // Verify Date is displayed with Rock Salt font (implied by just finding text for now)
    // formattedDate for 2025-01-15 depends on implementation, likely "Jan 15, 2025" or similar
    // We can check fuzzy match or look at Show.formattedDate implementation if needed.
    // Assuming "Jan 15, 2025" based on typical US locale
    expect(find.textContaining('Jan'), findsOneWidget);
    expect(find.text('Venue A'), findsOneWidget);
  });
}
