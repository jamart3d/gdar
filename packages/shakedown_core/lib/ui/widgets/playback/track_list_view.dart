import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/conditional_marquee.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/styles/font_config.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_reload_dialog.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_activity_indicator.dart';

class TrackListView extends StatelessWidget {
  final Source source;
  final double bottomPadding;
  final double topPadding;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final AudioProvider audioProvider;
  final Map<int, FocusNode>? trackFocusNodes;
  final FocusNode? trackListFocusNode;
  final VoidCallback? onFocusLeft;
  final VoidCallback? onFocusRight;
  final ValueChanged<int>? onTrackFocused;
  final void Function(int, {bool shouldScroll})?
  onWrapAround; // Added for robust wrap-around
  final int? initialScrollIndex;
  final double initialScrollAlignment;

  const TrackListView({
    super.key,
    required this.source,
    required this.bottomPadding,
    this.topPadding = 0.0,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.audioProvider,
    this.trackFocusNodes,
    this.trackListFocusNode,
    this.onFocusLeft,
    this.onFocusRight,
    this.onTrackFocused,
    this.onWrapAround,
    this.initialScrollIndex,
    this.initialScrollAlignment = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;
    final isTv = context.watch<DeviceService>().isTv;

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

    int resolvedInitialIndex = initialScrollIndex ?? 0;
    if (initialScrollIndex == null && audioProvider.currentTrack != null) {
      for (int i = 0; i < listItems.length; i++) {
        final item = listItems[i];
        if (item is Track &&
            item.title == audioProvider.currentTrack!.title &&
            item.trackNumber == audioProvider.currentTrack!.trackNumber) {
          resolvedInitialIndex = i;
          break;
        }
      }
    }

    return Focus(
      focusNode: trackListFocusNode,
      child: ScrollablePositionedList.builder(
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        initialScrollIndex: resolvedInitialIndex,
        initialAlignment: initialScrollAlignment,
        padding: isTv
            ? EdgeInsets.fromLTRB(28, topPadding, 28, bottomPadding)
            : EdgeInsets.fromLTRB(8, topPadding, 8, bottomPadding),
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
              index,
              isTrueBlackMode,
              firstTrackListIndex,
              lastTrackListIndex,
              ValueKey('track_${item.trackNumber}_${item.title}_$index'),
            );
          }
          return const SizedBox.shrink();
        },
      ),
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
    Key key,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final deviceService = context.watch<DeviceService>();
    final isTv = deviceService.isTv;

