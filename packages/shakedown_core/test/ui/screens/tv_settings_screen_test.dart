import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/ui/screens/tv_settings_screen.dart';
import 'package:shakedown_core/ui/screens/about_screen.dart';
import 'package:shakedown_core/ui/widgets/settings/tv_screensaver_preview_panel.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:shakedown_core/providers/update_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import '../../helpers/test_helpers.dart';

// Mock Providers (Simple versions for testing)
class FakeGaplessPlayer extends Fake implements GaplessPlayer {
  @override
  int? get androidAudioSessionId => 123;
  @override
  bool get playing => false;
}

class MockAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  int get cachedTrackCount => 0;
  @override
  Source? get currentSource => null;
  @override
  Show? get currentShow => null;
  @override
  bool get isPlaying => false;

  @override
  GaplessPlayer get audioPlayer => FakeGaplessPlayer();

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
    await CatalogService().reset();
    final tempDir = await Directory.systemTemp.createTemp(
      'hive_test_tv_settings_',
    );
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return tempDir.path;
        });

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    await CatalogService().initialize(prefs: prefs);
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
          create: (_) => MockAudioProvider(),
        ),
        ChangeNotifierProvider<ShowListProvider>(
          create: (_) => MockShowListProvider(),
        ),
        ChangeNotifierProvider<UpdateProvider>(
          create: (_) => MockUpdateProvider(),
        ),
        ChangeNotifierProvider<DeviceService>(
          create: (_) => MockDeviceService()..isTv = true,
        ),
      ],
      child: const MaterialApp(home: TvSettingsScreen()),
    );
  }

  testWidgets('About section is present and accessible in TV Settings', (
    WidgetTester tester,
  ) async {
    // Set screen size to TV dimensions to avoid overflows
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final settingsProvider = SettingsProvider(prefs);

    await tester.pumpWidget(createTestableWidget(settingsProvider));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify "About" category is present
    final aboutCategoryFinder = find.text('About');

    // Scroll until visible in the ListView (which is the first Scrollable)
    final scrollable = find.byType(Scrollable).first;
    expect(scrollable, findsOneWidget);

    await tester.scrollUntilVisible(
      aboutCategoryFinder,
      50,
      scrollable: scrollable,
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(aboutCategoryFinder, findsOneWidget);

    // Tap "About" category to select it
    await tester.tap(aboutCategoryFinder);

    // Use pump with duration because AboutSection has an infinite pulsing animation
    // that causes pumpAndSettle to timeout.
    await tester.pump(
      const Duration(seconds: 1),
    ); // Wait enough for transition/build

    // Verify AboutBody is displayed (TV uses full body instead of just a section card)
    expect(find.byType(AboutBody), findsOneWidget);
    // Use a text finder that is definitely in AboutBody
    expect(find.text('Shakedown'), findsOneWidget);
  });

  testWidgets(
    'Haptic Feedback and Swipe to Block are hidden in TV Interface Settings',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final settingsProvider = SettingsProvider(prefs);

      await tester.pumpWidget(createTestableWidget(settingsProvider));
      await tester.pump(const Duration(milliseconds: 500));

      // Select Interface category
      final interfaceCategoryFinder = find.text('Interface');
      await tester.tap(interfaceCategoryFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Haptic Feedback is NOT present
      expect(find.text('Haptic Feedback'), findsNothing);
      expect(find.text('Vibrate on interactions (PWA/Mobile)'), findsNothing);

      // Verify Swipe to Block is NOT present (using text segments to be safe)
      expect(find.text('Enable Swipe to Block'), findsNothing);
      expect(find.textContaining('swipe list items to block'), findsNothing);
    },
  );

  testWidgets(
    'Screensaver Preview Panel is visible only when Screensaver category is selected',
    (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final settingsProvider = SettingsProvider(prefs);

      await tester.pumpWidget(createTestableWidget(settingsProvider));
      await tester.pump(const Duration(milliseconds: 500));

      // Initial state (Library selected) -> Preview Panel should NOT be present
      expect(find.byType(TvScreensaverPreviewPanel), findsNothing);

      // Select Screensaver category
      final screensaverCategoryFinder = find.text('Screensaver');
      final scrollable = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(
        screensaverCategoryFinder,
        50,
        scrollable: scrollable,
      );
      await tester.tap(screensaverCategoryFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Preview Panel is now visible
      expect(find.byType(TvScreensaverPreviewPanel), findsOneWidget);

      // Switch back to Interface category (index 1)
      final interfaceCategoryFinder = find.text('Interface');
      await tester.tap(interfaceCategoryFinder);
      await tester.pump(const Duration(milliseconds: 500));

      // Verify Preview Panel is removed (and disposed)
      expect(find.byType(TvScreensaverPreviewPanel), findsNothing);
    },
  );
}
