import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/ui/screens/onboarding_screen.dart';

import 'splash_screen_test.mocks.dart';

// Manual mock for ThemeProvider since it's not generated
class MockThemeProvider extends ChangeNotifier implements ThemeProvider {
  bool _isDarkMode = false;

  @override
  bool get isDarkMode => _isDarkMode;

  @override
  ThemeMode get currentThemeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  @override
  void toggleTheme() {
    // print('MockThemeProvider: toggleTheme called. Current: $_isDarkMode');
    _isDarkMode = !_isDarkMode;
    // print('MockThemeProvider: New state: $_isDarkMode');
    notifyListeners();
  }
}

void main() {
  late MockSettingsProvider mockSettingsProvider;
  late MockShowListProvider mockShowListProvider;
  late MockAudioProvider mockAudioProvider;
  late MockThemeProvider mockThemeProvider;

  setUp(() {
    mockSettingsProvider = MockSettingsProvider();
    mockShowListProvider = MockShowListProvider();
    mockAudioProvider = MockAudioProvider();
    mockThemeProvider = MockThemeProvider();
  });

  Widget createSubject() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<ShowListProvider>.value(
            value: mockShowListProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
      ],
      child: const MaterialApp(
        home: OnboardingScreen(),
      ),
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
    });

    testWidgets('renders key UI elements correctly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Shakedown'), findsOneWidget);
      // We expect some text starting with 'Version' eventually, but without dragging in package_info_plus_platform_interface mocks, it might be safer to check for the FutureBuilder or just 'Shakedown' for now.
      // Actually, let's just check 'Shakedown'.

      expect(find.textContaining('Welcome friend'), findsOneWidget);
      expect(find.text('Font Selection'), findsOneWidget);
      expect(find.text('Rock Salt'), findsOneWidget);
      expect(find.text('Dark Mode'), findsOneWidget);
    });

    testWidgets('Get Started button triggers completion',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Find Get Started button
      final getStartedBtn = find.text('Get Started');
      expect(getStartedBtn, findsOneWidget);

      await tester.ensureVisible(getStartedBtn);
      await tester.tap(getStartedBtn);
      await tester
          .pump(const Duration(milliseconds: 500)); // Handle tap and navigation

      // Verify completion was called
      verify(mockSettingsProvider.completeOnboarding()).called(1);
    });

    testWidgets('UI Scale chip updates SettingsProvider',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

      // Initial state (false by default)
      expect(mockSettingsProvider.uiScale,
          false); // Use mock getter check if possible, or verify setup

      // Tap UI Scale Chip
      final uiScaleChip = find.text('UI Scale');
      await tester.ensureVisible(uiScaleChip);
      await tester.tap(uiScaleChip);
      await tester.pump(const Duration(milliseconds: 500));

      verify(mockSettingsProvider.toggleUiScale()).called(1);
    });

    testWidgets('Dark Mode chip toggles ThemeProvider',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(milliseconds: 500));

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
  });
}
