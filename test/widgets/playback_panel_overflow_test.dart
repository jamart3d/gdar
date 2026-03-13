import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/playback/playback_panel.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:shakedown/models/rating.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';

// Reuse mock classes from playback_panel_icon_size_test.dart
// Since we are in the same project, we can just define them briefly or import if possible.
// For self-contained test that I can run immediately:

class MockGaplessPlayer extends Mock implements GaplessPlayer {
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();
  @override
  Stream<bool> get playingStream => const Stream.empty();
  @override
  Stream<ProcessingState> get processingStateStream => const Stream.empty();
  @override
  Stream<Duration?> get nextTrackBufferedStream => const Stream.empty();
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<SequenceState?> get sequenceStateStream => const Stream.empty();
  @override
  Stream<String> get engineStateStringStream => const Stream.empty();
  @override
  Stream<String> get engineContextStateStream => const Stream.empty();

  @override
  Duration get position => Duration.zero;
  @override
  Duration get bufferedPosition => Duration.zero;
  @override
  List<IndexedAudioSource> get sequence => [];
  @override
  PlayerState get playerState => PlayerState(false, ProcessingState.idle);
  @override
  String get engineName => 'Mock Engine';
  @override
  String get selectionReason => 'Testing';

  @override
  dynamic noSuchMethod(Invocation invocation,
          {Object? returnValue, Object? returnValueForMissingStub}) =>
      super.noSuchMethod(invocation,
          returnValue: returnValue,
          returnValueForMissingStub: returnValueForMissingStub);
}

class MockAudioProvider extends Mock implements AudioProvider {
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();
  @override
  Stream<Duration?> get nextTrackBufferedStream => const Stream.empty();
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<String> get playbackErrorStream => const Stream.empty();
  @override
  Stream<({String message, VoidCallback? retryAction})>
      get bufferAgentNotificationStream => const Stream.empty();
  @override
  Stream<String> get notificationStream => const Stream.empty();

  @override
  bool get isPlaying => false;
  final _mockPlayer = MockGaplessPlayer();
  @override
  GaplessPlayer get audioPlayer => _mockPlayer;

  @override
  dynamic noSuchMethod(Invocation invocation,
          {Object? returnValue, Object? returnValueForMissingStub}) =>
      super.noSuchMethod(invocation,
          returnValue: returnValue,
          returnValueForMissingStub: returnValueForMissingStub);
}

class MockSettingsProvider extends Mock implements SettingsProvider {
  @override
  bool get uiScale => false;
  @override
  bool get useTrueBlack => false;
  @override
  String get appFont => 'default';
  @override
  bool get showDebugLayout => false;
  @override
  bool get showPlaybackMessages => true;
  @override
  bool get hideTrackDuration => false;
  @override
  bool get marqueeEnabled => true;
  @override
  bool get useNeumorphism => false;
  @override
  bool get performanceMode => false;
  @override
  bool get showDevAudioHud => true; // Enable HUD to increase height
  @override
  bool get omitHttpPathInCopy => false;
  @override
  double get rgbAnimationSpeed => 1.0;
  @override
  bool get highlightPlayingWithRgb => false;
  @override
  int get glowMode => 0;

  @override
  dynamic noSuchMethod(Invocation invocation,
          {Object? returnValue, Object? returnValueForMissingStub}) =>
      super.noSuchMethod(invocation,
          returnValue: returnValue,
          returnValueForMissingStub: returnValueForMissingStub);
}

class MockThemeProvider extends Mock implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => ThemeStyle.android;

  @override
  bool get isFruit => themeStyle == ThemeStyle.fruit;

  @override
  dynamic noSuchMethod(Invocation invocation,
          {Object? returnValue, Object? returnValueForMissingStub}) =>
      super.noSuchMethod(invocation,
          returnValue: returnValue,
          returnValueForMissingStub: returnValueForMissingStub);
}

class MockDeviceService extends Mock implements DeviceService {
  @override
  bool get isTv => false;

  @override
  dynamic noSuchMethod(Invocation invocation,
          {Object? returnValue, Object? returnValueForMissingStub}) =>
      super.noSuchMethod(invocation,
          returnValue: returnValue,
          returnValueForMissingStub: returnValueForMissingStub);
}

class MockCatalogService extends Mock implements CatalogService {
  @override
  ValueListenable<Box<Rating>> get ratingsListenable =>
      ValueNotifier(MockBox<Rating>());
  @override
  int getRating(String key) => 0;
  @override
  bool isPlayed(String key) => false;

  @override
  dynamic noSuchMethod(Invocation invocation,
          {Object? returnValue, Object? returnValueForMissingStub}) =>
      super.noSuchMethod(invocation,
          returnValue: returnValue,
          returnValueForMissingStub: returnValueForMissingStub);
}

class MockBox<T> extends Mock implements Box<T> {
  @override
  dynamic noSuchMethod(Invocation invocation,
          {Object? returnValue, Object? returnValueForMissingStub}) =>
      super.noSuchMethod(invocation,
          returnValue: returnValue,
          returnValueForMissingStub: returnValueForMissingStub);
}

void main() {
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockThemeProvider mockThemeProvider;
  late MockDeviceService mockDeviceService;
  late MockCatalogService mockCatalogService;

  setUp(() {
    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockThemeProvider = MockThemeProvider();
    mockDeviceService = MockDeviceService();
    mockCatalogService = MockCatalogService();

    CatalogService.setMock(mockCatalogService);
  });

  testWidgets(
      'PlaybackPanel does not overflow when constrained to small height',
      (WidgetTester tester) async {
    final dummyTrack = Track(
        trackNumber: 1,
        title: 'Track 1',
        duration: 100,
        url: 'url',
        setName: 'Set 1');
    final dummySource = Source(
        id: 'source1',
        tracks: [dummyTrack],
        location: 'Test Location',
        src: 'SBD');
    final dummyShow = Show(
      name: 'Show',
      artist: 'Artist',
      date: '2025-01-01',
      venue: 'Venue',
      sources: [dummySource],
    );

    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack);

    final panelPositionNotifier = ValueNotifier<double>(1.0); // Open state

    // Force a small height constraint on the expanded section area
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: mockSettingsProvider),
          ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 180, // User's requested constraint
                child: PlaybackPanel(
                  currentShow: dummyShow,
                  currentSource: dummySource,
                  minHeight: 100, // Enough height for the venue header
                  bottomPadding: 0,
                  panelPositionNotifier: panelPositionNotifier,
                  onVenueTap: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // If there's an overflow, pump will fail or throw an assertion error in debug mode.
    // In tests, we can check for the presence of yellow/black stripes if we want,
    // but typically any layout error in pumpWidget will be caught.

    // Verify it rendered successfully without crashing
    expect(find.text('Venue'), findsOneWidget);
    expect(find.text('Test Location'), findsOneWidget);
    // Track title is in the header, always visible if not collapsed.
    // In this test setup, let's see which text we actually expect.
    // Venue name is in the fixed header part.
  });
}
