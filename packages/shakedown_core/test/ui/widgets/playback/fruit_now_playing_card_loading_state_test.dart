import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/ui/widgets/playback/fruit_now_playing_card.dart';

class _MockGaplessPlayer extends Mock implements GaplessPlayer {
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
  Duration get position => super.noSuchMethod(
    Invocation.getter(#position),
    returnValue: Duration.zero,
    returnValueForMissingStub: Duration.zero,
  );

  @override
  Stream<Duration> get positionStream => super.noSuchMethod(
    Invocation.getter(#positionStream),
    returnValue: const Stream<Duration>.empty(),
    returnValueForMissingStub: const Stream<Duration>.empty(),
  );

  @override
  Duration get bufferedPosition => super.noSuchMethod(
    Invocation.getter(#bufferedPosition),
    returnValue: Duration.zero,
    returnValueForMissingStub: Duration.zero,
  );

  @override
  Stream<Duration> get bufferedPositionStream => super.noSuchMethod(
    Invocation.getter(#bufferedPositionStream),
    returnValue: const Stream<Duration>.empty(),
    returnValueForMissingStub: const Stream<Duration>.empty(),
  );

  @override
  Duration? get duration => super.noSuchMethod(
    Invocation.getter(#duration),
    returnValue: null,
    returnValueForMissingStub: null,
  );

  @override
  Stream<Duration?> get durationStream => super.noSuchMethod(
    Invocation.getter(#durationStream),
    returnValue: const Stream<Duration?>.empty(),
    returnValueForMissingStub: const Stream<Duration?>.empty(),
  );
}

class _TestAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  final GaplessPlayer audioPlayer;

  _TestAudioProvider(this.audioPlayer);

  @override
  Stream<PlayerState> get playerStateStream => audioPlayer.playerStateStream;

  @override
  Stream<Duration> get positionStream => audioPlayer.positionStream;

  @override
  Stream<Duration?> get durationStream => audioPlayer.durationStream;

  @override
  Stream<Duration> get bufferedPositionStream =>
      audioPlayer.bufferedPositionStream;

  @override
  Stream<HudSnapshot> get hudSnapshotStream =>
      const Stream<HudSnapshot>.empty();

  @override
  HudSnapshot get currentHudSnapshot => HudSnapshot.empty();

  @override
  bool get isPlaying => audioPlayer.playerState.playing;

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seekToNext() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestSettingsProvider extends ChangeNotifier implements SettingsProvider {
  final bool _glassEnabled;
  final bool _performanceMode;

  _TestSettingsProvider({
    required bool glassEnabled,
    required bool performanceMode,
  }) : _glassEnabled = glassEnabled,
       _performanceMode = performanceMode;

  @override
  bool get fruitEnableLiquidGlass => _glassEnabled;

  @override
  bool get performanceMode => _performanceMode;

  @override
  bool get showDevAudioHud => false;

  @override
  bool get showPlaybackMessages => false;

  @override
  bool get useTrueBlack => false;

  @override
  bool get uiScale => false;

  @override
  String get appFont => 'default';

  @override
  String get activeAppFont => 'default';

  @override
  bool get enableHaptics => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => ThemeStyle.fruit;

  @override
  bool get isFruit => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const pendingProgressKey = Key('fruit_pending_progress_overlay');
  const pendingTransportKey = Key('fruit_pending_transport_halo');

  final track = Track(
    trackNumber: 1,
    title: 'Slipknot!',
    duration: 420,
    url: 'https://archive.org/download/example/track.mp3',
    setName: 'Set 1',
  );
  final source = Source(id: 'gd90-03-29.sbd', tracks: [track]);
  final show = Show(
    name: '1990-03-29',
    artist: 'Grateful Dead',
    date: '1990-03-29',
    venue: 'Nassau Coliseum',
    sources: [source],
  );

  Future<void> pumpCard(
    WidgetTester tester, {
    required GaplessPlayer player,
    required bool glassEnabled,
    required bool performanceMode,
  }) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioProvider>.value(
            value: _TestAudioProvider(player),
          ),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: _TestSettingsProvider(
              glassEnabled: glassEnabled,
              performanceMode: performanceMode,
            ),
          ),
          ChangeNotifierProvider<ThemeProvider>.value(
            value: _TestThemeProvider(),
          ),
          ChangeNotifierProvider<DeviceService>.value(
            value: _TestDeviceService(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFF6B35),
              brightness: Brightness.dark,
            ),
          ),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                child: FruitNowPlayingCard(
                  trackShow: show,
                  track: track,
                  index: 1,
                  scaleFactor: 1.0,
                  showNext: false,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void stubPlayerState(
    _MockGaplessPlayer player,
    PlayerState state, {
    Duration position = Duration.zero,
    Duration buffered = Duration.zero,
    Duration? duration = const Duration(minutes: 8),
  }) {
    when(player.playerState).thenReturn(state);
    when(
      player.playerStateStream,
    ).thenAnswer((_) => Stream<PlayerState>.value(state));
    when(player.position).thenReturn(position);
    when(
      player.positionStream,
    ).thenAnswer((_) => Stream<Duration>.value(position));
    when(player.bufferedPosition).thenReturn(buffered);
    when(
      player.bufferedPositionStream,
    ).thenAnswer((_) => Stream<Duration>.value(buffered));
    when(player.duration).thenReturn(duration);
    when(
      player.durationStream,
    ).thenAnswer((_) => Stream<Duration?>.value(duration));
  }

  testWidgets(
    'pending Fruit playback cues stay visible across glass and performance modes',
    (tester) async {
      final variants = <({bool glassEnabled, bool performanceMode})>[
        (glassEnabled: true, performanceMode: false),
        (glassEnabled: false, performanceMode: false),
        (glassEnabled: true, performanceMode: true),
        (glassEnabled: false, performanceMode: true),
      ];

      for (final variant in variants) {
        final player = _MockGaplessPlayer();
        stubPlayerState(
          player,
          PlayerState(false, ProcessingState.loading),
          duration: const Duration(minutes: 8),
        );

        await pumpCard(
          tester,
          player: player,
          glassEnabled: variant.glassEnabled,
          performanceMode: variant.performanceMode,
        );
        await tester.pump();

        expect(
          find.byKey(pendingProgressKey),
          findsOneWidget,
          reason:
              'Expected pending progress shimmer for glass='
              '${variant.glassEnabled} perf=${variant.performanceMode}',
        );
        expect(
          find.byKey(pendingTransportKey),
          findsOneWidget,
          reason:
              'Expected pending transport halo for glass='
              '${variant.glassEnabled} perf=${variant.performanceMode}',
        );
      }
    },
  );

  testWidgets('pending Fruit playback cues disappear once playback is ready', (
    tester,
  ) async {
    final player = _MockGaplessPlayer();
    stubPlayerState(
      player,
      PlayerState(true, ProcessingState.ready),
      position: const Duration(seconds: 24),
      buffered: const Duration(seconds: 40),
      duration: const Duration(minutes: 8),
    );

    await pumpCard(
      tester,
      player: player,
      glassEnabled: true,
      performanceMode: false,
    );
    await tester.pump();

    expect(find.byKey(pendingProgressKey), findsNothing);
    expect(find.byKey(pendingTransportKey), findsNothing);
  });

  testWidgets(
    'pending progress shimmer appears when playback is ready but buffer headroom is empty',
    (tester) async {
      final player = _MockGaplessPlayer();
      stubPlayerState(
        player,
        PlayerState(true, ProcessingState.ready),
        position: const Duration(seconds: 9),
        buffered: const Duration(seconds: 9),
        duration: const Duration(minutes: 8),
      );

      await pumpCard(
        tester,
        player: player,
        glassEnabled: false,
        performanceMode: true,
      );
      await tester.pump();

      expect(find.byKey(pendingProgressKey), findsOneWidget);
      expect(find.byKey(pendingTransportKey), findsOneWidget);
    },
  );
}
