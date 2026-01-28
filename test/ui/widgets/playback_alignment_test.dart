import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:hive/hive.dart';
import 'package:shakedown/models/rating.dart';
import 'package:shakedown/services/catalog_service.dart';

import 'mini_player_test.mocks.dart'; // Reuse mocks

class FakeCatalogService extends Fake implements CatalogService {
  final ValueNotifier<Box<bool>> _history;
  final ValueNotifier<Box<Rating>> _ratings;

  FakeCatalogService(Box<bool> historyBox, Box<Rating> ratingsBox)
      : _history = ValueNotifier(historyBox),
        _ratings = ValueNotifier(ratingsBox);

  @override
  ValueListenable<Box<bool>> get historyListenable => _history;

  @override
  ValueListenable<Box<Rating>> get ratingsListenable => _ratings;

  @override
  int getRating(String id) => 0;

  @override
  bool isPlayed(String id) => false;
}

class MockBox<T> extends Mock implements Box<T> {}

@GenerateMocks([Box])
void main() {
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockAudioPlayer mockAudioPlayer;
  late FakeCatalogService fakeCatalogService;
  late MockBox<bool> mockHistoryBox;
  late MockBox<Rating> mockRatingsBox;

  setUp(() {
    mockAudioProvider = MockAudioProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockAudioPlayer = MockAudioPlayer();

    mockHistoryBox = MockBox<bool>();
    mockRatingsBox = MockBox<Rating>();
    fakeCatalogService = FakeCatalogService(mockHistoryBox, mockRatingsBox);

    // Inject Fake Service
    CatalogService.setMock(fakeCatalogService);

    // Stub Box methods called by UI
    when(mockHistoryBox.get(any)).thenReturn(false);
    when(mockRatingsBox.get(any)).thenReturn(null);

    // Audio Provider setup
    when(mockAudioProvider.audioPlayer).thenReturn(mockAudioPlayer);
    when(mockAudioProvider.playbackErrorStream)
        .thenAnswer((_) => Stream.value(''));
    when(mockAudioProvider.currentIndexStream)
        .thenAnswer((_) => Stream.value(0));
    when(mockAudioPlayer.currentIndex).thenReturn(0);
    when(mockAudioProvider.positionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(mockAudioProvider.durationStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(mockAudioProvider.bufferedPositionStream)
        .thenAnswer((_) => Stream.value(Duration.zero));
    when(mockAudioProvider.playerStateStream).thenAnswer(
        (_) => Stream.value(PlayerState(false, ProcessingState.ready)));
    when(mockAudioPlayer.sequenceStateStream).thenAnswer((_) => Stream.empty());
    when(mockAudioPlayer.playerState)
        .thenReturn(PlayerState(false, ProcessingState.ready));

    // Settings Provider setup
    when(mockSettingsProvider.useTrueBlack).thenReturn(false);
    when(mockSettingsProvider.highlightCurrentShowCard).thenReturn(true);
    when(mockSettingsProvider.appFont).thenReturn('roboto');
    when(mockSettingsProvider.uiScale).thenReturn(false);
    when(mockSettingsProvider.showDayOfWeek).thenReturn(true);
    when(mockSettingsProvider.abbreviateDayOfWeek).thenReturn(true);
    when(mockSettingsProvider.abbreviateMonth).thenReturn(true);
    when(mockSettingsProvider.showTrackNumbers).thenReturn(true);
    when(mockSettingsProvider.hideTrackDuration).thenReturn(false);
    when(mockSettingsProvider.highlightPlayingWithRgb)
        .thenReturn(true); // RGB ENABLED
    when(mockSettingsProvider.glowMode).thenReturn(50);
    when(mockSettingsProvider.rgbAnimationSpeed).thenReturn(1.0);
    when(mockSettingsProvider.showSingleShnid).thenReturn(false);
  });

  testWidgets(
      'Track title vertical position stays stable when toggling play state',
      (tester) async {
    // Setup Data
    final track1 = Track(
        trackNumber: 1,
        title: 'Track One',
        duration: 300,
        url: 'u1',
        setName: 'Set 1');
    final track2 = Track(
        trackNumber: 2,
        title: 'Track Two',
        duration: 300,
        url: 'u2',
        setName: 'Set 1');
    final source = Source(id: 's1', src: 'SBD', tracks: [track1, track2]);
    final show = Show(
        name: 'Show 1',
        artist: 'Band',
        date: '2022-01-01',
        venue: 'Venue',
        sources: [source]);

    when(mockAudioProvider.currentShow).thenReturn(show);
    when(mockAudioProvider.currentSource).thenReturn(source);

    // Scenario 1: Track 1 is PLAYING
    when(mockAudioProvider.currentTrack).thenReturn(track1);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: mockSettingsProvider),
        ],
        child: MaterialApp(
          home: PlaybackScreen(),
        ),
      ),
    );
    // Allow animations to start but don't wait forever
    await tester.pump(const Duration(milliseconds: 500));

    // Find Track 1 Title Text Position
    // Use a more generic finder if direct text match fails due to styling
    final track1TitleFinder = find.textContaining('Track One');
    expect(track1TitleFinder, findsOneWidget);

    final track1RectPlaying = tester.getRect(track1TitleFinder);

    // Scenario 2: Track 2 is PLAYING (Track 1 is NOT playing)
    // We update the mock and rebuild
    when(mockAudioProvider.currentTrack).thenReturn(track2);
    // Trigger rebuild
    mockAudioProvider.notifyListeners();

    // Trigger rebuild
    mockAudioProvider.notifyListeners();
    await tester.pump(const Duration(milliseconds: 500));

    final track1RectNotPlaying = tester.getRect(track1TitleFinder);

    print('Playing Rect: $track1RectPlaying');
    print('Not Playing Rect: $track1RectNotPlaying');
    print(
        'Vertical Diff: ${(track1RectPlaying.top - track1RectNotPlaying.top).abs()}');
    print(
        'Horizontal Diff: ${(track1RectPlaying.left - track1RectNotPlaying.left).abs()}');

    // COMPARE POSITIONS

    // Assert Vertical Stability
    expect(
        (track1RectPlaying.top - track1RectNotPlaying.top).abs(), lessThan(3.0),
        reason:
            'Vertical position shifted between playing/stopped (Diff: ${(track1RectPlaying.top - track1RectNotPlaying.top)})');

    // Assert Horizontal Stability (Left Alignment)
    expect((track1RectPlaying.left - track1RectNotPlaying.left).abs(),
        lessThan(1.0),
        reason:
            'Horizontal position shifted between playing/stopped (Diff: ${(track1RectPlaying.left - track1RectNotPlaying.left)})');
  });
}
