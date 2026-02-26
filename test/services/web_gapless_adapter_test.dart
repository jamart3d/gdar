// ignore: dangling_library_doc_comments
/// Regression tests for the Web Gapless Player adapter contract.
///
/// Since `gapless_player_web.dart` depends on `dart:js_interop` (browser-only),
/// we test the **contract** that `AudioProvider` depends on: stream emissions
/// from the mock player that simulate the web adapter's behavior.
import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/mockito.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';

import '../providers/audio_provider_test.mocks.dart';

void main() {
  late AudioProvider audioProvider;
  late MockAudioPlayerRelaxed mockPlayer;
  late MockShowListProvider mockShowListProvider;
  late MockSettingsProvider mockSettingsProvider;
  late MockCatalogService mockCatalogService;
  late MockAudioCacheService mockAudioCacheService;
  late MockWakelockService mockWakelockService;

  // Streams that simulate the web adapter emissions
  late StreamController<ProcessingState> processingStateController;
  late StreamController<bool> playingController;
  late StreamController<Duration> positionController;
  late StreamController<int?> currentIndexController;
  late StreamController<SequenceState?> sequenceController;
  late StreamController<PlaybackEvent> playbackEventController;
  late StreamController<PlayerState> playerStateController;

  setUp(() {
    mockPlayer = MockAudioPlayerRelaxed();
    mockShowListProvider = MockShowListProvider();
    mockSettingsProvider = MockSettingsProvider();
    mockCatalogService = MockCatalogService();
    mockAudioCacheService = MockAudioCacheService();
    mockWakelockService = MockWakelockService();

    // Mock path_provider
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => '.',
    );

    processingStateController = StreamController<ProcessingState>.broadcast();
    playingController = StreamController<bool>.broadcast();
    positionController = StreamController<Duration>.broadcast();
    currentIndexController = StreamController<int?>.broadcast();
    sequenceController = StreamController<SequenceState?>.broadcast();
    playbackEventController = StreamController<PlaybackEvent>.broadcast();
    playerStateController = StreamController<PlayerState>.broadcast();

    // Stub streams — mirrors what gapless_player_web.dart emits
    when(mockPlayer.processingStateStream)
        .thenAnswer((_) => processingStateController.stream);
    when(mockPlayer.playingStream).thenAnswer((_) => playingController.stream);
    when(mockPlayer.positionStream)
        .thenAnswer((_) => positionController.stream);
    when(mockPlayer.currentIndexStream)
        .thenAnswer((_) => currentIndexController.stream);
    when(mockPlayer.sequenceStateStream)
        .thenAnswer((_) => sequenceController.stream.cast<SequenceState?>());
    when(mockPlayer.playbackEventStream)
        .thenAnswer((_) => playbackEventController.stream);
    when(mockPlayer.playerStateStream)
        .thenAnswer((_) => playerStateController.stream);
    when(mockPlayer.durationStream).thenAnswer((_) => const Stream.empty());
    when(mockPlayer.bufferedPositionStream)
        .thenAnswer((_) => const Stream.empty());

    // Default property stubs
    when(mockPlayer.duration).thenReturn(const Duration(seconds: 100));
    when(mockPlayer.currentIndex).thenReturn(0);
    when(mockPlayer.sequence).thenReturn([]);
    when(mockPlayer.playing).thenReturn(false);
    when(mockPlayer.play()).thenAnswer((_) async {});
    when(mockPlayer.stop()).thenAnswer((_) async {});
    when(mockPlayer.setAudioSources(any,
            initialIndex: anyNamed('initialIndex'),
            preload: anyNamed('preload')))
        .thenAnswer((_) async => const Duration(seconds: 100));

    // Stub SettingsProvider
    when(mockSettingsProvider.randomOnlyUnplayed).thenReturn(false);
    when(mockSettingsProvider.randomOnlyHighRated).thenReturn(false);
    when(mockSettingsProvider.randomExcludePlayed).thenReturn(false);
    when(mockSettingsProvider.playRandomOnCompletion).thenReturn(false);
    when(mockSettingsProvider.showGlobalAlbumArt).thenReturn(true);

    // Stub CatalogService
    when(mockCatalogService.getRating(any)).thenReturn(0);
    when(mockCatalogService.isPlayed(any)).thenReturn(false);

    // Stub ShowListProvider
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

    when(mockPlayer.engineName).thenReturn('RelaxedMockEngine');

    // Create AudioProvider
    audioProvider = AudioProvider(
      audioPlayer: mockPlayer,
      catalogService: mockCatalogService,
      audioCacheService: mockAudioCacheService,
      wakelockService: mockWakelockService,
    );
    audioProvider.update(mockShowListProvider, mockSettingsProvider);
  });

  tearDown(() {
    processingStateController.close();
    playingController.close();
    positionController.close();
    currentIndexController.close();
    sequenceController.close();
    playbackEventController.close();
    playerStateController.close();
    audioProvider.dispose();
  });

  Show createDummyShow(int id, {int trackCount = 2}) {
    return Show(
      name: 'Grateful Dead at Venue $id on 1977-05-08',
      artist: 'Grateful Dead',
      date: '1977-05-08',
      venue: 'Venue $id',
      sources: [
        Source(
          id: 'source_$id',
          tracks: List.generate(
            trackCount,
            (i) => Track(
              trackNumber: i + 1,
              title: 'Track ${i + 1}',
              url: 'http://archive.org/track${i + 1}.mp3',
              duration: 300 + (i * 60),
              setName: 'Set 1',
            ),
          ),
        ),
      ],
    );
  }

  group('Web Adapter Stream Contract', () {
    testWidgets('PlaybackEvent emission triggers error listener without crash',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Simulate the web adapter emitting a PlaybackEvent (our fix)
        playbackEventController.add(PlaybackEvent(
          processingState: ProcessingState.ready,
          updatePosition: const Duration(seconds: 5),
          duration: const Duration(seconds: 300),
          currentIndex: 0,
        ));
        await Future.delayed(const Duration(milliseconds: 50));
        // No crash = success. The stream is consumed.
      });
    });

    testWidgets('Index change on currentIndexStream triggers notifyListeners',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        int notifyCount = 0;
        audioProvider.addListener(() => notifyCount++);

        // Setup 3-track sequence
        final sequence = [
          AudioSource.uri(Uri.parse('http://dummy/1')),
          AudioSource.uri(Uri.parse('http://dummy/2')),
          AudioSource.uri(Uri.parse('http://dummy/3')),
        ];
        when(mockPlayer.sequence).thenReturn(sequence);
        when(mockPlayer.currentIndex).thenReturn(0);

        // Simulate track change from index 0 to 1
        currentIndexController.add(1);
        await Future.delayed(const Duration(milliseconds: 50));

        expect(notifyCount, greaterThan(0),
            reason: 'AudioProvider should notify listeners on track change');
      });
    });

    testWidgets('Rapid index changes do not cause skipped notifications',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        int notifyCount = 0;
        audioProvider.addListener(() => notifyCount++);

        final sequence = List.generate(
          5,
          (i) => AudioSource.uri(Uri.parse('http://dummy/$i')),
        );
        when(mockPlayer.sequence).thenReturn(sequence);

        // Simulate rapid track changes (like gapless transitions)
        for (var i = 0; i < 5; i++) {
          when(mockPlayer.currentIndex).thenReturn(i);
          currentIndexController.add(i);
        }
        await Future.delayed(const Duration(milliseconds: 100));

        expect(notifyCount, greaterThanOrEqualTo(5),
            reason: 'Each index change should trigger a notification');
      });
    });

    testWidgets('Processing state "completed" triggers random show if enabled',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        when(mockSettingsProvider.playRandomOnCompletion).thenReturn(true);

        final show = createDummyShow(1);
        when(mockShowListProvider.filteredShows).thenReturn([show]);
        when(mockShowListProvider.allShows).thenReturn([show]);
        when(mockCatalogService.allShows).thenReturn([show]);

        // Simulate the web adapter emitting "completed" state
        processingStateController.add(ProcessingState.completed);
        await Future.delayed(const Duration(milliseconds: 100));

        // Should trigger setAudioSources (new random show load)
        verify(mockPlayer.setAudioSources(any,
                initialIndex: anyNamed('initialIndex'),
                preload: anyNamed('preload')))
            .called(1);
      });
    });

    testWidgets(
        'Processing state "completed" does NOT trigger random show if disabled',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        when(mockSettingsProvider.playRandomOnCompletion).thenReturn(false);

        processingStateController.add(ProcessingState.completed);
        await Future.delayed(const Duration(milliseconds: 100));

        verifyNever(mockPlayer.setAudioSources(any,
            initialIndex: anyNamed('initialIndex'),
            preload: anyNamed('preload')));
      });
    });

    testWidgets('Wakelock enabled when playing starts',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        when(mockPlayer.playing).thenReturn(true);
        when(mockSettingsProvider.preventSleep).thenReturn(true);

        playingController.add(true);
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockWakelockService.enable()).called(1);
      });
    });

    testWidgets('Wakelock disabled when playing stops',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        // First enable wakelock
        when(mockPlayer.playing).thenReturn(true);
        when(mockSettingsProvider.preventSleep).thenReturn(true);
        playingController.add(true);
        await Future.delayed(const Duration(milliseconds: 50));

        // Now stop playing
        when(mockPlayer.playing).thenReturn(false);
        when(mockWakelockService.enabled).thenAnswer((_) async => true);
        playingController.add(false);
        processingStateController.add(ProcessingState.idle);
        await Future.delayed(const Duration(milliseconds: 100));

        verify(mockWakelockService.disable()).called(greaterThan(0));
      });
    });

    testWidgets('Wakelock NOT enabled when preventSleep is false',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        when(mockPlayer.playing).thenReturn(true);
        when(mockSettingsProvider.preventSleep).thenReturn(false);

        playingController.add(true);
        await Future.delayed(const Duration(milliseconds: 100));

        verifyNever(mockWakelockService.enable());
      });
    });
  });
}
