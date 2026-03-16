import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_messages.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';

import 'playback_messages_test.mocks.dart';

@GenerateMocks([AudioProvider, SettingsProvider])
class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;
  @override
  bool get isMobile => true;
  @override
  bool get isDesktop => false;
  @override
  bool get isSafari => false;
  @override
  bool get isPwa => false;
  @override
  String? get deviceName => 'Mock';
  @override
  Future<void> refresh() async {}
}

void main() {
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockDeviceService mockDeviceService;

  // Stream Controllers
  late StreamController<HudSnapshot> hudSnapshotController;

  setUp(() {
    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockDeviceService = MockDeviceService();

    hudSnapshotController = StreamController<HudSnapshot>.broadcast();

    // Setup AudioProvider streams
    when(
      mockAudioProvider.hudSnapshotStream,
    ).thenAnswer((_) => hudSnapshotController.stream);
    when(mockAudioProvider.currentHudSnapshot).thenReturn(HudSnapshot.empty());

    // Setup SettingsProvider
    when(mockSettingsProvider.showPlaybackMessages).thenReturn(true);
    when(mockSettingsProvider.appFont).thenReturn('Roboto');
    when(mockSettingsProvider.uiScale).thenReturn(false);
  });

  tearDown(() {
    hudSnapshotController.close();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: mockSettingsProvider,
        ),
        ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(isTv: false),
        ),
      ],
      child: const MaterialApp(home: Scaffold(body: PlaybackMessages())),
    );
  }

  group('PlaybackMessages', () {
    testWidgets('Displays nothing when showPlaybackMessages is false', (
      tester,
    ) async {
      when(mockSettingsProvider.showPlaybackMessages).thenReturn(false);
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.byType(Text), findsNothing);
    });

    testWidgets('Displays "Loading..." when loading (HudSnapshot LD)', (
      tester,
    ) async {
      when(
        mockAudioProvider.currentHudSnapshot,
      ).thenReturn(HudSnapshot.empty().copyWith(processing: 'LD'));
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('Displays "Buffering..." when buffering (HudSnapshot BUF)', (
      tester,
    ) async {
      when(
        mockAudioProvider.currentHudSnapshot,
      ).thenReturn(HudSnapshot.empty().copyWith(processing: 'BUF'));
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Buffering...'), findsOneWidget);
    });

    testWidgets('Displays message from signal when present', (tester) async {
      when(mockAudioProvider.currentHudSnapshot).thenReturn(
        HudSnapshot.empty().copyWith(
          signal: 'AGT',
          message: 'Network issue detected',
          processing: 'BUF',
        ),
      );
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Network issue detected'), findsOneWidget);
      expect(find.text('Buffering...'), findsNothing);
    });

    testWidgets(
      'Clears message and shows Playing (HudSnapshot RDY + isPlaying)',
      (tester) async {
        // 1. Initial message state
        when(mockAudioProvider.currentHudSnapshot).thenReturn(
          HudSnapshot.empty().copyWith(
            signal: 'AGT',
            message: 'Retrying...',
            processing: 'BUF',
          ),
        );
        await tester.pumpWidget(createWidgetUnderTest());
        expect(find.text('Retrying...'), findsOneWidget);

        // 2. Emit RDY + Playing
        hudSnapshotController.add(
          HudSnapshot.empty().copyWith(
            signal: '--',
            message: '--',
            processing: 'RDY',
            isPlaying: true,
          ),
        );
        await tester.pump(); // No settle needed for simple Text change usually

        expect(find.text('Retrying...'), findsNothing);
        expect(find.text('Playing'), findsOneWidget);
      },
    );

    testWidgets('Shows Paused when RDY and not playing', (tester) async {
      when(mockAudioProvider.currentHudSnapshot).thenReturn(
        HudSnapshot.empty().copyWith(processing: 'RDY', isPlaying: false),
      );
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Paused'), findsOneWidget);
    });

    testWidgets('Prioritizes Handoff Countdown message', (tester) async {
      when(mockAudioProvider.currentHudSnapshot).thenReturn(
        HudSnapshot.empty().copyWith(
          isHandoffCountdown: true,
          message: 'Handoff in 5s...',
          processing: 'RDY',
          isPlaying: true,
        ),
      );
      await tester.pumpWidget(createWidgetUnderTest());
      expect(find.text('Handoff in 5s...'), findsOneWidget);
      expect(find.text('Playing'), findsNothing);
    });
  });
}
