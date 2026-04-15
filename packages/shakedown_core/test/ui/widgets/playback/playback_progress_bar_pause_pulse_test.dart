import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_progress_bar.dart';
import '../../../screens/playback_screen_test.mocks.dart';

class _FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  _FakeAudioProvider({
    required this.audioPlayerImpl,
    required this.positionStreamImpl,
    required this.durationStreamImpl,
    required this.bufferedPositionStreamImpl,
    required this.playerStateStreamImpl,
  });

  final GaplessPlayer audioPlayerImpl;
  final Stream<Duration> positionStreamImpl;
  final Stream<Duration?> durationStreamImpl;
  final Stream<Duration> bufferedPositionStreamImpl;
  final Stream<PlayerState> playerStateStreamImpl;

  @override
  GaplessPlayer get audioPlayer => audioPlayerImpl;
  @override
  Stream<Duration> get positionStream => positionStreamImpl;
  @override
  Stream<Duration?> get durationStream => durationStreamImpl;
  @override
  Stream<Duration> get bufferedPositionStream => bufferedPositionStreamImpl;
  @override
  Stream<PlayerState> get playerStateStream => playerStateStreamImpl;
  @override
  Future<void> seek(Duration position) async {}
  @override
  HudSnapshot get currentHudSnapshot => HudSnapshot.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get performanceMode => false;
  @override
  bool get fruitEnableLiquidGlass => false;
  @override
  bool get uiScale => false;
  @override
  bool get useTrueBlack => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Widget buildWidget({
    required AudioProvider audioProvider,
    required SettingsProvider settingsProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 420,
              child: const PlaybackProgressBar(),
            ),
          ),
        ),
      ),
    );
  }

  Finder pulseFinder() => find.byWidgetPredicate(
    (widget) => widget is TweenAnimationBuilder<double>,
  );

  Future<void> _pumpForState(
    WidgetTester tester, {
    required ProcessingState processingState,
  }) async {
    final mockAudioPlayer = MockGaplessPlayer();
    final settingsProvider = _FakeSettingsProvider();

    when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 5));
    when(mockAudioPlayer.duration).thenReturn(const Duration(minutes: 3));
    when(
      mockAudioPlayer.bufferedPosition,
    ).thenReturn(const Duration(seconds: 35));
    when(
      mockAudioPlayer.playerState,
    ).thenReturn(PlayerState(false, processingState));

    final audioProvider = _FakeAudioProvider(
      audioPlayerImpl: mockAudioPlayer,
      positionStreamImpl: Stream<Duration>.value(
        const Duration(seconds: 5),
      ).asBroadcastStream(),
      durationStreamImpl: Stream<Duration?>.value(
        const Duration(minutes: 3),
      ).asBroadcastStream(),
      bufferedPositionStreamImpl: Stream<Duration>.value(
        const Duration(seconds: 35),
      ).asBroadcastStream(),
      playerStateStreamImpl: Stream<PlayerState>.value(
        PlayerState(false, processingState),
      ).asBroadcastStream(),
    );

    await tester.pumpWidget(
      buildWidget(
        audioProvider: audioProvider,
        settingsProvider: settingsProvider,
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'PlaybackProgressBar pulses while loading before buffering',
    (tester) async {
      await _pumpForState(
        tester,
        processingState: ProcessingState.loading,
      );

      expect(pulseFinder(), findsOneWidget);
    },
  );

  testWidgets(
    'PlaybackProgressBar does not pulse once buffering starts',
    (tester) async {
      await _pumpForState(
        tester,
        processingState: ProcessingState.buffering,
      );

      expect(pulseFinder(), findsNothing);
    },
  );
}
