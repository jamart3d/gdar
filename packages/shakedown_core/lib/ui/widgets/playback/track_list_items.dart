import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';

class TrackListSection {
  TrackListSection({required this.setName, required this.tracks});

  final String setName;
  final List<Track> tracks;
}

sealed class TrackListItem {
  const TrackListItem();
}

final class TrackListShowHeaderItem extends TrackListItem {
  const TrackListShowHeaderItem();
}

final class TrackListSetHeaderItem extends TrackListItem {
  const TrackListSetHeaderItem(this.setName);

  final String setName;
}

final class TrackListTrackItem extends TrackListItem {
  const TrackListTrackItem({required this.track, required this.trackIndex});

  final Track track;
  final int trackIndex;
}

class TrackListLayout {
  const TrackListLayout({
    required this.sections,
    required this.items,
    required this.trackIndexToItemIndex,
    required this.itemIndexToTrackIndex,
  });

  final List<TrackListSection> sections;
  final List<TrackListItem> items;
  final Map<int, int> trackIndexToItemIndex;
  final Map<int, int> itemIndexToTrackIndex;
}

TrackListLayout buildTrackListLayout(
  Source source, {
  bool includeShowHeader = false,
}) {
  final sections = <TrackListSection>[];
  for (final track in source.tracks) {
    if (sections.isEmpty || sections.last.setName != track.setName) {
      sections.add(TrackListSection(setName: track.setName, tracks: [track]));
      continue;
    }
    sections.last.tracks.add(track);
  }

  final items = <TrackListItem>[
    if (includeShowHeader) const TrackListShowHeaderItem(),
  ];
  final trackIndexToItemIndex = <int, int>{};
  final itemIndexToTrackIndex = <int, int>{};

  var trackIndex = 0;
  for (final section in sections) {
    items.add(TrackListSetHeaderItem(section.setName));
    for (final track in section.tracks) {
      final itemIndex = items.length;
      items.add(TrackListTrackItem(track: track, trackIndex: trackIndex));
      trackIndexToItemIndex[trackIndex] = itemIndex;
      itemIndexToTrackIndex[itemIndex] = trackIndex;
      trackIndex++;
    }
  }

  return TrackListLayout(
    sections: sections,
    items: items,
    trackIndexToItemIndex: trackIndexToItemIndex,
    itemIndexToTrackIndex: itemIndexToTrackIndex,
  );
}
