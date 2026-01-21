import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
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

  final Map<String, int> _ratings = {};

  @override
  Future<void> setRating(String key, int rating) async {
    _ratings[key] = rating;
    notifyListeners();
  }

  @override
  int getRating(String key) => _ratings[key] ?? 0;

  @override
  bool get uiScale => false;
  @override
  bool get playRandomOnStartup => false;
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
  String? expandedShowKey; // Add this getter

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
  Future<void> fetchShows({bool forceRefresh = false}) async {}

  @override
  Future<void> init() async {}

  @override
  bool isShowExpanded(String key) => false;

  @override
  String get searchQuery => '';

  @override
  int get totalShnids => 0;

  // Alias to filteredShows for mock purposes so we have data
  @override
  List<Show> get allShows => _filteredShows;

  @override
  Show? getShow(String key) {
    if (_filteredShows.isEmpty) return null;
    try {
      return _filteredShows.firstWhere((s) => s.key == key);
    } catch (_) {
      return _filteredShows.first; // Fallback for mock
    }
  }

  @override
  bool isShowLoading(String key) => false; // Restored

  @override
  void setArchiveStatus(bool isReachable) {} // Restored

  @override
  void setPlayingShow(String? showName, String? sourceId) {} // Restored

  @override
  void update(SettingsProvider settings) {} // Restored

  @override
  bool get isArchiveReachable => false; // Restored

  @override
  bool get hasCheckedArchive => false; // Restored

  @override
  Set<String> get availableCategories => {};

  // Retry without override annotation to test lint theory
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
  void dismissSource(Show show, String sourceId) {}
}

void main() {
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockShowListProvider mockShowListProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = MockSettingsProvider(prefs);
    mockShowListProvider = MockShowListProvider();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<ShowListProvider>.value(
            value: mockShowListProvider),
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

    mockShowListProvider.setShows([show]); // Use modifiable list

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(seconds: 1)); // Allow animations to settle

    expect(find.text('Venue'), findsOneWidget);

    // Find Dismissible
    final dismissibleFinder = find.byType(Dismissible);
    expect(dismissibleFinder, findsOneWidget);

    // Verify swipe action starts
    await tester.drag(dismissibleFinder, const Offset(-500.0, 0.0));
    // Pump frames to allow animation and processing
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Animation completion

    // Verification:
    // 1. Check if setRating(-1) was called
    expect(mockSettingsProvider.getRating('source1'), -1);

    // 2. The item should be GONE now.
    // confirmDismiss returned true, onDismissed called dismissShow, mock updated list, UI rebuilt.
    expect(find.text('Venue'), findsNothing);
  });
}
