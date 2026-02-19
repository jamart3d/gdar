import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/ui/widgets/show_list/fast_scrollbar.dart';

void main() {
  late ItemScrollController itemScrollController;
  late ItemPositionsListener itemPositionsListener;
  late List<Show> mockShows;

  setUp(() {
    itemScrollController = ItemScrollController();
    itemPositionsListener = ItemPositionsListener.create();
    mockShows = List.generate(
      100,
      (i) => Show(
        name: 'Show $i',
        date: '${1965 + (i ~/ 10)}-01-01',
        venue: 'Venue $i',
        artist: 'Artist',
        sources: [],
        hasFeaturedTrack: false,
      ),
    );
  });

  Widget createWidget() {
    return MaterialApp(
      home: Scaffold(
        body: Stack(
          children: [
            ScrollablePositionedList.builder(
              itemCount: mockShows.length,
              itemBuilder: (context, index) => SizedBox(
                height: 100,
                child: Text('Item $index'),
              ),
              itemScrollController: itemScrollController,
              itemPositionsListener: itemPositionsListener,
            ),
            FastScrollbar(
              shows: mockShows,
              itemScrollController: itemScrollController,
              itemPositionsListener: itemPositionsListener,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('FastScrollbar is initially invisible (auto-hide)',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidget());

    // The scrollbar uses FadeTransition, initially at opacity 0
    final fadeTransition = tester
        .widget<FadeTransition>(find.byKey(const Key('fast_scrollbar_fade')));
    expect(fadeTransition.opacity.value, 0.0);
  });

  testWidgets('FastScrollbar becomes visible on scroll and hides after delay',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidget());

    // Simulate scroll
    itemScrollController.jumpTo(index: 10);
    await tester.pump(); // Start fade in

    // We expect the last FadeTransition to eventually be 1.0
    await tester.pumpAndSettle(); // Finish animation
    var fadeTransition = tester
        .widget<FadeTransition>(find.byKey(const Key('fast_scrollbar_fade')));
    expect(fadeTransition.opacity.value, 1.0);

    // Wait for auto-hide delay (1 second)
    // FastScrollbar uses Timer(_autoHideDelay, ...) which is simulated in tests.
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(); // Start reverse animation

    await tester.pumpAndSettle();
    fadeTransition = tester
        .widget<FadeTransition>(find.byKey(const Key('fast_scrollbar_fade')));
    expect(fadeTransition.opacity.value, 0.0);
  });

  testWidgets('Dragging shows overlay and jumps to index',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidget());

    // Find the Gesture detector area (right side of screen)
    final scrollbarArea = find.byType(GestureDetector).last;

    // Drag from middle
    final center = tester.getCenter(scrollbarArea);
    final gesture = await tester.startGesture(center);
    await tester.pump(); // Start drag, scale animation

    // Verify scale eventually increases
    await tester.pumpAndSettle();
    final scaleTransition = tester
        .widget<ScaleTransition>(find.byKey(const Key('fast_scrollbar_scale')));
    // Scale goes from 1.0 to 1.4
    expect(scaleTransition.scale.value, 1.4);

    // Verify overlay presence
    expect(find.byKey(const Key('year_chip_material')), findsOneWidget);
    // Year at index ~50 should be 1970 (1965 + 50~/10)
    expect(find.text('1970'), findsOneWidget);

    // Move drag
    await gesture
        .moveTo(tester.getBottomRight(scrollbarArea) - const Offset(10, 50));
    await tester.pump();

    // Ending drag
    await gesture.up();
    await tester.pump(); // Start scale reverse and hide timer

    expect(find.byKey(const Key('year_chip_material')),
        findsNothing); // Overlay should be removed immediately

    // Explicitly wait for auto-hide timer (1 second)
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(); // Start reverse animation

    await tester.pumpAndSettle();
    final fadeTransition = tester
        .widget<FadeTransition>(find.byKey(const Key('fast_scrollbar_fade')));
    expect(fadeTransition.opacity.value, 0.0); // Should eventually hide
  });

  testWidgets('Disposes correctly without timer leaks',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidget());

    // Trigger timer
    itemScrollController.jumpTo(index: 5);
    await tester.pump();

    // Dispose while timer is active
    await tester.pumpWidget(const SizedBox());

    // If no exception thrown, then it's good.
    // AutomatedTestWidgetsFlutterBinding will catch pending timers at end of test.
  });
}
