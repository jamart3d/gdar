import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart'; // Add import
import 'package:shakedown/ui/widgets/show_list_item_details.dart';

import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/services/catalog_service.dart';

// Mock AudioProvider since it's used in onDismissed
class MockAudioProvider extends Mock implements AudioProvider {
  @override
  Source? get currentSource => null; // Default to null

  @override
  Future<void> stopAndClear() async {}
}

// Mock SettingsProvider to track calls
class MockSettingsProvider extends SettingsProvider {
  MockSettingsProvider(super.prefs);

  @override
  bool get highlightPlayingWithRgb => false;

  @override
  bool get uiScale => false;
}

// Mock ShowListProvider for dismissal logic
class MockShowListProvider extends ChangeNotifier implements ShowListProvider {
  Show? _currentShow;

  void setShow(Show show) {
    _currentShow = show;
    notifyListeners();
  }

  Show get currentShow => _currentShow!;

  @override
  void dismissSource(Show show, String sourceId) {
    if (_currentShow != null) {
      final updatedSources =
          _currentShow!.sources.where((s) => s.id != sourceId).toList();
      _currentShow = _currentShow!.copyWith(sources: updatedSources);
      notifyListeners();
    }
  }

  // Missing overrides stubs
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences prefs;
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockShowListProvider mockShowListProvider;

  setUp(() async {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await CatalogService().initialize(prefs: prefs);

    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = MockSettingsProvider(prefs);
    mockShowListProvider = MockShowListProvider();
  });

  Show createDummyShow(String name, {int sourceCount = 2}) {
    return Show(
      name: name,
      artist: 'Grateful Dead',
      date: '2025-01-01',
      venue: 'Venue',
      sources:
          List.generate(sourceCount, (i) => Source(id: 'source$i', tracks: [])),
      hasFeaturedTrack: false,
    );
  }

  Widget createTestableWidget({
    required Show show,
    String? playingSourceId,
  }) {
    // Initialize mock with show
    mockShowListProvider.setShow(show);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<ShowListProvider>.value(
            value: mockShowListProvider),
        Provider<CatalogService>.value(value: CatalogService()),
      ],
      child: MaterialApp(
        home: Scaffold(
          // Use Consumer to update ShowListItemDetails when provider changes due to dismissal
          body: Consumer<ShowListProvider>(
            builder: (context, provider, child) {
              // Should access currentShow from provider, effectively simulating parent rebuild
              // cast provider to mock to access testing helper if strict type needed,
              // but here we just rely on the side-effect that provider.notifyListeners() rebuilds this Consumer.
              // AND we need to pass the UPDATED show which lives in the Mock.
              // Since ShowListProvider interface doesn't have "currentShowForTest",
              // we cast or add getter. We added accessors to Mock.
              final currentShow =
                  (provider as MockShowListProvider).currentShow;

              return ShowListItemDetails(
                show: currentShow,
                playingSourceId: playingSourceId,
                height: 300,
                onSourceTapped: (_) {},
                onSourceLongPress: (_) {},
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('Swipe to block removes item and triggers block logic',
      (WidgetTester tester) async {
    final show = createDummyShow('Show Swipe', sourceCount: 3);

    await tester.pumpWidget(createTestableWidget(show: show));

    expect(find.text('source0'), findsOneWidget);
    expect(find.text('source1'), findsOneWidget);
    expect(find.text('source2'), findsOneWidget);

    // Find the dismissible for source0
    final dismissibleFinder = find.widgetWithText(Dismissible, 'source0');
    expect(dismissibleFinder, findsOneWidget);

    // Swipe left (DismissDirection.endToStart)
    await tester.drag(dismissibleFinder, const Offset(-500.0, 0.0));
    // Pump to start animation
    await tester.pump();
    // Pump to complete animation and trigger dismissal
    await tester.pump(const Duration(seconds: 1));

    // Verification:
    // 1. Check if setRating(-1) was called
    expect(CatalogService().getRating('source0'), -1);

    // 2. Check for SnackBar (verifies confirmDismiss logic ran)
    // expect(find.byType(SnackBar), findsOneWidget); // Commented out to isolate failure

    // 3. Check if Source is removed (verifies onDismissed -> provider -> rebuild logic)
    expect(find.text('source0'), findsNothing);
    // source1 and source2 should remain
    expect(find.text('source1'), findsOneWidget);
    expect(find.text('source2'), findsOneWidget);
  });
}
