import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/ui/widgets/conditional_marquee.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/utils.dart';

class TrackListView extends StatelessWidget {
  final Source source;
  final double bottomPadding;
  final double topPadding;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final AudioProvider audioProvider;

  const TrackListView({
    super.key,
    required this.source,
    required this.bottomPadding,
    this.topPadding = 0.0,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.audioProvider,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final Map<String, List<Track>> tracksBySet = {};
    for (var track in source.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName]!.add(track);
    }

    final List<dynamic> listItems = [];
    final Map<int, int> listItemToTrackIndex = {};
    int currentTrackIndex = 0;

    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName);
      for (var track in tracks) {
        listItemToTrackIndex[listItems.length] = currentTrackIndex++;
        listItems.add(track);
      }
    });

    return ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      padding: EdgeInsets.fromLTRB(8, topPadding, 8, bottomPadding),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];
        if (item is String) {
          return _buildSetHeader(context, item);
        } else if (item is Track) {
          final trackIndex = listItemToTrackIndex[index] ?? 0;
          return _buildTrackItem(
              context, audioProvider, item, trackIndex, isTrueBlackMode);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSetHeader(BuildContext context, String setName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        setName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: AppTypography.responsiveFontSize(context, 14.0),
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTrackItem(
    BuildContext context,
    AudioProvider audioProvider,
    Track track,
    int index,
    bool isTrueBlackMode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, snapshot) {
        // Use currentTrack equality for robust highlighting (handles seamless playback)
        final currentTrack = audioProvider.currentTrack;
        final isPlaying = currentTrack != null &&
            currentTrack.title == track.title &&
            currentTrack.trackNumber == track.trackNumber;

        final deviceService = context.watch<DeviceService>();
        final isTv = deviceService.isTv;
        final double scaleFactor =
            FontLayoutConfig.getEffectiveScale(context, settingsProvider);

        Widget trackItem = Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          decoration: BoxDecoration(
            color: (isPlaying && settingsProvider.highlightPlayingWithRgb)
                ? Colors.transparent
                : isPlaying
                    ? (isTrueBlackMode
                        ? Colors.black
                        : colorScheme.primaryContainer)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: (isPlaying && settingsProvider.highlightPlayingWithRgb)
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: AnimatedGradientBorder(
                    borderRadius: 12,
                    borderWidth: 4,
                    colors: const [
                      Colors.red,
                      Colors.yellow,
                      Colors.green,
                      Colors.cyan,
                      Colors.blue,
                      Colors.purple,
                      Colors.red,
                    ],
                    showGlow: true,
                    showShadow: !isTv && settingsProvider.glowMode > 0,
                    glowOpacity: 0.5 * (settingsProvider.glowMode / 100.0),
                    animationSpeed: settingsProvider.rgbAnimationSpeed,
                    child: Material(
                      color: isTrueBlackMode
                          ? Colors.black
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: _buildTrackListTile(context, audioProvider, track,
                          index, isPlaying, scaleFactor),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildTrackListTile(context, audioProvider, track,
                      index, isPlaying, scaleFactor),
                ),
        );

        if (isTv) {
          trackItem = TvFocusWrapper(
            onTap: () {
              if (!isPlaying) {
                HapticFeedback.lightImpact();
                audioProvider.seekToTrack(index);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: trackItem,
          );
        }

        return trackItem;
      },
    );
  }

  Widget _buildTrackListTile(BuildContext context, AudioProvider audioProvider,
      Track track, int index, bool isPlaying, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsProvider = context.watch<SettingsProvider>();

    final baseTitleStyle =
        textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);

    // Simplified centralized font sizing
    final double titleFontSize =
        AppTypography.responsiveFontSize(context, 16.0);

    final titleStyle = baseTitleStyle.copyWith(
      fontSize: titleFontSize,
      fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
      color: isPlaying ? colorScheme.primary : colorScheme.onSurface,
      height: 1.1, // Fix vertical jump when bolding
    );

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: SizedBox(
        height: titleStyle.fontSize! *
            (settingsProvider.appFont == 'rock_salt' ? 2.0 : 1.6),
        child: ConditionalMarquee(
          text: settingsProvider.showTrackNumbers
              ? '${track.trackNumber}. ${track.title}'
              : track.title,
          style: titleStyle,
          textAlign: settingsProvider.hideTrackDuration
              ? TextAlign.center
              : TextAlign.start,
        ),
      ),
      trailing: settingsProvider.hideTrackDuration
          ? null
          : Text(
              formatDuration(Duration(seconds: track.duration)),
              style: textTheme.bodyMedium
                  ?.apply(fontSizeFactor: scaleFactor)
                  .copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
            ),
      onTap: () {
        if (!isPlaying) {
          HapticFeedback.lightImpact();
          audioProvider.seekToTrack(index);
        }
      },
    );
  }
}
