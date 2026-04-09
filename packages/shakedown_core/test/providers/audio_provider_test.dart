import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show AppLifecycleState;

import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/services/wakelock_service.dart';

import 'audio_provider_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<GaplessPlayer>(
    as: #MockAudioPlayerRelaxed,
    onMissingStub: OnMissingStub.returnDefault,
  ),
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
  late StreamController<ProcessingState> processingStateController;
  late StreamController<Duration> positionController;
  late StreamController<int?> currentIndexController;
  late StreamController<void> playBlockedController;
  late StreamController<bool> playingController;

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
    playBlockedController = StreamController<void>.broadcast();
    playingController = StreamController<bool>.broadcast();

    // Stub SettingsProvider methods FIRST
    when(mockSettingsProvider.randomOnlyUnplayed).thenReturn(false);
    when(mockSettingsProvider.randomOnlyHighRated).thenReturn(false);
    when(mockSettingsProvider.randomExcludePlayed).thenReturn(false);
    when(mockSettingsProvider.playRandomOnCompletion).thenReturn(false);
    when(mockSettingsProvider.showGlobalAlbumArt).thenReturn(true);

    // Stub CatalogService methods
    when(mockCatalogService.getRating(any)).thenReturn(0);
    when(mockCatalogService.isPlayed(any)).thenReturn(false);

    when(
      mockAudioPlayer.processingStateStream,
    ).thenAnswer((_) => processingStateController.stream);
    when(
      mockAudioPlayer.playbackEventStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockAudioPlayer.playerState,
    ).thenReturn(PlayerState(false, ProcessingState.idle));
    when(mockAudioPlayer.position).thenReturn(Duration.zero);
    when(mockAudioPlayer.bufferedPosition).thenReturn(Duration.zero);
    when(mockAudioPlayer.nextTrackBuffered).thenReturn(null);
    when(
      mockAudioPlayer.currentIndexStream,
    ).thenAnswer((_) => currentIndexController.stream);
    when(
      mockAudioPlayer.durationStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockAudioPlayer.positionStream,
    ).thenAnswer((_) => positionController.stream);
    when(
      mockAudioPlayer.bufferedPositionStream,
    ).thenAnswer((_) => const Stream.empty());
    when(
      mockAudioPlayer.playBlockedStream,
    ).thenAnswer((_) => playBlockedController.stream);
    when(
      mockAudioPlayer.playingStream,
    ).thenAnswer((_) => playingController.stream);

    when(mockAudioPlayer.play()).thenAnswer((_) async {});
    when(mockAudioPlayer.stop()).thenAnswer((_) async {});
    when(
      mockAudioPlayer.setAudioSources(
        any,
        initialIndex: anyNamed('initialIndex'),
        initialPosition: anyNamed('initialPosition'),
        preload: anyNamed('preload'),
      ),
    ).thenAnswer((_) async => const Duration(seconds: 100));
    when(mockAudioPlayer.addAudioSources(any)).thenAnswer((_) async {});

    // Stub AudioCacheService
    when(mockAudioCacheService.getAlbumArtUri()).thenAnswer((_) async => null);
    when(
      mockAudioCacheService.createAudioSource(
        uri: anyNamed('uri'),
        tag: anyNamed('tag'),
        useCache: anyNamed('useCache'),
      ),
    ).thenAnswer((invocation) {
      final uri = invocation.namedArguments[#uri] as Uri;
      final tag = invocation.namedArguments[#tag];
      return AudioSource.uri(uri, tag: tag);
    });

    // Stub WakelockService
    when(mockWakelockService.enabled).thenAnswer((_) async => false);
    when(mockWakelockService.enable()).thenAnswer((_) async {});
    when(mockWakelockService.disable()).thenAnswer((_) async {});

    when(mockShowListProvider.isLoading).thenReturn(false);
    when(mockShowListProvider.allShows).thenReturn([]);
    when(mockShowListProvider.initializationComplete).thenAnswer((_) async {});
    when(mockShowListProvider.initializationComplete).thenAnswer((_) async {});
    when(mockShowListProvider.isSourceAllowed(any)).thenReturn(true);

    when(mockAudioPlayer.engineName).thenReturn('RelaxedMockEngine');

    // Create AudioProvider AFTER stubbing
    audioProvider = AudioProvider(
      audioPlayer: mockAudioPlayer,
      catalogService: mockCatalogService,
      audioCacheService: mockAudioCacheService,
      wakelockService: mockWakelockService,
    );
    audioProvider.update(
      mockShowListProvider,
      mockSettingsProvider,
      mockAudioCacheService,
    );
  });

  tearDown(() {
    processingStateController.close();
    positionController.close();
    currentIndexController.close();
    playBlockedController.close();
    playingController.close();
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
              setName: 'Set 1',
            ),
            Track(
              trackNumber: 2,
              title: 'Track 2',
              url: 'http://track2.mp3',
              duration: 120,
              setName: 'Set 1',
            ),
          ],
        ),
      ),
    );
  }

  group('AudioProvider Tests', () {
    testWidgets(
      'playRandomShow plays a random source when shows are available',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          // Stub SettingsProvider methods
          for (var i = 1; i <= 2; i++) {
            // final name = 'Grateful Dead at Venue $i on 2025-11-15'; // Unused
            final sourceId = 'source${i - 1}';
            when(mockCatalogService.getRating(sourceId)).thenReturn(0);
            when(mockCatalogService.isPlayed(sourceId)).thenReturn(false);
            // Assuming source ID structure from createDummyShow source${index-1}
          }
          when(mockSettingsProvider.randomOnlyUnplayed).thenReturn(false);
          when(mockSettingsProvider.randomOnlyHighRated).thenReturn(false);

          // Stub AudioPlayer methods
          when(
            mockAudioPlayer.setAudioSources(
              any,
              initialIndex: anyNamed('initialIndex'),
              preload: anyNamed('preload'),
            ),
          ).thenAnswer((_) async => const Duration(seconds: 100));
          when(mockAudioPlayer.play()).thenAnswer((_) async {});

          final shows = [createDummyShow(1), createDummyShow(2)];
          when(mockShowListProvider.filteredShows).thenReturn(shows);

          final playedShow = await audioProvider.playRandomShow();

          expect(playedShow, isNotNull);
          expect(shows.contains(playedShow), isTrue);

          verify(
            mockAudioPlayer.setAudioSources(
              any,
              initialIndex: 0,
              preload: false,
            ),
          ).called(1);
          verify(mockAudioPlayer.play()).called(1);

          expect(audioProvider.currentShow, isNotNull);
          expect(audioProvider.currentSource, isNotNull);
        });
      },
    );

    testWidgets('playRandomShow does nothing when no shows are available', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        when(mockShowListProvider.filteredShows).thenReturn([]);
        when(
          mockShowListProvider.allShows,
        ).thenReturn([]); // Ensure allShows is also empty

        final playedShow = await audioProvider.playRandomShow();

        expect(playedShow, isNull);
        verifyNever(mockAudioPlayer.setAudioSources(any));
        verifyNever(mockAudioPlayer.play());
      });
    });

    testWidgets('playBlockedStream sets the browser resume agent message', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        playBlockedController.add(null);
        await Future<void>.delayed(Duration.zero);

        final hud = audioProvider.currentHudSnapshot;

        expect(hud.message, 'Playback paused by browser. Tap play to resume.');
        expect(hud.signal, isNot('--'));
      });
    });

    testWidgets('playBlockedStream prompt clears after playback resumes', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        playBlockedController.add(null);
        await Future<void>.delayed(Duration.zero);

        expect(
          audioProvider.currentHudSnapshot.message,
          'Playback paused by browser. Tap play to resume.',
        );

        when(
          mockAudioPlayer.playerState,
        ).thenReturn(PlayerState(true, ProcessingState.ready));
        playingController.add(true);
        await Future<void>.delayed(Duration.zero);

        final hud = audioProvider.currentHudSnapshot;
        expect(hud.signal, '--');
        expect(hud.message, '--');
        expect(hud.isPlaying, isTrue);
        expect(hud.processing, 'RDY');
      });
    });

    testWidgets(
      'playRandomShow(filterBySearch: false) uses allShows and ignores search filter',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          // Stub SettingsProvider
          for (var i = 1; i <= 2; i++) {
            // final name = 'Grateful Dead at Venue $i on 2025-11-15'; // Unused
            final sourceId = 'source${i - 1}';
            when(mockCatalogService.getRating(sourceId)).thenReturn(0);
            when(mockCatalogService.isPlayed(sourceId)).thenReturn(false);
          }
          when(mockCatalogService.getRating('source0')).thenReturn(0);
          when(mockSettingsProvider.randomOnlyUnplayed).thenReturn(false);
          when(mockSettingsProvider.randomOnlyHighRated).thenReturn(false);

          // Stub AudioPlayer
          when(
            mockAudioPlayer.setAudioSources(
              any,
              initialIndex: anyNamed('initialIndex'),
              preload: anyNamed('preload'),
            ),
          ).thenAnswer((_) async => const Duration(seconds: 100));
          when(mockAudioPlayer.play()).thenAnswer((_) async {});

          final show1 = createDummyShow(1); // filtered show
          final show2 = createDummyShow(2); // unfiltered show

          // filterBySearch=true uses filteredShows
          when(mockShowListProvider.filteredShows).thenReturn([show1]);
          // filterBySearch=false uses allShows
          when(mockShowListProvider.allShows).thenReturn([show1, show2]);

          // 1. Default (filterBySearch: true) should only pick show1
          final playedShow1 = await audioProvider.playRandomShow();
          expect(playedShow1, equals(show1));

          // 2. filterBySearch: false should pick from allShows.
          // To verify it CAN pick show2, we'll force filteredShows to be empty
          // and allShows to have show2.
          when(mockShowListProvider.filteredShows).thenReturn([]);
          when(mockShowListProvider.allShows).thenReturn([show2]);

          final playedShow2 = await audioProvider.playRandomShow(
            filterBySearch: false,
          );
          expect(playedShow2, equals(show2));

          verify(mockAudioPlayer.play()).called(2);
        });
      },
    );

    testWidgets(
      'playRandomShow(delayPlayback: true) sets selection and emits event but does not start playback',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          final show = createDummyShow(1);
          when(mockShowListProvider.filteredShows).thenReturn([show]);

          // Listen to the stream for orchestration verification
          final selectionCompleter = Completer<({Show show, Source source})>();
          final sub = audioProvider.randomShowRequestStream.listen(
            selectionCompleter.complete,
          );

          final playedShow = await audioProvider.playRandomShow(
            delayPlayback: true,
          );

          expect(playedShow, equals(show));
          expect(audioProvider.currentShow, equals(show));
          expect(audioProvider.pendingRandomShowRequest, isNotNull);

          // Verify stream emitted correctly for TV orchestrator
          final selection = await selectionCompleter.future;
          expect(selection.show, equals(show));

          // Verify playback NOT started directly (waits for TV sequence)
          verifyNever(
            mockAudioPlayer.setAudioSources(
              any,
              initialIndex: anyNamed('initialIndex'),
              preload: anyNamed('preload'),
            ),
          );
          verifyNever(mockAudioPlayer.play());

          await sub.cancel();
        });
      },
    );

    testWidgets('playSource sets current show/source and plays audio', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final show = createDummyShow(1);
        final source = show.sources.first;

        await audioProvider.playSource(show, source);

        expect(audioProvider.currentShow, equals(show));
        expect(audioProvider.currentSource, equals(source));

        verify(
          mockAudioPlayer.setAudioSources(any, initialIndex: 0, preload: false),
        ).called(1);
        verify(mockAudioPlayer.play()).called(1);
      });
    });

    testWidgets(
      'currentTrack resolves correctly using MediaItem tag when global index differs',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          final show = createDummyShow(1);
          final source = show.sources.first; // 2 tracks

          // Simulate that we are playing this source
          unawaited(audioProvider.playSource(show, source));

          // Mock Sequence with an offset.
          // items [0, 1, 2] are dummy (previous show).
          // items [3, 4] are current show (tracks 0, 1).
          final previousItems = List.generate(
            3,
            (i) => AudioSource.uri(Uri.parse('prev/$i')),
          );
          final currentItems = source.tracks.asMap().entries.map((e) {
            return AudioSource.uri(
              Uri.parse(e.value.url),
              tag: MediaItem(
                id: 'id_${e.key}',
                title: e.value.title,
                extras: {'track_index': e.key}, // Using the new extras key
              ),
            );
          }).toList();

          final fullSequence = [...previousItems, ...currentItems];

          // Stub AudioPlayer state
          when(mockAudioPlayer.sequence).thenReturn(fullSequence);

          // Scenario 1: Playing global index 3 (Local index 0)
          when(mockAudioPlayer.currentIndex).thenReturn(3);

          expect(audioProvider.currentTrack, equals(source.tracks[0]));

          // Scenario 2: Playing global index 4 (Local index 1)
          when(mockAudioPlayer.currentIndex).thenReturn(4);

          expect(audioProvider.currentTrack, equals(source.tracks[1]));
          expect(audioProvider.currentTrack, equals(source.tracks[1]));
        });
      },
    );

    testWidgets('seekToTrack uses global index when available', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final show = createDummyShow(1);
        final source = show.sources.first; // 2 tracks

        // Simulate playing
        await audioProvider.playSource(show, source);

        // Mock Sequence: [Previous Show (2 items), Current Show (2 items)]
        // Global Indices: 0, 1 are dummy. 2, 3 are current show.
        final previousItems = List.generate(
          2,
          (i) => AudioSource.uri(Uri.parse('prev/$i')),
        );

        final currentItems = source.tracks.asMap().entries.map((e) {
          return AudioSource.uri(
            Uri.parse(e.value.url),
            tag: MediaItem(
              id: 'id_${e.key}',
              title: e.value.title,
              extras: {'source_id': source.id, 'track_index': e.key},
            ),
          );
        }).toList();

        final fullSequence = [...previousItems, ...currentItems];
        when(mockAudioPlayer.sequence).thenReturn(fullSequence);

        // Action: Seek to Local Index 0
        // Expected: Global Index 2
        audioProvider.seekToTrack(0);
        verify(mockAudioPlayer.seek(Duration.zero, index: 2)).called(1);

        // Action: Seek to Local Index 1
        // Expected: Global Index 3
        audioProvider.seekToTrack(1);
        verify(mockAudioPlayer.seek(Duration.zero, index: 3)).called(1);
      });
    });

    testWidgets(
      'seekToTrack during startup load does not let stale playSource win',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          final show = createDummyShow(1);
          final source = show.sources.first;
          final firstArtUriCompleter = Completer<Uri?>();
          var artRequestCount = 0;

          when(
            mockAudioPlayer.processingState,
          ).thenReturn(ProcessingState.loading);
          when(mockAudioPlayer.sequence).thenReturn(const []);
          when(mockAudioCacheService.getAlbumArtUri()).thenAnswer((_) {
            artRequestCount++;
            if (artRequestCount == 1) {
              return firstArtUriCompleter.future;
            }
            return Future<Uri?>.value(null);
          });

          unawaited(audioProvider.playSource(show, source));
          await Future<void>.delayed(Duration.zero);

          audioProvider.seekToTrack(1);
          await Future<void>.delayed(Duration.zero);

          firstArtUriCompleter.complete(null);
          await Future<void>.delayed(const Duration(milliseconds: 120));

          verify(
            mockAudioPlayer.setAudioSources(
              any,
              initialIndex: 1,
              preload: false,
            ),
          ).called(1);
          verifyNever(
            mockAudioPlayer.setAudioSources(
              any,
              initialIndex: 0,
              preload: false,
            ),
          );
          verify(mockAudioPlayer.play()).called(1);
        });
      },
    );

    //       .thenReturn([createDummyShow(1)]);
    //   when(audioProvider.playRandomShow()).thenAnswer((_) async {
    //     completer.complete();
    //     return null;
    //   });

    //   processingStateController.add(ProcessingState.completed);
    //   await completer.future;

    //   verify(audioProvider.playRandomShow()).called(1);
    // });

    testWidgets('Pre-queues random show at start of last track', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        // Stub addAudioSources
        when(mockAudioPlayer.addAudioSources(any)).thenAnswer((_) async {});

        when(mockSettingsProvider.playRandomOnCompletion).thenReturn(true);
        when(
          mockShowListProvider.allShows,
        ).thenReturn([createDummyShow(3)]); // A different show to queue

        // Setup Player State: playing show 1, last track.
        when(mockAudioPlayer.sequence).thenReturn([
          AudioSource.uri(Uri.parse('1')),
          AudioSource.uri(Uri.parse('2')),
        ]);

        // Simulating the transition to the LAST track (index 1)
        when(mockAudioPlayer.currentIndex).thenReturn(1);
        currentIndexController.add(1);

        // Wait for async listener
        await Future.delayed(const Duration(milliseconds: 50));

        // It should have called pickRandomShow -> and appended to playlist
        // Verify mockAudioPlayer.addAudioSources(any) was called
        verify(mockAudioPlayer.addAudioSources(any)).called(1);
      });
    });

    testWidgets(
      'Pre-queueing retries if first attempt fails (null selection)',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          // Stub addAudioSources
          when(mockAudioPlayer.addAudioSources(any)).thenAnswer((_) async {});

          when(mockSettingsProvider.playRandomOnCompletion).thenReturn(true);
          // First attempt: Return null (no shows?)
          // We simulate this by momentarily returning empty list for allShows
          when(mockShowListProvider.allShows).thenReturn([]);

          // Setup Player State: playing show 1, last track.
          when(mockAudioPlayer.sequence).thenReturn([
            AudioSource.uri(Uri.parse('1')),
            AudioSource.uri(Uri.parse('2')),
          ]);
          when(mockAudioPlayer.currentIndex).thenReturn(1);

          // Trigger 1 (Fail)
          currentIndexController.add(1);
          await Future.delayed(const Duration(milliseconds: 50));

          // Verify NO addAudioSources called yet
          verifyNever(mockAudioPlayer.addAudioSources(any));

          // Second attempt: Return valid show
          when(mockShowListProvider.allShows).thenReturn([createDummyShow(3)]);

          // Trigger 2 (Retry)
          // We need to re-emit the index to trigger the listener again
          currentIndexController.add(1);
          await Future.delayed(const Duration(milliseconds: 50));

          // Verify addAudioSources called NOW
          verify(mockAudioPlayer.addAudioSources(any)).called(1);
        });
      },
    );

    testWidgets('Does NOT pre-queue if setting is disabled', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        when(mockSettingsProvider.playRandomOnCompletion).thenReturn(false);
        // Stub addAudioSources (verifyNever will be used later potentially or implicitly)
        when(mockAudioPlayer.addAudioSources(any)).thenAnswer((_) async {});

        when(mockAudioPlayer.sequence).thenReturn([
          AudioSource.uri(Uri.parse('1')),
          AudioSource.uri(Uri.parse('2')),
        ]);

        // Last track transition
        when(mockAudioPlayer.currentIndex).thenReturn(1);
        currentIndexController.add(1);

        await Future.delayed(const Duration(milliseconds: 50));

        verifyNever(mockAudioPlayer.addAudioSources(any));
      });
    });

    // The 'Marks show as played' logic is now tied to Metadata Updates (sourceId change).
    // We can test that _updateCurrentShowFromSourceId triggers markAsPlayed.
    // However, that method is private and driven by index updates with specific tags.
    // Testing it requires constructing AudioSources with MediaItem tags, which is cumbersome
    // with strict mocks. We will rely on the pre-queueing test for the main feature.

    testWidgets(
      'Triggers fallback playRandomShow when processing state completes',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          when(mockSettingsProvider.playRandomOnCompletion).thenReturn(true);
          when(mockShowListProvider.allShows).thenReturn([createDummyShow(5)]);
          when(
            mockShowListProvider.filteredShows,
          ).thenReturn([createDummyShow(5)]);

          // Ensure playRandomShow works
          when(
            mockAudioPlayer.setAudioSources(
              any,
              initialIndex: anyNamed('initialIndex'),
              preload: anyNamed('preload'),
            ),
          ).thenAnswer((_) async => const Duration(seconds: 10));
          when(mockAudioPlayer.play()).thenAnswer((_) async {});

          // Signal Completion
          processingStateController.add(ProcessingState.completed);
          await Future.delayed(const Duration(milliseconds: 200));

          // Should call setAudioSources again (which implies playRandomShow was called)
          verify(
            mockAudioPlayer.setAudioSources(
              any,
              initialIndex: anyNamed('initialIndex'),
              preload: anyNamed('preload'),
            ),
          ).called(1);
        });
      },
    );

    testWidgets(
      'Does not fallback-load random show after last-track prequeue succeeds',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          when(mockSettingsProvider.playRandomOnCompletion).thenReturn(true);
          final queuedShow = createDummyShow(5);
          when(mockShowListProvider.allShows).thenReturn([queuedShow]);
          when(mockShowListProvider.filteredShows).thenReturn([queuedShow]);

          when(mockAudioPlayer.addAudioSources(any)).thenAnswer((_) async {});
          when(
            mockAudioPlayer.setAudioSources(
              any,
              initialIndex: anyNamed('initialIndex'),
              preload: anyNamed('preload'),
            ),
          ).thenAnswer((_) async => const Duration(seconds: 10));

          when(mockAudioPlayer.sequence).thenReturn([
            AudioSource.uri(Uri.parse('1')),
            AudioSource.uri(Uri.parse('2')),
          ]);
          when(mockAudioPlayer.currentIndex).thenReturn(1);

          currentIndexController.add(1);
          await Future.delayed(const Duration(milliseconds: 50));

          verify(mockAudioPlayer.addAudioSources(any)).called(1);

          processingStateController.add(ProcessingState.completed);
          await Future.delayed(const Duration(milliseconds: 100));

          verifyNever(
            mockAudioPlayer.setAudioSources(
              any,
              initialIndex: anyNamed('initialIndex'),
              preload: anyNamed('preload'),
            ),
          );
        });
      },
    );

    testWidgets('stopAndClear stops player and clears state', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        final show = createDummyShow(1);
        await audioProvider.playSource(show, show.sources.first);
        expect(audioProvider.currentShow, isNotNull);

        await audioProvider.stopAndClear();

        verify(mockAudioPlayer.stop()).called(1);
      });
    });

    testWidgets('queueRandomShow handles PlatformException gracefully', (
      WidgetTester tester,
    ) async {
      await tester.runAsync(() async {
        // Stub addAudioSources to throw PlatformException
        when(mockAudioPlayer.addAudioSources(any)).thenThrow(
          PlatformException(
            code: 'IllegalArgumentException',
            message: 'Failed to set shuffle order',
          ),
        );

        when(mockSettingsProvider.playRandomOnCompletion).thenReturn(true);
        when(
          mockShowListProvider.allShows,
        ).thenReturn([createDummyShow(3)]); // A show to queue
        when(
          mockShowListProvider.filteredShows,
        ).thenReturn([createDummyShow(3)]);

        // Setup Player State
        when(mockAudioPlayer.sequence).thenReturn([
          AudioSource.uri(Uri.parse('1')),
          AudioSource.uri(Uri.parse('2')),
        ]);
        when(mockAudioPlayer.currentIndex).thenReturn(1);

        try {
          await audioProvider.queueRandomShow();
        } catch (e) {
          fail('queueRandomShow should catch PlatformException but threw: $e');
        }

        // Verify addAudioSources WAS called (so we know we actually hit the error)
        verify(mockAudioPlayer.addAudioSources(any)).called(1);
      });
    });

    group('Navigation Undo', () {
      void primeSequence(Source source, {required int currentLocalIndex}) {
        when(mockAudioPlayer.currentIndex).thenReturn(currentLocalIndex);
        when(mockAudioPlayer.sequence).thenReturn(
          source.tracks.asMap().entries.map((entry) {
            return AudioSource.uri(
              Uri.parse(entry.value.url),
              tag: MediaItem(
                id: '${source.id}_${entry.key}',
                title: entry.value.title,
                extras: {'source_id': source.id, 'track_index': entry.key},
              ),
            );
          }).toList(),
        );
      }

      testWidgets('captureUndoCheckpoint stores current track and position', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() async {
          final show = createDummyShow(1);
          final source = show.sources.first;

          await audioProvider.playSource(show, source);
          primeSequence(source, currentLocalIndex: 1);
          when(
            mockAudioPlayer.position,
          ).thenReturn(const Duration(seconds: 37));

          audioProvider.captureUndoCheckpoint();

          final checkpoint = audioProvider.undoCheckpointForTest;
          expect(checkpoint, isNotNull);
          expect(checkpoint!.sourceId, source.id);
          expect(checkpoint.trackIndex, 1);
          expect(checkpoint.position, const Duration(seconds: 37));
        });
      });

      testWidgets(
        'seekToPrevious restores checkpoint when pressed near track start',
        (WidgetTester tester) async {
          await tester.runAsync(() async {
            final show = createDummyShow(1);
            final source = show.sources.first;

            await audioProvider.playSource(show, source);
            primeSequence(source, currentLocalIndex: 0);
            when(
              mockAudioPlayer.position,
            ).thenReturn(const Duration(seconds: 28));
            audioProvider.captureUndoCheckpoint();

            when(mockShowListProvider.allShows).thenReturn([show]);

            when(
              mockAudioPlayer.position,
            ).thenReturn(const Duration(seconds: 3));

            await audioProvider.seekToPrevious();

            verify(
              mockAudioPlayer.setAudioSources(
                any,
                initialIndex: 0,
                initialPosition: const Duration(seconds: 28),
                preload: false,
              ),
            ).called(1);
            verifyNever(mockAudioPlayer.seekToPrevious());
            expect(audioProvider.undoCheckpointForTest, isNull);
          });
        },
      );

      testWidgets(
        'seekToPrevious delegates normally when current position is above threshold',
        (WidgetTester tester) async {
          await tester.runAsync(() async {
            final show = createDummyShow(1);
            final source = show.sources.first;

            await audioProvider.playSource(show, source);
            primeSequence(source, currentLocalIndex: 0);
            when(
              mockAudioPlayer.position,
            ).thenReturn(const Duration(seconds: 28));
            audioProvider.captureUndoCheckpoint();

            when(
              mockAudioPlayer.position,
            ).thenReturn(const Duration(seconds: 8));

            await audioProvider.seekToPrevious();

            verify(mockAudioPlayer.seekToPrevious()).called(1);
          });
        },
      );

      testWidgets('checkpoint expires after 10 seconds', (
        WidgetTester tester,
      ) async {
        final show = createDummyShow(1);
        final source = show.sources.first;

        await audioProvider.playSource(show, source);
        primeSequence(source, currentLocalIndex: 0);
        when(mockAudioPlayer.position).thenReturn(const Duration(seconds: 12));
        audioProvider.captureUndoCheckpoint();

        await tester.pump(const Duration(seconds: 11));

        expect(audioProvider.undoCheckpointForTest, isNull);
      });

      testWidgets('paused lifecycle clears the checkpoint', (
        WidgetTester tester,
      ) async {
        await tester.runAsync(() async {
          final show = createDummyShow(1);
          final source = show.sources.first;

          await audioProvider.playSource(show, source);
          primeSequence(source, currentLocalIndex: 0);
          when(
            mockAudioPlayer.position,
          ).thenReturn(const Duration(seconds: 12));
          audioProvider.captureUndoCheckpoint();

          audioProvider.didChangeAppLifecycleState(AppLifecycleState.paused);

          expect(audioProvider.undoCheckpointForTest, isNull);
        });
      });

      testWidgets(
        'playRandomShow clears a fresh undo checkpoint when no selection exists',
        (WidgetTester tester) async {
          await tester.runAsync(() async {
            final show = createDummyShow(1);
            final source = show.sources.first;

            await audioProvider.playSource(show, source);
            primeSequence(source, currentLocalIndex: 0);
            when(
              mockAudioPlayer.position,
            ).thenReturn(const Duration(seconds: 12));
            audioProvider.captureUndoCheckpoint();

            when(mockShowListProvider.filteredShows).thenReturn([]);
            when(mockShowListProvider.allShows).thenReturn([]);

            final playedShow = await audioProvider.playRandomShow();

            expect(playedShow, isNull);
            expect(audioProvider.undoCheckpointForTest, isNull);
          });
        },
      );

      testWidgets(
        'playRandomShow clears a fresh undo checkpoint after delayed failure',
        (WidgetTester tester) async {
          await tester.runAsync(() async {
            final show = createDummyShow(1);
            final source = show.sources.first;
            final initializationCompleter = Completer<void>();

            await audioProvider.playSource(show, source);
            primeSequence(source, currentLocalIndex: 0);
            when(
              mockAudioPlayer.position,
            ).thenReturn(const Duration(seconds: 12));
            audioProvider.captureUndoCheckpoint();

            when(mockShowListProvider.isLoading).thenReturn(true);
            when(mockShowListProvider.allShows).thenReturn([]);
            when(mockShowListProvider.filteredShows).thenReturn([]);
            when(
              mockShowListProvider.initializationComplete,
            ).thenAnswer((_) => initializationCompleter.future);

            final playedShowFuture = audioProvider.playRandomShow();
            await Future<void>.delayed(const Duration(milliseconds: 10));
            when(
              mockAudioPlayer.position,
            ).thenReturn(const Duration(seconds: 15));
            initializationCompleter.complete();

            final playedShow = await playedShowFuture;

            expect(playedShow, isNull);
            expect(audioProvider.undoCheckpointForTest, isNull);
          });
        },
      );

      testWidgets(
        'playFromShareString clears a fresh undo checkpoint when parsing fails',
        (WidgetTester tester) async {
          await tester.runAsync(() async {
            final show = createDummyShow(1);
            final source = show.sources.first;

            await audioProvider.playSource(show, source);
            primeSequence(source, currentLocalIndex: 0);
            when(
              mockAudioPlayer.position,
            ).thenReturn(const Duration(seconds: 12));
            audioProvider.captureUndoCheckpoint();

            final success = await audioProvider.playFromShareString(
              'not a share string',
            );

            expect(success, isFalse);
            expect(audioProvider.undoCheckpointForTest, isNull);
          });
        },
      );
    });

    group('Regression: Web Playback Race Condition', () {
      setUp(() {
        audioProvider = AudioProvider(
          audioPlayer: mockAudioPlayer,
          catalogService: mockCatalogService,
          audioCacheService: mockAudioCacheService,
          wakelockService: mockWakelockService,
          isWeb: true,
        );
        audioProvider.update(
          mockShowListProvider,
          mockSettingsProvider,
          mockAudioCacheService,
        );
      });

      testWidgets('pause() is aborted if play() is called during fade-out', (
        tester,
      ) async {
        await tester.runAsync(() async {
          // 1. Mock play() and pause() to respond immediately
          when(mockAudioPlayer.play()).thenAnswer((_) async {});
          when(mockAudioPlayer.pause()).thenAnswer((_) async {});
          when(mockAudioPlayer.setVolume(any)).thenAnswer((_) async {});

          // 2. Mock usePlayPauseFade to true
          when(mockSettingsProvider.usePlayPauseFade).thenReturn(true);

          // 3. Start a pause operation (this will start a 150ms fade)
          final pauseFuture = audioProvider.pause();

          // 4. Immediately start a play operation
          // This increases _fadeId, which should cause pause() to abort its engine call.
          await audioProvider.play();

          await pauseFuture;

          // 5. Verify that mockAudioPlayer.pause() was NEVER called because it was aborted
          verifyNever(mockAudioPlayer.pause());

          // 6. Verify that mockAudioPlayer.play() WAS called
          verify(mockAudioPlayer.play()).called(1);
        });
      });

      testWidgets('play() handles engine errors gracefully', (tester) async {
        await tester.runAsync(() async {
          // Mock engine to throw an error (simulating browser interruption)
          when(
            mockAudioPlayer.play(),
          ).thenThrow(Exception('Interrupted by pause'));

          // Should not re-throw
          await audioProvider.play();

          verify(mockAudioPlayer.play()).called(1);
        });
      });
    });
  });

  group('Wake Lock', () {
    testWidgets(
      'releases wake lock when preventSleep toggled off during active playback',
      (WidgetTester tester) async {
        await tester.runAsync(() async {
          // Establish initial state: preventSleep=true, player idle.
          final settingsOn = MockSettingsProvider();
          when(settingsOn.preventSleep).thenReturn(true);
          audioProvider.update(
            mockShowListProvider,
            settingsOn,
            mockAudioCacheService,
          );
          await Future.delayed(const Duration(milliseconds: 50));

          // Playback starts and wake lock is active.
          when(mockAudioPlayer.playing).thenReturn(true);
          when(
            mockWakelockService.enabled,
          ).thenAnswer((_) async => true);

          // User disables "Keep Screen On" while audio is playing.
          final settingsOff = MockSettingsProvider();
          when(settingsOff.preventSleep).thenReturn(false);
          audioProvider.update(
            mockShowListProvider,
            settingsOff,
            mockAudioCacheService,
          );
          await Future.delayed(const Duration(milliseconds: 50));

          verify(mockWakelockService.disable()).called(1);
        });
      },
    );
  });
}
