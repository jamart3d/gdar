import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/screens/tv_settings_screen.dart';
import 'package:shakedown/ui/screens/about_screen.dart';
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
    await CatalogService().reset();
    final tempDir =
        await Directory.systemTemp.createTemp('hive_test_tv_settings_');
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
            create: (_) => MockAudioProvider()),
        ChangeNotifierProvider<ShowListProvider>(
            create: (_) => MockShowListProvider()),
        ChangeNotifierProvider<UpdateProvider>(
            create: (_) => MockUpdateProvider()),
        ChangeNotifierProvider<DeviceService>(
            create: (_) => MockDeviceService()),
      ],
      child: const MaterialApp(
        home: TvSettingsScreen(),
      ),
    );
  }

  testWidgets('About section is present and accessible in TV Settings',
      (WidgetTester tester) async {
    // Set screen size to TV dimensions to avoid overflows
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final settingsProvider = SettingsProvider(prefs);

    await tester.pumpWidget(createTestableWidget(settingsProvider));
    await tester.pumpAndSettle();

    // Verify "About" category is present
    final aboutCategoryFinder = find.text('About');

    // Scroll until visible in the ListView (which is the first Scrollable)
    final scrollable = find.byType(Scrollable).first;
    expect(scrollable, findsOneWidget);

    await tester.scrollUntilVisible(aboutCategoryFinder, 50,
        scrollable: scrollable);
    await tester.pumpAndSettle();

    expect(aboutCategoryFinder, findsOneWidget);

    // Tap "About" category to select it
    await tester.tap(aboutCategoryFinder);

    // Use pump with duration because AboutSection has an infinite pulsing animation
    // that causes pumpAndSettle to timeout.
    await tester
        .pump(const Duration(seconds: 1)); // Wait enough for transition/build

    // Verify AboutBody is displayed (TV uses full body instead of just a section card)
    expect(find.byType(AboutBody), findsOneWidget);
    // Use a text finder that is definitely in AboutBody
    expect(find.text('Shakedown'), findsOneWidget);
  });
}
