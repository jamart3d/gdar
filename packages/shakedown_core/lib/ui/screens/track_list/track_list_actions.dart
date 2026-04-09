import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/screens/fruit_tab_host_screen.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';
import 'package:shakedown_core/utils/app_haptics.dart';

enum TrackTapActionKind { showPlayOnTapMenu, seekCurrentSource, playFromHeader }

TrackTapActionKind resolveTrackTapAction({
  required bool playOnTap,
  required String? currentSourceId,
  required String sourceId,
}) {
  if (!playOnTap) {
    return TrackTapActionKind.showPlayOnTapMenu;
  }

  if (currentSourceId == sourceId) {
    return TrackTapActionKind.seekCurrentSource;
  }

  return TrackTapActionKind.playFromHeader;
}

Future<void> executePlayAndNavigate({
  required BuildContext context,
  required Show show,
  required Source source,
  required bool isFruit,
  required bool Function() isMounted,
  required VoidCallback stopAnimationController,
  required VoidCallback repeatAnimationController,
}) async {
  unawaited(AppHaptics.selectionClick(context.read<DeviceService>()));
  final audioProvider = context.read<AudioProvider>();
  unawaited(audioProvider.playSource(show, source));

  if (context.read<DeviceService>().isTv) {
    Navigator.of(context).pop();
    context.read<AudioProvider>().requestPlaybackFocus();
    return;
  }

  if (isFruit) {
    if (!isMounted()) {
      return;
    }

    await Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FruitTabHostScreen(initialTab: 0),
        transitionDuration: Duration.zero,
      ),
      (route) => false,
    );
    return;
  }

  stopAnimationController();

  await Navigator.of(context).push(
    PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const PlaybackScreen(),
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;
        final tween = Tween(
          begin: begin,
          end: end,
        ).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ),
  );

  if (isMounted()) {
    repeatAnimationController();
  }
}

Future<void> handleTrackTap({
  required BuildContext context,
  required Source source,
  required int trackIndex,
  required SettingsProvider settingsProvider,
  required AudioProvider audioProvider,
  required ColorScheme colorScheme,
  required Offset? tapPosition,
  required Future<void> Function({required int initialIndex})
  playShowFromHeader,
  required VoidCallback togglePlayOnTap,
}) async {
  final action = resolveTrackTapAction(
    playOnTap: settingsProvider.playOnTap,
    currentSourceId: audioProvider.currentSource?.id,
    sourceId: source.id,
  );

  switch (action) {
    case TrackTapActionKind.showPlayOnTapMenu:
      final screenSize = MediaQuery.sizeOf(context);
      final pos =
          tapPosition ?? Offset(screenSize.width / 2, screenSize.height / 2);

      final result = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          pos.dx,
          pos.dy,
          screenSize.width - pos.dx,
          screenSize.height - pos.dy,
        ),
        items: [
          PopupMenuItem<String>(
            enabled: false,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              '"Play on Tap" is off',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const PopupMenuItem<String>(
            value: 'enable',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.touch_app_rounded, size: 16),
                SizedBox(width: 8),
                Text('Enable Play on Tap'),
              ],
            ),
          ),
        ],
      );

      if (result == 'enable') {
        togglePlayOnTap();
      }
      return;
    case TrackTapActionKind.seekCurrentSource:
      audioProvider.captureUndoCheckpoint();
      audioProvider.seekToTrack(trackIndex);
      return;
    case TrackTapActionKind.playFromHeader:
      unawaited(playShowFromHeader(initialIndex: trackIndex));
      return;
  }
}
