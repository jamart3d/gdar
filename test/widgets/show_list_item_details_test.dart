import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/widgets/rating_control.dart';
import 'package:gdar/ui/widgets/show_list_item_details.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Show createDummyShow(String name, {int sourceCount = 2}) {
    return Show(
      name: name,
      artist: 'Grateful Dead',
      date: '2025-01-01',
      venue: 'Venue',
      sources:
          List.generate(sourceCount, (i) => Source(id: 'source$i', tracks: [])),
      hasFeaturedTrack: false,
    );
  }

  Widget createTestableWidget({
    required Show show,
    String? playingSourceId,
    SettingsProvider? settingsProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => settingsProvider ?? SettingsProvider(prefs)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ShowListItemDetails(
            show: show,
            playingSourceId: playingSourceId,
            height: 200,
            onSourceTapped: (_) {},
            onSourceLongPress: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('ShowListItemDetails displays rating control for each source',
      (WidgetTester tester) async {
    final show = createDummyShow('Show A', sourceCount: 2);
    await tester.pumpWidget(createTestableWidget(show: show));

    // Should find 2 RatingControl widgets
    expect(find.byType(RatingControl), findsNWidgets(2));
    // And they should contain empty stars
    expect(find.byIcon(Icons.star_border), findsWidgets);
  });

  testWidgets('ShowListItemDetails displays source IDs',
      (WidgetTester tester) async {
    final show = createDummyShow('Show B', sourceCount: 2);
    await tester.pumpWidget(createTestableWidget(show: show));

    expect(find.text('source0'), findsOneWidget);
    expect(find.text('source1'), findsOneWidget);
  });

  testWidgets('Tapping rating control in details opens dialog when playing',
      (WidgetTester tester) async {
    final show = createDummyShow('Show C', sourceCount: 2);
    await tester.pumpWidget(
        createTestableWidget(show: show, playingSourceId: 'source0'));

    // Find the rating control
    final ratingControl = find.byType(RatingControl).first;
    expect(ratingControl, findsOneWidget);

    // Tap it
    await tester.tap(ratingControl);
    await tester.pumpAndSettle();

    // Verify dialog is open
    expect(find.text('Rate Show'), findsOneWidget);
  });

  testWidgets(
      'Tapping rating control in details does NOT open dialog when NOT playing',
      (WidgetTester tester) async {
    final show = createDummyShow('Show C', sourceCount: 2);
    await tester.pumpWidget(
        createTestableWidget(show: show, playingSourceId: 'other_source'));

    // Find the rating control
    final ratingControl = find.byType(RatingControl).first;
    expect(ratingControl, findsOneWidget);

    // Tap it
    await tester.tap(ratingControl);
    await tester.pumpAndSettle();

    // Verify dialog is NOT open
    expect(find.text('Rate Show'), findsNothing);
  });

  testWidgets('Rating dialog displays source ID badge',
      (WidgetTester tester) async {
    final show = createDummyShow('Show D', sourceCount: 2);
    await tester.pumpWidget(
        createTestableWidget(show: show, playingSourceId: 'source0'));

    // Find the rating control for source0
    final ratingControl = find.byType(RatingControl).first;
    await tester.tap(ratingControl);
    await tester.pumpAndSettle();

    // Verify dialog title contains source ID
    expect(
        find.descendant(
            of: find.byType(SimpleDialog), matching: find.text('source0')),
        findsOneWidget);
  });
}
