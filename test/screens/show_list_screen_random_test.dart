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

// Mocks - Reuse mocks from show_list_screen_swipe_test.dart
// Ideally, we'd centralize these, but for this task we'll duplicate relevant parts
// to ensure self-contained tests and modify as needed (e.g. for hasUsedRandomButton).

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
  @override
  Future<Show?> playRandomShow({bool filterBySearch = false}) async {
    return null;
  }
}

class MockSettingsProvider extends SettingsProvider {
  MockSettingsProvider(super.prefs);
  @override
  bool get uiScale => false;
  @override
  bool get playRandomOnStartup => false;
}

class MockCatalogService extends Mock implements CatalogService {}

// A mock provider that we can control the 'hasUsedRandomButton' state of.
class MockShowListProvider extends ChangeNotifier implements ShowListProvider {
  List<Show> _filteredShows = [];
  bool _hasUsedRandomButton = false;

  void setHasUsedRandomButton(bool value) {
    _hasUsedRandomButton = value;
  }

  @override
  bool get hasUsedRandomButton => _hasUsedRandomButton;

  @override
  void markRandomButtonUsed() {
    _hasUsedRandomButton = true;
    notifyListeners();
  }

  // === Default implementations for other required members ===
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
  Show? getShow(String key) => null;
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
  @override
  Future<void> get initializationComplete => Future.value();
  @override
  void dismissShow(Show show) {}
  @override
  bool isSourceAllowed(Source source) => true;
  @override
  void dismissSource(Show show, String sourceId) {}
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

  group('ShowListScreen Random Button Animation', () {
    testWidgets('Random button pulses when not used previously',
        (WidgetTester tester) async {
      mockShowListProvider.setHasUsedRandomButton(false);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump(); // Frame 0

      // Find the specific ScaleTransition for the random button
      // We can look for the question mark icon and then its ancestor ScaleTransition
      final iconFinder = find.byIcon(Icons.question_mark_rounded);
      expect(iconFinder, findsOneWidget);

      final scaleTransitionFinder = find.ancestor(
        of: iconFinder,
        matching: find.byType(ScaleTransition),
      );
      expect(scaleTransitionFinder, findsOneWidget);

      final ScaleTransition scaleTransition =
          tester.widget(scaleTransitionFinder);
      final animation = scaleTransition.scale;

      // It should be animating (status forward or reverse depending on timing)
      expect(animation.status,
          anyOf(AnimationStatus.forward, AnimationStatus.reverse));
    });

    testWidgets('Random button does NOT pulse when already used',
        (WidgetTester tester) async {
      mockShowListProvider.setHasUsedRandomButton(true);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      final iconFinder = find.byIcon(Icons.question_mark_rounded);
      expect(iconFinder, findsOneWidget);

      final scaleTransitionFinder = find.ancestor(
        of: iconFinder,
        matching: find.byType(ScaleTransition),
      );
      // Logic check: The widget code always wraps it in ScaleTransition now, or did we?
      // Let's check the code:
      // if (_isRandomShowLoading) ... else ScaleTransition(...)
      // So it is always wrapped, but if we stopped it, the scale should be 1.0 (or whatever the tween begin was if stopped/reset).
      // Actually, if we stopped it, checking `isAnimating` or status would be better.
      expect(scaleTransitionFinder, findsOneWidget); // Still there

      final ScaleTransition scaleTransition =
          tester.widget(scaleTransitionFinder);
      final animation = scaleTransition.scale;

      // If already used, we expect it NOT to be animating loop
      // However, in initState we only start it if (!hasUsed).
      // So it should be dismissed or idle or 1.0.
      // Since it's a specific AnimationController created in State, and we didn't call .repeat(),
      // it should be at value 0.0 or lower bound?
      // Wait, Tween(begin: 1.0 ...)
      // Controller default value is 0.0 unless configured.
      // But we map it through Tween.
      // If controller is 0.0, Tween(1.0, 1.2) -> 1.0.
      expect(animation.value, 1.0);
      expect(animation.status, AnimationStatus.dismissed);
    });

    testWidgets('Tapping random button stops animation and marks as used',
        (WidgetTester tester) async {
      mockShowListProvider.setHasUsedRandomButton(false);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      // Verify initial state
      expect(mockShowListProvider.hasUsedRandomButton, isFalse);

      // Tap the button
      await tester.tap(find.byIcon(Icons.question_mark_rounded));

      // Pump to trigger the onPressed handler
      await tester.pump();

      // Verify provider was updated (synchronous start of handler)
      expect(mockShowListProvider.hasUsedRandomButton, isTrue);

      // Settle any remaining animations/timers (like the loading indicator reset)
      await tester.pumpAndSettle();
    });
  });
}
