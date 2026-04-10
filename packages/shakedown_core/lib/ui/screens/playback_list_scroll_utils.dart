import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';

Future<void> safeTrackListScrollTo({
  required bool mounted,
  required ItemScrollController controller,
  required int index,
  required double alignment,
  required Duration duration,
  required Curve curve,
}) async {
  if (!mounted || !controller.isAttached) return;
  try {
    await controller.scrollTo(
      index: index,
      duration: duration,
      curve: curve,
      alignment: alignment,
    );
  } catch (_) {
    // The list can detach between scheduling and execution on web.
  }
}

void safeTrackListJumpTo({
  required bool mounted,
  required ItemScrollController controller,
  required int index,
  required double alignment,
}) {
  if (!mounted || !controller.isAttached) return;
  try {
    controller.jumpTo(index: index, alignment: alignment);
  } catch (_) {
    // Ignore detach races during route/layout transitions.
  }
}

int calculateTrackListItems(Source source) {
  final Map<String, List<Track>> tracksBySet = {};
  for (final track in source.tracks) {
    tracksBySet.putIfAbsent(track.setName, () => <Track>[]).add(track);
  }

  var count = 0;
  tracksBySet.forEach((_, tracks) {
    count++;
    count += tracks.length;
  });
  return count;
}