    return StreamBuilder<int?>(
      key: key,
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, snapshot) {
        final currentIdx = snapshot.data;
        // Use direct index comparison for maximum stability and reactivity
        final isPlaying = currentIdx == trackIndex;
        final double scaleFactor = FontLayoutConfig.getEffectiveScale(
          context,
          settingsProvider,
        );

        final themeProvider = context.watch<ThemeProvider>();
        final bool isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

        // Consolidated highlight logic:
        // On TV, we suppress this mobile-style AnimatedGradientBorder and let
        // TvFocusWrapper handle it via showGlow or Premium Highlight.
        final bool showMobilePlayingBorder =
            !isTv && isPlaying && settingsProvider.highlightPlayingWithRgb;

        Widget trackItem = Container(
          margin: EdgeInsets.symmetric(
            horizontal: isFruit ? 8 : 16,
            vertical: isFruit ? 2 : 1,
          ),
          decoration: BoxDecoration(
            color: showMobilePlayingBorder
                ? Colors.transparent
                : (isPlaying && !isFruit && !isTv)
                ? (isTrueBlackMode
                      ? Colors.black
                      : colorScheme.primaryContainer)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(isFruit ? 14 : 12),
          ),
          child: showMobilePlayingBorder
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: AnimatedGradientBorder(
                    borderRadius: 12,
                    borderWidth: 4,
                    ignoreGlobalClock: true,
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
                        false,
                        currentIdx,
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(isFruit ? 6.0 : 8.0),
                  child: _buildTrackListTile(
                    context,
                    audioProvider,
                    track,
                    trackIndex,
                    isPlaying,
                    scaleFactor,
                    false,
                    currentIdx,
                  ),
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
            true,
            currentIdx,
          );

          trackItem = TvFocusWrapper(
            focusNode: trackFocusNodes?[listIndex],
            scaleOnFocus: 1.0,
            isPlaying: isPlaying,
            focusDecoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 16,
                  spreadRadius: 4,
                ),
              ],
            ),
            focusColor: colorScheme.primary,
            borderRadius: BorderRadius.circular(8),
            // We rely purely on the crisp border for selection to avoid
            // BoxShadows filling the hollow transparent center of the item.
            showGlow: false,
            // Preserve the Premium highlight on focus even if it is the currently playing track.
            overridePremiumHighlight: null,
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
                if (trackIndex == source.tracks.length - 1) {
                  if (event is KeyDownEvent) {
                    onWrapAround?.call(firstTrackListIndex);
                  }
                  return KeyEventResult.handled;
                }
              } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                if (trackIndex == 0) {
                  if (event is KeyDownEvent) {
                    onWrapAround?.call(lastTrackListIndex);
                  }
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            onLongPress: () => _handleLongPress(context, audioProvider, track),
            onTap: () {
              if (isPlaying) {
                if (audioProvider.isPlaying) {
                  audioProvider.pause();
                } else {
                  audioProvider.resume();
                }
              } else {
                AppHaptics.lightImpact(context.read<DeviceService>());
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

  TextStyle _durationTextStyle(
    TextTheme textTheme,
    ColorScheme colorScheme,
    double scaleFactor, [
    bool isFruit = false,
    bool isDarkMode = true,
  ]) {
    final Color textColor = isFruit
        ? (isDarkMode
              ? Colors.white.withValues(alpha: 0.6)
              : Colors.black.withValues(alpha: 0.6))
        : colorScheme.onSurfaceVariant;

    return (textTheme.bodyMedium ?? const TextStyle())
        .apply(fontSizeFactor: scaleFactor)
        .copyWith(
          fontFamily: null, // clear inherited app font
          package: null,
          color: textColor,
          fontWeight: isFruit ? FontWeight.w500 : FontWeight.w500,
          letterSpacing: isFruit ? 0.3 : null,
          fontFeatures: const [FontFeature.tabularFigures()],
        )
        .merge(TextStyle(fontFamily: FontConfig.resolve('Roboto')));
  }

  Widget _buildTrackListTile(
    BuildContext context,
    AudioProvider audioProvider,
    Track track,
    int trackIndex,
    bool isPlaying,
    double scaleFactor, [
    bool isTvFocus = false,
    int? activeTrackIndex,
  ]) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();
    final bool isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final baseTitleStyle =
        textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);

    final double titleFontSize = AppTypography.responsiveFontSize(
      context,
      context.read<DeviceService>().isTv ? 14.0 : 16.0,
    );

    final Color titleColor = isFruit
        ? (isDarkMode
              ? Colors.white.withValues(alpha: isPlaying ? 1.0 : 0.9)
              : Colors.black.withValues(alpha: isPlaying ? 1.0 : 0.9))
        : (isPlaying ? colorScheme.primary : colorScheme.onSurface);

    final titleStyle = baseTitleStyle.copyWith(
      fontSize: titleFontSize,
      fontWeight: isPlaying ? FontWeight.w700 : FontWeight.w400,
      color: titleColor,
      height: 1.1,
      letterSpacing: isFruit ? -0.2 : null,
    );

    Widget? leadingWidget;
    final isTv = context.read<DeviceService>().isTv;

    if (isTv || isFruit) {
      if (isPlaying) {
        leadingWidget = StreamBuilder<PlayerState>(
          stream: audioProvider.playerStateStream,
          builder: (context, snapshot) {
            final processingState = snapshot.data?.processingState;
            final playing = snapshot.data?.playing ?? false;

            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return SizedBox(
                width: isFruit ? 32 : 24,
                height: isFruit ? 32 : 24,
                child: Center(
                  child: isFruit
                      ? FruitActivityIndicator(radius: 10, color: titleColor)
                      : SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        ),
                ),
              );
            } else {
              Widget icon = Icon(
                playing
                    ? (isFruit ? LucideIcons.pause : Icons.pause_rounded)
                    : (isFruit ? LucideIcons.play : Icons.play_arrow_rounded),
                color: isFruit ? titleColor : colorScheme.primary,
                size: isFruit ? 18 : 24,
              );

              if (isFruit) {
                icon = NeumorphicWrapper(
                  enabled: settingsProvider.useNeumorphism,
                  borderRadius: 20,
                  isCircle: true,
                  intensity: 0.8,
                  child: LiquidGlassWrapper(
                    enabled: !settingsProvider.useTrueBlack,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: settingsProvider.useTrueBlack
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.1),
                      ),
                      child: icon,
                    ),
                  ),
                );
              }

              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    final deviceService = context.read<DeviceService>();
                    AppHaptics.lightImpact(deviceService);
                    if (playing) {
                      audioProvider.pause();
                    } else {
                      audioProvider.audioPlayer.play();
                    }
                  },
                  child: icon,
                ),
              );
            }
          },
        );
      } else if (isFruit) {
        // Fruit: track state dot — played / next (buffered) / queued
        final activeIdx =
            activeTrackIndex ?? audioProvider.audioPlayer.currentIndex ?? -1;
        const dotSize = 32.0;
        final isPlayed = activeIdx >= 0 && trackIndex < activeIdx;
        final isNext = activeIdx >= 0 && trackIndex == activeIdx + 1;

        final Color dotColor;
        if (isPlayed) {
          dotColor = colorScheme.primary.withValues(alpha: 0.3);
        } else if (isNext) {
          final buffered = audioProvider.audioPlayer.nextTrackBuffered;
          final nextTotal = audioProvider.audioPlayer.nextTrackTotal;
          final hasBuffer = buffered != null && buffered.inMilliseconds > 0;
          final isFullyBuffered =
              hasBuffer &&
              nextTotal != null &&
              nextTotal.inMilliseconds > 0 &&
              buffered.inMilliseconds >= nextTotal.inMilliseconds - 500;
          dotColor = isFullyBuffered
              ? Colors.green
              : hasBuffer
              ? Colors.green.withValues(alpha: 0.6)
              : Colors.amber;
        } else {
          dotColor = isDarkMode
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.15);
        }
        leadingWidget = SizedBox(
          width: dotSize,
          height: dotSize,
          child: Center(
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor,
              ),
            ),
          ),
        );
      } else {
        // TV/non-Fruit: plain spacer for alignment
        leadingWidget = const SizedBox(width: 24, height: 24);
      }
    }

    final durationStyle = _durationTextStyle(
      textTheme,
      colorScheme,
      scaleFactor,
      isFruit,
      isDarkMode,
    );

    final Widget listTile = isFruit
        ? _FruitTrackTile(
            leading: leadingWidget,
            title: settingsProvider.showTrackNumbers
                ? '${track.trackNumber}. ${track.title}'
                : track.title,
            titleStyle: titleStyle,
            trailing: settingsProvider.hideTrackDuration
                ? null
                : (isPlaying && isTv
                      ? StreamBuilder<Duration>(
                          stream: audioProvider.positionStream,
                          builder: (context, snapshot) {
                            final position = snapshot.data ?? Duration.zero;
                            return Text(
                              '${formatDuration(position)} / ${formatDuration(Duration(seconds: track.duration))}',
                              style: durationStyle,
                            );
                          },
                        )
                      : Text(
                          formatDuration(Duration(seconds: track.duration)),
                          style: durationStyle,
                        )),
            isPlaying: isPlaying,
            onTap: isTv
                ? null
                : () {
                    if (!isPlaying) {
                      final deviceService = context.read<DeviceService>();
                      AppHaptics.lightImpact(deviceService);
                      audioProvider.seekToTrack(trackIndex);
                    }
                  },
            onLongPress: () => _handleLongPress(context, audioProvider, track),
            isTv: isTv,
            settingsProvider: settingsProvider,
          )
        : ListTile(
            leading: leadingWidget,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            visualDensity: context.read<DeviceService>().isTv
                ? VisualDensity.compact
                : VisualDensity.standard,
            contentPadding: context.read<DeviceService>().isTv
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 0)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            title: SizedBox(
              height:
                  titleStyle.fontSize! *
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
                              style: durationStyle,
                            );
                          },
                        )
                      : Text(
                          formatDuration(Duration(seconds: track.duration)),
                          style: durationStyle,
                        )),
            onTap: isTv
                ? null
                : () {
                    if (!isPlaying) {
                      final deviceService = context.read<DeviceService>();
                      AppHaptics.lightImpact(deviceService);
                      audioProvider.seekToTrack(trackIndex);
                    }
                  },
            onLongPress: () => _handleLongPress(context, audioProvider, track),
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
                width: double.infinity,
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
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.1,
                              ),
                            ),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: bufferedProgress.clamp(0.0, 1.0),
                              child: Container(
                                color: colorScheme.tertiary.withValues(
                                  alpha: 0.25,
                                ),
                              ),
                            ),
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
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

  void _handleLongPress(
    BuildContext context,
    AudioProvider audioProvider,
    Track track,
  ) {
    final playerState = audioProvider.audioPlayer.processingState;
    final isStuck =
        playerState == ProcessingState.loading ||
        playerState == ProcessingState.buffering;

    final isTv = context.read<DeviceService>().isTv;
    final isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;

    final currentTrack = audioProvider.currentTrack;
    final isThisTrack =
        currentTrack != null &&
        currentTrack.title == track.title &&
        currentTrack.trackNumber == track.trackNumber;

    // For TV, long-press is always a "Safety Reset" hatch.
    // For other platforms, only show for specifically stuck active tracks.
    if (!isTv && (!isStuck || !isThisTrack)) return;

    if (isTv) {
      TvReloadDialog.show(
        context,
        onReload: () => audioProvider.retryCurrentSource(),
        onHardReset: () => audioProvider.stopAndClear(),
      );
    } else {
      showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          final colorScheme = Theme.of(context).colorScheme;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Safety Hatch',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'Is the playback stuck? Try these options to reset the engine.',
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: Icon(
                    isFruit ? LucideIcons.refreshCw : Icons.refresh_rounded,
                  ),
                  title: const Text('Reload Current Show'),
                  onTap: () {
                    Navigator.pop(context);
                    audioProvider.retryCurrentSource();
                  },
                ),
                ListTile(
                  leading: Icon(
                    isFruit
                        ? LucideIcons.stopCircle
                        : Icons.stop_circle_rounded,
                    color: colorScheme.error,
                  ),
                  title: Text(
                    'Emergency Reset',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  subtitle: const Text('Clears playlist and stops all audio'),
                  onTap: () {
                    Navigator.pop(context);
                    audioProvider.stopAndClear();
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(isFruit ? LucideIcons.x : Icons.close_rounded),
                  title: const Text('Cancel'),
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      );
    }
  }
}

