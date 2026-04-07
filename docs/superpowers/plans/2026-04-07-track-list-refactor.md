# Track List Refactor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refactor the track-list feature so `track_list_screen_build.dart` and `track_list_view.dart` share typed list-shaping logic, use smaller presentational widgets, and keep current behavior while adding focused tests.

**Architecture:** Introduce one shared typed layout builder for grouped track-list data and index mapping, then migrate `TrackListView` and `TrackListScreen` to consume it. Extract focused playback widgets for set headers and track tiles so screen coordination, list composition, and row rendering are separated cleanly.

**Tech Stack:** Flutter, Dart 3.11, Provider, `ScrollablePositionedList`, `just_audio`, `flutter_test`

---

### Task 1: Introduce Shared Track List Layout Models

**Files:**
- Create: `packages/shakedown_core/lib/ui/widgets/playback/track_list_items.dart`
- Test: `packages/shakedown_core/test/ui/widgets/playback/track_list_items_test.dart`

- [ ] **Step 1: Write the failing unit test**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/ui/widgets/playback/track_list_items.dart';

void main() {
  Source buildSource() {
    return Source(
      id: 'gd77-05-08.sbd',
      tracks: const [
        Track(
          trackNumber: 1,
          title: 'Bertha',
          duration: 365,
          url: 'https://archive.org/1.mp3',
          setName: 'Set 1',
        ),
        Track(
          trackNumber: 2,
          title: 'Good Lovin\'',
          duration: 420,
          url: 'https://archive.org/2.mp3',
          setName: 'Set 1',
        ),
        Track(
          trackNumber: 3,
          title: 'U.S. Blues',
          duration: 310,
          url: 'https://archive.org/3.mp3',
          setName: 'Encore',
        ),
      ],
    );
  }

  test('buildTrackListLayout preserves section order and track mappings', () {
    final layout = buildTrackListLayout(buildSource(), includeShowHeader: true);

    expect(layout.sections.length, 2);
    expect(layout.sections[0].setName, 'Set 1');
    expect(layout.sections[0].tracks.map((track) => track.title), [
      'Bertha',
      'Good Lovin\'',
    ]);
    expect(layout.sections[1].setName, 'Encore');
    expect(layout.items.whereType<TrackListSetHeaderItem>().map((item) => item.setName), [
      'Set 1',
      'Encore',
    ]);
    expect(layout.items.whereType<TrackListTrackItem>().map((item) => item.track.title), [
      'Bertha',
      'Good Lovin\'',
      'U.S. Blues',
    ]);
    expect(layout.items.first, isA<TrackListShowHeaderItem>());
    expect(layout.trackIndexToItemIndex[0], 2);
    expect(layout.trackIndexToItemIndex[1], 3);
    expect(layout.trackIndexToItemIndex[2], 5);
    expect(layout.itemIndexToTrackIndex[2], 0);
    expect(layout.itemIndexToTrackIndex[3], 1);
    expect(layout.itemIndexToTrackIndex[5], 2);
  });

  test('buildTrackListLayout omits show header when requested', () {
    final layout = buildTrackListLayout(buildSource());

    expect(layout.items.first, isA<TrackListSetHeaderItem>());
    expect(layout.trackIndexToItemIndex[0], 1);
    expect(layout.trackIndexToItemIndex[2], 4);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run from `packages/shakedown_core`:

```bash
flutter test test/ui/widgets/playback/track_list_items_test.dart
```

Expected: FAIL with missing import symbols such as `buildTrackListLayout` or `TrackListTrackItem`.

- [ ] **Step 3: Write the minimal implementation**

```dart
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';

class TrackListSection {
  const TrackListSection({required this.setName, required this.tracks});

  final String setName;
  final List<Track> tracks;
}

sealed class TrackListItem {
  const TrackListItem();
}

final class TrackListShowHeaderItem extends TrackListItem {
  const TrackListShowHeaderItem();
}

final class TrackListSetHeaderItem extends TrackListItem {
  const TrackListSetHeaderItem(this.setName);

  final String setName;
}

final class TrackListTrackItem extends TrackListItem {
  const TrackListTrackItem({required this.track, required this.trackIndex});

  final Track track;
  final int trackIndex;
}

class TrackListLayout {
  const TrackListLayout({
    required this.sections,
    required this.items,
    required this.trackIndexToItemIndex,
    required this.itemIndexToTrackIndex,
  });

  final List<TrackListSection> sections;
  final List<TrackListItem> items;
  final Map<int, int> trackIndexToItemIndex;
  final Map<int, int> itemIndexToTrackIndex;
}

TrackListLayout buildTrackListLayout(
  Source source, {
  bool includeShowHeader = false,
}) {
  final sections = <TrackListSection>[];
  for (final track in source.tracks) {
    if (sections.isEmpty || sections.last.setName != track.setName) {
      sections.add(TrackListSection(setName: track.setName, tracks: [track]));
    } else {
      sections.last.tracks.add(track);
    }
  }

  final items = <TrackListItem>[
    if (includeShowHeader) const TrackListShowHeaderItem(),
  ];
  final trackIndexToItemIndex = <int, int>{};
  final itemIndexToTrackIndex = <int, int>{};

  var trackIndex = 0;
  for (final section in sections) {
    items.add(TrackListSetHeaderItem(section.setName));
    for (final track in section.tracks) {
      final itemIndex = items.length;
      items.add(TrackListTrackItem(track: track, trackIndex: trackIndex));
      trackIndexToItemIndex[trackIndex] = itemIndex;
      itemIndexToTrackIndex[itemIndex] = trackIndex;
      trackIndex++;
    }
  }

  return TrackListLayout(
    sections: sections,
    items: items,
    trackIndexToItemIndex: trackIndexToItemIndex,
    itemIndexToTrackIndex: itemIndexToTrackIndex,
  );
}
```

- [ ] **Step 4: Run test to verify it passes**

Run from `packages/shakedown_core`:

```bash
flutter test test/ui/widgets/playback/track_list_items_test.dart
```

Expected: PASS with 2 tests passing.

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/ui/widgets/playback/track_list_items.dart packages/shakedown_core/test/ui/widgets/playback/track_list_items_test.dart
git commit -m "refactor: add shared track list layout models"
```

### Task 2: Refactor `TrackListView` Around Shared Layout And Extracted Widgets

**Files:**
- Create: `packages/shakedown_core/lib/ui/widgets/playback/track_list_set_header.dart`
- Create: `packages/shakedown_core/lib/ui/widgets/playback/track_list_tile.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart`
- Test: `packages/shakedown_core/test/ui/widgets/playback/track_list_view_test.dart`

- [ ] **Step 1: Write the failing widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/test/helpers/test_helpers.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/ui/widgets/playback/track_list_view.dart';

class _TestGaplessPlayer extends Fake implements GaplessPlayer {
  @override
  int? get currentIndex => 1;

  @override
  Stream<int?> get currentIndexStream => Stream<int?>.value(1);

  @override
  PlayerState get playerState => PlayerState(true, ProcessingState.ready);

  @override
  Stream<PlayerState> get playerStateStream =>
      Stream<PlayerState>.value(PlayerState(true, ProcessingState.ready));

  @override
  Duration get position => Duration.zero;

  @override
  Stream<Duration> get positionStream => Stream<Duration>.value(Duration.zero);

  @override
  Duration get bufferedPosition => const Duration(seconds: 30);

  @override
  Stream<Duration> get bufferedPositionStream =>
      Stream<Duration>.value(const Duration(seconds: 30));

  @override
  Duration? get duration => const Duration(minutes: 6);

  @override
  Stream<Duration?> get durationStream =>
      Stream<Duration?>.value(const Duration(minutes: 6));
}

class _RecordingAudioProvider extends ChangeNotifier implements AudioProvider {
  _RecordingAudioProvider(this.audioPlayer);

  @override
  final GaplessPlayer audioPlayer;

  final List<int> seekRequests = <int>[];

  @override
  Stream<int?> get currentIndexStream => audioPlayer.currentIndexStream;

  @override
  Stream<PlayerState> get playerStateStream => audioPlayer.playerStateStream;

  @override
  Stream<Duration> get positionStream => audioPlayer.positionStream;

  @override
  Stream<Duration?> get durationStream => audioPlayer.durationStream;

  @override
  Stream<Duration> get bufferedPositionStream =>
      audioPlayer.bufferedPositionStream;

  @override
  bool get isPlaying => true;

  @override
  Future<void> seekToTrack(int index) async {
    seekRequests.add(index);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TrackListView renders ordered set headers and forwards track taps', (tester) async {
    SharedPreferences.setMockInitialValues({
      'highlight_playing_with_rgb': true,
      'glow_mode': 0,
    });
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs)
      ..setHighlightPlayingWithRgb(true)
      ..setGlowMode(0);
    final audioProvider = _RecordingAudioProvider(_TestGaplessPlayer());
    final source = Source(
      id: 'gd77-05-08.sbd',
      tracks: const [
        Track(trackNumber: 1, title: 'Bertha', duration: 365, url: 'https://archive.org/1.mp3', setName: 'Set 1'),
        Track(trackNumber: 2, title: 'Good Lovin\'', duration: 420, url: 'https://archive.org/2.mp3', setName: 'Set 1'),
        Track(trackNumber: 3, title: 'U.S. Blues', duration: 310, url: 'https://archive.org/3.mp3', setName: 'Encore'),
      ],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
          ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<DeviceService>.value(value: MockDeviceService()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: TrackListView(
                source: source,
                bottomPadding: 40,
                itemScrollController: ItemScrollController(),
                itemPositionsListener: ItemPositionsListener.create(),
                audioProvider: audioProvider,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Set 1'), findsOneWidget);
    expect(find.text('Encore'), findsOneWidget);
    expect(find.byType(AnimatedGradientBorder), findsOneWidget);

    await tester.tap(find.text('U.S. Blues'));
    await tester.pump();

    expect(audioProvider.seekRequests, [2]);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run from `packages/shakedown_core`:

```bash
flutter test test/ui/widgets/playback/track_list_view_test.dart
```

Expected: FAIL because `TrackListView` still owns internal grouping logic and no extracted widgets exist yet.

- [ ] **Step 3: Write the minimal implementation**

Create the set-header and tile widgets, then simplify `TrackListView` so it
consumes `buildTrackListLayout(source)` and branches only on typed items.

```dart
class TrackListSetHeader extends StatelessWidget {
  const TrackListSetHeader({
    super.key,
    required this.setName,
    required this.isFruit,
  });

  final String setName;
  final bool isFruit;

  @override
  Widget build(BuildContext context) {
    return isFruit
        ? Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(setName, style: Theme.of(context).textTheme.titleSmall),
          )
        : Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(setName, style: Theme.of(context).textTheme.titleSmall),
          );
  }
}

class TrackListTile extends StatelessWidget {
  const TrackListTile({
    super.key,
    required this.track,
    required this.trackIndex,
    required this.isPlaying,
    required this.onTap,
    required this.onLongPress,
  });

  final Track track;
  final int trackIndex;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text('${track.trackNumber}. ${track.title}'),
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
```

Update `track_list_view.dart` so the grouping block becomes:

```dart
final layout = buildTrackListLayout(source);
final firstTrackListIndex = layout.trackIndexToItemIndex[0] ?? 1;
final lastTrackListIndex =
    layout.trackIndexToItemIndex[source.tracks.length - 1] ??
    (layout.items.length - 1);
```

And the list builder becomes:

```dart
itemBuilder: (context, index) {
  final item = layout.items[index];
  if (item is TrackListSetHeaderItem) {
    return TrackListSetHeader(
      setName: item.setName,
      isFruit: isFruit,
    );
  }
  if (item is TrackListTrackItem) {
    return _buildTrackItem(
      context,
      audioProvider,
      item.track,
      item.trackIndex,
      index,
      isTrueBlackMode,
      firstTrackListIndex,
      lastTrackListIndex,
      ValueKey('track_${item.track.trackNumber}_${item.track.title}_$index'),
    );
  }
  return const SizedBox.shrink();
}
```

Keep the existing TV focus, RGB highlight, loading state, and long-press safety
reset logic intact. The refactor goal is ownership cleanup, not feature loss.

- [ ] **Step 4: Run the focused widget test**

Run from `packages/shakedown_core`:

```bash
flutter test test/ui/widgets/playback/track_list_view_test.dart
```

Expected: PASS with ordered headers present, one active-track highlight, and the
recorded seek call matching the tapped track index.

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/ui/widgets/playback/track_list_set_header.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_tile.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart packages/shakedown_core/test/ui/widgets/playback/track_list_view_test.dart
git commit -m "refactor: split track list view rendering"
```

### Task 3: Refactor `TrackListScreen` To Reuse Shared Layout Data

**Files:**
- Modify: `packages/shakedown_core/lib/ui/screens/track_list_screen.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart`
- Test: `packages/shakedown_core/test/screens/track_list_screen_test.dart`

- [ ] **Step 1: Write the failing screen test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/test/helpers/test_helpers.dart';
import 'package:shakedown_core/ui/screens/track_list_screen.dart';

class _IdleAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('TrackListScreen renders grouped sets and empty state without dynamic sentinels', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    final source = Source(
      id: 'gd77-05-08.sbd',
      tracks: const [
        Track(trackNumber: 1, title: 'Bertha', duration: 365, url: 'https://archive.org/1.mp3', setName: 'Set 1'),
        Track(trackNumber: 2, title: 'U.S. Blues', duration: 310, url: 'https://archive.org/2.mp3', setName: 'Encore'),
      ],
    );
    final show = Show(
      name: '1977-05-08',
      artist: 'Grateful Dead',
      date: '1977-05-08',
      venue: 'Barton Hall',
      sources: [source],
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(prefs),
          ),
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<DeviceService>.value(value: MockDeviceService()),
          ChangeNotifierProvider<AudioProvider>(
            create: (_) => _IdleAudioProvider(),
          ),
          ChangeNotifierProvider<ShowListProvider>(
            create: (_) => ShowListProvider(),
          ),
        ],
        child: MaterialApp(home: TrackListScreen(show: show, source: source)),
      ),
    );

    await tester.pump();

    expect(find.text('Set 1'), findsOneWidget);
    expect(find.text('Encore'), findsOneWidget);
    expect(find.text('No tracks available for this show.'), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run from `packages/shakedown_core`:

```bash
flutter test test/screens/track_list_screen_test.dart
```

Expected: FAIL until `track_list_screen_build.dart` stops owning its own
`List<dynamic>` grouping path and the test harness is completed.

- [ ] **Step 3: Write the minimal implementation**

Add the new playback-widget imports to `track_list_screen.dart`, then replace
the local grouping logic in `track_list_screen_build.dart` with the shared
layout builder.

```dart
final layout = buildTrackListLayout(widget.source, includeShowHeader: true);

if (themeProvider.themeStyle == ThemeStyle.fruit) {
  return _buildFruitBody(context, layout.items, bottomPadding);
}

return ListView.builder(
  padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding),
  itemCount: layout.items.length,
  itemBuilder: (context, index) {
    final item = layout.items[index];
    if (item is TrackListShowHeaderItem) {
      return _buildShowHeader(context);
    }
    if (item is TrackListSetHeaderItem) {
      return TrackListSetHeader(
        setName: item.setName,
        isFruit: false,
      );
    }
    if (item is TrackListTrackItem) {
      return _buildTrackItem(
        context,
        item.track,
        widget.source,
        item.trackIndex,
      );
    }
    return const SizedBox.shrink();
  },
);
```

Update `_buildFruitBody` to iterate typed items and ignore only
`TrackListShowHeaderItem`, because the Fruit overlay header already owns that
visual slot.

- [ ] **Step 4: Run the focused screen test**

Run from `packages/shakedown_core`:

```bash
flutter test test/screens/track_list_screen_test.dart
```

Expected: PASS with grouped sets still visible and no empty-state regression.

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/ui/screens/track_list_screen.dart packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart packages/shakedown_core/test/screens/track_list_screen_test.dart
git commit -m "refactor: share track list layout in screen build"
```

### Task 4: Tighten Imports, Format, Analyze, And Run The Targeted Suite

**Files:**
- Modify: `packages/shakedown_core/lib/ui/widgets/playback/track_list_items.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/playback/track_list_set_header.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/playback/track_list_tile.dart`
- Modify: `packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/track_list_screen.dart`
- Modify: `packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart`
- Test: `packages/shakedown_core/test/ui/widgets/playback/track_list_items_test.dart`
- Test: `packages/shakedown_core/test/ui/widgets/playback/track_list_view_test.dart`
- Test: `packages/shakedown_core/test/screens/track_list_screen_test.dart`

- [ ] **Step 1: Format the touched files**

Run from repo root:

```bash
dart format packages/shakedown_core/lib/ui/widgets/playback/track_list_items.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_set_header.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_tile.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart packages/shakedown_core/lib/ui/screens/track_list_screen.dart packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart packages/shakedown_core/test/ui/widgets/playback/track_list_items_test.dart packages/shakedown_core/test/ui/widgets/playback/track_list_view_test.dart packages/shakedown_core/test/screens/track_list_screen_test.dart
```

Expected: formatter rewrites only style issues.

- [ ] **Step 2: Run targeted analysis**

Run from repo root:

```bash
dart analyze packages/shakedown_core/lib/ui/widgets/playback/track_list_items.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_set_header.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_tile.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart packages/shakedown_core/lib/ui/screens/track_list_screen.dart packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart packages/shakedown_core/test/ui/widgets/playback/track_list_items_test.dart packages/shakedown_core/test/ui/widgets/playback/track_list_view_test.dart packages/shakedown_core/test/screens/track_list_screen_test.dart
```

Expected: `No issues found!`

- [ ] **Step 3: Run the targeted test suite**

Run from `packages/shakedown_core`:

```bash
flutter test test/ui/widgets/playback/track_list_items_test.dart
flutter test test/ui/widgets/playback/track_list_view_test.dart
flutter test test/screens/track_list_screen_test.dart
```

Expected: PASS for all three test files.

- [ ] **Step 4: Run one adjacent regression test for playback widgets**

Run from `packages/shakedown_core`:

```bash
flutter test test/ui/widgets/playback/fruit_now_playing_card_loading_state_test.dart
```

Expected: PASS, confirming the refactor did not destabilize nearby playback
widget dependencies.

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/ui/widgets/playback/track_list_items.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_set_header.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_tile.dart packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart packages/shakedown_core/lib/ui/screens/track_list_screen.dart packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart packages/shakedown_core/test/ui/widgets/playback/track_list_items_test.dart packages/shakedown_core/test/ui/widgets/playback/track_list_view_test.dart packages/shakedown_core/test/screens/track_list_screen_test.dart
git commit -m "refactor: clean up track list feature structure"
```
