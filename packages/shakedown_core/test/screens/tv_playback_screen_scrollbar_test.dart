import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/screens/tv_playback_screen.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_scrollbar.dart';

import 'playback_screen_test.mocks.dart';
import '../helpers/fake_settings_provider.dart';

class _MockTvDeviceService extends ChangeNotifier implements DeviceService {
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
  bool get isLowEndTvDevice => false;
  @override
  Future<void> refresh() async {}
}

class _MockShowListProvider extends ChangeNotifier implements ShowListProvider {
  @override
  bool get isChoosingRandomShow => false;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// FakeSettingsProvider variant with scrollbars hidden.
class _HiddenScrollbarFakeSettings extends FakeSettingsProvider {
  @override
  bool get hideTvScrollbars => true;
}

void main() {
  late MockAudioProvider mockAudioProvider;
  late MockGaplessPlayer mockAudioPlayer;

  final dummyTrack = Track(
    trackNumber: 1,
    title: 'Track 1',
    duration: 100,
    url: '',
    setName: 'Set 1',
  );
  final dummySource = Source(id: 'source1', tracks: [dummyTrack]);
  final dummyShow = Show(
    name: 'Venue A on 2025-01-15',
    artist: 'Grateful Dead',
    date: '2025-01-15',
    venue: 'Venue A',
    sources: [dummySource],
  );

  setUp(() async {
    final tempDir = Directory.systemTemp.createTempSync('gdar_tv_scrollbar_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return tempDir.path;
        });

    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await CatalogService().initialize(prefs: prefs);

    mockAudioProvider = MockAudioProvider();
    mockAudioPlayer = MockGaplessPlayer();

    when(mockAudioProvider.audioPlayer).thenReturn(mockAudioPlayer);
    when(
      mockAudioProvider.playbackErrorStream,
    ).thenAnswer((_) => const Stream.empty());
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
      mockAudioPlayer.sequenceStateStream,
    ).thenAnswer((_) => const Stream.empty());
    when(mockAudioProvider.currentTrack).thenReturn(null);
    when(
      mockAudioProvider.hudSnapshotStream,
    ).thenAnswer((_) => const Stream.empty());
    when(mockAudioProvider.currentHudSnapshot).thenReturn(HudSnapshot.empty());
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
  });

  tearDown(() async {
    await CatalogService().reset();
  });

  Widget buildWidget(FakeSettingsProvider settings) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ChangeNotifierProvider<ShowListProvider>(
          create: (_) => _MockShowListProvider(),
        ),
        ChangeNotifierProvider<DeviceService>.value(
          value: _MockTvDeviceService(),
        ),
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
      ],
      child: const MaterialApp(
        home: Material(child: PlaybackScreen(isPane: true)),
      ),
    );
  }

  testWidgets(
    'TvScrollbar is visible in TV track list when hideTvScrollbars is false',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildWidget(FakeSettingsProvider()));
      await tester.pump();

      expect(find.byType(TvScrollbar), findsOneWidget);
    },
  );

  testWidgets(
    'TvScrollbar is hidden in TV track list when hideTvScrollbars is true',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildWidget(_HiddenScrollbarFakeSettings()));
      await tester.pump();

      expect(find.byType(TvScrollbar), findsNothing);
    },
  );
}
