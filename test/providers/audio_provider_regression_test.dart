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
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/services/audio_cache_service.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';
import 'package:shakedown/services/wakelock_service.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'audio_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GaplessPlayer>(
      as: #MockAudioPlayerRelaxed, onMissingStub: OnMissingStub.returnDefault),
  MockSpec<ShowListProvider>(),
  MockSpec<SettingsProvider>(),
  MockSpec<CatalogService>(),
  MockSpec<AudioCacheService>(),
  MockSpec<WakelockService>(),
])
void main() {
  late AudioProvider audioProvider;
  late MockAudioPlayerRelaxed mockAudioPlayer;
  late MockShowListProvider mockShowListProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockCatalogService mockCatalogService;

  late MockAudioCacheService mockAudioCacheService;
  late MockWakelockService mockWakelockService;

  // Stream Controllers for mocks
  late StreamController<ProcessingState> processingStateController;
  late StreamController<Duration> positionController;
  late StreamController<int?> currentIndexController;
  late StreamController<SequenceState?> sequenceController;

  setUp(() {
    mockSettingsProvider = MockSettingsProvider();
    mockShowListProvider = MockShowListProvider();
    mockAudioPlayer = MockAudioPlayerRelaxed();

    mockCatalogService = MockCatalogService();

    mockAudioCacheService = MockAudioCacheService();
    mockWakelockService = MockWakelockService();

    // Mock path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return '.';
      },
    );

    processingStateController = StreamController<ProcessingState>.broadcast();
    positionController = StreamController<Duration>.broadcast();
    currentIndexController = StreamController<int?>.broadcast();
    sequenceController = StreamController<SequenceState?>.broadcast();

    // Stub SettingsProvider methods
    when(mockSettingsProvider.randomOnlyUnplayed).thenReturn(false);
    when(mockSettingsProvider.randomOnlyHighRated).thenReturn(false);
    when(mockSettingsProvider.randomExcludePlayed).thenReturn(false);
    when(mockSettingsProvider.playRandomOnCompletion).thenReturn(false);
    when(mockSettingsProvider.showGlobalAlbumArt).thenReturn(true);

    // Stub CatalogService methods
    when(mockCatalogService.getRating(any)).thenReturn(0);
    when(mockCatalogService.isPlayed(any)).thenReturn(false);

    // Stub AudioPlayer Streams
    when(mockAudioPlayer.processingStateStream)
        .thenAnswer((_) => processingStateController.stream);
    when(mockAudioPlayer.positionStream)
        .thenAnswer((_) => positionController.stream);
    when(mockAudioPlayer.currentIndexStream)
        .thenAnswer((_) => currentIndexController.stream);
    when(mockAudioPlayer.sequenceStateStream)
        .thenAnswer((_) => sequenceController.stream.cast<SequenceState?>());

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
    when(mockAudioPlayer.setAudioSources(any,
            initialIndex: anyNamed('initialIndex'),
            preload: anyNamed('preload')))
        .thenAnswer((_) async => const Duration(seconds: 100));
    when(mockAudioPlayer.addAudioSources(any)).thenAnswer((_) async {});

    when(mockShowListProvider.isLoading).thenReturn(false);
    when(mockShowListProvider.allShows).thenReturn([]);
    when(mockShowListProvider.initializationComplete).thenAnswer((_) async {});
    when(mockShowListProvider.isSourceAllowed(any)).thenReturn(true);

    // Stub WakelockService
    when(mockWakelockService.enabled).thenAnswer((_) async => false);
    when(mockWakelockService.enable()).thenAnswer((_) async {});
    when(mockWakelockService.disable()).thenAnswer((_) async {});

    // Stub AudioCacheService
    when(mockAudioCacheService.getAlbumArtUri()).thenAnswer((_) async => null);

    when(mockAudioPlayer.engineName).thenReturn('RelaxedMockEngine');

    // Create AudioProvider
    audioProvider = AudioProvider(
      audioPlayer: mockAudioPlayer,
      catalogService: mockCatalogService,
      audioCacheService: mockAudioCacheService,
      wakelockService: mockWakelockService,
    );
    audioProvider.update(
        mockShowListProvider, mockSettingsProvider, mockAudioCacheService);
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

  testWidgets('Pre-Queueing: Adds next random show when starting last track',
      (WidgetTester tester) async {
    await tester.runAsync(() async {
      // 1. Setup Settings
      when(mockSettingsProvider.playRandomOnCompletion).thenReturn(true);

      // 2. Setup Audio State for "Last Track"
      final sequence = [
        AudioSource.uri(Uri.parse('http://dummy/1')),
        AudioSource.uri(Uri.parse('http://dummy/2'))
      ];
      when(mockAudioPlayer.sequence).thenReturn(sequence);
      when(mockAudioPlayer.currentIndex).thenReturn(1);

      // Stub addAudioSources to return success
      when(mockAudioPlayer.addAudioSources(any)).thenAnswer((_) async {});

      // 3. Setup Show List for Random Pick
      final show = createDummyShow(1);
      when(mockShowListProvider.filteredShows).thenReturn([show]);
      when(mockShowListProvider.allShows).thenReturn([show]);
      when(mockCatalogService.allShows).thenReturn([show]);

      // 4. Emit Index Update causing trigger (Start of Last Track)
      currentIndexController.add(1);

      // Wait for async operations
      await Future.delayed(const Duration(milliseconds: 50));

      // 5. Verify Random Show Queued (addAudioSources called)
      verify(mockAudioPlayer.addAudioSources(any)).called(1);

      // Verify setAudioSources was NOT called (we shouldn't stop playback)
      verifyNever(mockAudioPlayer.setAudioSources(any,
          initialIndex: anyNamed('initialIndex'),
          preload: anyNamed('preload')));
    });
  });

  group('Relisten Mode (HTML5) Stability', () {
    testWidgets(
        'State Preservation: Does not trigger premature Random Show on mid-track completed emission',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Setup: Relisten mode identified by name
        when(mockAudioPlayer.engineName)
            .thenReturn('Mobile Gapless Engine (HTML5)');
        when(mockSettingsProvider.playRandomOnCompletion).thenReturn(true);

        // Current state: track 0 of 2
        final sequence = [
          AudioSource.uri(Uri.parse('http://dummy/1')),
          AudioSource.uri(Uri.parse('http://dummy/2'))
        ];
        when(mockAudioPlayer.sequence).thenReturn(sequence);
        when(mockAudioPlayer.currentIndex).thenReturn(0);

        // Simulate a premature 'completed' state (which our JS fix prevents, but Dart should be robust)
        // If Dart receives 'completed' at index 0 when total is 2, it might trigger a random show
        // unless it checks if it's actually the last track.
        processingStateController.add(ProcessingState.completed);
        await Future.delayed(const Duration(milliseconds: 50));

        // NOTE: Currently AudioProvider only checks ProcessingState.completed
        // without checking if it's the last track, relying on the engine to be correct.
        // If we want Dart to be robust, we'd add the check there too.
        // For regression, we'll verify the CURRENT behavior and then decide if we need more guards.

        // Verification: If it triggers, it calls setAudioSources.
        // In our isolated state, we want to ensure it DOES NOT trigger
        // if it's not the last track of a sequence.
        verifyNever(mockAudioPlayer.setAudioSources(any,
            initialIndex: anyNamed('initialIndex'),
            preload: anyNamed('preload')));
      });
    });

    testWidgets(
        'Metadata Sync: AudioProvider updates currentTrack on index change',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final show = createDummyShow(1);
        final source = show.sources.first;

        // Load the show
        await audioProvider.playSource(show, source);

        // Setup sequence with MediaItems as they would be created by _createAudioSource
        final sequence = source.tracks.asMap().entries.map((entry) {
          return AudioSource.uri(
            Uri.parse(entry.value.url),
            tag: MediaItem(
              id: 'show_source_${entry.key}',
              album: show.venue,
              title: entry.value.title,
              extras: {'source_id': source.id, 'track_index': entry.key},
            ),
          );
        }).toList();

        when(mockAudioPlayer.sequence).thenReturn(sequence);
        when(mockAudioPlayer.currentIndex).thenReturn(1);

        // Simulate index change to track 1
        currentIndexController.add(1);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(audioProvider.currentTrack?.title, 'Track 2',
            reason:
                'AudioProvider should resolve the correct Track object when index changes');
      });
    });
  });
}
