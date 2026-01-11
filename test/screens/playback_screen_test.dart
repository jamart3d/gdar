import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/screens/playback_screen.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:gdar/ui/widgets/rating_control.dart';

import 'playback_screen_test.mocks.dart';

class MockSettingsProvider extends Mock implements SettingsProvider {
  @override
  bool get sortOldestFirst => true;
  @override
  void toggleSortOldestFirst() {}

  @override
  bool get uiScale => false;
  @override
  bool get showSingleShnid => false;
  @override
  bool get showTrackNumbers => false;
  @override
  int get glowMode => 0;

  @override
  bool get useTrueBlack => false;
  @override
  bool get highlightPlayingWithRgb => false;
  @override
  bool get showPlaybackMessages => false;
  // useHandwritingFont removed
  @override
  bool get useDynamicColor => false;
  // halfGlowDynamic removed
  @override
  double get rgbAnimationSpeed => 1.0;
  @override
  Color? get seedColor => null;
  @override
  bool get showSplashScreen => false;
  @override
  bool get dateFirstInShowCard => true;
  @override
  bool get playOnTap => false;
  @override
  bool get playRandomOnCompletion => false;
  @override
  bool get playRandomOnStartup => false;
  @override
  bool get useSliverAppBar => false;
  @override
  bool get useSharedAxisTransition => false;
  @override
  bool get hideTrackCountInSourceList => false;
  @override
  bool get highlightCurrentShowCard => false;
  @override
  bool get useMaterial3 => true;
  @override
  bool get showExpandIcon => false;
  @override
  set showExpandIcon(bool value) {}

  // New Getters that were missing
  @override
  bool get showDayOfWeek => true;
  @override
  bool get abbreviateDayOfWeek => true;
  @override
  bool get abbreviateMonth => true;

  @override
  void toggleShowSplashScreen() {}
  @override
  void toggleShowTrackNumbers() {}
  @override
  void togglePlayOnTap() {}
  @override
  void toggleShowSingleShnid() {}
  @override
  void togglePlayRandomOnCompletion() {}
  @override
  void togglePlayRandomOnStartup() {}
  @override
  void toggleDateFirstInShowCard() {}
  @override
  void toggleUseDynamicColor() {}
  @override
  String get appFont => 'default';
  @override
  void setAppFont(String font) {}
  @override
  void toggleUiScale() {}
  @override
  void setGlowMode(int mode) {}
  @override
  void toggleHighlightPlayingWithRgb() {}
  @override
  void toggleShowPlaybackMessages() {}
  // toggleHalfGlowDynamic removed
  @override
  void setRgbAnimationSpeed(double speed) {}
  @override
  Future<void> setSeedColor(Color? color) async {}

  @override
  Map<String, int> get showRatings => {};
  @override
  Set<String> get playedShows => {};
  @override
  bool get randomOnlyUnplayed => false;
  @override
  bool get randomOnlyHighRated => false;

  @override
  int getRating(String showName) => 0;
  @override
  bool isPlayed(String showName) => false;
  @override
  Future<void> setRating(String showName, int rating) async {}
  @override
  Future<void> togglePlayed(String showName) async {}
  @override
  Future<void> markAsPlayed(String showName) async {}
  @override
  void toggleRandomOnlyUnplayed() {}
  @override
  void toggleRandomOnlyHighRated() {}
  @override
  bool get hideTrackDuration => false;
  @override
  bool get randomExcludePlayed => false;
  @override
  void toggleRandomExcludePlayed() {}
  @override
  bool get showGlobalAlbumArt => true;
}

