import 'package:flutter/material.dart';
import 'package:gdar_design/typography/font_config.dart';
import 'package:shakedown_core/utils/web_runtime.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_ui.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_tooltip.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/ui/widgets/conditional_marquee.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_messages.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/ui/widgets/playback/fruit_now_playing_progress_bar.dart';
import 'package:shakedown_core/ui/widgets/playback/fruit_now_playing_transport_glyph.dart';

class FruitNowPlayingCard extends StatelessWidget {
  final Show trackShow;
  final Track? track;
  final int index;
  final double scaleFactor;
  final bool showNext;
  final VoidCallback? onWebStuckReset;

  const FruitNowPlayingCard({
    super.key,
    required this.trackShow,
    this.track,
    required this.index,
    required this.scaleFactor,
    this.showNext = true,
    this.onWebStuckReset,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.read<AudioProvider>();
    final isSimple = context.select<SettingsProvider, bool>(
      (settings) => settings.performanceMode,
    );
    final enableLiquidGlass = context.select<SettingsProvider, bool>(
      (settings) => settings.fruitEnableLiquidGlass,
    );
    final useRgbBorder = context.select<SettingsProvider, bool>(
      (settings) => settings.highlightPlayingWithRgb,
    );
    final rgbAnimationSpeed = context.select<SettingsProvider, double>(
      (settings) => settings.rgbAnimationSpeed,
    );
    final showDevAudioHud = context.select<SettingsProvider, bool>(
      (settings) => settings.showDevAudioHud,
    );
    final showPlaybackMessages = context.select<SettingsProvider, bool>(
      (settings) => settings.showPlaybackMessages,
    );
    final marqueeEnabled = context.select<SettingsProvider, bool>(
      (settings) => settings.marqueeEnabled,
    );
    final colorScheme = Theme.of(context).colorScheme;

    final hasGlass = enableLiquidGlass && !isSimple;
    const bool showWebTrackStepControls = kIsWeb;
    final showCompactHud = kIsWeb && showDevAudioHud;
    final bool showInlineTransportCluster =
        showWebTrackStepControls && !showCompactHud;
    final horizontalPadding = showCompactHud ? 12.0 : 16.0;
    final surface = FruitSurface(
      borderRadius: BorderRadius.circular(16.0 * scaleFactor),
      blur: isSimple ? FruitTokens.blurSoft : 18.0,
      opacity: isSimple ? 0.96 : 0.88,
      showBorder: !useRgbBorder,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.0 * scaleFactor),
          color: hasGlass
              ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.08)
              : colorScheme.surfaceContainer,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding * scaleFactor,
          vertical: 12.0 * scaleFactor,
        ),
        child: Row(
          children: [
            if (!showCompactHud) ...[
              if (showInlineTransportCluster)
                _buildInlineTransportCluster(
                  context,
                  audioProvider,
                  colorScheme,
                  glassEnabled: enableLiquidGlass,
                )
              else
                _buildCompactPlayButton(
                  context,
                  audioProvider,
                  colorScheme,
                  enableLiquidGlass,
                ),
              SizedBox(width: 14 * scaleFactor),
            ],
            // Info & Progress
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 20 * scaleFactor,
                          child: ConditionalMarquee(
                            text:
                                track?.title ??
                                (audioProvider
                                            .currentSource
                                            ?.tracks
                                            .isNotEmpty ==
                                        true
                                    ? audioProvider
                                          .currentSource!
                                          .tracks
                                          .first
                                          .title
                                    : 'Picking show...'),
                            style: TextStyle(
                              fontFamily: FontConfig.resolve('Inter'),
                              fontSize: 15 * scaleFactor,
                              fontWeight: FontWeight.w700,
                              color: colorScheme.onSurface,
                            ),
                            velocity: 36.0,
                            blankSpace: 48.0,
                            pauseAfterRound: const Duration(milliseconds: 900),
                            fadingEdgeStartFraction: 0.02,
                            fadingEdgeEndFraction: 0.08,
                            enableAnimation: marqueeEnabled,
                          ),
                        ),
                      ),
                      SizedBox(width: 8 * scaleFactor),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _buildDurationInfo(
                          audioProvider,
                          colorScheme,
                          isSimple: isSimple,
                        ),
                      ),
                      if (!showWebTrackStepControls &&
                          showCompactHud &&
                          showNext) ...[
                        SizedBox(width: 8 * scaleFactor),
                        _buildSkipNextButton(audioProvider, colorScheme),
                      ],
                    ],
                  ),
                  SizedBox(height: 8 * scaleFactor),
                  StreamBuilder<PlayerState>(
                    stream: audioProvider.playerStateStream,
                    initialData: audioProvider.audioPlayer.playerState,
                    builder: (context, stateSnapshot) {
                      final processingState =
                          stateSnapshot.data?.processingState;
                      final isLoading =
                          processingState == ProcessingState.loading;
                      final isBuffering =
                          processingState == ProcessingState.buffering;
                      return StreamBuilder<Duration>(
                        stream: audioProvider.bufferedPositionStream,
                        initialData: audioProvider.audioPlayer.bufferedPosition,
                        builder: (context, bufferedSnapshot) {
                          return StreamBuilder<Duration>(
                            stream: audioProvider.positionStream,
                            initialData: audioProvider.audioPlayer.position,
                            builder: (context, positionSnapshot) {
                              return StreamBuilder<Duration?>(
                                stream: audioProvider.durationStream,
                                initialData: audioProvider.audioPlayer.duration,
                                builder: (context, durationSnapshot) {
                                  final buffered =
                                      bufferedSnapshot.data ?? Duration.zero;
                                  final int positionMs =
                                      (positionSnapshot.data ?? Duration.zero)
                                          .inMilliseconds;
                                  final int durationMs =
                                      (durationSnapshot.data ?? Duration.zero)
                                          .inMilliseconds;
                                  final int bufferedMs =
                                      buffered.inMilliseconds;
                                  final progressBar =
                                      FruitNowPlayingProgressBar(
                                        colorScheme: colorScheme,
                                        scaleFactor: scaleFactor,
                                        isLoading: isLoading,
                                        bufferedPositionMs: bufferedMs,
                                        positionMs: positionMs,
                                        durationMs: durationMs,
                                        glassEnabled: enableLiquidGlass,
                                        showPendingState: _shouldShowPendingCue(
                                          isLoading: isLoading,
                                          isBuffering: isBuffering,
                                          bufferedPositionMs: bufferedMs,
                                          positionMs: positionMs,
                                          durationMs: durationMs,
                                        ),
                                      );
                                  if (!showCompactHud) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        progressBar,
                                        if (showPlaybackMessages) ...[
                                          SizedBox(height: 4 * scaleFactor),
                                          const SizedBox(
                                            key: ValueKey(
                                              'fruit_now_playing_message_below_progress',
                                            ),
                                            child: PlaybackMessages(
                                              textAlign: TextAlign.left,
                                              showDivider: false,
                                              showDevHudInline: false,
                                              fontScale: 0.74,
                                            ),
                                          ),
                                        ],
                                      ],
                                    );
                                  }

                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          if (showWebTrackStepControls) ...[
                                            _buildInlineTransportCluster(
                                              context,
                                              audioProvider,
                                              colorScheme,
                                              glassEnabled: enableLiquidGlass,
                                            ),
                                          ] else ...[
                                            _buildCompactPlayButton(
                                              context,
                                              audioProvider,
                                              colorScheme,
                                              enableLiquidGlass,
                                            ),
                                          ],
                                          SizedBox(width: 6 * scaleFactor),
                                          Expanded(child: progressBar),
                                        ],
                                      ),
                                      SizedBox(height: 4 * scaleFactor),
                                      Padding(
                                        padding: EdgeInsets.only(
                                          left:
                                              (showWebTrackStepControls
                                                  ? 108
                                                  : (36 + 18)) *
                                              scaleFactor,
                                        ),
                                        child: const PlaybackMessages(
                                          textAlign: TextAlign.left,
                                          showDivider: false,
                                          showDevHudInline: false,
                                          fontScale: 0.74,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  if (showCompactHud) ...[
                    SizedBox(height: 8 * scaleFactor),
                    const PlaybackMessages(
                      textAlign: TextAlign.left,
                      showDivider: false,
                      showStatusLine: false,
                      compactDevHud: true,
                    ),
                  ],
                ],
              ),
            ),
            if (!showWebTrackStepControls && !showCompactHud && showNext) ...[
              SizedBox(width: 12 * scaleFactor),
              _buildSkipNextButton(audioProvider, colorScheme),
            ],
          ],
        ),
      ),
    );

    if (!useRgbBorder) {
      return surface;
    }

    return AnimatedGradientBorder(
      borderRadius: 16.0 * scaleFactor,
      borderWidth: 2.0,
      showGlow: false,
      showShadow: false,
      usePadding: true,
      allowInPerformanceMode: true,
      animationSpeed: rgbAnimationSpeed,
      colors: const [
        Colors.red,
        Colors.yellow,
        Colors.green,
        Colors.cyan,
        Colors.blue,
        Color(0xFF8B00FF),
        Colors.red,
      ],
      child: surface,
    );
  }

  Widget _buildSkipNextButton(
    AudioProvider audioProvider,
    ColorScheme colorScheme,
  ) {
    return FruitIconButton(
      onPressed: () => audioProvider.seekToNext(),
      icon: Icon(
        LucideIcons.skipForward,
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        size: 18 * scaleFactor,
      ),
      size: 20 * scaleFactor,
      padding: 4 * scaleFactor,
      tooltip: 'Skip Next',
    );
  }

  Widget _buildTrackStepButton(
    BuildContext context,
    AudioProvider audioProvider,
    ColorScheme colorScheme, {
    required bool glassEnabled,
    required VoidCallback onPressed,
    required String tooltip,
    required IconData icon,
    required Key buttonKey,
    required bool enabled,
  }) {
    void onTap() {
      if (!enabled) return;
      AppHaptics.selectionClick(context.read<DeviceService>());
      onPressed();
    }

    final child = Icon(
      icon,
      size: 15 * scaleFactor,
      color: enabled
          ? (glassEnabled
                ? colorScheme.onSurface.withValues(alpha: 0.9)
                : colorScheme.onSurfaceVariant.withValues(alpha: 0.9))
          : colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
    );

    return FruitTooltip(
      message: tooltip,
      child: GestureDetector(
        key: buttonKey,
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: glassEnabled
            ? FruitSurface(
                borderRadius: BorderRadius.circular(999),
                blur: 12,
                opacity: enabled ? 0.30 : 0.18,
                padding: EdgeInsets.all(5 * scaleFactor),
                child: child,
              )
            : Container(
                padding: EdgeInsets.all(5 * scaleFactor),
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withValues(
                    alpha: enabled ? 0.08 : 0.04,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(
                      alpha: enabled ? 0.12 : 0.06,
                    ),
                    width: 0.8,
                  ),
                ),
                child: child,
              ),
      ),
    );
  }

  Widget _buildInlineTransportCluster(
    BuildContext context,
    AudioProvider audioProvider,
    ColorScheme colorScheme, {
    required bool glassEnabled,
  }) {
    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, indexSnapshot) {
        final index = indexSnapshot.data ?? 0;
        final sequenceLength = audioProvider.audioPlayer.sequence.length;
        final isFirstTrack = index <= 0;
        final isLastTrack = sequenceLength == 0
            ? false
            : index >= sequenceLength - 1;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTrackStepButton(
              context,
              audioProvider,
              colorScheme,
              glassEnabled: glassEnabled,
              onPressed: () => audioProvider.seekToPrevious(),
              tooltip: 'Previous Track',
              icon: LucideIcons.skipBack,
              buttonKey: const ValueKey('fruit_now_playing_prev_track_button'),
              enabled: !isFirstTrack,
            ),
            SizedBox(width: 6 * scaleFactor),
            _buildCompactPlayButton(
              context,
              audioProvider,
              colorScheme,
              glassEnabled,
            ),
            SizedBox(width: 6 * scaleFactor),
            _buildTrackStepButton(
              context,
              audioProvider,
              colorScheme,
              glassEnabled: glassEnabled,
              onPressed: () => audioProvider.seekToNext(),
              tooltip: 'Next Track',
              icon: LucideIcons.skipForward,
              buttonKey: const ValueKey('fruit_now_playing_next_track_button'),
              enabled: !isLastTrack,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCompactPlayButton(
    BuildContext context,
    AudioProvider audioProvider,
    ColorScheme colorScheme,
    bool glassEnabled,
  ) {
    void activate() {
      AppHaptics.lightImpact(context.read<DeviceService>());
      if (audioProvider.isPlaying) {
        audioProvider.pause();
      } else {
        audioProvider.resume();
      }
    }

    return StreamBuilder<PlayerState>(
      stream: audioProvider.playerStateStream,
      initialData: audioProvider.audioPlayer.playerState,
      builder: (context, snapshot) {
        final playerState =
            snapshot.data ?? audioProvider.audioPlayer.playerState;
        final processingState = playerState.processingState;
        final bool isPlaying = playerState.playing;
        return StreamBuilder<Duration>(
          stream: audioProvider.bufferedPositionStream,
          initialData: audioProvider.audioPlayer.bufferedPosition,
          builder: (context, bufferedSnapshot) {
            return StreamBuilder<Duration>(
              stream: audioProvider.positionStream,
              initialData: audioProvider.audioPlayer.position,
              builder: (context, positionSnapshot) {
                return StreamBuilder<Duration?>(
                  stream: audioProvider.durationStream,
                  initialData: audioProvider.audioPlayer.duration,
                  builder: (context, durationSnapshot) {
                    final bool showPendingCue = _shouldShowPendingCue(
                      isLoading: processingState == ProcessingState.loading,
                      isBuffering: processingState == ProcessingState.buffering,
                      bufferedPositionMs:
                          (bufferedSnapshot.data ?? Duration.zero)
                              .inMilliseconds,
                      positionMs: (positionSnapshot.data ?? Duration.zero)
                          .inMilliseconds,
                      durationMs: (durationSnapshot.data ?? Duration.zero)
                          .inMilliseconds,
                    );

                    return Semantics(
                      button: true,
                      toggled: isPlaying,
                      label: showPendingCue
                          ? 'Loading playback'
                          : (isPlaying ? 'Pause playback' : 'Resume playback'),
                      child: ExcludeSemantics(
                        child: FocusableActionDetector(
                          enabled: true,
                          mouseCursor: SystemMouseCursors.click,
                          shortcuts: const <ShortcutActivator, Intent>{
                            SingleActivator(LogicalKeyboardKey.enter):
                                ActivateIntent(),
                            SingleActivator(LogicalKeyboardKey.space):
                                ActivateIntent(),
                          },
                          actions: <Type, Action<Intent>>{
                            ActivateIntent: CallbackAction<ActivateIntent>(
                              onInvoke: (_) {
                                activate();
                                return null;
                              },
                            ),
                          },
                          child: GestureDetector(
                            key: const ValueKey(
                              'fruit_now_playing_compact_play_button',
                            ),
                            behavior: HitTestBehavior.opaque,
                            onTap: activate,
                            onLongPress: onWebStuckReset ?? () {},
                            child: Container(
                              width: 36 * scaleFactor,
                              height: 36 * scaleFactor,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: isWasmSafeMode()
                                    ? null
                                    : [
                                        BoxShadow(
                                          color: colorScheme.primary.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                              ),
                              child: Center(
                                child: FruitNowPlayingTransportGlyph(
                                  isPlaying: isPlaying,
                                  isPending: showPendingCue,
                                  glassEnabled: glassEnabled,
                                  color: colorScheme.onPrimary,
                                  size: 18 * scaleFactor,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildDurationInfo(
    AudioProvider audioProvider,
    ColorScheme colorScheme, {
    required bool isSimple,
  }) {
    return StreamBuilder<Duration>(
      stream: audioProvider.positionStream,
      initialData: audioProvider.audioPlayer.position,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration?>(
          stream: audioProvider.durationStream,
          initialData: audioProvider.audioPlayer.duration,
          builder: (context, durationSnapshot) {
            final pos = positionSnapshot.data ?? Duration.zero;
            final dur = durationSnapshot.data ?? Duration.zero;
            final isUnknown =
                dur.inMilliseconds == 0 && pos.inMilliseconds == 0;
            final elapsed = isUnknown ? '--:--' : formatDuration(pos);
            final total = isUnknown ? '--:--' : formatDuration(dur);

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 6 * scaleFactor,
                vertical: 2 * scaleFactor,
              ),
              decoration: BoxDecoration(
                color: isSimple
                    ? colorScheme.onSurface.withValues(alpha: 0.06)
                    : colorScheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6 * scaleFactor),
              ),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11 * scaleFactor,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  children: [
                    TextSpan(
                      text: elapsed,
                      style: TextStyle(
                        color: isSimple
                            ? colorScheme.onSurface.withValues(alpha: 0.92)
                            : colorScheme.primary,
                      ),
                    ),
                    TextSpan(
                      text: ' / ',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                    TextSpan(
                      text: total,
                      style: TextStyle(
                        color: isSimple
                            ? colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.88,
                              )
                            : colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _shouldShowPendingCue({
    required bool isLoading,
    required bool isBuffering,
    required int bufferedPositionMs,
    required int positionMs,
    required int durationMs,
  }) {
    final int remainingMs = durationMs - positionMs;
    final bool hasPlayableTail = durationMs <= 0 || remainingMs > 900;
    final bool hasVisibleBufferHeadroom =
        bufferedPositionMs > (positionMs + 350);
    return isLoading ||
        isBuffering ||
        (hasPlayableTail && !hasVisibleBufferHeadroom);
  }
}
