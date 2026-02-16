import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_dual_pane_layout.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:just_audio/just_audio.dart';

// Manual Mock definitions to avoid code generation dependency for this quick test
class MockAudioProvider extends ChangeNotifier implements AudioProvider {
  final _randomShowRequestController =
      StreamController<({Show show, Source source})>.broadcast();
  int playRandomShowCallCount = 0;
  int playPendingSelectionCallCount = 0;
  int playSourceCallCount = 0;

  @override
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      _randomShowRequestController.stream;

  bool _isPlaying = false;

  @override
  bool get isPlaying => _isPlaying;

  @override
  Show? get currentShow => Show(
        date: '1977-05-08',
        venue: 'Cornell',
        name: 'Cornell 77',
        artist: 'Grateful Dead',
        sources: [
          Source(id: '123', tracks: [
            Track(
              trackNumber: 1,
              title: 'Track 1',
              duration: 180,
              url: 'http://example.com/track.mp3',
              setName: 'Set 1',
            )
          ])
        ],
      );

  @override
  Source? get currentSource => currentShow!.sources.first;

  @override
  Track? get currentTrack => currentShow?.sources.first.tracks.first;

  ({Show show, Source source})? _pendingRequest;

  @override
  ({Show show, Source source})? get pendingRandomShowRequest => _pendingRequest;

  @override
  Future<Show?> playRandomShow({
    bool filterBySearch = true,
    bool animationOnly = false,
    bool delayPlayback = false,
  }) async {
    playRandomShowCallCount++;
    if (delayPlayback) {
      _pendingRequest = (show: currentShow!, source: currentSource!);
      _randomShowRequestController
          .add((show: currentShow!, source: currentSource!));
    }
    return currentShow;
  }

  @override
  Future<void> playPendingSelection() async {
    playPendingSelectionCallCount++;
    // Simulate what playPendingSelection does: calls playSource
    await playSource(currentShow!, currentSource!);
  }

  @override
  Future<void> playSource(Show show, Source source,
      {int initialIndex = 0, Duration? initialPosition}) async {
    playSourceCallCount++;
    _isPlaying = true;
  }

  // Stubs for other used members
  @override
  Stream<String> get playbackErrorStream => Stream.empty();
  @override
  Stream<PlayerState> get playerStateStream => Stream.empty();
  @override
  Stream<Duration> get positionStream => Stream.empty();
  @override
  Stream<Duration> get bufferedPositionStream => Stream.empty();
  @override
  Stream<int?> get currentIndexStream => Stream.empty();
  @override
  AudioPlayer get audioPlayer =>
      AudioPlayer(); // This might need a mock too if accessed deep

  @override
  void update(ShowListProvider slp, SettingsProvider sp) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get showPlaybackMessages => false;
  @override
  bool get useTrueBlack => false;
  @override
  bool get highlightCurrentShowCard => false;
  @override
  bool get uiScale => false;
  @override
  String get appFont => 'Roboto';
  @override
  bool get showTrackNumbers => true;
  @override
  bool get highlightPlayingWithRgb => false;
  @override
  double get rgbAnimationSpeed => 1.0;
  @override
  int get glowMode => 0;
  @override
  bool get hideTrackDuration => false;
  @override
  bool get playRandomOnStartup => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockShowListProvider extends ChangeNotifier implements ShowListProvider {
  @override
  bool get isChoosingRandomShow => false;
  @override
  List<Show> get allShows => [];
  @override
  List<Show> get filteredShows => [];

  @override
  bool get isSearchVisible => false;

  @override
  bool get hasUsedRandomButton => false;

  @override
  bool get isLoading => false;

  @override
  String? get error => null;

  @override
  void setIsChoosingRandomShow(bool value) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => true;
  @override
  String? get deviceName => 'Test TV';
  @override
  Future<void> refresh() async {}
}

void main() {
  testWidgets(
      'TvDualPaneLayout debouncing fails to prevent double playback if playback starts early',
      (WidgetTester tester) async {
    final mockAudioProvider = MockAudioProvider();
    final mockSettingsProvider = MockSettingsProvider();
    final mockShowListProvider = MockShowListProvider();
    final mockDeviceService = MockDeviceService();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
          ChangeNotifierProvider<SettingsProvider>.value(
              value: mockSettingsProvider),
          ChangeNotifierProvider<ShowListProvider>.value(
              value: mockShowListProvider),
          ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
        ],
        child: MaterialApp(
          home: TvDualPaneLayout(),
        ),
      ),
    );

    // Initial state
    expect(mockAudioProvider.playRandomShowCallCount, 0);
    expect(mockAudioProvider.playSourceCallCount, 0);

    // Tap the dice
    await tester.tap(find.byType(AnimatedDiceIcon));
    await tester.pump();

    expect(mockAudioProvider.playRandomShowCallCount, 1);

    // 1.2s delay for Show List
    await tester.pump(const Duration(milliseconds: 1200));

    // 2.0s delay for Pane Switch (Track List Focus)
    await tester.pump(const Duration(milliseconds: 2000));

    // SIMULATE PREMATURE PLAYBACK (e.g. from accidental focus trigger)
    // We manually call playSource as if the system triggered it.
    await mockAudioProvider.playSource(
        mockAudioProvider.currentShow!, mockAudioProvider.currentSource!);
    expect(mockAudioProvider.playSourceCallCount, 1);

    // 2.0s delay for Playback Start (Timer finishes)
    await tester.pump(const Duration(milliseconds: 2000));

    // Clear the 500ms safety buffer timer
    await tester.pump(const Duration(milliseconds: 500));

    // Check call count. If 2, then the bug exists (it tried to play again).
    // The bug we want to fix is that it SHOULD be 1 (TvDualPaneLayout should catch it).
    expect(mockAudioProvider.playSourceCallCount, 1,
        reason: 'Double playback prevented!');
  });
}
