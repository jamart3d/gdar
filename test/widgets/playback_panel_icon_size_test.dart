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
import 'package:hive/hive.dart';
import 'package:shakedown/models/rating.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';

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
  Duration get position => Duration.zero;
  @override
  Duration get bufferedPosition => Duration.zero;
  @override
  List<IndexedAudioSource> get sequence => [];
  @override
  PlayerState get playerState => PlayerState(false, ProcessingState.idle);

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
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<String> get playbackErrorStream => const Stream.empty();
  @override
  bool get isPlaying => false;
  @override
  GaplessPlayer get audioPlayer => MockGaplessPlayer();

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
  bool get highlightCurrentShowCard => true;
  @override
  bool get showDayOfWeek => true;
  @override
  bool get abbreviateDayOfWeek => false;
  @override
  bool get abbreviateMonth => false;
  @override
  String get appFont => 'default';
  @override
  bool get showPlaybackMessages => false;
  @override
  bool get hideTrackDuration => false;
  @override
  bool get showSingleShnid => false;
  @override
  bool get marqueeEnabled => true;
  @override
  bool get useNeumorphism => false;

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

  testWidgets('PlaybackPanel copy icon has size 20 but scaled by 2.0 visually',
      (WidgetTester tester) async {
    final dummyTrack = Track(
        trackNumber: 1,
        title: 'Track 1',
        duration: 100,
        url: 'url',
        setName: 'Set 1');
    final dummySource = Source(id: 'source1', tracks: [dummyTrack]);
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

    final panelPositionNotifier = ValueNotifier<double>(1.0);

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
            body: PlaybackPanel(
              currentShow: dummyShow,
              currentSource: dummySource,
              minHeight: 100,
              bottomPadding: 0,
              panelPositionNotifier: panelPositionNotifier,
              onVenueTap: () {},
            ),
          ),
        ),
      ),
    );

    final iconFinder = find.byIcon(Icons.copy_rounded);
    expect(iconFinder, findsOneWidget);

    final Icon icon = tester.widget(iconFinder);
    expect(icon.size, equals(20.0));

    final transformFinder =
        find.ancestor(of: iconFinder, matching: find.byType(Transform));
    expect(transformFinder, findsAtLeastNWidgets(1));

    final Transform transform = tester.widget(transformFinder.first);
    expect(transform.transform.getMaxScaleOnAxis(), closeTo(2.0, 0.001));
  });
}
