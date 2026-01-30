import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AnimatedDiceIcon renders and respects loading state',
      (WidgetTester tester) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs);
    final themeProvider = ThemeProvider();

    Widget buildDice(bool loading) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settingsProvider),
          ChangeNotifierProvider.value(value: themeProvider),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: AnimatedDiceIcon(
              onPressed: () {},
              isLoading: loading,
            ),
          ),
        ),
      );
    }

    // 1. Render in non-loading state
    await tester.pumpWidget(buildDice(false));

    // Verify CustomPaint logic produces no error (implicit) and widget exists
    expect(find.byType(AnimatedDiceIcon), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(AnimatedDiceIcon),
        matching: find.byType(CustomPaint),
      ),
      findsAtLeastNWidgets(1),
    );

    // 2. Render in loading state
    await tester.pumpWidget(buildDice(true));

    // Pump to advance animation
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify it is still there without error
    expect(find.byType(AnimatedDiceIcon), findsOneWidget);
  });
}