@GenerateMocks([AudioProvider, AudioPlayer])
void main() {
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockAudioPlayer mockAudioPlayer;

  // Dummy data
  final dummyTrack1 = Track(
      trackNumber: 1,
      title: 'Track 1',
      duration: 100,
      url: '',
      setName: 'Set 1');
  final dummyTrack2 = Track(
      trackNumber: 2,
      title: 'Track 2',
      duration: 120,
      url: '',
      setName: 'Set 1');
  final dummySource = Source(id: 'source1', tracks: [dummyTrack1, dummyTrack2]);
  final dummyShow = Show(
    name: 'Venue A on 2025-01-15',
    artist: 'Grateful Dead',
    date: '2025-01-15',
    venue: 'Venue A',
    sources: [dummySource],
  );

  setUp(() {
    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockAudioPlayer = MockAudioPlayer();

    // Stub the audio player on the audio provider
    when(mockAudioProvider.audioPlayer).thenReturn(mockAudioPlayer);
    when(mockAudioPlayer.currentIndex).thenReturn(0);
    when(mockAudioPlayer.position).thenReturn(Duration.zero);
    when(mockAudioPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(mockAudioPlayer.duration).thenReturn(const Duration(seconds: 100));
    when(mockAudioPlayer.playerState)
        .thenReturn(PlayerState(false, ProcessingState.idle));

    // Stub default return values for streams to avoid null errors
    when(mockAudioProvider.playerStateStream).thenAnswer(
        (_) => Stream.value(PlayerState(false, ProcessingState.idle)));
    when(mockAudioProvider.currentIndexStream)
        .thenAnswer((_) => Stream.value(0));
    when(mockAudioProvider.durationStream)
        .thenAnswer((_) => Stream.value(const Duration(seconds: 100)));
    when(mockAudioProvider.positionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(mockAudioProvider.bufferedPositionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(mockAudioProvider.playbackErrorStream)
        .thenAnswer((_) => Stream.value(''));
    when(mockAudioProvider.currentTrack).thenReturn(null);
  });

  Widget createTestableWidget({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets(
      'PlaybackScreen shows "No show selected" when currentShow is null',
      (WidgetTester tester) async {
    when(mockAudioProvider.currentShow).thenReturn(null);
    when(mockAudioProvider.currentSource).thenReturn(null);

    await tester
        .pumpWidget(createTestableWidget(child: const PlaybackScreen()));

    expect(find.text('No show selected.'), findsOneWidget);
  });

  testWidgets('PlaybackScreen displays show and track information',
      (WidgetTester tester) async {
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);

    await tester
        .pumpWidget(createTestableWidget(child: const PlaybackScreen()));

    // Venue is displayed twice (at least): AppBar and Panel
    // Date is displayed twice (at least): AppBar and Panel
    // Date is displayed twice (at least): AppBar and Panel
    expect(find.textContaining('Jan 15, 2025'), findsAtLeastNWidgets(1));

    // The track title is displayed in the list and in the bottom controls
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == dummyTrack1.title),
        findsAtLeastNWidgets(1));
    expect(
        find.byWidgetPredicate(
            (widget) => widget is Text && widget.data == dummyTrack2.title),
        findsAtLeastNWidgets(1));
  });

  testWidgets('Tapping a non-playing track seeks to it',
      (WidgetTester tester) async {
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioPlayer.currentIndex)
        .thenReturn(0); // Currently playing the first track
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);

    await tester
        .pumpWidget(createTestableWidget(child: const PlaybackScreen()));

    await tester.tap(find.text(dummyTrack2.title));

    verify(mockAudioProvider.seekToTrack(1)).called(1);
  });

  testWidgets('PlaybackScreen displays rating control',
      (WidgetTester tester) async {
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioProvider.currentTrack).thenReturn(dummyTrack1);

    await tester
        .pumpWidget(createTestableWidget(child: const PlaybackScreen()));

    // Verify basic content is present (Date should be visible)
    expect(find.textContaining('Jan'), findsAtLeastNWidgets(1),
        reason: 'Date should be visible');

    // Verify RatingControl is present
    expect(find.byType(RatingControl), findsAtLeastNWidgets(1),
        reason: 'RatingControl widget should be present');

    // Should find 3 star_border icons (RatingControl default is 0, appearing in AppBar)
    // Note: If finding icons fails but RatingControl is present, check flutter_rating_bar implementation
    expect(find.byIcon(Icons.star_border), findsAtLeastNWidgets(3));
  });
}
