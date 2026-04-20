import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/ui/screens/settings_screen.dart';
import 'package:shakedown_core/ui/screens/rated_shows_screen.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shakedown_core/providers/update_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/settings/collection_statistics.dart';
import 'package:shakedown_core/ui/widgets/settings/data_section.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_tooltip.dart';
import '../../helpers/test_helpers.dart';

// Mock Providers (Simple versions for testing)
class MockAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  int get cachedTrackCount => 0;
  @override
  Source? get currentSource => null;
  @override
  Show? get currentShow => null;
  @override
  bool get isPlaying => false;

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
  Null get updateInfo => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    // Basic setup similar to show_list_card_test.dart
    await CatalogService().reset();
    final tempDir = await Directory.systemTemp.createTemp(
      'hive_test_settings_',
    );
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

  Widget createTestableWidget(
    SettingsProvider settingsProvider, {
    ThemeProvider? themeProvider,
    bool showFruitTabBar = true,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => settingsProvider),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => themeProvider ?? ThemeProvider(),
        ),
        ChangeNotifierProvider<AudioProvider>(
          create: (_) => MockAudioProvider(),
        ),
        ChangeNotifierProvider<ShowListProvider>(
          create: (_) => MockShowListProvider(),
        ),
        ChangeNotifierProvider<UpdateProvider>(
          create: (_) => MockUpdateProvider(),
        ),
        ChangeNotifierProvider<DeviceService>(
          create: (_) => MockDeviceService(),
        ),
      ],
      child: MaterialApp(
        home: SettingsScreen(showFruitTabBar: showFruitTabBar),
      ),
    );
  }

  testWidgets(
    'Fruit settings header car button toggles scoped car mode state',
    (WidgetTester tester) async {
      final settingsProvider = SettingsProvider(prefs);
      await prefs.setInt('theme_style_preference', 1);
      final themeProvider = ThemeProvider();
      themeProvider.testOnlyOverrideFruitAllowed = true;
      await themeProvider.initializationComplete;

      expect(settingsProvider.carMode, isFalse);
      expect(settingsProvider.preventSleep, isFalse);
      expect(settingsProvider.fruitFloatingSpheres, isFalse);
      expect(settingsProvider.fruitEnableLiquidGlass, isFalse);

      await tester.pumpWidget(
        createTestableWidget(
          settingsProvider,
          themeProvider: themeProvider,
          showFruitTabBar: false,
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      final enableFinder = find.bySemanticsLabel('Enable Car Mode');
      expect(enableFinder, findsOneWidget);
      expect(find.byType(FruitTooltip), findsNothing);

      await tester.tap(enableFinder);
      await tester.pump();

      expect(settingsProvider.carMode, isTrue);
      expect(settingsProvider.preventSleep, isFalse);
      expect(settingsProvider.fruitFloatingSpheres, isTrue);
      expect(settingsProvider.fruitEnableLiquidGlass, isTrue);

      final disableFinder = find.bySemanticsLabel('Disable Car Mode');
      expect(disableFinder, findsOneWidget);

      await tester.tap(disableFinder);
      await tester.pump();

      expect(settingsProvider.carMode, isFalse);
      expect(settingsProvider.fruitFloatingSpheres, isTrue);
      expect(settingsProvider.fruitEnableLiquidGlass, isTrue);
    },
  );

  testWidgets(
    'SettingsScreen uses 1.0 TextScaler even when car mode is active',
    (WidgetTester tester) async {
      final settingsProvider = SettingsProvider(prefs);
      if (!settingsProvider.carMode) settingsProvider.toggleCarMode();

      expect(settingsProvider.carMode, isTrue);
      expect(settingsProvider.settingsScreenUiScale, isTrue);

      await tester.pumpWidget(createTestableWidget(settingsProvider));

      final MediaQuery mediaQuery = tester.widget(find.byType(MediaQuery).last);
      expect(mediaQuery.data.textScaler, const TextScaler.linear(1.0));
    },
  );

  testWidgets('Random switch toggles text in other Random settings', (
    WidgetTester tester,
  ) async {
    final settingsProvider = SettingsProvider(prefs);

    // Pump widget
    await tester.pumpWidget(createTestableWidget(settingsProvider));
    await tester.pump(
      const Duration(seconds: 2),
    ); // Wait for animations (pumpAndSettle might timeout due to infinite animations)

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
    final switchFinder = find.byWidgetPredicate(
      (widget) =>
          widget is SwitchListTile &&
          widget.title is FittedBox &&
          (widget.title as FittedBox).child is Text &&
          ((widget.title as FittedBox).child as Text).data == 'Random' &&
          widget.value == true,
    );
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
    await tester.scrollUntilVisible(
      randomFinder,
      100,
      scrollable: find.byType(Scrollable),
    );
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

  testWidgets('Verifies CollectionStatistics and DataSection are present', (
    WidgetTester tester,
  ) async {
    final settingsProvider = SettingsProvider(prefs);

    await tester.pumpWidget(createTestableWidget(settingsProvider));
    await tester.pump(const Duration(seconds: 1));

    // Scroll until CollectionStatistics is visible
    final statsFinder = find.byType(CollectionStatistics);
    await tester.scrollUntilVisible(
      statsFinder,
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Collection Statistics is present
    expect(find.byType(CollectionStatistics), findsOneWidget);
    expect(find.text('Collection Statistics'), findsOneWidget);

    // Verify DataSection (Manage Rated Shows Library) is present
    final dataFinder = find.byType(DataSection);
    await tester.scrollUntilVisible(
      dataFinder,
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(dataFinder, findsOneWidget);

    // Tap to navigate
    await tester.tap(dataFinder);
    await tester.pumpAndSettle(); // Navigate to new screen

    // Verify we are on the RatedShowsScreen by checking for its body
    expect(find.byType(RatedShowsBody), findsOneWidget);
    expect(find.text('Rated Shows Library'), findsOneWidget);
  });
}
