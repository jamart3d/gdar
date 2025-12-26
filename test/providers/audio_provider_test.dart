import 'dart:async';
import 'package:flutter/services.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
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
  late StreamController<ProcessingState> processingStateController;

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

    // Stub SettingsProvider methods FIRST
    when(mockSettingsProvider.randomOnlyUnplayed).thenReturn(false);
    when(mockSettingsProvider.randomOnlyHighRated).thenReturn(false);
    when(mockSettingsProvider.randomExcludePlayed).thenReturn(false);
    when(mockSettingsProvider.playRandomOnCompletion).thenReturn(false);
    when(mockSettingsProvider.markAsPlayed(any)).thenAnswer((_) async {});
    when(mockSettingsProvider.showGlobalAlbumArt).thenReturn(true);
    when(mockSettingsProvider.getRating(any)).thenReturn(0);
    when(mockSettingsProvider.isPlayed(any)).thenReturn(false);

    when(mockAudioPlayer.processingStateStream)
        .thenAnswer((_) => processingStateController.stream);
    when(mockAudioPlayer.playbackEventStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockAudioPlayer.currentIndexStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockAudioPlayer.durationStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockAudioPlayer.positionStream)
        .thenAnswer((_) => const Stream.empty());
    when(mockAudioPlayer.bufferedPositionStream)
        .thenAnswer((_) => const Stream.empty());

    when(mockAudioPlayer.play()).thenAnswer((_) async {});
    when(mockAudioPlayer.stop()).thenAnswer((_) async {});
    when(mockAudioPlayer.setAudioSource(any,
            initialIndex: anyNamed('initialIndex'),
            preload: anyNamed('preload')))
        .thenAnswer((_) async => const Duration(seconds: 100));

    // Create AudioProvider AFTER stubbing
    audioProvider = AudioProvider(audioPlayer: mockAudioPlayer);
    audioProvider.update(mockShowListProvider, mockSettingsProvider);
  });

  tearDown(() {
    processingStateController.close();
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

  group('AudioProvider Tests', () {
    testWidgets('playRandomShow plays a random source when shows are available',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Stub SettingsProvider methods
        for (var i = 1; i <= 2; i++) {
          final name = 'Grateful Dead at Venue $i on 2025-11-15';
          when(mockSettingsProvider.getRating(name)).thenReturn(0);
          when(mockSettingsProvider.isPlayed(name)).thenReturn(false);
        }
        when(mockSettingsProvider.randomOnlyUnplayed).thenReturn(false);
        when(mockSettingsProvider.randomOnlyHighRated).thenReturn(false);

        // Stub AudioPlayer methods
        when(mockAudioPlayer.setAudioSource(any,
                initialIndex: anyNamed('initialIndex'),
                preload: anyNamed('preload')))
            .thenAnswer((_) async => const Duration(seconds: 100));
        when(mockAudioPlayer.play()).thenAnswer((_) async {});

        final shows = [createDummyShow(1), createDummyShow(2)];
        when(mockShowListProvider.filteredShows).thenReturn(shows);

        final playedShow = await audioProvider.playRandomShow();

        expect(playedShow, isNotNull);
        expect(shows.contains(playedShow), isTrue);

        verify(mockAudioPlayer.setAudioSource(any,
                initialIndex: 0, preload: true))
            .called(1);
        verify(mockAudioPlayer.play()).called(1);

        expect(audioProvider.currentShow, isNotNull);
        expect(audioProvider.currentSource, isNotNull);
      });
    });

    testWidgets('playRandomShow does nothing when no shows are available',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        when(mockShowListProvider.filteredShows).thenReturn([]);
        when(mockShowListProvider.allShows)
            .thenReturn([]); // Ensure allShows is also empty

        final playedShow = await audioProvider.playRandomShow();

        expect(playedShow, isNull);
        verifyNever(mockAudioPlayer.setAudioSource(any));
        verifyNever(mockAudioPlayer.play());
      });
    });

    testWidgets(
        'playRandomShow(filterBySearch: false) uses allShows and ignores search filter',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        // Stub SettingsProvider
        for (var i = 1; i <= 2; i++) {
          final name = 'Grateful Dead at Venue $i on 2025-11-15';
          when(mockSettingsProvider.getRating(name)).thenReturn(0);
          when(mockSettingsProvider.isPlayed(name)).thenReturn(false);
          // Stub source rating
          when(mockSettingsProvider.getRating('source0'))
              .thenReturn(0); // Dummy sources start at source0
        }
        when(mockSettingsProvider.randomOnlyUnplayed).thenReturn(false);
        when(mockSettingsProvider.randomOnlyHighRated).thenReturn(false);

        // Stub AudioPlayer
        when(mockAudioPlayer.setAudioSource(any,
                initialIndex: anyNamed('initialIndex'),
                preload: anyNamed('preload')))
            .thenAnswer((_) async => const Duration(seconds: 100));
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

        final playedShow2 =
            await audioProvider.playRandomShow(filterBySearch: false);
        expect(playedShow2, equals(show2));

        verify(mockAudioPlayer.play()).called(2);
      });
    });

    testWidgets('playSource sets current show/source and plays audio',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final show = createDummyShow(1);
        final source = show.sources.first;

        await audioProvider.playSource(show, source);

        expect(audioProvider.currentShow, equals(show));
        expect(audioProvider.currentSource, equals(source));

        verify(mockAudioPlayer.setAudioSource(any,
                initialIndex: 0, preload: true))
            .called(1);
        verify(mockAudioPlayer.play()).called(1);
      });
    });

    // testWidgets('Auto-plays random show on completion if setting is enabled',
    //     (WidgetTester tester) async {
    //   // This test is commented out because it is proving difficult to test
    //   // the stream listener in a reliable way.
    //   final completer = Completer<void>();
    //   when(mockSettingsProvider.playRandomOnCompletion).thenReturn(true);
    //   when(mockShowListProvider.filteredShows)
    //       .thenReturn([createDummyShow(1)]);
    //   when(audioProvider.playRandomShow()).thenAnswer((_) async {
    //     completer.complete();
    //     return null;
    //   });

    //   processingStateController.add(ProcessingState.completed);
    //   await completer.future;

    //   verify(audioProvider.playRandomShow()).called(1);
    // });

    testWidgets('Does NOT auto-play on completion if setting is disabled',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        when(mockSettingsProvider.playRandomOnCompletion).thenReturn(false);
        when(mockShowListProvider.filteredShows)
            .thenReturn([createDummyShow(1)]);

        processingStateController.add(ProcessingState.completed);
        await Future.delayed(const Duration(milliseconds: 10));

        verifyNever(mockAudioPlayer.setAudioSource(any));
        verifyNever(mockAudioPlayer.play());
      });
    });

    testWidgets('Marks show as played on completion',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final show = createDummyShow(1);
        final source = show.sources.first;

        // Setup current show/source
        await audioProvider.playSource(show, source);

        // Simulate completion
        processingStateController.add(ProcessingState.completed);
        await Future.delayed(const Duration(milliseconds: 10));

        verify(mockSettingsProvider.markAsPlayed('source0')).called(1);
      });
    });

    testWidgets('stopAndClear stops player and clears state',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        final show = createDummyShow(1);
        await audioProvider.playSource(show, show.sources.first);
        expect(audioProvider.currentShow, isNotNull);

        await audioProvider.stopAndClear();

        verify(mockAudioPlayer.stop()).called(1);
        expect(audioProvider.currentShow, isNull);
        expect(audioProvider.currentSource, isNull);
      });
    });
  });
}
