import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';

class MockSettingsProvider extends Mock implements SettingsProvider {}

void main() {
  testWidgets('TvFocusWrapper does NOT trigger onTap on focus gain',
      (WidgetTester tester) async {
    bool tapped = false;
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SettingsProvider>.value(value: MockSettingsProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TvFocusWrapper(
              focusNode: focusNode,
              onTap: () {
                tapped = true;
              },
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ),
    );

    expect(tapped, isFalse);

    // Focus the widget
    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(tapped, isFalse,
        reason: 'onTap should not be called when focus is gained');
  });

  testWidgets('TvFocusWrapper triggers onTap on Select key up',
      (WidgetTester tester) async {
    bool tapped = false;
    final focusNode = FocusNode();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<SettingsProvider>.value(value: MockSettingsProvider()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: TvFocusWrapper(
              focusNode: focusNode,
              onTap: () {
                tapped = true;
              },
              child: const SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    // Send Select Key Down
    await simulateKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(tapped, isFalse);

    // Send Select Key Up
    await simulateKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(tapped, isTrue);
  });
}
