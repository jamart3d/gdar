import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdar_mobile/main.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';

class _FakeShowListProvider extends ChangeNotifier implements ShowListProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isLoading => false;

  @override
  bool get hasCheckedArchive => true;

  @override
  bool get isArchiveReachable => true;

  @override
  List<Show> get allShows => const [];

  @override
  int get totalShnids => 0;

  @override
  void update(SettingsProvider settingsProvider) {}
}

class _FakeAudioCacheService extends ChangeNotifier
    implements AudioCacheService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  final GaplessPlayer _player = GaplessPlayer();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  GaplessPlayer get audioPlayer => _player;

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Stream<int?> get currentIndexStream => const Stream.empty();

  @override
  Stream<Duration?> get durationStream => const Stream.empty();

  @override
  Stream<Duration> get positionStream => const Stream.empty();

  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();

  @override
  Stream<Duration?> get nextTrackBufferedStream => const Stream.empty();

  @override
  Stream<Duration?> get nextTrackTotalStream => const Stream.empty();

  @override
  Stream<bool> get heartbeatActiveStream => const Stream.empty();

  @override
  Stream<bool> get heartbeatNeededStream => const Stream.empty();

  @override
  Stream<String> get engineStateStringStream => const Stream.empty();

  @override
  Stream<String> get engineContextStateStream => const Stream.empty();

  @override
  Stream<String> get playbackErrorStream => const Stream.empty();

  @override
  Stream<HudSnapshot> get hudSnapshotStream => const Stream.empty();

  @override
  HudSnapshot get currentHudSnapshot => HudSnapshot.empty();

  @override
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      const Stream.empty();

  @override
  Stream<({String message, VoidCallback? retryAction})>
  get bufferAgentNotificationStream => const Stream.empty();

  @override
  Stream<String> get notificationStream => const Stream.empty();

  @override
  Stream<void> get playbackFocusRequestStream => const Stream.empty();

  @override
  void update(
    ShowListProvider showListProvider,
    SettingsProvider settingsProvider,
    AudioCacheService audioCacheService,
  ) {}
}

class _FakeDeviceService extends ChangeNotifier implements DeviceService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isTv => false;
}

void main() {
  testWidgets('App boots into a Material app shell', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Suppress ancestor-lookup-during-dispose errors that occur when
    // the complex Provider tree is torn down via pumpWidget(SizedBox).
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('Looking up a deactivated') ||
          msg.contains('StateIsActiveForAncestorLookup')) {
        return; // Known teardown noise — ignore.
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      GdarMobileApp(
        prefs: prefs,
        isTv: false,
        showListProvider: _FakeShowListProvider(),
        audioProvider: _FakeAudioProvider(),
        audioCacheService: _FakeAudioCacheService(),
        deviceService: _FakeDeviceService(),
        enableDeepLinks: false,
      ),
    );
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
