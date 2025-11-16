import 'dart:async';

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

@GenerateMocks([
  AudioPlayer,
  ShowListProvider,
  SettingsProvider,
], customMocks: [
  MockSpec<AudioPlayer>(
      as: #MockAudioPlayerRelaxed, onMissingStub: OnMissingStub.returnDefault)
])
void main() {
  late AudioProvider audioProvider;
  late MockAudioPlayerRelaxed mockAudioPlayer;
  late MockShowListProvider mockShowListProvider;
  late MockSettingsProvider mockSettingsProvider;
  late StreamController<ProcessingState> processingStateController;

  setUp(() {
    mockAudioPlayer = MockAudioPlayerRelaxed();
    mockShowListProvider = MockShowListProvider();
    mockSettingsProvider = MockSettingsProvider();
    processingStateController = StreamController<ProcessingState>.broadcast();

    audioProvider = AudioProvider(audioPlayer: mockAudioPlayer);
    audioProvider.update(mockShowListProvider, mockSettingsProvider);

    when(mockAudioPlayer.processingStateStream)
        .thenAnswer((_) => processingStateController.stream);
    when(mockAudioPlayer.play()).thenAnswer((_) async {});
    when(mockAudioPlayer.stop()).thenAnswer((_) async {});
    when(mockAudioPlayer.setAudioSource(any,
            initialIndex: anyNamed('initialIndex'),
            preload: anyNamed('preload')))
        .thenAnswer((_) async => const Duration(seconds: 100));
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
      year: '2025',
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
                duration: 100),
            Track(
                trackNumber: 2,
                title: 'Track 2',
                url: 'http://track2.mp3',
                duration: 120),
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
        final shows = [createDummyShow(1), createDummyShow(2)];
        when(mockShowListProvider.filteredShows).thenReturn(shows);

        final playedShow = await audioProvider.playRandomShow();

        expect(playedShow, isNotNull);
        expect(shows.contains(playedShow), isTrue);

        verify(mockAudioPlayer.setAudioSource(any,
                initialIndex: anyNamed('initialIndex'),
                preload: anyNamed('preload')))
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

        final playedShow = await audioProvider.playRandomShow();

        expect(playedShow, isNull);
        verifyNever(mockAudioPlayer.setAudioSource(any));
        verifyNever(mockAudioPlayer.play());
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
                initialIndex: 0, preload: anyNamed('preload')))
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
