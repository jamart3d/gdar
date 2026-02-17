import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

void main() {
  testWidgets(
      'TvFocusWrapper should NOT trigger onTap on KeyUp if KeyDown was not received',
      (WidgetTester tester) async {
    int tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TvFocusWrapper(
            onTap: () => tapCount++,
            child: const Text('Focus Me'),
          ),
        ),
      ),
    );

    // Give focus to the widget
    await tester.tap(find.text('Focus Me'));
    await tester.pump();

    // Simulate only a KeyUp event (as if KeyDown was handled by a previous overlay)
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();

    // The tapCount should still be 0
    expect(tapCount, 0,
        reason: 'onTap should not be called without a preceding KeyDown event');
  });

  testWidgets(
      'TvFocusWrapper SHOULD trigger onTap on KeyUp if KeyDown WAS received',
      (WidgetTester tester) async {
    int tapCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TvFocusWrapper(
            onTap: () => tapCount++,
            child: const Text('Focus Me'),
          ),
        ),
      ),
    );

    // Give focus to the widget
    await tester.tap(find.text('Focus Me'));
    await tester.pump();

    // Simulate a full KeyDown -> KeyUp sequence
    await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump();
    await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();

    // The tapCount should be 1
    expect(tapCount, 1);
  });
}
