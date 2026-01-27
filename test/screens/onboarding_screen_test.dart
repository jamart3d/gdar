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
      when(mockSettingsProvider.enableShakedownTween)
          .thenReturn(false); // Added missing stub
      when(mockSettingsProvider.marqueeEnabled)
          .thenReturn(false); // Disable marquee
    });

    testWidgets('renders key UI elements correctly',
        (WidgetTester tester) async {
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

    testWidgets('Get Started button triggers completion',
        (WidgetTester tester) async {
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

    testWidgets('Dark Mode chip toggles ThemeProvider',
        (WidgetTester tester) async {
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
  });
}
