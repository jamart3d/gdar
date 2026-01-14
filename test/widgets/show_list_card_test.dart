import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/show_list_card.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  // Helper function to create a dummy show
  Show createDummyShow(String name, String date,
      {int sourceCount = 1, bool hasFeaturedTrack = false}) {
    return Show(
      name: name,
      artist: 'Grateful Dead',
      date: date,
      venue: name.split(' on ').first,
      sources:
          List.generate(sourceCount, (i) => Source(id: 'source$i', tracks: [])),
      hasFeaturedTrack: hasFeaturedTrack,
    );
  }

  final dummyShow = createDummyShow('Venue A on 2025-01-15', '2025-01-15');

  // The widget needs to be wrapped in a MaterialApp and other providers
  Widget createTestableWidget({
    required Show show,
    bool isExpanded = false,
    bool isPlaying = false,
    bool isLoading = false,
    VoidCallback? onTap,
    VoidCallback? onLongPress,
    SettingsProvider? settingsProvider,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => settingsProvider ?? SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: ShowListCard(
            show: show,
            isExpanded: isExpanded,
            isPlaying: isPlaying,
            isLoading: isLoading,
            onTap: onTap ?? () {},
            onLongPress: onLongPress ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('ShowListCard displays venue and date',
      (WidgetTester tester) async {
    final settingsProvider = SettingsProvider(prefs);
    // Default abbreviateMonth is true ("Jan"), but Show.formattedDate is "January".
    // Toggle to false to match the full date string expected by the test.
    // settingsProvider.toggleAbbreviateMonth(); // Removed as we now expect abbreviated month

    await tester.pumpWidget(createTestableWidget(
        show: dummyShow,
        settingsProvider: settingsProvider // Pass the configured provider
        ));

    expect(find.text(dummyShow.venue), findsOneWidget);
    // Default abbreviateMonth is true, so we expect "Jan", not "January"
    expect(find.text('Jan 15, 2025'), findsOneWidget);
  });

  testWidgets('ShowListCard border color changes when isPlaying is true',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(createTestableWidget(show: dummyShow, isPlaying: true));

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    final side = shape.side;

    expect(
        side.color,
        equals(
            Theme.of(tester.element(find.byType(Card))).colorScheme.primary));
  });

  testWidgets('ShowListCard expand icon rotates when isExpanded is true',
      (WidgetTester tester) async {
    final settingsProvider = SettingsProvider(prefs);
    settingsProvider.showExpandIcon = true;
    await tester.pumpWidget(createTestableWidget(
      show: dummyShow,
      isExpanded: true,
      settingsProvider: settingsProvider,
    ));

    final animatedRotation =
        tester.widget<AnimatedRotation>(find.byType(AnimatedRotation));
    expect(animatedRotation.turns, equals(0.5));
  });

  testWidgets(
      'ShowListCard shows CircularProgressIndicator when isLoading is true',
      (WidgetTester tester) async {
    final settingsProvider = SettingsProvider(prefs);
    settingsProvider.showExpandIcon = true;
    await tester.pumpWidget(createTestableWidget(
      show: dummyShow,
      isLoading: true,
      settingsProvider: settingsProvider,
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ShowListCard displays badge for multiple sources',
      (WidgetTester tester) async {
    final showWithMultipleSources =
        createDummyShow('Venue B on 2025-02-20', '2025-02-20', sourceCount: 2);
    await tester
        .pumpWidget(createTestableWidget(show: showWithMultipleSources));

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('ShowListCard calls onTap when tapped',
      (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(createTestableWidget(
      show: dummyShow,
      onTap: () => tapped = true,
    ));

    await tester.tap(find.byType(ShowListCard));
    expect(tapped, isTrue);
  });

  testWidgets('ShowListCard calls onLongPress when long-pressed',
      (WidgetTester tester) async {
    bool longPressed = false;
    await tester.pumpWidget(createTestableWidget(
      show: dummyShow,
      onLongPress: () => longPressed = true,
    ));

    await tester.longPress(find.byType(ShowListCard));
    expect(longPressed, isTrue);
  });

  testWidgets('ShowListCard displays rating control for single source show',
      (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(show: dummyShow));

    // Should find RatingControl widget
    expect(find.byType(RatingControl), findsOneWidget);
    // And it should contain empty stars (RatingBar uses Icons.star_border for empty)
    expect(find.byIcon(Icons.star_border), findsWidgets);
  });

  testWidgets('ShowListCard hides rating control for multi-source show',
      (WidgetTester tester) async {
    final showWithMultipleSources = createDummyShow('Show B', '2025-01-01');
    showWithMultipleSources.sources.add(Source(id: 'source2', tracks: []));

    await tester
        .pumpWidget(createTestableWidget(show: showWithMultipleSources));

    // Should NOT find RatingControl
    expect(find.byType(RatingControl), findsNothing);
  });

  testWidgets('Tapping rating control opens dialog when playing',
      (WidgetTester tester) async {
    final show = createDummyShow('Show C', '2025-01-01');
    await tester.pumpWidget(createTestableWidget(show: show, isPlaying: true));

    // Find the rating control
    final ratingControl = find.byType(RatingControl);
    expect(ratingControl, findsOneWidget);

    // Tap it
    await tester.tap(ratingControl);
    await tester.pumpAndSettle();

    // Verify dialog is open
    expect(find.text('Rate Show'), findsOneWidget);

    // Verify RatingBar is present (might find 2, one in card, one in dialog)
    expect(find.byType(RatingBar), findsWidgets);

    // Verify Block and Clear options
    expect(find.text('Block (Red Star)'), findsOneWidget);
    expect(find.text('Clear Rating'), findsOneWidget);
  });

  testWidgets('ShowListCard displays grey star for played but unrated show',
      (WidgetTester tester) async {
    final show = createDummyShow('Played Show', '2025-01-01');
    final settingsProvider = SettingsProvider(prefs);
    await settingsProvider.markAsPlayed('source0');

    await tester.pumpWidget(createTestableWidget(
      show: show,
      settingsProvider: settingsProvider,
    ));

    // Should find RatingControl
    expect(find.byType(RatingControl), findsOneWidget);

    // Should find 1 grey star (filled)
    expect(find.byIcon(Icons.star), findsOneWidget);
    // Should find 2 empty stars (borders)
    expect(find.byIcon(Icons.star_border), findsNWidgets(2));
  });

  testWidgets('ShowListCard displays empty stars for unplayed and unrated show',
      (WidgetTester tester) async {
    final show = createDummyShow('Unplayed Show', '2025-01-02');
    // No played status set

    await tester.pumpWidget(createTestableWidget(
      show: show,
    ));

    // Should find RatingControl
    expect(find.byType(RatingControl), findsOneWidget);

    // Should find 3 empty stars (borders)
    expect(find.byIcon(Icons.star_border), findsNWidgets(3));
    // Should NOT find any filled stars
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('Tapping rating control does NOT open dialog when NOT playing',
      (WidgetTester tester) async {
    await tester
        .pumpWidget(createTestableWidget(show: dummyShow, isPlaying: false));

    // Find the rating control
    final ratingControl = find.byType(RatingControl);
    expect(ratingControl, findsOneWidget);

    // Tap it
    await tester.tap(ratingControl);
    await tester.pumpAndSettle();

    // Verify dialog is NOT open
    expect(find.text('Rate Show'), findsNothing);
  });

  testWidgets('ShowListCard meets accessibility guidelines',
      (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await tester.pumpWidget(createTestableWidget(show: dummyShow));

    // Checks that tap targets satisfy a minimum size of 48x48.
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));

    // Checks that text and background color contrast is sufficient.
    await expectLater(tester, meetsGuideline(textContrastGuideline));

    // Checks that interactive elements have labels.
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

    handle.dispose();
  });
}
