import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/ui/widgets/show_list/embedded_mini_player.dart';

class MockAudioProvider extends ChangeNotifier implements AudioProvider {
  final _positionStream = Stream<Duration>.value(
    Duration.zero,
  ).asBroadcastStream();
  final _durationStream = Stream<Duration?>.value(
    const Duration(minutes: 5),
  ).asBroadcastStream();
  final _playerStateStream = Stream<PlayerState>.value(
    PlayerState(false, ProcessingState.ready),
  ).asBroadcastStream();

  @override
  Track? get currentTrack => Track(
    trackNumber: 1,
    title: 'Test Track Title',
    duration: 300,
    url: 'http://example.com/song.mp3',
    setName: 'Set 1',
  );

  @override
  Stream<Duration> get positionStream => _positionStream;
  @override
  Stream<Duration?> get durationStream => _durationStream;
  @override
  Stream<PlayerState> get playerStateStream => _playerStateStream;

  @override
  GaplessPlayer get audioPlayer => MockGaplessPlayer();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;
  @override
  bool get isMobile => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockGaplessPlayer extends Fake implements GaplessPlayer {
  @override
  Duration get position => Duration.zero;
  @override
  Duration? get duration => const Duration(minutes: 5);
  @override
  ProcessingState get processingState => ProcessingState.ready;
  @override
  bool get playing => false;
  @override
  PlayerState get playerState => PlayerState(false, ProcessingState.ready);
}

void main() {
  testWidgets('EmbeddedMiniPlayer compact renders without overflow', (
    WidgetTester tester,
  ) async {
    final mockAudioProvider = MockAudioProvider();
    final mockDeviceService = MockDeviceService();

    // Track overflow errors specifically
    final overflowErrors = <FlutterErrorDetails>[];
    final oldHandler = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('overflowed') || msg.contains('OVERFLOWING')) {
        overflowErrors.add(details);
      }
      // Suppress known semantics framework assertion
      // (_needsLayout during scheduler callback)
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
          ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: MockSettingsProvider(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                Flexible(
                  flex: 0,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 254.0),
                    child: const EmbeddedMiniPlayer(
                      compact: true,
                      scaleFactor: 1.0,
                    ),
                  ),
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    FlutterError.onError = oldHandler;

    // Verify no overflow occurred
    expect(
      overflowErrors,
      isEmpty,
      reason: 'EmbeddedMiniPlayer should not overflow',
    );

    // Verify the player rendered
    expect(find.text('Test Track Title'), findsOneWidget);
  });
}

class MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get showDebugLayout => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
