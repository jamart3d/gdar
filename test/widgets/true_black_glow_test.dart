import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/theme_provider.dart';
import 'package:gdar/ui/widgets/animated_gradient_border.dart';
import 'package:gdar/ui/widgets/show_list_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  // Helper function to create a dummy show
  Show createDummyShow(String name, String date) {
    return Show(
      name: name,
      artist: 'Grateful Dead',
      date: date,
      venue: name,
      sources: [Source(id: 'source1', tracks: [])],
    );
  }

  Widget createTestableWidget({
    required Show show,
    required SettingsProvider settingsProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        // Force Dark Mode to test True Black logic
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ShowListCard(
            show: show,
            isExpanded: false,
            isPlaying: false,
            isLoading: false,
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('True Black & Half Glow forces shadow ON and reduces opacity',
      (WidgetTester tester) async {
    final settingsProvider = SettingsProvider(prefs);

    // Simulate "True Black and Half Glow" configuration:
    // 1. Dark Mode (set in createTestableWidget via Theme)
    // 2. Dynamic Color = TRUE (required for half glow logic branch)
    // Defaults to true, so we just calculate.
    if (!settingsProvider.useDynamicColor) {
      settingsProvider.toggleUseDynamicColor();
    }
    // 3. Set Glow Mode to HALF (2)
    settingsProvider.setGlowMode(2);

    expect(settingsProvider.glowMode, equals(2));

    await tester.pumpWidget(createTestableWidget(
      show: createDummyShow('Test Venue', '2025-01-01'),
      settingsProvider: settingsProvider,
    ));

    // Find the AnimatedGradientBorder widget
    final borderFinder = find.byType(AnimatedGradientBorder);
    expect(borderFinder, findsOneWidget);

    final borderWidget = tester.widget<AnimatedGradientBorder>(borderFinder);

    // ASCERTION 1: Shadow should be TRUE (Mode 2 has shadow)
    expect(borderWidget.showShadow, isTrue,
        reason: 'Shadow should be forced ON when Half Glow is active (Mode 2)');

    // Expected: 0.2 * 0.5 * 0.25 = 0.025
    expect(borderWidget.glowOpacity, closeTo(0.025, 0.0001),
        reason:
            'Opacity should be 0.025 (standard 0.2 * half 0.5 * not-playing 0.25)');
  });

  testWidgets('True Black & Half Glow reduces opacity for Playing Card',
      (WidgetTester tester) async {
    final settingsProvider = SettingsProvider(prefs);
    if (!settingsProvider.useDynamicColor) {
      settingsProvider.toggleUseDynamicColor();
    }
    // Set Glow Mode to HALF (2) to test reduced opacity
    settingsProvider.setGlowMode(2);

    final show = createDummyShow('Test Venue', '2025-01-01');

    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsProvider),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: ShowListCard(
            show: show,
            isPlaying: true, // Playing = glowing
            isExpanded: false,
            isLoading: false,
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      ),
    ));

    final borderWidget = tester
        .widget<AnimatedGradientBorder>(find.byType(AnimatedGradientBorder));

    // Calculation: 1.0 * 0.2 * 0.5 = 0.1
    // expect(borderWidget.glowOpacity, closeTo(0.1, 0.0001), ...

    if ((borderWidget.glowOpacity - 0.1).abs() > 0.0001) {
      fail(
          'Opacity mismatch! Expected 0.1 but got ${borderWidget.glowOpacity}. (Show shadow: ${borderWidget.showShadow})');
    }
  });
}
