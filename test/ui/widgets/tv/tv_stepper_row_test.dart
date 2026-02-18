import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/ui/widgets/tv/tv_stepper_row.dart';

void main() {
  group('TvStepperRow', () {
    testWidgets('renders label and formatted value', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvStepperRow(
              label: 'Test Speed',
              value: 1.5,
              min: 0.0,
              max: 3.0,
              step: 0.1,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Test Speed'), findsOneWidget);
      expect(find.text('1.50'), findsOneWidget);
    });

    testWidgets('captures DPAD Right key to increment value', (tester) async {
      double? updatedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvStepperRow(
              label: 'Test Speed',
              value: 1.5,
              min: 0.0,
              max: 3.0,
              step: 0.1,
              onChanged: (v) => updatedValue = v,
            ),
          ),
        ),
      );

      // Focus the stepper
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Press Right Arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(updatedValue, closeTo(1.6, 0.001));
    });

    testWidgets('captures DPAD Left key to decrement value', (tester) async {
      double? updatedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvStepperRow(
              label: 'Test Speed',
              value: 1.5,
              min: 0.0,
              max: 3.0,
              step: 0.1,
              onChanged: (v) => updatedValue = v,
            ),
          ),
        ),
      );

      // Focus the stepper
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Press Left Arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(updatedValue, closeTo(1.4, 0.001));
    });

    testWidgets('respects min/max bounds', (tester) async {
      double? updatedValue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvStepperRow(
              label: 'Test Speed',
              value: 3.0, // Already at max
              min: 0.0,
              max: 3.0,
              step: 0.1,
              onChanged: (v) => updatedValue = v,
            ),
          ),
        ),
      );

      // Focus the stepper
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Press Right Arrow (should not exceed max)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(updatedValue,
          isNull); // onChanged shouldn't be called if value doesn't change
    });

    testWidgets('uses custom valueFormatter if provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TvStepperRow(
              label: 'Test Speed',
              value: 0.995,
              min: 0.0,
              max: 1.0,
              step: 0.001,
              valueFormatter: (v) => 'VAL: ${v.toStringAsFixed(3)}',
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('VAL: 0.995'), findsOneWidget);
    });
  });
}
