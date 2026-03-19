import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdar_tv/main.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/ui/screens/screensaver_screen.dart';
import 'package:shakedown_core/ui/screens/onboarding_screen.dart';
import 'package:shakedown_core/ui/screens/splash_screen.dart';

import '../../../packages/shakedown_core/test/helpers/fake_settings_provider.dart';

class MockAudioCacheService extends Mock implements AudioCacheService {
  @override
  Future<void> init() async {}

  @override
  int get cachedTrackCount => 0;

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void dispose() {}
}

class MockGaplessPlayer extends Mock implements GaplessPlayer {
  @override
  PlayerState get playerState => PlayerState(false, ProcessingState.idle);

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Stream<String> get engineStateStringStream => const Stream.empty();

  @override
  Stream<String> get engineContextStateStream => const Stream.empty();

  @override
  Duration get position => Duration.zero;

  @override
  Duration get bufferedPosition => Duration.zero;

  @override
  Duration? get nextTrackBuffered => null;

  @override
  int? get currentIndex => null;

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
  Future<void> dispose() async {}
}

class MockAudioProvider extends Mock implements AudioProvider {
  final MockGaplessPlayer _mockPlayer = MockGaplessPlayer();

  @override
  GaplessPlayer get audioPlayer => _mockPlayer;

  @override
  void update(dynamic showList, dynamic settings, dynamic cache) {}

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void dispose() {}

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
  bool get isPlaying => false;

  @override
  ({Show show, Source source})? get pendingRandomShowRequest => null;

  @override
  void clearPendingRandomShowRequest() {}

  @override
  Show? get currentShow => null;

  @override
  Source? get currentSource => null;

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
}

class MockShowListProvider extends Mock implements ShowListProvider {
  @override
  bool get isLoading => false;

  @override
  bool get hasCheckedArchive => true;

  @override
  bool get isArchiveReachable => true;

  @override
  int get totalShnids => 0;

  @override
  List<Show> get allShows => [];

  @override
  List<Show> get filteredShows => [];

  @override
  void addListener(VoidCallback listener) {}

  @override
  void removeListener(VoidCallback listener) {}

  @override
  void update(dynamic settings) {}

  @override
  Future<void> init(SharedPreferences prefs) async {}

  @override
  Future<void> get initializationComplete => Future.value(null);

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
}

class FakeTvDeviceService extends ChangeNotifier implements DeviceService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isTv => true;
}

class FakeTvSettingsProvider extends FakeSettingsProvider {
  FakeTvSettingsProvider() {
    isTv = true;
  }

  @override
  bool get performanceMode => true;
}

class FakeTvScreensaverSettingsProvider extends FakeTvSettingsProvider {
  FakeTvScreensaverSettingsProvider({
    required this.screensaverEnabled,
    required this.inactivityMinutes,
  });

  final bool screensaverEnabled;
  final int inactivityMinutes;

  @override
  bool get useOilScreensaver => screensaverEnabled;

  @override
  int get oilScreensaverInactivityMinutes => inactivityMinutes;

  @override
  bool get oilEnableAudioReactivity => false;
}

void main() {
  testWidgets(
    'TV startup boots through splash and does not route to onboarding',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'onboarding_completed_version': 0,
        'show_splash_screen': false,
        'performance_mode': true,
      });
      final prefs = await SharedPreferences.getInstance();
      final mockShowListProvider = MockShowListProvider();
      final mockAudioProvider = MockAudioProvider();
      final mockAudioCacheService = MockAudioCacheService();

      await tester.pumpWidget(
        GdarTvApp(
          prefs: prefs,
          isTv: true,
          showListProvider: mockShowListProvider,
          audioProvider: mockAudioProvider,
          audioCacheService: mockAudioCacheService,
          settingsProvider: FakeTvSettingsProvider(),
          deviceService: FakeTvDeviceService(),
          enableDeepLinks: false,
        ),
      );

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(OnboardingScreen), findsNothing);
    },
  );

  testWidgets('TV app launches screensaver after inactivity when enabled', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'show_splash_screen': false,
      'performance_mode': true,
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      GdarTvApp(
        prefs: prefs,
        isTv: true,
        showListProvider: MockShowListProvider(),
        audioProvider: MockAudioProvider(),
        audioCacheService: MockAudioCacheService(),
        settingsProvider: FakeTvScreensaverSettingsProvider(
          screensaverEnabled: true,
          inactivityMinutes: 1,
        ),
        deviceService: FakeTvDeviceService(),
        enableDeepLinks: false,
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 10)); // Clear everything

    await tester.pump(const Duration(minutes: 1)); // Trigger inactivity
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(ScreensaverScreen), findsOneWidget);
  });

  testWidgets(
    'TV app does not launch screensaver after inactivity when disabled',
    (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({
        'show_splash_screen': false,
        'performance_mode': true,
      });
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        GdarTvApp(
          prefs: prefs,
          isTv: true,
          showListProvider: MockShowListProvider(),
          audioProvider: MockAudioProvider(),
          audioCacheService: MockAudioCacheService(),
          settingsProvider: FakeTvScreensaverSettingsProvider(
            screensaverEnabled: false,
            inactivityMinutes: 1,
          ),
          deviceService: FakeTvDeviceService(),
          enableDeepLinks: false,
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(minutes: 1, milliseconds: 50));

      expect(find.byType(ScreensaverScreen), findsNothing);
    },
  );
}
