import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/playback/playback_messages.dart';

import 'playback_messages_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AudioProvider>(),
  MockSpec<SettingsProvider>(),
  MockSpec<AudioPlayer>(),
])
class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;
  @override
  String? get deviceName => 'Mock Device';
  @override
  Future<void> refresh() async {}
}

void main() {
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockAudioPlayer mockAudioPlayer;
  late MockDeviceService mockDeviceService;

  // Stream Controllers
  late StreamController<PlayerState> playerStateController;
  late StreamController<Duration> bufferedPositionController;
  late StreamController<({String message, VoidCallback? retryAction})>
      bufferAgentController;

  setUp(() {
    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockAudioPlayer = MockAudioPlayer();
    mockDeviceService = MockDeviceService();

    // Initialize controllers
    playerStateController = StreamController<PlayerState>.broadcast();
    bufferedPositionController = StreamController<Duration>.broadcast();
    bufferAgentController = StreamController<
        ({String message, VoidCallback? retryAction})>.broadcast();

    // Stub AudioProvider.audioPlayer FIRST so it doesn't return null
    when(mockAudioProvider.audioPlayer).thenReturn(mockAudioPlayer);

    // Setup AudioPlayer stub
    when(mockAudioPlayer.playerState)
        .thenReturn(PlayerState(false, ProcessingState.idle));
    when(mockAudioPlayer.bufferedPosition).thenReturn(Duration.zero);

    // Setup AudioProvider streams
    when(mockAudioProvider.playerStateStream)
        .thenAnswer((_) => playerStateController.stream);
    when(mockAudioProvider.bufferedPositionStream)
        .thenAnswer((_) => bufferedPositionController.stream);
    when(mockAudioProvider.bufferAgentNotificationStream)
        .thenAnswer((_) => bufferAgentController.stream);

    // Setup SettingsProvider
    when(mockSettingsProvider.showPlaybackMessages).thenReturn(true);
    when(mockSettingsProvider.appFont).thenReturn('Roboto');
    when(mockSettingsProvider.uiScale).thenReturn(false);
  });

  tearDown(() {
    playerStateController.close();
    bufferedPositionController.close();
    bufferAgentController.close();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: PlaybackMessages(),
        ),
      ),
    );
  }

  group('PlaybackMessages', () {
    testWidgets('Displays nothing when showPlaybackMessages is false',
        (tester) async {
      when(mockSettingsProvider.showPlaybackMessages).thenReturn(false);
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('Displays "Loading..." when loading', (tester) async {
      when(mockAudioPlayer.playerState)
          .thenReturn(PlayerState(false, ProcessingState.loading));
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('Displays "Buffering..." when buffering', (tester) async {
      when(mockAudioPlayer.playerState)
          .thenReturn(PlayerState(true, ProcessingState.buffering));
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Buffering...'), findsOneWidget);
    });

    testWidgets('Displays Agent Message when notification received',
        (tester) async {
      // 1. Start with normal buffering
      when(mockAudioPlayer.playerState)
          .thenReturn(PlayerState(true, ProcessingState.buffering));
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Buffering...'), findsOneWidget);

      // 2. Emit Agent Notification
      bufferAgentController.add(
          (message: 'Network issue detected. Retrying...', retryAction: null));
      await tester.pumpAndSettle();

      // 3. Verify Message
      expect(find.text('Network issue detected. Retrying...'), findsOneWidget);
      // Ensure "Buffering..." is gone (replaced)
      expect(find.text('Buffering...'), findsNothing);
    });

    testWidgets('Clears Agent Message when playback resumes (Ready + Playing)',
        (tester) async {
      // 1. Setup Agent Message state
      when(mockAudioPlayer.playerState)
          .thenReturn(PlayerState(true, ProcessingState.buffering));
      await tester.pumpWidget(createWidgetUnderTest());

      bufferAgentController.add((message: 'Retrying...', retryAction: null));
      await tester.pumpAndSettle();
      expect(find.text('Retrying...'), findsOneWidget);

      // 2. Emit Playing State
      playerStateController.add(PlayerState(true, ProcessingState.ready));
      await tester.pumpAndSettle();

      // 3. Verify Message Cleared and showing "Playing"
      expect(find.text('Retrying...'), findsNothing);
      expect(find.text('Playing'), findsOneWidget);
    });

    testWidgets('Does NOT clear Agent Message if paused (Ready + Not Playing)',
        (tester) async {
      // Logic: If we pause while it was retrying (maybe user pause?), we might want to keep the message?
      // Actually the code says: if (state.playing && state.processingState == ProcessingState.ready && _agentMessage != null)
      // So if it's NOT playing, it won't clear.

      // 1. Setup Agent Message state
      when(mockAudioPlayer.playerState)
          .thenReturn(PlayerState(true, ProcessingState.buffering));
      await tester.pumpWidget(createWidgetUnderTest());

      bufferAgentController.add((message: 'Retrying...', retryAction: null));
      await tester.pumpAndSettle();

      // 2. Emit Paused State (Ready but not playing)
      playerStateController.add(PlayerState(false, ProcessingState.ready));
      await tester.pumpAndSettle();

      // 3. Verify Message Persists (because we strictly check logic)
      expect(find.text('Retrying...'), findsOneWidget);
      // "Paused" should NOT be shown if message is present
      expect(find.text('Paused'), findsNothing);
    });
  });
}
