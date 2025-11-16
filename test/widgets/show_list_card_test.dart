import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/theme_provider.dart';
import 'package:gdar/ui/widgets/show_list_card.dart';
import 'package:provider/provider.dart';

void main() {
  // Helper function to create a dummy show
  Show createDummyShow(String name, String date, {int sourceCount = 1, bool hasFeaturedTrack = false}) {
    return Show(
      name: name,
      artist: 'Grateful Dead',
      date: date,
      year: date.split('-').first,
      venue: name.split(' on ').first,
      sources: List.generate(sourceCount, (i) => Source(id: 'source$i', tracks: [])),
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
        ChangeNotifierProvider(create: (_) => settingsProvider ?? SettingsProvider()),
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

  testWidgets('ShowListCard displays venue and date', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(show: dummyShow));

    expect(find.text(dummyShow.venue), findsOneWidget);
    expect(find.text(dummyShow.formattedDate), findsOneWidget);
  });

  testWidgets('ShowListCard border color changes when isPlaying is true', (WidgetTester tester) async {
    await tester.pumpWidget(createTestableWidget(show: dummyShow, isPlaying: true));

    final card = tester.widget<Card>(find.byType(Card));
    final shape = card.shape as RoundedRectangleBorder;
    final side = shape.side;

    expect(side.color, equals(Theme.of(tester.element(find.byType(Card))).colorScheme.primary));
  });

  testWidgets('ShowListCard expand icon rotates when isExpanded is true', (WidgetTester tester) async {
    final settingsProvider = SettingsProvider();
    settingsProvider.showExpandIcon = true;
    await tester.pumpWidget(createTestableWidget(
      show: dummyShow,
      isExpanded: true,
      settingsProvider: settingsProvider,
    ));

    final animatedRotation = tester.widget<AnimatedRotation>(find.byType(AnimatedRotation));
    expect(animatedRotation.turns, equals(0.5));
  });

  testWidgets('ShowListCard shows CircularProgressIndicator when isLoading is true', (WidgetTester tester) async {
    final settingsProvider = SettingsProvider();
    settingsProvider.showExpandIcon = true;
    await tester.pumpWidget(createTestableWidget(
      show: dummyShow,
      isLoading: true,
      settingsProvider: settingsProvider,
    ));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('ShowListCard displays badge for multiple sources', (WidgetTester tester) async {
    final showWithMultipleSources = createDummyShow('Venue B on 2025-02-20', '2025-02-20', sourceCount: 2);
    await tester.pumpWidget(createTestableWidget(show: showWithMultipleSources));

    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('ShowListCard calls onTap when tapped', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(createTestableWidget(
      show: dummyShow,
      onTap: () => tapped = true,
    ));

    await tester.tap(find.byType(ShowListCard));
    expect(tapped, isTrue);
  });

  testWidgets('ShowListCard calls onLongPress when long-pressed', (WidgetTester tester) async {
    bool longPressed = false;
    await tester.pumpWidget(createTestableWidget(
      show: dummyShow,
      onLongPress: () => longPressed = true,
    ));

    await tester.longPress(find.byType(ShowListCard));
    expect(longPressed, isTrue);
  });
}
