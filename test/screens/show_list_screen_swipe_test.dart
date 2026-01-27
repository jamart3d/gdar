import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';

// Mocks
class MockAudioProvider extends Mock implements AudioProvider {
  @override
  Show? get currentShow => null;
  @override
  Source? get currentSource => null;
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      const Stream.empty();
  @override
  ({Show show, Source source})? get pendingRandomShowRequest => null;
  @override
  void clearError() {}
  @override
  String? get error => null;
  @override
  Future<void> stopAndClear() async {}
}

class MockSettingsProvider extends SettingsProvider {
  MockSettingsProvider(super.prefs);
  @override
  bool get uiScale => false;
  @override
  bool get playRandomOnStartup => false;

  // Note: setRating/getRating removed as they are no longer in SettingsProvider
}

class MockCatalogService extends Mock implements CatalogService {
  final Map<String, int> _ratings = {};

  @override
  int getRating(String? sourceId) => _ratings[sourceId] ?? 0;

  @override
  Future<void> setRating(String? sourceId, int rating) async {
    if (sourceId != null) {
      _ratings[sourceId] = rating;
    }
  }
}

class MockShowListProvider extends ChangeNotifier implements ShowListProvider {
  List<Show> _filteredShows = [];

  @override
  List<Show> get filteredShows => _filteredShows;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  String? loadingShowKey;

  @override
  String? expandedShowKey;

  void setShows(List<Show> shows) {
    _filteredShows = shows;
    notifyListeners();
  }

  @override
  String getShowKey(Show show) => '${show.name}_${show.date}';

  @override
  void setLoadingShow(String? key) {}

  @override
  void collapseCurrentShow() {}

  @override
  void expandShow(String key) {}

  @override
  void toggleShowExpansion(String key) {}

  @override
  void setSearchQuery(String query) {}

  @override
  Future<void> checkArchiveStatus() async {}

  @override
  Future<void> fetchShows(SharedPreferences prefs,
      {bool forceRefresh = false}) async {}

  @override
  Future<void> init(SharedPreferences prefs) async {}

  @override
  bool isShowExpanded(String key) => false;

  @override
  String get searchQuery => '';

  @override
  int get totalShnids => 0;

  @override
  List<Show> get allShows => _filteredShows;

  @override
  Show? getShow(String key) {
    if (_filteredShows.isEmpty) return null;
    try {
      return _filteredShows.firstWhere((s) => s.key == key);
    } catch (_) {
      return _filteredShows.first;
    }
  }

  @override
  bool isShowLoading(String key) => false;

  @override
  void setArchiveStatus(bool isReachable) {}

  @override
  void setPlayingShow(String? showName, String? sourceId) {}

  @override
  void update(SettingsProvider settings) {}

  @override
  bool get isArchiveReachable => false;

  @override
  bool get hasCheckedArchive => false;

  @override
  Set<String> get availableCategories => {};

  void retry() {}

  @override
  Future<void> get initializationComplete => Future.value();

  @override
  void dismissShow(Show show) {
    if (_filteredShows.contains(show)) {
      _filteredShows.remove(show);
      notifyListeners();
    }
  }

  @override
  bool isSourceAllowed(Source source) => true;

  @override
  void dismissSource(Show show, String sourceId) {
    if (_filteredShows.contains(show)) {
      // Logic to simulate dismissal (not robust but sufficient for test if needed)
      // Actually the test sets up logic in setShows.
    }
  }

  bool _isSearchVisible = false;

  @override
  bool get isSearchVisible => _isSearchVisible;

  @override
  void setSearchVisible(bool visible) {
    _isSearchVisible = visible;
    notifyListeners();
  }

  @override
  void toggleSearchVisible() {
    _isSearchVisible = !_isSearchVisible;
    notifyListeners();
  }

  @override
  bool get hasUsedRandomButton => false;

  @override
  void markRandomButtonUsed() {}
}

void main() {
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockShowListProvider mockShowListProvider;
  late MockCatalogService mockCatalogService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = MockSettingsProvider(prefs);
    mockShowListProvider = MockShowListProvider();
    mockCatalogService = MockCatalogService();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<ShowListProvider>.value(
            value: mockShowListProvider),
        Provider<CatalogService>.value(value: mockCatalogService),
      ],
      child: const MaterialApp(
        home: ShowListScreen(),
      ),
    );
  }

  testWidgets(
      'Dismissing a single-source show removes it from the list without crash',
      (WidgetTester tester) async {
    // Setup a single source show
    final source = Source(id: 'source1', tracks: []);
    final show = Show(
        name: 'Test Show',
        date: '2025-01-01',
        venue: 'Venue',
        artist: 'Grateful Dead',
        sources: [source],
        hasFeaturedTrack: false);

    mockShowListProvider.setShows([show]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Venue'), findsOneWidget);

    final dismissibleFinder = find.byType(Dismissible);
    expect(dismissibleFinder, findsOneWidget);

    await tester.drag(dismissibleFinder, const Offset(-500.0, 0.0));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Animation completion

    // Verification:
    // 1. Check if setRating(-1) was called on CatalogService
    expect(mockCatalogService.getRating('source1'), -1);

    // 2. The item should be GONE now.
    expect(find.text('Venue'), findsNothing);
  });
}
