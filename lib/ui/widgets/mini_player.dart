import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/conditional_marquee.dart';

import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/utils/color_generator.dart';
import 'package:shakedown/utils/app_date_utils.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';

class MiniPlayer extends StatefulWidget {
  final VoidCallback onTap;
  final bool hideControls;

  const MiniPlayer({
    super.key,
    required this.onTap,
    this.hideControls = false,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final Show? currentShow = audioProvider.currentShow;
    final Source? currentSource = audioProvider.currentSource;

    if (currentShow == null || currentSource == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final themeProvider = context.watch<ThemeProvider>();
    final isFruitNeumorphic = themeProvider.themeStyle == ThemeStyle.fruit &&
        settingsProvider.useNeumorphism &&
        !settingsProvider.useTrueBlack;

    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    Color backgroundColor = colorScheme.surfaceContainerHigh;

    // Only apply custom background color if NOT in "True Black" mode.
    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    if (!isTrueBlackMode && settingsProvider.highlightCurrentShowCard) {
      String seed = currentShow.name;
      if (currentShow.sources.length > 1) {
        seed = currentSource.id;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }

    if (themeProvider.themeStyle == ThemeStyle.fruit) {
      return _buildFruitMiniPlayer(
        context,
        audioProvider,
        settingsProvider,
        themeProvider,
        colorScheme,
        textTheme,
        scaleFactor,
        currentShow,
      );
    }

    Widget miniPlayerContent = Stack(
      children: [
        Positioned.fill(
          child: Hero(
            tag: 'player',
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.zero,
              clipBehavior: Clip.antiAlias,
              elevation: settingsProvider.performanceMode ? 0.0 : 4.0,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
              child: Container(), // Empty container for background
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration>(
                stream: audioProvider.positionStream,
                initialData: audioProvider.audioPlayer.position,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: audioProvider.durationStream,
                    initialData: audioProvider.audioPlayer.duration,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;
                      final progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0;
                      return StreamBuilder<Duration>(
                        stream: audioProvider.bufferedPositionStream,
                        initialData: audioProvider.audioPlayer.bufferedPosition,
                        builder: (context, bufferedSnapshot) {
                          final bufferedPosition =
                              bufferedSnapshot.data ?? Duration.zero;
                          final bufferedProgress = duration.inMilliseconds > 0
                              ? bufferedPosition.inMilliseconds /
                                  duration.inMilliseconds
                              : 0.0;
                          return StreamBuilder<PlayerState>(
                            stream: audioProvider.playerStateStream,
                            initialData: audioProvider.audioPlayer.playerState,
                            builder: (context, stateSnapshot) {
                              final processingState =
                                  stateSnapshot.data?.processingState;
                              final isBuffering = processingState ==
                                      ProcessingState.buffering ||
                                  processingState == ProcessingState.loading;
                              return SizedBox(
                                height: 4,
                                child: Stack(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isTrueBlackMode
                                            ? Colors.white24
                                            : colorScheme
                                                .surfaceContainerHighest,
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor:
                                          bufferedProgress.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colorScheme.tertiary
                                                  .withValues(alpha: 0.3),
                                              colorScheme.tertiary
                                                  .withValues(alpha: 0.5),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: progress.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colorScheme.primary,
                                              colorScheme.primary
                                                  .withValues(alpha: 0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isBuffering)
                                      SizedBox(
                                        height: 4,
                                        child: LinearProgressIndicator(
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
              InkWell(
                onTap: widget.onTap,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 4.0,
                    top: 20.0 * scaleFactor,
                    bottom: 20.0 * scaleFactor,
                    right: 4.0 * scaleFactor,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<SequenceState?>(
                          stream: audioProvider.audioPlayer.sequenceStateStream,
                          builder: (context, snapshot) {
                            final currentTrack = audioProvider.currentTrack;
                            final baseTitleStyle = textTheme.titleMedium
                                    ?.copyWith(fontSize: 19.0) ??
                                const TextStyle(fontSize: 19.0);
                            final titleStyle = baseTitleStyle.copyWith(
                              fontSize: AppTypography.responsiveFontSize(
                                  context, 19.0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              color: colorScheme.onSurface,
                            );

                            // Calculate the fixed height needed for titles (2.2x font size)
                            final double fixedTitleHeight =
                                titleStyle.fontSize! * 2.2;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: fixedTitleHeight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2.0),
                                    child: Builder(builder: (context) {
                                      final Widget textWidget = Material(
                                        type: MaterialType.transparency,
                                        child: AnimatedSwitcher(
                                          duration:
                                              const Duration(milliseconds: 300),
                                          child: currentTrack == null
                                              ? SizedBox(
                                                  key: const ValueKey(
                                                      'loading_placeholder'),
                                                  height: fixedTitleHeight)
                                              : ConditionalMarquee(
                                                  key: ValueKey(
                                                      currentTrack.url),
                                                  text: currentTrack.title,
                                                  style: titleStyle.copyWith(
                                                      height: 1.2),
                                                  textAlign: TextAlign.center,
                                                ),
                                        ),
                                      );

                                      if (isFruitNeumorphic) {
                                        return NeumorphicWrapper(
                                          borderRadius: 12.0,
                                          intensity: 0.6,
                                          isPressed: true,
                                          color: Colors.transparent,
                                          child: LiquidGlassWrapper(
                                            enabled: true,
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            opacity: 0.04,
                                            blur: 6.0,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8.0),
                                              child: Center(child: textWidget),
                                            ),
                                          ),
                                        );
                                      }

                                      return textWidget;
                                    }),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (!widget.hideControls) ...[
                        const SizedBox(width: 8),
                        // Skip Previous, Play/Pause, Skip Next
                        StreamBuilder<int?>(
                          stream: audioProvider.currentIndexStream,
                          initialData: audioProvider.audioPlayer.currentIndex,
                          builder: (context, indexSnapshot) {
                            final index = indexSnapshot.data ?? 0;
                            final sequence = audioProvider.audioPlayer.sequence;
                            final isFirstTrack = index == 0;
                            final isLastTrack = index >= sequence.length - 1;

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                NeumorphicWrapper(
                                  enabled: isFruitNeumorphic,
                                  borderRadius: 10,
                                  isCircle: false,
                                  intensity: 1.2,
                                  child: SizedBox(
                                    width: (isFruitNeumorphic ? 32.0 : 40.0) *
                                        scaleFactor,
                                    height: (isFruitNeumorphic ? 32.0 : 40.0) *
                                        scaleFactor,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon((themeProvider.themeStyle ==
                                              ThemeStyle.fruit)
                                          ? LucideIcons.skipBack
                                          : Icons.skip_previous_rounded),
                                      iconSize: (themeProvider.themeStyle ==
                                              ThemeStyle.fruit)
                                          ? 16.0 * scaleFactor
                                          : 28.0 * scaleFactor,
                                      color: colorScheme.onSurface,
                                      onPressed: isFirstTrack
                                          ? null
                                          : () {
                                              AppHaptics.selectionClick(context
                                                  .read<DeviceService>());
                                              audioProvider.seekToPrevious();
                                            },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 10.0 * scaleFactor),
                                StreamBuilder<PlayerState>(
                                  stream: audioProvider.playerStateStream,
                                  builder: (context, snapshot) {
                                    final playerState = snapshot.data;
                                    final processingState =
                                        playerState?.processingState;
                                    final playing = playerState?.playing;

                                    if (processingState ==
                                            ProcessingState.loading ||
                                        processingState ==
                                            ProcessingState.buffering) {
                                      return Container(
                                        margin:
                                            EdgeInsets.all(8.0 * scaleFactor),
                                        width: 38.0 * scaleFactor,
                                        height: 38.0 * scaleFactor,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            colorScheme.onSurface,
                                          ),
                                        ),
                                      );
                                    }

                                    final bool isFruit =
                                        themeProvider.themeStyle ==
                                            ThemeStyle.fruit;
                                    final double playButtonSize =
                                        (isFruit ? 38.0 : 38.0) * scaleFactor;

                                    Widget playIcon;
                                    VoidCallback? onPressed;

                                    if (playing != true) {
                                      playIcon = Icon(isFruit
                                          ? LucideIcons.play
                                          : Icons.play_arrow_rounded);
                                      onPressed =
                                          audioProvider.audioPlayer.play;
                                    } else if (processingState !=
                                        ProcessingState.completed) {
                                      playIcon = Icon(isFruit
                                          ? LucideIcons.pause
                                          : Icons.pause_rounded);
                                      onPressed =
                                          audioProvider.audioPlayer.pause;
                                    } else {
                                      playIcon = Icon(isFruit
                                          ? LucideIcons.rotateCcw
                                          : Icons.replay_rounded);
                                      onPressed = () => audioProvider
                                          .audioPlayer
                                          .seek(Duration.zero);
                                    }

                                    Widget button = IconButton(
                                      icon: playIcon,
                                      iconSize: isFruit
                                          ? 22.0 * scaleFactor
                                          : 38.0 * scaleFactor,
                                      onPressed: onPressed,
                                      color: isFruit
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                    );

                                    if (isFruit) {
                                      button = Container(
                                        width: playButtonSize,
                                        height: playButtonSize,
                                        decoration: BoxDecoration(
                                          color: colorScheme.surface,
                                          shape: BoxShape.circle,
                                        ),
                                        child: button,
                                      );
                                    }

                                    return NeumorphicWrapper(
                                      enabled: isFruitNeumorphic,
                                      isCircle: true,
                                      intensity: 1.4,
                                      child: button,
                                    );
                                  },
                                ),
                                SizedBox(width: 10.0 * scaleFactor),
                                NeumorphicWrapper(
                                  enabled: isFruitNeumorphic,
                                  borderRadius: 10,
                                  isCircle: false,
                                  intensity: 1.2,
                                  child: SizedBox(
                                    width: (isFruitNeumorphic ? 32.0 : 40.0) *
                                        scaleFactor,
                                    height: (isFruitNeumorphic ? 32.0 : 40.0) *
                                        scaleFactor,
                                    child: IconButton(
                                      padding: EdgeInsets.zero,
                                      icon: Icon((themeProvider.themeStyle ==
                                              ThemeStyle.fruit)
                                          ? LucideIcons.skipForward
                                          : Icons.skip_next_rounded),
                                      iconSize: (themeProvider.themeStyle ==
                                              ThemeStyle.fruit)
                                          ? 16.0 * scaleFactor
                                          : 28.0 * scaleFactor,
                                      color: colorScheme.onSurface,
                                      onPressed: isLastTrack
                                          ? null
                                          : () {
                                              AppHaptics.selectionClick(context
                                                  .read<DeviceService>());
                                              audioProvider.seekToNext();
                                            },
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    return miniPlayerContent;
  }

  Widget _buildFruitMiniPlayer(
    BuildContext context,
    AudioProvider audioProvider,
    SettingsProvider settingsProvider,
    ThemeProvider themeProvider,
    ColorScheme colorScheme,
    TextTheme textTheme,
    double scaleFactor,
    Show currentShow,
  ) {
    final isFruitNeumorphic =
        settingsProvider.useNeumorphism && !settingsProvider.useTrueBlack;

    final String dateStr =
        AppDateUtils.formatDateYearFirst(currentShow.date).toUpperCase();
    final String venueStr = currentShow.venue.toUpperCase();
    final String subtitleStr = '$dateStr $venueStr';

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16.0 * scaleFactor,
        vertical: 16.0 * scaleFactor,
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Main Pill Container
          NeumorphicWrapper(
            enabled: isFruitNeumorphic,
            borderRadius: 24.0,
            intensity: 0.6,
            color: colorScheme.surface,
            child: LiquidGlassWrapper(
              enabled: true,
              borderRadius: BorderRadius.circular(24.0),
              opacity: 0.4,
              blur: kIsWeb ? 15.0 : 8.0,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(24.0),
                  child: Padding(
                    padding: EdgeInsets.only(
                      left: 20.0 * scaleFactor,
                      right: 16.0 * scaleFactor,
                      top: 14.0 * scaleFactor,
                      bottom: 22.0 * scaleFactor, // Room for progress bar
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Track Text
                        Expanded(
                          child: StreamBuilder<SequenceState?>(
                            stream:
                                audioProvider.audioPlayer.sequenceStateStream,
                            builder: (context, snapshot) {
                              final currentTrack = audioProvider.currentTrack;
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: currentTrack == null
                                        ? SizedBox(
                                            height: 18 * scaleFactor,
                                            width: 100 * scaleFactor)
                                        : Text(
                                            currentTrack.title,
                                            key: ValueKey(currentTrack.url),
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 15.0 * scaleFactor,
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.onSurface,
                                              height: 1.2,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                  ),
                                  SizedBox(height: 4.0 * scaleFactor),
                                  Text(
                                    subtitleStr,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 10.0 * scaleFactor,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.8,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.5),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        // Right: Controls
                        if (!widget.hideControls) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Skip Prev
                              StreamBuilder<int?>(
                                stream: audioProvider.currentIndexStream,
                                initialData:
                                    audioProvider.audioPlayer.currentIndex,
                                builder: (context, indexSnapshot) {
                                  final index = indexSnapshot.data ?? 0;
                                  final isFirstTrack = index == 0;
                                  return IconButton(
                                    icon: const Icon(LucideIcons.skipBack),
                                    iconSize: 22.0 * scaleFactor,
                                    color: colorScheme.primary.withValues(
                                        alpha: isFirstTrack ? 0.3 : 0.7),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: isFirstTrack
                                        ? null
                                        : () {
                                            AppHaptics.selectionClick(
                                                context.read<DeviceService>());
                                            audioProvider.seekToPrevious();
                                          },
                                  );
                                },
                              ),
                              SizedBox(width: 8.0 * scaleFactor),
                              // Play/Pause
                              StreamBuilder<PlayerState>(
                                stream: audioProvider.playerStateStream,
                                builder: (context, snapshot) {
                                  final playerState = snapshot.data;
                                  final processingState =
                                      playerState?.processingState;
                                  final playing = playerState?.playing;

                                  if (processingState ==
                                          ProcessingState.loading ||
                                      processingState ==
                                          ProcessingState.buffering) {
                                    return Container(
                                      width: 44.0 * scaleFactor,
                                      height: 44.0 * scaleFactor,
                                      padding:
                                          EdgeInsets.all(12.0 * scaleFactor),
                                      decoration: BoxDecoration(
                                        color: colorScheme.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: colorScheme.primary
                                                .withValues(alpha: 0.3),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          )
                                        ],
                                      ),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.0,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                colorScheme.onPrimary),
                                      ),
                                    );
                                  }

                                  IconData iconData;
                                  VoidCallback? onPressed;

                                  if (playing != true) {
                                    iconData = LucideIcons.play;
                                    onPressed = audioProvider.audioPlayer.play;
                                  } else if (processingState !=
                                      ProcessingState.completed) {
                                    iconData = LucideIcons.pause;
                                    onPressed = audioProvider.audioPlayer.pause;
                                  } else {
                                    iconData = LucideIcons.rotateCcw;
                                    onPressed = () => audioProvider.audioPlayer
                                        .seek(Duration.zero);
                                  }

                                  return Container(
                                    width: 44.0 * scaleFactor,
                                    height: 44.0 * scaleFactor,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: colorScheme.primary
                                              .withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        )
                                      ],
                                    ),
                                    child: IconButton(
                                      icon: Icon(iconData),
                                      iconSize: 20.0 * scaleFactor,
                                      color: colorScheme.onPrimary,
                                      padding: EdgeInsets.zero,
                                      onPressed: onPressed,
                                    ),
                                  );
                                },
                              ),
                              SizedBox(width: 8.0 * scaleFactor),
                              // Skip Next
                              StreamBuilder<int?>(
                                stream: audioProvider.currentIndexStream,
                                initialData:
                                    audioProvider.audioPlayer.currentIndex,
                                builder: (context, indexSnapshot) {
                                  final index = indexSnapshot.data ?? 0;
                                  final sequence =
                                      audioProvider.audioPlayer.sequence;
                                  final isLastTrack =
                                      index >= sequence.length - 1;
                                  return IconButton(
                                    icon: const Icon(LucideIcons.skipForward),
                                    iconSize: 22.0 * scaleFactor,
                                    color: colorScheme.primary.withValues(
                                        alpha: isLastTrack ? 0.3 : 0.7),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: isLastTrack
                                        ? null
                                        : () {
                                            AppHaptics.selectionClick(
                                                context.read<DeviceService>());
                                            audioProvider.seekToNext();
                                          },
                                  );
                                },
                              ),
                            ],
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Progress Bar (Inset)
          Positioned(
            bottom: 14.0 * scaleFactor,
            left: 20.0 * scaleFactor,
            right: 20.0 * scaleFactor,
            child: IgnorePointer(
              // Allow taps to fall through to the MiniPlayer InkWell
              ignoring: true,
              child: StreamBuilder<Duration>(
                stream: audioProvider.positionStream,
                initialData: audioProvider.audioPlayer.position,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: audioProvider.durationStream,
                    initialData: audioProvider.audioPlayer.duration,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;
                      final progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0;
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: SizedBox(
                          height: 4.0 * scaleFactor,
                          child: Stack(
                            children: [
                              Container(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.08),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: colorScheme.primary,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
