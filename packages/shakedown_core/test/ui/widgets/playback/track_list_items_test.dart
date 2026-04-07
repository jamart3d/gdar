import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/ui/widgets/playback/track_list_items.dart';

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
        title: 'Good Lovin\'',
        duration: 420,
        url: 'https://archive.org/2.mp3',
        setName: 'Set 1',
      ),
      Track(
        trackNumber: 3,
        title: 'U.S. Blues',
        duration: 310,
        url: 'https://archive.org/3.mp3',
        setName: 'Encore',
      ),
    ],
  );
}

void main() {
  group('buildTrackListLayout', () {
    test('preserves section order and flattened item mappings', () {
      final layout = buildTrackListLayout(
        _buildSource(),
        includeShowHeader: true,
      );

      expect(layout.sections.length, 2);
      expect(layout.sections[0].setName, 'Set 1');
      expect(layout.sections[0].tracks.map((track) => track.title).toList(), [
        'Bertha',
        'Good Lovin\'',
      ]);
      expect(layout.sections[1].setName, 'Encore');
      expect(layout.sections[1].tracks.map((track) => track.title).toList(), [
        'U.S. Blues',
      ]);

      expect(layout.items.first, isA<TrackListShowHeaderItem>());
      expect(
        layout.items
            .whereType<TrackListSetHeaderItem>()
            .map((item) => item.setName)
            .toList(),
        ['Set 1', 'Encore'],
      );
      expect(
        layout.items
            .whereType<TrackListTrackItem>()
            .map((item) => item.track.title)
            .toList(),
        ['Bertha', 'Good Lovin\'', 'U.S. Blues'],
      );

      expect(layout.trackIndexToItemIndex[0], 2);
      expect(layout.trackIndexToItemIndex[1], 3);
      expect(layout.trackIndexToItemIndex[2], 5);

      expect(layout.itemIndexToTrackIndex[2], 0);
      expect(layout.itemIndexToTrackIndex[3], 1);
      expect(layout.itemIndexToTrackIndex[5], 2);
    });

    test('omits the show header when not requested', () {
      final layout = buildTrackListLayout(_buildSource());

      expect(layout.items.first, isA<TrackListSetHeaderItem>());
      expect(layout.items[1], isA<TrackListTrackItem>());
      expect(layout.items[2], isA<TrackListTrackItem>());
      expect(layout.items[3], isA<TrackListSetHeaderItem>());
      expect(layout.items[4], isA<TrackListTrackItem>());

      expect(layout.trackIndexToItemIndex[0], 1);
      expect(layout.trackIndexToItemIndex[1], 2);
      expect(layout.trackIndexToItemIndex[2], 4);
    });
  });
}
