import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/ui/widgets/playback/track_list_view.dart';

import '../../../helpers/test_helpers.dart';

class _FakeGaplessPlayer extends Fake implements GaplessPlayer {
  @override
  int? get currentIndex => 1;

  @override
  Stream<int?> get currentIndexStream => Stream<int?>.value(1);
}

class _RecordingAudioProvider extends ChangeNotifier implements AudioProvider {
  _RecordingAudioProvider({GaplessPlayer? audioPlayer})
    : audioPlayer = audioPlayer ?? _FakeGaplessPlayer();

  @override
  final GaplessPlayer audioPlayer;

  final List<int> seekRequests = <int>[];
  int captureUndoCheckpointCalls = 0;

  @override
  Stream<int?> get currentIndexStream => audioPlayer.currentIndexStream;

  @override
  Track? get currentTrack => null;

  @override
  bool get isPlaying => true;

  @override
  Future<void> seekToTrack(int index) async {
    seekRequests.add(index);
  }

  @override
  void captureUndoCheckpoint() {
    captureUndoCheckpointCalls++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Source _buildSource() {
  return Source(
    id: 'gd77-05-08.sbd',
    tracks: [
      Track(
        trackNumber: 1,
        title: 'Bertha',
        duration: 365,
        url: 'https://archive.org/1.mp3',
        setName: 'Set 1',
      ),
      Track(
        trackNumber: 2,
        title: 'Drums',
        duration: 420,
        url: 'https://archive.org/2.mp3',
        setName: 'Encore',
      ),
      Track(
        trackNumber: 3,
        title: 'U.S. Blues',
        duration: 310,
        url: 'https://archive.org/3.mp3',
        setName: 'Set 1',
      ),
    ],
  );
}

void main() {
  testWidgets(
    'TrackListView preserves contiguous set order and forwards track taps',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        'show_track_numbers': true,
        'hide_track_duration': false,
        'highlight_playing_with_rgb': false,
      });
      final prefs = await SharedPreferences.getInstance();
      final settingsProvider = SettingsProvider(prefs);
      final audioProvider = _RecordingAudioProvider();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(
              value: settingsProvider,
            ),
            ChangeNotifierProvider<ThemeProvider>(
              create: (_) => ThemeProvider(),
            ),
            ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
            ChangeNotifierProvider<DeviceService>.value(
              value: MockDeviceService(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TrackListView(
                source: _buildSource(),
                bottomPadding: 40,
                itemScrollController: ItemScrollController(),
                itemPositionsListener: ItemPositionsListener.create(),
                audioProvider: audioProvider,
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      final setOneFinder = find.text('Set 1');
      final encoreFinder = find.text('Encore');

      expect(setOneFinder, findsNWidgets(2));
      expect(encoreFinder, findsOneWidget);

      final firstSetOneY = tester.getTopLeft(setOneFinder.first).dy;
      final encoreY = tester.getTopLeft(encoreFinder).dy;
      final secondSetOneY = tester.getTopLeft(setOneFinder.last).dy;

      expect(firstSetOneY, lessThan(encoreY));
      expect(encoreY, lessThan(secondSetOneY));

      await tester.tap(find.text('3. U.S. Blues'));
      await tester.pump();

      expect(audioProvider.seekRequests, [2]);
      expect(audioProvider.captureUndoCheckpointCalls, 1);
    },
  );
}
