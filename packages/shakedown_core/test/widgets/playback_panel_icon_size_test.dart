import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_panel.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MockGaplessPlayer extends Mock implements GaplessPlayer {
  @override
  PlayerState get playerState => super.noSuchMethod(
    Invocation.getter(#playerState),
    returnValue: PlayerState(false, ProcessingState.idle),
    returnValueForMissingStub: PlayerState(false, ProcessingState.idle),
  );
  @override
  Stream<PlayerState> get playerStateStream => super.noSuchMethod(
    Invocation.getter(#playerStateStream),
    returnValue: const Stream<PlayerState>.empty(),
    returnValueForMissingStub: const Stream<PlayerState>.empty(),
  );
  @override
  Stream<Duration> get positionStream => super.noSuchMethod(
    Invocation.getter(#positionStream),
    returnValue: const Stream<Duration>.empty(),
    returnValueForMissingStub: const Stream<Duration>.empty(),
  );
  @override
  Stream<Duration?> get durationStream => super.noSuchMethod(
    Invocation.getter(#durationStream),
    returnValue: const Stream<Duration?>.empty(),
    returnValueForMissingStub: const Stream<Duration?>.empty(),
  );
  @override
  Stream<Duration> get bufferedPositionStream => super.noSuchMethod(
    Invocation.getter(#bufferedPositionStream),
    returnValue: const Stream<Duration>.empty(),
    returnValueForMissingStub: const Stream<Duration>.empty(),
  );
  @override
  Stream<String> get engineStateStringStream => super.noSuchMethod(
    Invocation.getter(#engineStateStringStream),
    returnValue: const Stream<String>.empty(),
    returnValueForMissingStub: const Stream<String>.empty(),
  );
  @override
  Stream<String> get engineContextStateStream => super.noSuchMethod(
    Invocation.getter(#engineContextStateStream),
    returnValue: const Stream<String>.empty(),
    returnValueForMissingStub: const Stream<String>.empty(),
  );
  @override
  Stream<PlaybackEvent> get playbackEventStream => super.noSuchMethod(
    Invocation.getter(#playbackEventStream),
    returnValue: const Stream<PlaybackEvent>.empty(),
    returnValueForMissingStub: const Stream<PlaybackEvent>.empty(),
  );
  @override
  Duration get position => super.noSuchMethod(
    Invocation.getter(#position),
    returnValue: Duration.zero,
    returnValueForMissingStub: Duration.zero,
  );
  @override
  Duration get bufferedPosition => super.noSuchMethod(
    Invocation.getter(#bufferedPosition),
    returnValue: Duration.zero,
    returnValueForMissingStub: Duration.zero,
  );
  @override
  Duration? get duration => super.noSuchMethod(
    Invocation.getter(#duration),
    returnValue: null,
    returnValueForMissingStub: null,
  );
  @override
  List<IndexedAudioSource> get sequence => super.noSuchMethod(
    Invocation.getter(#sequence),
    returnValue: <IndexedAudioSource>[],
    returnValueForMissingStub: <IndexedAudioSource>[],
  );
}

class FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  final GaplessPlayer audioPlayer;
  @override
  Show? currentShow;
  @override
  Source? currentSource;
  @override
  Track? currentTrack;

  FakeAudioProvider(this.audioPlayer);

  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _bufferedPositionController = StreamController<Duration>.broadcast();
  final _indexController = StreamController<int?>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _notificationController = StreamController<String>.broadcast();
  final _agentController =
      StreamController<
        ({String message, VoidCallback? retryAction})
      >.broadcast();
  final _randomShowController =
      StreamController<({Show show, Source source})>.broadcast();
  final _focusController = StreamController<void>.broadcast();
  final _hudSnapshotController = StreamController<HudSnapshot>.broadcast();

  @override
  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  @override
  Stream<Duration> get positionStream => _positionController.stream;
  @override
  Stream<Duration?> get durationStream => _durationController.stream;
  @override
  Stream<Duration> get bufferedPositionStream =>
      _bufferedPositionController.stream;
  @override
  Stream<int?> get currentIndexStream => _indexController.stream;
  @override
  Stream<String> get playbackErrorStream => _errorController.stream;
  @override
  Stream<String> get notificationStream => _notificationController.stream;
  @override
  Stream<({String message, VoidCallback? retryAction})>
  get bufferAgentNotificationStream => _agentController.stream;
  @override
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      _randomShowController.stream;
  @override
  Stream<void> get playbackFocusRequestStream => _focusController.stream;
  @override
  Stream<HudSnapshot> get hudSnapshotStream => _hudSnapshotController.stream;
  @override
  HudSnapshot get currentHudSnapshot => HudSnapshot.empty();

  @override
  bool get isPlaying => false;

  @override
  void dispose() {
    _playerStateController.close();
    _positionController.close();
    _durationController.close();
    _bufferedPositionController.close();
    _indexController.close();
    _errorController.close();
    _notificationController.close();
    _agentController.close();
    _randomShowController.close();
    _focusController.close();
    _hudSnapshotController.close();
    super.dispose();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSettingsProvider extends Mock implements SettingsProvider {
  @override
  String get appFont => super.noSuchMethod(
    Invocation.getter(#appFont),
    returnValue: 'default',
    returnValueForMissingStub: 'default',
  );
  @override
  String get activeAppFont => super.noSuchMethod(
    Invocation.getter(#activeAppFont),
    returnValue: 'default',
    returnValueForMissingStub: 'default',
  );
  @override
  bool get useNeumorphism => super.noSuchMethod(
    Invocation.getter(#useNeumorphism),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  @override
  bool get useTrueBlack => super.noSuchMethod(
    Invocation.getter(#useTrueBlack),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  @override
  bool get uiScale => super.noSuchMethod(
    Invocation.getter(#uiScale),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  @override
  bool get marqueeEnabled => super.noSuchMethod(
    Invocation.getter(#marqueeEnabled),
    returnValue: true,
    returnValueForMissingStub: true,
  );
  @override
  bool get performanceMode => super.noSuchMethod(
    Invocation.getter(#performanceMode),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  @override
  bool get hideTrackDuration => super.noSuchMethod(
    Invocation.getter(#hideTrackDuration),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  @override
  bool get showDayOfWeek => super.noSuchMethod(
    Invocation.getter(#showDayOfWeek),
    returnValue: true,
    returnValueForMissingStub: true,
  );
  @override
  bool get showDebugLayout => super.noSuchMethod(
    Invocation.getter(#showDebugLayout),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  @override
  bool get showPlaybackMessages => super.noSuchMethod(
    Invocation.getter(#showPlaybackMessages),
    returnValue: false,
    returnValueForMissingStub: false,
  );
  @override
  bool get showDevAudioHud => super.noSuchMethod(
    Invocation.getter(#showDevAudioHud),
    returnValue: false,
    returnValueForMissingStub: false,
  );
}

class MockThemeProvider extends Mock implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => super.noSuchMethod(
    Invocation.getter(#themeStyle),
    returnValue: ThemeStyle.android,
    returnValueForMissingStub: ThemeStyle.android,
  );

  @override
  bool get isFruit => themeStyle == ThemeStyle.fruit;
}

class MockDeviceService extends Mock implements DeviceService {
  @override
  bool get isTv => super.noSuchMethod(
    Invocation.getter(#isTv),
    returnValue: false,
    returnValueForMissingStub: false,
  );
}

class MockCatalogService extends Mock implements CatalogService {
  @override
  ValueListenable<Box<Rating>> get ratingsListenable => super.noSuchMethod(
    Invocation.getter(#ratingsListenable),
    returnValue: ValueNotifier(MockBox<Rating>()),
    returnValueForMissingStub: ValueNotifier(MockBox<Rating>()),
  );
  @override
  int getRating(String sourceId) => super.noSuchMethod(
    Invocation.method(#getRating, [sourceId]),
    returnValue: 0,
    returnValueForMissingStub: 0,
  );
  @override
  bool isPlayed(String sourceId) => super.noSuchMethod(
    Invocation.method(#isPlayed, [sourceId]),
    returnValue: false,
    returnValueForMissingStub: false,
  );
}

class MockBox<T> extends Mock implements Box<T> {}

void main() {
  late FakeAudioProvider fakeAudioProvider;
  late MockGaplessPlayer mockGaplessPlayer;
  late MockSettingsProvider mockSettingsProvider;
  late MockThemeProvider mockThemeProvider;
  late MockDeviceService mockDeviceService;
  late MockCatalogService mockCatalogService;

  setUp(() {
    mockGaplessPlayer = MockGaplessPlayer();
    fakeAudioProvider = FakeAudioProvider(mockGaplessPlayer);
    mockSettingsProvider = MockSettingsProvider();
    mockThemeProvider = MockThemeProvider();
    mockDeviceService = MockDeviceService();
    mockCatalogService = MockCatalogService();

    CatalogService.setMock(mockCatalogService);
  });

  testWidgets('PlaybackPanel copy icon has size 20 but scaled by 2.0 visually', (
    WidgetTester tester,
  ) async {
    final dummyTrack = Track(
      trackNumber: 1,
      title: 'Track 1',
      duration: 100,
      url: 'url',
      setName: 'Set 1',
    );
    final dummySource = Source(id: 'source1', tracks: [dummyTrack]);
    final dummyShow = Show(
      name: 'Show',
      artist: 'Artist',
      date: '2025-01-01',
      venue: 'Venue',
      sources: [dummySource],
    );

    fakeAudioProvider.currentShow = dummyShow;
    fakeAudioProvider.currentSource = dummySource;
    fakeAudioProvider.currentTrack = dummyTrack;

    when(
      mockGaplessPlayer.playerState,
    ).thenReturn(PlayerState(false, ProcessingState.idle));
    when(mockGaplessPlayer.position).thenReturn(Duration.zero);
    when(mockGaplessPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(mockGaplessPlayer.duration).thenReturn(Duration.zero);
    when(
      mockGaplessPlayer.playerState,
    ).thenReturn(PlayerState(false, ProcessingState.idle));
    when(mockGaplessPlayer.position).thenReturn(Duration.zero);
    when(mockGaplessPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(mockGaplessPlayer.duration).thenReturn(Duration.zero);
    when(
      mockGaplessPlayer.playerStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockGaplessPlayer.positionStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockGaplessPlayer.durationStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockGaplessPlayer.bufferedPositionStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockGaplessPlayer.playbackEventStream,
    ).thenAnswer((_) => const Stream.empty());
    when(mockGaplessPlayer.sequence).thenReturn(<IndexedAudioSource>[]);

    when(mockSettingsProvider.useNeumorphism).thenReturn(true);
    when(mockSettingsProvider.useTrueBlack).thenReturn(false);
    when(mockSettingsProvider.uiScale).thenReturn(false);
    when(mockSettingsProvider.appFont).thenReturn('default');
    when(mockSettingsProvider.showDebugLayout).thenReturn(false);
    when(mockSettingsProvider.performanceMode).thenReturn(false);
    when(mockSettingsProvider.showDevAudioHud).thenReturn(false);

    when(mockThemeProvider.themeStyle).thenReturn(ThemeStyle.android);

    when(mockDeviceService.isTv).thenReturn(false);

    when(
      mockCatalogService.ratingsListenable,
    ).thenReturn(ValueNotifier(MockBox<Rating>()));
    when(mockCatalogService.getRating('source1')).thenReturn(0);
    when(mockCatalogService.isPlayed('source1')).thenReturn(false);

    final panelPositionNotifier = ValueNotifier<double>(1.0);

    debugPrint(
      'DEBUG: fakeAudioProvider.playerStateStream = ${fakeAudioProvider.playerStateStream}',
    );
    debugPrint(
      'DEBUG: fakeAudioProvider.playerStateStream type = ${fakeAudioProvider.playerStateStream.runtimeType}',
    );

    debugPrint(
      'DEBUG: fakeAudioProvider.audioPlayer.playerState = ${fakeAudioProvider.audioPlayer.playerState}',
    );
    debugPrint(
      'DEBUG: fakeAudioProvider.audioPlayer.playerState type = ${fakeAudioProvider.audioPlayer.playerState.runtimeType}',
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioProvider>.value(value: fakeAudioProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider,
          ),
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

    final iconFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Icon &&
          (widget.icon == LucideIcons.copy ||
              widget.icon == Icons.copy_rounded),
    );
    expect(iconFinder, findsOneWidget);

    final Icon icon = tester.widget(iconFinder);
    double? iconSize = icon.size;

    if (iconSize == null) {
      final iconThemeFinder = find.ancestor(
        of: iconFinder,
        matching: find.byType(IconTheme),
      );
      final IconTheme iconTheme = tester.widget(iconThemeFinder.first);
      iconSize = iconTheme.data.size;
    }
    expect(iconSize, equals(20.0));

    final transformFinder = find.ancestor(
      of: iconFinder,
      matching: find.byType(Transform),
    );
    final Transform transform = tester.widget(transformFinder.first);
    final double scale = transform.transform.getMaxScaleOnAxis();
    expect(scale, closeTo(2.0, 0.001));
  });
}


