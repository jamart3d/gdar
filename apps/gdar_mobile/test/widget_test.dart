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

import '../../../packages/shakedown_core/test/helpers/fake_settings_provider.dart';

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
  List<Show> get filteredShows => const [];

  @override
  int get totalShnids => 0;

  @override
  Future<void> get initializationComplete => Future.value();

  @override
  bool get isSearchVisible => false;

  @override
  bool get hasUsedRandomButton => true;

  @override
  void markRandomButtonUsed() {}

  @override
  bool get isChoosingRandomShow => false;

  @override
  void setIsChoosingRandomShow(bool value) {}

  @override
  void setSearchQuery(String query) {}

  @override
  void setSearchVisible(bool value) {}

  @override
  void toggleSearchVisible() {}

  @override
  String? get loadingShowKey => null;

  @override
  String getShowKey(Show show) => show.date;

  @override
  void setLoadingShow(String? key) {}

  @override
  String? get expandedShowKey => null;

  @override
  void expandShow(String key) {}

  @override
  void collapseCurrentShow() {}

  @override
  void toggleShowExpansion(String key) {}

  @override
  String? get error => null;

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
  bool get isPlaying => false;

  @override
  Show? get currentShow => null;

  @override
  Source? get currentSource => null;

  @override
  ({Show show, Source source})? get pendingRandomShowRequest => null;

  @override
  void clearPendingRandomShowRequest() {}

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
  Future<Show?> playRandomShow({
    bool filterBySearch = false,
    bool delayPlayback = false,
    bool animationOnly = false,
  }) async => null;

  @override
  Future<void> playPendingSelection() async {}

  @override
  void requestPlaybackFocus() {}

  @override
  String? get error => null;

  @override
  void clearError() {}

  @override
  Future<void> playSource(
    Show show,
    Source source, {
    int initialIndex = 0,
    Duration? initialPosition,
  }) async {}

  @override
  void update(
    ShowListProvider showListProvider,
    SettingsProvider settingsProvider,
    AudioCacheService audioCacheService,
  ) {}
}

class _FakeDeviceService extends ChangeNotifier implements DeviceService {
  _FakeDeviceService({this.tv = false});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  final bool tv;

  @override
  bool get isTv => tv;
}

class _FakeTvMobileSettingsProvider extends FakeSettingsProvider {
  _FakeTvMobileSettingsProvider() {
    isTv = true;
  }

  @override
  bool get useOilScreensaver => true;

  @override
  int get oilScreensaverInactivityMinutes => 1;

  @override
  bool get oilEnableAudioReactivity => false;
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

  testWidgets('Forced TV mobile shell shows SS overlay', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'show_splash_screen': false,
      'use_oil_screensaver': true,
      'oil_screensaver_inactivity_minutes': 1,
    });
    final prefs = await SharedPreferences.getInstance();

    tester.view.physicalSize = const Size(2560, 1440);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GdarMobileApp(
        prefs: prefs,
        isTv: true,
        showListProvider: _FakeShowListProvider(),
        audioProvider: _FakeAudioProvider(),
        audioCacheService: _FakeAudioCacheService(),
        settingsProvider: _FakeTvMobileSettingsProvider(),
        deviceService: _FakeDeviceService(tv: true),
        enableDeepLinks: false,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 10));

    expect(find.textContaining('SS:'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
