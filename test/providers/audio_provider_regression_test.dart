import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'audio_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<AudioPlayer>(
      as: #MockAudioPlayerRelaxed, onMissingStub: OnMissingStub.returnDefault),
  MockSpec<ShowListProvider>(),
  MockSpec<SettingsProvider>(),
])
void main() {
  late AudioProvider audioProvider;
  late MockAudioPlayerRelaxed mockAudioPlayer;
  late MockShowListProvider mockShowListProvider;
  late MockSettingsProvider mockSettingsProvider;

  // Stream Controllers for mocks
  late StreamController<ProcessingState> processingStateController;
  late StreamController<Duration> positionController;
  late StreamController<int?> currentIndexController;
  late StreamController<List<IndexedAudioSource>> sequenceController;

  setUp(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '.';
    });

    mockSettingsProvider = MockSettingsProvider();
    mockShowListProvider = MockShowListProvider();
    mockAudioPlayer = MockAudioPlayerRelaxed();

    processingStateController = StreamController<ProcessingState>.broadcast();
    positionController = StreamController<Duration>.broadcast();
    currentIndexController = StreamController<int?>.broadcast();
    sequenceController = StreamController<List<IndexedAudioSource>>.broadcast();

    // Stub SettingsProvider methods
    when(mockSettingsProvider.randomOnlyUnplayed).thenReturn(false);
    when(mockSettingsProvider.randomOnlyHighRated).thenReturn(false);
    when(mockSettingsProvider.randomExcludePlayed).thenReturn(false);
    when(mockSettingsProvider.playRandomOnCompletion).thenReturn(false);
    when(mockSettingsProvider.markAsPlayed(any)).thenAnswer((_) async {});
    when(mockSettingsProvider.showGlobalAlbumArt).thenReturn(true);
    when(mockSettingsProvider.getRating(any)).thenReturn(0);
    when(mockSettingsProvider.isPlayed(any)).thenReturn(false);

    // Stub AudioPlayer Streams
    when(mockAudioPlayer.processingStateStream)
        .thenAnswer((_) => processingStateController.stream);
    when(mockAudioPlayer.positionStream)
        .thenAnswer((_) => positionController.stream);
    when(mockAudioPlayer.currentIndexStream)
        .thenAnswer((_) => currentIndexController.stream);
    when(mockAudioPlayer.sequenceStream)
        .thenAnswer((_) => sequenceController.stream);

    // Default Stubs for other streams
    when(mockAudioPlayer.playbackEventStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockAudioPlayer.durationStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockAudioPlayer.bufferedPositionStream)
        .thenAnswer((_) => const Stream.empty());

    // Default return values
    when(mockAudioPlayer.duration).thenReturn(const Duration(seconds: 100));
    when(mockAudioPlayer.currentIndex).thenReturn(0);
    when(mockAudioPlayer.sequence).thenReturn([]);

    when(mockAudioPlayer.play()).thenAnswer((_) async {});
    when(mockAudioPlayer.stop()).thenAnswer((_) async {});
    when(mockAudioPlayer.setAudioSource(any,
            initialIndex: anyNamed('initialIndex'),
            preload: anyNamed('preload')))
        .thenAnswer((_) async => const Duration(seconds: 100));

    when(mockShowListProvider.isLoading).thenReturn(false);
    when(mockShowListProvider.allShows).thenReturn([]);
    when(mockShowListProvider.initializationComplete).thenAnswer((_) async {});
    when(mockShowListProvider.isSourceAllowed(any)).thenReturn(true);

    // Create AudioProvider
    audioProvider = AudioProvider(audioPlayer: mockAudioPlayer);
    audioProvider.update(mockShowListProvider, mockSettingsProvider);
  });

  tearDown(() {
    processingStateController.close();
    positionController.close();
    currentIndexController.close();
    sequenceController.close();
    audioProvider.dispose();
  });

  Show createDummyShow(int id, {int sourceCount = 1}) {
    return Show(
      name: 'Grateful Dead at Venue $id on 2025-11-15',
      artist: 'Grateful Dead',
      date: '2025-11-15',
      venue: 'Venue $id',
      sources: List.generate(
        sourceCount,
        (i) => Source(
          id: 'source$i',
          tracks: [
            Track(
                trackNumber: 1,
                title: 'Track 1',
                url: 'http://track1.mp3',
                duration: 100,
                setName: 'Set 1'),
            Track(
                trackNumber: 2,
                title: 'Track 2',
                url: 'http://track2.mp3',
                duration: 120,
                setName: 'Set 1'),
          ],
        ),
      ),
    );
  }

  testWidgets(
      'Early Trigger: Plays next random show when near end of last track',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      // 1. Setup Settings
      when(mockSettingsProvider.playRandomOnCompletion).thenReturn(true);

      // 2. Setup Audio State for "End of Show"
      // 100s duration. Threshold is duration - 0.25s = 99.75s
      when(mockAudioPlayer.duration).thenReturn(const Duration(seconds: 100));

      // Sequence of 2 tracks. Index 1 is the last track.
      final sequence = [
        AudioSource.uri(Uri.parse('http://dummy/1')),
        AudioSource.uri(Uri.parse('http://dummy/2'))
      ];
      when(mockAudioPlayer.sequence).thenReturn(sequence);
      // Current index is last track
      when(mockAudioPlayer.currentIndex).thenReturn(1);

      // 3. Setup Show List for Random Pick
      final show = createDummyShow(1);
      when(mockShowListProvider.filteredShows).thenReturn([show]);
      when(mockShowListProvider.allShows).thenReturn([show]);

      // 4. Emit Position Update causing trigger
      // 99.8s > 99.75s threshold
      positionController.add(const Duration(milliseconds: 99800));

      // Wait for async operations
      await Future.delayed(const Duration(milliseconds: 50));

      // 5. Verify Random Show Triggered
      verify(mockAudioPlayer.setAudioSource(any,
              initialIndex: 0, preload: false))
          .called(1);
    });
  });
}
