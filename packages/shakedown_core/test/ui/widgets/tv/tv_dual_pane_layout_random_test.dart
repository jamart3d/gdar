import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import '../../../helpers/fake_settings_provider.dart';
import '../../../helpers/test_helpers.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_dual_pane_layout.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_header.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  final _randomShowRequestController =
      StreamController<({Show show, Source source})>.broadcast();

  int playRandomShowCallCount = 0;
  int playPendingSelectionCallCount = 0;
  int playSourceCallCount = 0;

  bool _isPlaying = false;
  ({Show show, Source source})? _pendingRequest;
  Show? _currentShow = Show(
    date: '1977-05-08',
    venue: 'Cornell',
    name: 'Cornell 77',
    artist: 'Grateful Dead',
    sources: [
      Source(
        id: '123',
        tracks: [
          Track(
            trackNumber: 1,
            title: 'Track 1',
            duration: 180,
            url: 'http://example.com/track.mp3',
            setName: 'Set 1',
          ),
        ],
      ),
    ],
  );

  @override
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      _randomShowRequestController.stream;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Show? get currentShow => _currentShow;

  @override
  Source? get currentSource => _currentShow?.sources.first;

  @override
  Track? get currentTrack => _currentShow?.sources.first.tracks.first;

  @override
  String? get error => null;

  @override
  ({Show show, Source source})? get pendingRandomShowRequest => _pendingRequest;

  @override
  Future<Show?> playRandomShow({
    bool filterBySearch = true,
    bool animationOnly = false,
    bool delayPlayback = false,
  }) async {
    playRandomShowCallCount++;
    if (delayPlayback) {
      _pendingRequest = (show: currentShow!, source: currentSource!);
      _randomShowRequestController.add((
        show: currentShow!,
        source: currentSource!,
      ));
    }
    notifyListeners();
    return currentShow;
  }

  @override
  Future<void> playPendingSelection() async {
    playPendingSelectionCallCount++;
    if (_pendingRequest != null) {
      await playSource(_pendingRequest!.show, _pendingRequest!.source);
      _pendingRequest = null;
    }
  }

  @override
  Future<void> playSource(
    Show show,
    Source source, {
    int initialIndex = 0,
    Duration? initialPosition,
  }) async {
    playSourceCallCount++;
    _isPlaying = true;
    _currentShow = show;
    notifyListeners();
  }

  @override
  Stream<String> get playbackErrorStream => const Stream.empty();
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<Duration> get bufferedPositionStream => const Stream.empty();
  @override
  Stream<int?> get currentIndexStream => const Stream.empty();
  @override
  Stream<Duration?> get durationStream => const Stream.empty();
  @override
  Stream<void> get playbackFocusRequestStream => const Stream.empty();
  @override
  Stream<HudSnapshot> get hudSnapshotStream => const Stream.empty();
  @override
  HudSnapshot get currentHudSnapshot => HudSnapshot.empty();
  @override
  Stream<String> get notificationStream => const Stream.empty();
  @override
  Stream<({String message, VoidCallback? retryAction})>
  get bufferAgentNotificationStream => const Stream.empty();
  @override
  late final GaplessPlayer audioPlayer = GaplessPlayer();

  @override
  void update(
    ShowListProvider slp,
    SettingsProvider sp,
    AudioCacheService acs,
  ) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeShowListProvider extends ChangeNotifier implements ShowListProvider {
  bool _isChoosingRandomShow = false;
  late final List<Show> _shows;

  FakeShowListProvider() {
    _shows = [
      Show(
        date: '1977-05-08',
        venue: 'Cornell',
        name: 'Cornell 77',
        artist: 'Grateful Dead',
        sources: [
          Source(
            id: '123',
            tracks: [
              Track(
                trackNumber: 1,
                title: 'Track 1',
                duration: 180,
                url: 'http://example.com/track.mp3',
                setName: 'Set 1',
              ),
            ],
          ),
        ],
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  bool get isChoosingRandomShow => _isChoosingRandomShow;

  @override
  String? get expandedShowKey => null;

  @override
  void setIsChoosingRandomShow(bool value) {
    _isChoosingRandomShow = value;
  }

  @override
  List<Show> get allShows => _shows;

  @override
  List<Show> get filteredShows => _shows;

  @override
  String getShowKey(Show show) => show.key;

  @override
  Show? getShow(String key) {
    try {
      return _shows.firstWhere((s) => s.key == key);
    } catch (e) {
      return null;
    }
  }

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  bool get isSearchVisible => false;

  @override
  bool get hasUsedRandomButton => false;

  @override
  bool get hasCheckedArchive => true;

  @override
  bool get isArchiveReachable => true;

  @override
  bool isShowExpanded(String key) => false;

  @override
  bool isShowLoading(String key) => false;

  @override
  void expandShow(String key) {}

  @override
  void collapseCurrentShow() {}

  @override
  void toggleShowExpansion(String key) {}

  @override
  void dismissShow(Show show) {}

  @override
  void dismissSource(Show show, String sourceId) {}

  @override
  void setLoadingShow(String? key) {}

  @override
  String? get loadingShowKey => null;

  @override
  void setSearchVisible(bool visible) {}

  @override
  void toggleSearchVisible() {}

  @override
  void setSearchQuery(String query) {}

  @override
  String get searchQuery => '';

  @override
  void markRandomButtonUsed() {}

  @override
  Future<void> fetchShows(SharedPreferences prefs) async {}

  @override
  int get totalShnids => 0;

  @override
  Set<String> get availableCategories => {};

  @override
  void update(SettingsProvider settings) {}

  @override
  void setPlayingShow(String? showName, String? sourceId) {}

  @override
  Future<void> get initializationComplete => Future.value();
}

class FakeCatalogService extends CatalogService {
  FakeCatalogService() : super.internal();

  @override
  ValueListenable<Box<int>> get playCountsListenable =>
      ValueNotifier(_FakeBox<int>());

  @override
  ValueListenable<Box<bool>> get historyListenable =>
      ValueNotifier(_FakeBox<bool>());

  @override
  ValueListenable<Box<Rating>> get ratingsListenable =>
      ValueNotifier(_FakeBox<Rating>());

  @override
  int getRating(String sourceId) => 0;

  @override
  bool isPlayed(String sourceId) => false;

  @override
  int getPlayCount(String sourceId) => 0;

  @override
  bool get isInitialized => true;
}

class _FakeBox<T> extends ChangeNotifier implements Box<T> {
  @override
  T? get(key, {T? defaultValue}) => defaultValue;

  @override
  bool get isOpen => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAudioCacheService extends ChangeNotifier
    implements AudioCacheService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'TvDualPaneLayout avoids duplicate playback when random selection starts early',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final catalogService = FakeCatalogService();
      CatalogService.setMock(catalogService);
      final audioProvider = FakeAudioProvider();
      final settingsProvider = FakeSettingsProvider()..isTv = true;
      final showListProvider = FakeShowListProvider();
      final deviceService = MockDeviceService()..isTv = true;
      final themeProvider = ThemeProvider(isTv: true);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<CatalogService>.value(value: catalogService),
            ChangeNotifierProvider<AudioCacheService>.value(
              value: FakeAudioCacheService(),
            ),
            ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
            ChangeNotifierProvider<ShowListProvider>.value(
              value: showListProvider,
            ),
            ChangeNotifierProvider<DeviceService>.value(value: deviceService),
            ChangeNotifierProvider<ThemeProvider>.value(value: themeProvider),
          ],
          child: const MaterialApp(home: TvDualPaneLayout()),
        ),
      );

      expect(audioProvider.playRandomShowCallCount, 0);
      expect(audioProvider.playSourceCallCount, 0);

      final header = tester.widget<TvHeader>(find.byType(TvHeader));
      header.onRandomPlay();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(audioProvider.playRandomShowCallCount, 1);

      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(milliseconds: 2000));

      await audioProvider.playSource(
        audioProvider.currentShow!,
        audioProvider.currentSource!,
      );
      expect(audioProvider.playSourceCallCount, 1);

      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pump(const Duration(milliseconds: 500));

      expect(audioProvider.playSourceCallCount, 1);
    },
  );
}
