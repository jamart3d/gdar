import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';

class EmbeddedMiniPlayer extends StatelessWidget {
  final double scaleFactor;
  final bool compact;
  final bool useRgb;
  final bool showFullDuration;

  const EmbeddedMiniPlayer({
    super.key,
    this.scaleFactor = 1.0,
    this.compact = false,
    this.useRgb = false,
    this.showFullDuration = false,
  });

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '${duration.inMinutes}:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final currentTrack = audioProvider.currentTrack;

    if (currentTrack == null) return const SizedBox.shrink();

    final isFruit = context.read<ThemeProvider?>()?.isFruit ?? false;
    final horizontalPad = compact ? 4.0 : 10.0;
    final verticalPad = compact ? 0.0 : 8.0;
    final buttonSize = (compact ? 36.0 : 32.0) * scaleFactor;
    final iconSize = (compact ? 18.0 : 16.0) * scaleFactor;
    final loaderSize = (compact ? 16.0 : 18.0) * scaleFactor;
    final titleSize = (compact ? (isFruit ? 22.0 : 18.0) : 14.0) * scaleFactor;
    final isTv = Provider.of<DeviceService>(context).isTv;
    final timeSize = (compact ? 12.0 : 11.0) * scaleFactor;
    final contentRadius = isTv
        ? 12.0
        : 28.0; // Matching the card's 28px radius (semicircle look)
    final content = Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: verticalPad,
      ),
      decoration: BoxDecoration(
        color: isFruit
            ? Colors.transparent
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(contentRadius),
        border: (useRgb || isFruit)
            ? null
            : Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 1.0,
              ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Play/Pause Button
          StreamBuilder<PlayerState>(
            stream: audioProvider.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;

              bool isLoading =
                  processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering;
              final bool isPlaying = playing == true;

              void activate() {
                AppHaptics.lightImpact(context.read<DeviceService>());
                if (isPlaying) {
                  audioProvider.audioPlayer.pause();
                } else {
                  audioProvider.audioPlayer.play();
                }
              }

              return Semantics(
                button: true,
                toggled: isPlaying,
                label: isPlaying ? 'Pause playback' : 'Resume playback',
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
                      onTap: activate,
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  width: loaderSize,
                                  height: loaderSize,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? LucideIcons.pause
                                      : LucideIcons.play,
                                  size: iconSize,
                                  color: colorScheme.onPrimary,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: compact ? 4 : 12),
          // Info & Progress
          // Compact mode: no Expanded (intrinsic width from parent)
          // Non-compact mode: Expanded to fill available space
          if (compact)
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Text(
                      currentTrack.title,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: titleSize,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                        height: 1.0,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Time + progress bar, right-aligned
                  IntrinsicWidth(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTimeText(
                          audioProvider,
                          colorScheme,
                          timeSize,
                          compact,
                          showFullDuration,
                        ),
                        const SizedBox(height: 1),
                        _buildProgressBar(audioProvider, colorScheme, compact),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          currentTrack.title,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: titleSize,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: compact ? 6 : 8),
                      Container(
                        child: _buildTimeText(
                          audioProvider,
                          colorScheme,
                          timeSize,
                          compact,
                          showFullDuration,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? 3 : 6),
                  // Progress Bar
                  Container(
                    child: _buildProgressBar(
                      audioProvider,
                      colorScheme,
                      compact,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );

    if (useRgb) {
      return AnimatedGradientBorder(
        borderRadius: contentRadius,
        borderWidth: 1.5,
        allowInPerformanceMode: true,
        alignment: Alignment.centerLeft,
        usePadding:
            true, // Prevents button/text from clipping against the border
        backgroundColor: isFruit ? Colors.transparent : null,
        showGlow: true,
        glowOpacity: 0.3,
        glowSpread: 8.0,
        colors: const [
          Colors.red,
          Colors.yellow,
          Colors.green,
          Colors.cyan,
          Colors.blue,
          Colors.purple,
          Colors.red,
        ],
        child: content,
      );
    }

    return content;
  }

  Widget _buildTimeText(
    AudioProvider audioProvider,
    ColorScheme colorScheme,
    double timeSize,
    bool compact,
    bool showFullDuration,
  ) {
    return StreamBuilder<Duration>(
      stream: audioProvider.positionStream,
      initialData: audioProvider.audioPlayer.position,
      builder: (context, posSnap) {
        final pos = posSnap.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: audioProvider.durationStream,
          initialData: audioProvider.audioPlayer.duration,
          builder: (context, durSnap) {
            final dur = durSnap.data ?? Duration.zero;
            return Text(
              (compact && !showFullDuration)
                  ? _formatDuration(pos)
                  : '${_formatDuration(pos)} / ${_formatDuration(dur)}',
              textAlign: TextAlign.end,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: timeSize,
                fontWeight: FontWeight.w400,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                height: 1.0,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressBar(
    AudioProvider audioProvider,
    ColorScheme colorScheme,
    bool compact,
  ) {
    return StreamBuilder<Duration>(
      stream: audioProvider.positionStream,
      initialData: audioProvider.audioPlayer.position,
      builder: (context, posSnap) {
        final pos = posSnap.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: audioProvider.durationStream,
          initialData: audioProvider.audioPlayer.duration,
          builder: (context, durSnap) {
            final dur = durSnap.data ?? Duration.zero;
            final double progress = dur.inMilliseconds > 0
                ? (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;

            return LinearProgressIndicator(
              value: progress,
              backgroundColor: colorScheme.onSurface.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              minHeight: 2,
              borderRadius: BorderRadius.circular(1),
            );
          },
        );
      },
    );
  }
}
