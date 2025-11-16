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

import 'playback_screen_test.mocks.dart';

@GenerateMocks([AudioProvider, SettingsProvider, AudioPlayer])
void main() {
  late MockAudioProvider mockAudioProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockAudioPlayer mockAudioPlayer;

  // Dummy data
  final dummyTrack1 = Track(trackNumber: 1, title: 'Track 1', duration: 100, url: '');
  final dummyTrack2 = Track(trackNumber: 2, title: 'Track 2', duration: 120, url: '');
  final dummySource = Source(id: 'source1', tracks: [dummyTrack1, dummyTrack2]);
  final dummyShow = Show(
    name: 'Venue A on 2025-01-15',
    artist: 'Grateful Dead',
    date: '2025-01-15',
    year: '2025',
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
    when(mockAudioPlayer.playerState).thenReturn(PlayerState(false, ProcessingState.idle));
    
    // Stub default return values for streams to avoid null errors
    when(mockAudioProvider.playerStateStream).thenAnswer((_) => Stream.value(PlayerState(false, ProcessingState.idle)));
    when(mockAudioProvider.currentIndexStream).thenAnswer((_) => Stream.value(0));
    when(mockAudioProvider.durationStream).thenAnswer((_) => Stream.value(const Duration(seconds: 100)));
    when(mockAudioProvider.positionStream).thenAnswer((_) => Stream.value(Duration.zero));
    when(mockAudioProvider.bufferedPositionStream).thenAnswer((_) => Stream.value(Duration.zero));

    // Stub settings provider values
    when(mockSettingsProvider.scaleTrackList).thenReturn(false);
    when(mockSettingsProvider.scalePlayer).thenReturn(false);
    when(mockSettingsProvider.showSingleShnid).thenReturn(false);
    when(mockSettingsProvider.showTrackNumbers).thenReturn(false);
  });

  Widget createTestableWidget({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<SettingsProvider>.value(value: mockSettingsProvider),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  testWidgets('PlaybackScreen shows "No show selected" when currentShow is null', (WidgetTester tester) async {
    when(mockAudioProvider.currentShow).thenReturn(null);
    when(mockAudioProvider.currentSource).thenReturn(null);

    await tester.pumpWidget(createTestableWidget(child: const PlaybackScreen()));

    expect(find.text('No show selected.'), findsOneWidget);
  });

  testWidgets('PlaybackScreen displays show and track information', (WidgetTester tester) async {
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);

    await tester.pumpWidget(createTestableWidget(child: const PlaybackScreen()));

    expect(find.text(dummyShow.venue), findsOneWidget);
    expect(find.text(dummyShow.formattedDate), findsOneWidget);
    
    // The track title is displayed in the list and in the bottom controls
    expect(find.byWidgetPredicate((widget) => widget is Text && widget.data == dummyTrack1.title), findsNWidgets(2));
    expect(find.byWidgetPredicate((widget) => widget is Text && widget.data == dummyTrack2.title), findsOneWidget);
  });

  testWidgets('Tapping a non-playing track seeks to it', (WidgetTester tester) async {
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioPlayer.currentIndex).thenReturn(0); // Currently playing the first track

    await tester.pumpWidget(createTestableWidget(child: const PlaybackScreen()));

    await tester.tap(find.text(dummyTrack2.title));
    
    verify(mockAudioProvider.seekToTrack(1)).called(1);
  });

  testWidgets('Play/pause button toggles playback', (WidgetTester tester) async {
    final playerStateController = StreamController<PlayerState>.broadcast();
    when(mockAudioProvider.currentShow).thenReturn(dummyShow);
    when(mockAudioProvider.currentSource).thenReturn(dummySource);
    when(mockAudioProvider.playerStateStream).thenAnswer((_) => playerStateController.stream);
    
    // Test playing state
    await tester.pumpWidget(createTestableWidget(child: const PlaybackScreen()));
    playerStateController.add(PlayerState(true, ProcessingState.ready));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.pause_rounded));
    verify(mockAudioProvider.pause()).called(1);

    // Test paused state
    playerStateController.add(PlayerState(false, ProcessingState.ready));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    verify(mockAudioProvider.play()).called(1);

    playerStateController.close();
  });
}
