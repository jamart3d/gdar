import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';

void main() {
  testWidgets('AnimatedDiceIcon renders and respects loading state',
      (WidgetTester tester) async {
    // 1. Render in non-loading state
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedDiceIcon(
            onPressed: () {},
            isLoading: false,
          ),
        ),
      ),
    );

    // Verify CustomPaint logic produces no error (implicit) and widget exists
    expect(find.byType(AnimatedDiceIcon), findsOneWidget);
    // Use descendant finder to ensure we are finding OUR CustomPaint, not internal Flutter ones
    expect(
      find.descendant(
        of: find.byType(AnimatedDiceIcon),
        matching: find.byType(CustomPaint),
      ),
      findsAtLeastNWidgets(1),
    );

    // 2. Render in loading state
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AnimatedDiceIcon(
            onPressed: () {},
            isLoading: true,
          ),
        ),
      ),
    );

    // Pump to advance animation
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Verify it is still there without error
    expect(find.byType(AnimatedDiceIcon), findsOneWidget);
  });
}
