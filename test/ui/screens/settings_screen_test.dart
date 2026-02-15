import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shakedown/models/rating.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shakedown/providers/update_provider.dart';
import 'package:shakedown/services/device_service.dart';
import '../../helpers/test_helpers.dart';

// Mock Providers (Simple versions for testing)
class MockAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  int get cachedTrackCount => 0;
  @override
  Source? get currentSource => null;
  @override
  Show? get currentShow => null;

  // Implement other necessary overrides or leave blank if not used by SettingsScreen
  // Using dynamic to bypass strict typing for methods we don't implement fully mock
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockShowListProvider extends ChangeNotifier implements ShowListProvider {
  List<Show> get shows => [];
  @override
  List<Show> get filteredShows => [];
  @override
  List<Show> get allShows => [];
  @override
  Set<String> get availableCategories => {};

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUpdateProvider extends ChangeNotifier implements UpdateProvider {
  @override
  bool get isSimulated => false;
  @override
  get updateInfo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    // Basic setup similar to show_list_card_test.dart
    await CatalogService().reset();
    final tempDir =
        await Directory.systemTemp.createTemp('hive_test_settings_');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return tempDir.path;
    });

    SharedPreferences.setMockInitialValues({
      'non_random': false, // Start with false
    });
    prefs = await SharedPreferences.getInstance();

    await CatalogService().initialize(prefs: prefs);
    // Hive boxes are needed for CollectionStatistics
    await Hive.box<Rating>('ratings').clear();
    await Hive.box<bool>('user_history').clear();
    await Hive.box<int>('play_counts').clear();
  });

  tearDown(() async {
    await CatalogService().reset();
  });

  Widget createTestableWidget(SettingsProvider settingsProvider) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AudioProvider>(
            create: (_) => MockAudioProvider()),
        ChangeNotifierProvider<ShowListProvider>(
            create: (_) => MockShowListProvider()),
        ChangeNotifierProvider<UpdateProvider>(
            create: (_) => MockUpdateProvider()),
        ChangeNotifierProvider<DeviceService>(
            create: (_) => MockDeviceService()),
      ],
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('Random switch toggles text in other Random settings',
      (WidgetTester tester) async {
    final settingsProvider = SettingsProvider(prefs);

    // Pump widget
    await tester.pumpWidget(createTestableWidget(settingsProvider));
    await tester.pump(const Duration(
        seconds:
            2)); // Wait for animations (pumpAndSettle might timeout due to infinite animations)

    // 1. Open "Playback" section if not open
    final playbackTitle = find.text('Playback');
    expect(playbackTitle, findsOneWidget);

    if (find.text('Random').evaluate().isEmpty) {
      await tester.tap(playbackTitle);
      await tester.pump(const Duration(milliseconds: 500));
    }

    // 2. Verify initial state (Random is ON, because non_random is false)
    expect(find.text('Random'), findsOneWidget);
    // Switch should be ON (true)
    final switchFinder = find.byWidgetPredicate((widget) =>
        widget is SwitchListTile &&
        widget.title is FittedBox &&
        (widget.title as FittedBox).child is Text &&
        ((widget.title as FittedBox).child as Text).data == 'Random' &&
        widget.value == true);
    expect(switchFinder, findsOneWidget);

    // Verify dynamic text says "Play Random Show..."
    expect(find.text('Play Random Show on Completion'), findsOneWidget);
    expect(find.text('Play Random Show on Startup'), findsOneWidget);
    expect(find.text('Play Next Show on Completion'), findsNothing);
    expect(find.text('Play Next Show on Startup'), findsNothing);

    // 3. Toggle "Random" OFF (Enabling Non-Random mode)
    // Ensure it's visible by scrolling
    await tester.drag(find.byType(Scrollable), const Offset(0, -600));
    await tester.pump(const Duration(milliseconds: 500));

    final randomFinder = find.text('Random');
    await tester.scrollUntilVisible(randomFinder, 100,
        scrollable: find.byType(Scrollable));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(randomFinder);
    await tester.pump(const Duration(milliseconds: 500));

    // 4. Verify new state (Random is OFF -> Non-Random mode is ON)
    expect(settingsProvider.nonRandom, true);

    // Label remains "Random" (but visually disabled)
    expect(find.text('Random'), findsOneWidget);
    expect(find.text('Non-Random'), findsNothing);

    // Verify dynamic text says "Play Next Show..."
    expect(find.text('Play Next Show on Completion'), findsOneWidget);
    expect(find.text('Play Next Show on Startup'), findsOneWidget);
    expect(find.text('Play Random Show on Completion'), findsNothing);
    expect(find.text('Play Random Show on Startup'), findsNothing);
  });
}
