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
import 'package:just_audio/just_audio.dart';

class TrackListView extends StatelessWidget {
  final Source source;
  final double bottomPadding;
  final double topPadding;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final AudioProvider audioProvider;
  final Map<int, FocusNode>? trackFocusNodes;
  final VoidCallback? onFocusLeft;
  final VoidCallback? onFocusRight;
  final ValueChanged<int>? onTrackFocused;
  final ValueChanged<int>? onWrapAround; // Added for robust wrap-around

  const TrackListView({
    super.key,
    required this.source,
    required this.bottomPadding,
    this.topPadding = 0.0,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.audioProvider,
    this.trackFocusNodes,
    this.onFocusLeft,
    this.onFocusRight,
    this.onTrackFocused,
    this.onWrapAround,
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
    final Map<int, int> trackToListItemIndex = {};
    int currentTrackIndex = 0;

    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName);
      for (var track in tracks) {
        final lIdx = listItems.length;
        listItemToTrackIndex[lIdx] = currentTrackIndex;
        trackToListItemIndex[currentTrackIndex] = lIdx;
        currentTrackIndex++;
        listItems.add(track);
      }
    });

    final int firstTrackListIndex = trackToListItemIndex[0] ?? 1;
    final int lastTrackListIndex =
        trackToListItemIndex[source.tracks.length - 1] ??
            (listItems.length - 1);

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
            context,
            audioProvider,
            item,
            trackIndex,
            index, // Pass list index
            isTrueBlackMode,
            firstTrackListIndex,
            lastTrackListIndex,
          );
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
    int trackIndex,
    int listIndex,
    bool isTrueBlackMode,
    int firstTrackListIndex,
    int lastTrackListIndex,
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
                      child: _buildTrackListTile(
                          context,
                          audioProvider,
                          track,
                          trackIndex,
                          isPlaying,
                          scaleFactor,
                          false), // Pass false or handle differently if needed
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildTrackListTile(context, audioProvider, track,
                      trackIndex, isPlaying, scaleFactor, false),
                ),
        );

        if (isTv) {
          Widget content = _buildTrackListTile(
              context,
              audioProvider,
              track,
              trackIndex,
              isPlaying,
              scaleFactor,
              true); // Pass focused state if needed, or just rely on wrapper

          if (isPlaying && settingsProvider.highlightPlayingWithRgb) {
            content = AnimatedGradientBorder(
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
              showShadow: false,
              glowOpacity: 0.5 * (settingsProvider.glowMode / 100.0),
              animationSpeed: settingsProvider.rgbAnimationSpeed,
              child: Material(
                color: isTrueBlackMode
                    ? Colors.black
                    : colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
                clipBehavior: Clip.antiAlias,
                child: content,
              ),
            );
          }

          trackItem = TvFocusWrapper(
            focusNode: trackFocusNodes?[listIndex],
            scaleOnFocus: 1.0, // Disable scaling as requested
            focusBackgroundColor: Colors.transparent, // Disable background fill
            focusColor: colorScheme.primary, // Show focus border
            borderRadius: BorderRadius.circular(8), // Tighter radius
            onFocusChange: (focused) {
              if (focused) onTrackFocused?.call(listIndex);
            },
            onKeyEvent: (node, event) {
              if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                if (event is KeyDownEvent) onFocusLeft?.call();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                if (event is KeyDownEvent) onFocusRight?.call();
                return KeyEventResult.handled;
              } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                // Wrap-around logic: If last track item, go to first track item
                if (trackIndex == source.tracks.length - 1) {
                  if (event is KeyDownEvent) {
                    onWrapAround?.call(firstTrackListIndex);
                  }
                  return KeyEventResult
                      .handled; // Consume repeats to prevent bubbling/jumps
                }
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                // Wrap-around logic: If first track item, go to last track item
                if (trackIndex == 0) {
                  if (event is KeyDownEvent) {
                    onWrapAround?.call(lastTrackListIndex);
                  }
                  return KeyEventResult
                      .handled; // Consume repeats to prevent bubbling/jumps
                }
              }
              return KeyEventResult.ignored;
            },
            onTap: () {
              if (isPlaying) {
                // Toggle Play/Pause if this is the current track
                // We need to check actual player state to toggle correctly
                if (audioProvider.isPlaying) {
                  audioProvider.pause();
                } else {
                  audioProvider.resume();
                }
              } else {
                HapticFeedback.lightImpact();
                audioProvider.seekToTrack(trackIndex);
              }
            },
            child: content,
          );
        }

        return trackItem;
      },
    );
  }

  Widget _buildTrackListTile(BuildContext context, AudioProvider audioProvider,
      Track track, int trackIndex, bool isPlaying, double scaleFactor,
      [bool isTvFocus = false]) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsProvider = context.watch<SettingsProvider>();

    final baseTitleStyle =
        textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);

    // Simplified centralized font sizing
    final double titleFontSize = AppTypography.responsiveFontSize(
        context,
        context.read<DeviceService>().isTv
            ? 14.0
            : 16.0); // Smaller font for TV

    final titleStyle = baseTitleStyle.copyWith(
      fontSize: titleFontSize,
      fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
      color: isPlaying ? colorScheme.primary : colorScheme.onSurface,
      height: 1.1, // Fix vertical jump when bolding
    );

    // TV Playback Indicator Logic
    Widget? leadingWidget;
    final isTv = context.read<DeviceService>().isTv;

    if (isPlaying && isTv) {
      leadingWidget = StreamBuilder<PlayerState>(
        stream: audioProvider.playerStateStream,
        builder: (context, snapshot) {
          final processingState = snapshot.data?.processingState;
          final playing = snapshot.data?.playing ?? false;

          if (processingState == ProcessingState.loading ||
              processingState == ProcessingState.buffering) {
            return SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.primary,
              ),
            );
          } else if (playing) {
            return Icon(Icons.pause, color: colorScheme.primary);
          } else {
            return Icon(Icons.play_arrow, color: colorScheme.primary);
          }
        },
      );
    }

    final Widget listTile = ListTile(
      leading: leadingWidget,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      visualDensity: context.read<DeviceService>().isTv
          ? VisualDensity.compact // Reduce height on TV
          : VisualDensity.standard,
      contentPadding: context.read<DeviceService>().isTv
          ? const EdgeInsets.symmetric(
              horizontal: 12, vertical: 0) // Tighter padding
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
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
          : (isPlaying && isTv
              ? StreamBuilder<Duration>(
                  stream: audioProvider.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return Text(
                      '${formatDuration(position)} / ${formatDuration(Duration(seconds: track.duration))}',
                      style: textTheme.bodyMedium
                          ?.apply(fontSizeFactor: scaleFactor)
                          .copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    );
                  },
                )
              : Text(
                  formatDuration(Duration(seconds: track.duration)),
                  style: textTheme.bodyMedium
                      ?.apply(fontSizeFactor: scaleFactor)
                      .copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                )),
      onTap: () {
        if (!isPlaying) {
          HapticFeedback.lightImpact();
          audioProvider.seekToTrack(trackIndex);
        }
      },
    );

    if (isPlaying && isTv) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          listTile,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                height: 2,
                child: StreamBuilder<Duration>(
                  stream: audioProvider.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final duration = Duration(seconds: track.duration);
                    final progress = duration.inSeconds > 0
                        ? position.inSeconds / duration.inSeconds
                        : 0.0;

                    return StreamBuilder<Duration>(
                      stream: audioProvider.bufferedPositionStream,
                      builder: (context, buffSnapshot) {
                        final buffered = buffSnapshot.data ?? Duration.zero;
                        final bufferedProgress = duration.inSeconds > 0
                            ? buffered.inSeconds / duration.inSeconds
                            : 0.0;

                        return Stack(
                          children: [
                            Container(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.1)),
                            FractionallySizedBox(
                              widthFactor: bufferedProgress.clamp(0.0, 1.0),
                              child: Container(
                                color: colorScheme.tertiary
                                    .withValues(alpha: 0.25),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      colorScheme.primary,
                                      colorScheme.tertiary,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      );
    }

    return listTile;
  }
}
