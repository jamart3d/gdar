import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:flutter/services.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';

import 'playback_screen_test.mocks.dart';
import '../helpers/fake_settings_provider.dart';

// Reuse mocks from playback_screen_test.mocks.dart
// But we need a custom MockTvDeviceService to return isTv = true

class MockTvDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => true;
  @override
  bool get isMobile => false;
  @override
  bool get isDesktop => true;
  @override
  bool get isSafari => false;
  @override
  bool get isPwa => false;
  @override
  String? get deviceName => 'Mock TV';
  @override
  Future<void> refresh() async {}
}

class MockShowListProvider extends ChangeNotifier implements ShowListProvider {
  @override
  bool get isChoosingRandomShow => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

@GenerateMocks([AudioProvider, GaplessPlayer])
void main() {
  late MockAudioProvider mockAudioProvider;
  late FakeSettingsProvider mockSettingsProvider;
  late MockGaplessPlayer mockAudioPlayer;
  late MockTvDeviceService mockTvDeviceService;

  // Dummy data
  final dummyTrack1 = Track(
    trackNumber: 1,
    title: 'Track 1',
    duration: 100,
    url: '',
    setName: 'Set 1',
  );
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
    mockAudioPlayer = MockGaplessPlayer();
    mockTvDeviceService = MockTvDeviceService();

    when(mockAudioProvider.audioPlayer).thenReturn(mockAudioPlayer);
    when(
      mockAudioProvider.playbackErrorStream,
    ).thenAnswer((_) => Stream.value(''));
    when(mockAudioProvider.isPlaying).thenReturn(false);
    when(mockAudioPlayer.sequence).thenReturn([]);
    when(mockAudioPlayer.currentIndex).thenReturn(0);
    when(mockAudioPlayer.position).thenReturn(Duration.zero);
    when(mockAudioPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(mockAudioPlayer.duration).thenReturn(const Duration(seconds: 100));
    when(
      mockAudioPlayer.playerState,
    ).thenReturn(PlayerState(false, ProcessingState.idle));

    when(
      mockAudioProvider.playerStateStream,
    ).thenAnswer((_) => Stream.value(PlayerState(false, ProcessingState.idle)));
    when(
      mockAudioProvider.currentIndexStream,
    ).thenAnswer((_) => Stream.value(0));
    when(
      mockAudioProvider.durationStream,
    ).thenAnswer((_) => Stream.value(const Duration(seconds: 100)));
    when(
      mockAudioProvider.positionStream,
    ).thenAnswer((_) => Stream.value(Duration.zero));
    when(
      mockAudioProvider.bufferedPositionStream,
    ).thenAnswer((_) => Stream.value(Duration.zero));
    when(
      mockAudioProvider.playbackErrorStream,
    ).thenAnswer((_) => Stream.value(''));
    when(mockAudioPlayer.sequence).thenReturn([]);
    when(
      mockAudioPlayer.sequenceStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(mockAudioProvider.currentTrack).thenReturn(null);
    when(
      mockAudioProvider.hudSnapshotStream,
    ).thenAnswer((_) => const Stream.empty());
    when(mockAudioProvider.currentHudSnapshot).thenReturn(HudSnapshot.empty());
  });

  Widget createTestableWidget({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
          value: mockSettingsProvider,
        ),
        ChangeNotifierProvider<DeviceService>.value(value: mockTvDeviceService),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<ShowListProvider>(
          create: (_) => MockShowListProvider(),
        ),
      ],
      child: MaterialApp(home: Material(child: child)),
    );
  }

  testWidgets(
    'PlaybackScreen on TV displays Show Date and Venue in header instead of TRACK LIST',
    (WidgetTester tester) async {
      when(mockAudioProvider.currentShow).thenReturn(dummyShow);
      when(mockAudioProvider.currentSource).thenReturn(dummySource);
      when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);

      await tester.pumpWidget(
        createTestableWidget(
          child: const PlaybackScreen(
            isPane: true, // Simulate being in TV Dual Pane
          ),
        ),
      );

      // Verify "TRACK LIST" is NOT present (using a robust check)
      // We expect the Date and Venue to be there.
      expect(find.text('TRACK LIST'), findsNothing);

      // Verify Date is displayed with Rock Salt font (implied by just finding text for now)
      // formattedDate for 2025-01-15 depends on implementation, likely "Jan 15, 2025" or similar
      // We can check fuzzy match or look at Show.formattedDate implementation if needed.
      // Assuming "Jan 15, 2025" based on typical US locale
      expect(find.textContaining('2025'), findsAtLeastNWidgets(1));
      expect(find.text('Venue A'), findsOneWidget);
    },
  );
}
