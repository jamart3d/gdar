import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/ui/widgets/rgb_clock_wrapper.dart';

void main() {
  testWidgets('RgbClockWrapper provides Animation<double> without error',
      (WidgetTester tester) async {
    // This test simulates the structure in main.dart to "catch" the Provider safety check
    await tester.pumpWidget(
      RgbClockWrapper(
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                // Verify we can read the value
                try {
                  final animation = Provider.of<Animation<double>>(context);
                  final controller = Provider.of<AnimationController>(
                      context); // Verify controller availability
                  return Text(
                      'Animation Value: ${animation.value}, HasController: ${controller.runtimeType}');
                } catch (e) {
                  return Text('Error: $e');
                }
              },
            ),
          ),
        ),
      ),
    );

    // If Provider safety check fails, it usually throws an exception during pump
    // or the builder might catch it.
    // However, the specific error "Tried to use Provider with a subtype of Listenable..."
    // is thrown by Provider during build.

    expect(find.textContaining('Animation Value:'), findsOneWidget);
    expect(find.textContaining('HasController: AnimationController'),
        findsOneWidget);
    expect(find.textContaining('Error:'), findsNothing);
  });
}
