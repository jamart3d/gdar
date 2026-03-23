import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/ui/screens/onboarding_screen.dart';
import 'package:shakedown_core/providers/update_provider.dart';
import 'package:shakedown_core/services/device_service.dart';

import 'splash_screen_test.mocks.dart';

class MockThemeProvider extends ChangeNotifier
    with WidgetsBindingObserver
    implements ThemeProvider {
  bool _isDarkMode = false;

  @override
  bool get isDarkMode => _isDarkMode;

  @override
  bool get isTv => false;

  @override
  bool testOnlyOverrideFruitAllowed = false;

  @override
  bool get isFruitAllowed => true;

  @override
  ThemeMode get currentThemeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  @override
  ThemeMode get selectedThemeMode => currentThemeMode;

  ThemeStyle _themeStyle = ThemeStyle.android;
  @override
  ThemeStyle get themeStyle => _themeStyle;

  @override
  bool get isFruit => _themeStyle == ThemeStyle.fruit;

  @override
  void setThemeStyle(ThemeStyle style) {
    _themeStyle = style;
    notifyListeners();
  }

  @override
  void setSettingsProvider(SettingsProvider provider) {}

  FruitColorOption _fruitColorOption = FruitColorOption.sophisticate;
  @override
  FruitColorOption get fruitColorOption => _fruitColorOption;

  @override
  void setFruitColorOption(FruitColorOption option) {
    _fruitColorOption = option;
    notifyListeners();
  }

  @override
  void toggleTheme({Brightness? currentBrightness}) {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  @override
  void setThemeMode(ThemeMode mode) {
    if (mode == ThemeMode.dark) {
      _isDarkMode = true;
    } else if (mode == ThemeMode.light) {
      _isDarkMode = false;
    }
    notifyListeners();
  }

  @override
  Future<void> get initializationComplete => Future.value();
}

class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;
  @override
  bool get isMobile => true;
  @override
  bool get isDesktop => false;
  @override
  bool get isSafari => false;
  @override
  bool get isPwa => false;
  @override
  String? get deviceName => 'Mock Device';
  @override
  Future<void> refresh() async {}
}

void main() {
  late MockSettingsProvider mockSettingsProvider;
  late MockShowListProvider mockShowListProvider;
  late MockAudioProvider mockAudioProvider;
  late MockThemeProvider mockThemeProvider;
  late MockUpdateProvider mockUpdateProvider;
  late MockDeviceService mockDeviceService;

  setUp(() {
    mockSettingsProvider = MockSettingsProvider();
    mockShowListProvider = MockShowListProvider();
    mockAudioProvider = MockAudioProvider();
    mockThemeProvider = MockThemeProvider();
    mockUpdateProvider = MockUpdateProvider();
    mockDeviceService = MockDeviceService();
  });

  Widget createSubject() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
          value: mockSettingsProvider,
        ),
        ChangeNotifierProvider<ShowListProvider>.value(
          value: mockShowListProvider,
        ),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
        ChangeNotifierProvider<UpdateProvider>.value(value: mockUpdateProvider),
        ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
      ],
      child: const MaterialApp(home: OnboardingScreen()),
    );
  }

  group('OnboardingScreen', () {
    setUp(() {
      // Default stubbing
      when(mockSettingsProvider.appFont).thenReturn('default');
      when(mockSettingsProvider.uiScale).thenReturn(false);
      when(mockSettingsProvider.useTrueBlack).thenReturn(false);
      when(mockSettingsProvider.showSplashScreen).thenReturn(true);
      when(mockSettingsProvider.showOnboarding).thenReturn(true);
      when(mockSettingsProvider.seedColor).thenReturn(null);
      when(
        mockSettingsProvider.enableShakedownTween,
      ).thenReturn(false); // Added missing stub
      when(
        mockSettingsProvider.marqueeEnabled,
      ).thenReturn(false); // Disable marquee
      when(mockUpdateProvider.updateInfo).thenReturn(null);
      when(mockUpdateProvider.isSimulated).thenReturn(false);
    });

    testWidgets('renders key UI elements correctly', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Page 0
      expect(find.text('Shakedown'), findsOneWidget);
      expect(find.textContaining('Welcome friend'), findsOneWidget);

      // Navigate to Page 1 (Try drag instead of tap)
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(seconds: 1)); // Wait for transition

      // Verify Page 1
      expect(find.text('Quick Tips'), findsOneWidget);

      // Navigate to Page 2
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(seconds: 1)); // Wait for transition

      expect(find.text('Font Selection'), findsOneWidget);
      expect(find.text('Rock Salt'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('Get Started button triggers completion', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to Page 2
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(seconds: 1));

      // Find Get Started button
      final getStartedBtn = find.text('Get Started');
      expect(getStartedBtn, findsOneWidget);

      // Tap "Don't show again" to trigger completeOnboarding
      final checkbox = find.text("Don't show again");
      await tester.ensureVisible(checkbox);
      await tester.tap(checkbox);
      await tester.pump();

      await tester.ensureVisible(getStartedBtn);
      await tester.tap(getStartedBtn);
      await tester.pump(
        const Duration(milliseconds: 500),
      ); // Handle tap and navigation

      // Verify completion was called
      verify(mockSettingsProvider.completeOnboarding()).called(1);
    });

    testWidgets('UI Scale chip updates SettingsProvider', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to Page 2
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(seconds: 1));

      // Initial state (false by default)
      // Note: SettingsProvider is mocked, so we can't check its real state property unless we stubbed a getter that returns a variable.
      // But verify() checks the method call.

      // Tap UI Scale Chip
      final uiScaleChip = find.text('UI Scale');
      await tester.ensureVisible(uiScaleChip);
      await tester.tap(uiScaleChip);
      await tester.pump(const Duration(milliseconds: 500));

      verify(mockSettingsProvider.toggleUiScale()).called(1);
    });

    testWidgets('Dark Mode chip toggles ThemeProvider', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Navigate to Page 2
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(seconds: 1));
      await tester.drag(find.byType(PageView), const Offset(-500, 0));
      await tester.pump(const Duration(seconds: 1));

      expect(mockThemeProvider.isDarkMode, false);

      await tester.ensureVisible(find.text('Dark Mode'));
      await tester.tap(find.text('Dark Mode'));
      await tester.pump(const Duration(milliseconds: 500));

      expect(mockThemeProvider.isDarkMode, true);

      // Tap again to toggle off
      await tester.ensureVisible(find.text('Dark Mode'));
      await tester.tap(find.text('Dark Mode'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(mockThemeProvider.isDarkMode, false);
    });

    testWidgets('shows UpdateBanner when update is simulated', (
      WidgetTester tester,
    ) async {
      when(mockUpdateProvider.isSimulated).thenReturn(true);
      when(mockUpdateProvider.updateInfo).thenReturn(null);

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Page 0 (WelcomePage)
      expect(find.text('Update Available'), findsOneWidget);
      expect(find.text('A new version is ready to install.'), findsOneWidget);

      // Tap UPDATE button
      final updateBtn = find.text('UPDATE');
      expect(updateBtn, findsOneWidget);
      await tester.tap(updateBtn);
      await tester.pump();

      verify(mockUpdateProvider.startUpdate()).called(1);
    });
  });
}
