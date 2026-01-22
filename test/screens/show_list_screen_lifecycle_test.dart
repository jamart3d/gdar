import 'dart:async';

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

// Manual Mocks for simplicity
class MockAudioProvider extends Mock implements AudioProvider {
  final _randomShowController =
      StreamController<({Show show, Source source})>.broadcast();

  @override
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      _randomShowController.stream;

  void emitRandomShow(({Show show, Source source}) selection) {
    _randomShowController.add(selection);
  }

  @override
  Show? get currentShow => null;
  @override
  Source? get currentSource => null;
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();
  @override
  ({Show show, Source source})? get pendingRandomShowRequest => null;
  @override
  void clearError() {}
  @override
  String? get error => null;
  @override
  Future<void> stopAndClear() async {}

  @override
  void dispose() {
    _randomShowController.close();
  }
}

class MockSettingsProvider extends Mock implements SettingsProvider {
  @override
  bool get uiScale => false;
  @override
  bool get playRandomOnStartup => false;
  @override
  bool get showGlobalAlbumArt => false;
  @override
  bool get useSliverAppBar => false;
}

class MockShowListProvider extends Mock implements ShowListProvider {
  List<Show> _filteredShows = [];

  void setFilteredShows(List<Show> shows) {
    _filteredShows = shows;
  }

  @override
  List<Show> get filteredShows => _filteredShows;
  @override
  List<Show> get allShows => _filteredShows;

  @override
  bool get isLoading => false;
  @override
  String? get error => null;
  @override
  String get searchQuery => '';
  @override
  int get totalShnids => 0;

  @override
  String? get expandedShowKey => null;

  @override
  String getShowKey(Show show) => '${show.name}_${show.date}';

  @override
  bool isShowExpanded(String key) => false;
  @override
  bool isShowLoading(String key) => false;

  @override
  void setPlayingShow(String? showName, String? sourceId) {}

  @override
  Future<void> init(SharedPreferences prefs) async {}
  @override
  Future<void> get initializationComplete => Future.value();
}

void main() {
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockShowListProvider mockShowListProvider;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = MockSettingsProvider();
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
      'Random Show Selection is DEFERRED when app is in BACKGROUND and EXECUTED when RESUMED',
      (WidgetTester tester) async {
    // 1. Setup Data
    final source1 = Source(id: 's1', tracks: []);
    final source2 =
        Source(id: 's2', tracks: []); // 2 sources to enforce expansion
    final show = Show(
        name: 'Test Show',
        date: '2025-01-01',
        venue: 'Venue',
        artist: 'GD',
        sources: [source1, source2],
        hasFeaturedTrack: false);

    mockShowListProvider.setFilteredShows([show]);

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // 2. Simulate Background State
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    // 3. Trigger Random Show Event
    mockAudioProvider.emitRandomShow((show: show, source: source1));
    await tester.pump(); // Process stream event

    // 4. Verify NOT Expanded (Action Deferred)
    // verifyNever(mockShowListProvider.expandShow(any)); // Mockito verification
    // Since Mock implements, standard Verify works if we used spy/mock properly.
    // Using simple mock here: verify(mockShowListProvider.expandShow(any)).called(0)
    verifyNever(mockShowListProvider.expandShow('Test Show_2025-01-01'));

    // 5. Simulate Resume
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    // 6. Verify Expanded (Action Executed)
    verify(mockShowListProvider.expandShow('Test Show_2025-01-01')).called(1);
  });
}