class _FruitTrackTile extends StatefulWidget {
  final Widget? leading;
  final String title;
  final TextStyle titleStyle;
  final Widget? trailing;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isTv;
  final SettingsProvider settingsProvider;

  const _FruitTrackTile({
    this.leading,
    required this.title,
    required this.titleStyle,
    this.trailing,
    required this.isPlaying,
    this.onTap,
    this.onLongPress,
    required this.isTv,
    required this.settingsProvider,
  });

  @override
  State<_FruitTrackTile> createState() => _FruitTrackTileState();
}

class _FruitTrackTileState extends State<_FruitTrackTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isTv ? null : (_) => setState(() => _isPressed = true),
      onTapUp: widget.isTv ? null : (_) => setState(() => _isPressed = false),
      onTapCancel: widget.isTv
          ? null
          : () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isPressed ? 0.6 : 1.0,
        child: Container(
          padding: widget.isTv
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                widget.leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SizedBox(
                  height:
                      widget.titleStyle.fontSize! *
                      (widget.settingsProvider.appFont == 'rock_salt'
                          ? 2.0
                          : 1.6),
                  child: ConditionalMarquee(
                    text: widget.title,
                    style: widget.titleStyle,
                    textAlign: widget.settingsProvider.hideTrackDuration
                        ? TextAlign.center
                        : TextAlign.start,
                  ),
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
