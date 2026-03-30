import 'package:flutter/material.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/utils.dart'; // for formatDuration
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class PlaybackProgressBar extends StatefulWidget {
  const PlaybackProgressBar({super.key});

  @override
  State<PlaybackProgressBar> createState() => _PlaybackProgressBarState();
}

class _PlaybackProgressBarState extends State<PlaybackProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _thumbAnimationController;
  late final Animation<double> _thumbRadiusAnimation;
  bool _isInteracting = false;
  bool _pulseReverse = false;
  bool _sweepToggle = false;

  static const int _timeRoleElapsed = 0;
  static const int _timeRoleTotal = 1;

  @override
  void initState() {
    super.initState();
    _thumbAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _thumbRadiusAnimation = Tween<double>(begin: 10.0, end: 16.0).animate(
      CurvedAnimation(
        parent: _thumbAnimationController,
        curve: Curves.easeOutBack,
        reverseCurve: Curves.easeIn,
      ),
    );
  }

  @override
  void dispose() {
    _thumbAnimationController.dispose();
    super.dispose();
  }

  void _updateInteractionState(bool isInteracting) {
    if (_isInteracting != isInteracting) {
      setState(() {
        _isInteracting = isInteracting;
      });
      if (isInteracting) {
        _thumbAnimationController.forward();
      } else {
        _thumbAnimationController.reverse();
      }
      AppHaptics.selectionClick(context.read<DeviceService>());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final isSimple = settingsProvider.performanceMode;
    final bool glassOn = settingsProvider.fruitEnableLiquidGlass;
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final audioProvider = context.watch<AudioProvider>();

    return StreamBuilder<Duration>(
      stream: audioProvider.positionStream,
      initialData: audioProvider.audioPlayer.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: audioProvider.durationStream,
          initialData: audioProvider.audioPlayer.duration,
          builder: (context, durationSnapshot) {
            final totalDuration = durationSnapshot.data ?? Duration.zero;
            final hasKnownDuration = totalDuration.inSeconds > 0;
            final isUnknown = !hasKnownDuration && position.inMilliseconds == 0;
            const unknownLabel = '--:--';

            return SizedBox(
              height: 32 * scaleFactor,
              child: Row(
                children: [
                  // 1. ELAPSED TIME
                  _buildTimeBadge(
                    context: context,
                    text: isUnknown ? unknownLabel : formatDuration(position),
                    scaleFactor: scaleFactor,
                    alignRight: false,
                    isSimple: isSimple,
                    role: _timeRoleElapsed,
                  ),
                  SizedBox(width: 4 * scaleFactor),
                  // 2. SEEK BAR (Expanded to fill space)
                  Expanded(
                    child: StreamBuilder<Duration>(
                      stream: audioProvider.bufferedPositionStream,
                      initialData: audioProvider.audioPlayer.bufferedPosition,
                      builder: (context, bufferedSnapshot) {
                        final bufferedPosition =
                            bufferedSnapshot.data ?? Duration.zero;
                        return StreamBuilder<PlayerState>(
                          stream: audioProvider.playerStateStream,
                          initialData: audioProvider.audioPlayer.playerState,
                          builder: (context, stateSnapshot) {
                            final processingState =
                                stateSnapshot.data?.processingState;
                            final isBuffering =
                                processingState == ProcessingState.buffering ||
                                processingState == ProcessingState.loading;
                            final bufferingPercentage =
                                (hasKnownDuration
                                        ? bufferedPosition.inSeconds /
                                              totalDuration.inSeconds
                                        : 0.0)
                                    .clamp(0.0, 1.0);
                            final positionPercentage =
                                (hasKnownDuration
                                        ? position.inSeconds /
                                              totalDuration.inSeconds
                                        : 0.0)
                                    .clamp(0.0, 1.0);

                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background Track
                                Container(
                                  height: 12 * scaleFactor,
                                  decoration: BoxDecoration(
                                    color: isTrueBlackMode
                                        ? const Color(0x1FFFFFFF)
                                        : colorScheme.onSurface.withValues(
                                            alpha: 0.2,
                                          ),
                                    borderRadius: BorderRadius.circular(
                                      6 * scaleFactor,
                                    ),
                                  ),
                                ),
                                // Shimmer / pulse across full track
                                if (isBuffering)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      6 * scaleFactor,
                                    ),
                                    child: glassOn
                                        // Glass ON: gradient sweep
                                        ? TweenAnimationBuilder<double>(
                                            key: ValueKey(_sweepToggle),
                                            tween: Tween(begin: -0.3, end: 1.3),
                                            duration: const Duration(
                                              milliseconds: 1800,
                                            ),
                                            builder:
                                                (context, sweepValue, child) {
                                                  return Container(
                                                    height: 12 * scaleFactor,
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        begin: Alignment
                                                            .centerLeft,
                                                        end: Alignment
                                                            .centerRight,
                                                        stops: [
                                                          (sweepValue - 0.2)
                                                              .clamp(
                                                                0.0,
                                                                0.998,
                                                              ),
                                                          sweepValue.clamp(
                                                            0.001,
                                                            0.999,
                                                          ),
                                                          (sweepValue + 0.2)
                                                              .clamp(
                                                                0.002,
                                                                1.0,
                                                              ),
                                                        ],
                                                        colors: [
                                                          const Color(
                                                            0x00000000,
                                                          ),
                                                          colorScheme.primary
                                                              .withValues(
                                                                alpha: 0.32,
                                                              ),
                                                          const Color(
                                                            0x00000000,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                            onEnd: () {
                                              if (isBuffering &&
                                                  context.mounted) {
                                                setState(() {
                                                  _sweepToggle = !_sweepToggle;
                                                });
                                              }
                                            },
                                          )
                                        // Glass OFF: simple opacity pulse
                                        : TweenAnimationBuilder<double>(
                                            key: ValueKey(_pulseReverse),
                                            tween: _pulseReverse
                                                ? Tween(begin: 0.22, end: 0.06)
                                                : Tween(begin: 0.06, end: 0.22),
                                            duration: const Duration(
                                              milliseconds: 900,
                                            ),
                                            curve: Curves.easeInOut,
                                            builder: (context, value, child) {
                                              return Container(
                                                height: 12 * scaleFactor,
                                                decoration: BoxDecoration(
                                                  color: colorScheme.primary
                                                      .withValues(alpha: value),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        6 * scaleFactor,
                                                      ),
                                                ),
                                              );
                                            },
                                            onEnd: () {
                                              if (isBuffering &&
                                                  context.mounted) {
                                                _pulseReverse = !_pulseReverse;
                                                (context as Element)
                                                    .markNeedsBuild();
                                              }
                                            },
                                          ),
                                  ),
                                if (!hasKnownDuration && isBuffering)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(
                                      6 * scaleFactor,
                                    ),
                                    child: SizedBox(
                                      height: 12 * scaleFactor,
                                      child: LinearProgressIndicator(
                                        value: null,
                                        backgroundColor: const Color(
                                          0x00000000,
                                        ),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              colorScheme.tertiary.withValues(
                                                alpha: 0.45,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                // Buffered Progress
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: bufferingPercentage,
                                    child: Container(
                                      height: 12 * scaleFactor,
                                      decoration: BoxDecoration(
                                        color: colorScheme.tertiary.withValues(
                                          alpha: 0.35,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          6 * scaleFactor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Active Progress
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: positionPercentage,
                                    child: Container(
                                      height: 12 * scaleFactor,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.primary,
                                            colorScheme.tertiary,
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          6 * scaleFactor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                // Interactive Slider (Transparent Overlay)
                                AnimatedBuilder(
                                  animation: _thumbRadiusAnimation,
                                  builder: (context, child) {
                                    return SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackHeight: 12 * scaleFactor,
                                        thumbShape: RoundSliderThumbShape(
                                          enabledThumbRadius:
                                              _thumbRadiusAnimation.value *
                                              scaleFactor,
                                        ),
                                        overlayShape: RoundSliderOverlayShape(
                                          overlayRadius: 22 * scaleFactor,
                                        ),
                                        activeTrackColor: const Color(
                                          0x00000000,
                                        ),
                                        inactiveTrackColor: const Color(
                                          0x00000000,
                                        ),
                                        thumbColor: colorScheme.primary,
                                        overlayColor: colorScheme.primary
                                            .withValues(alpha: 0.2),
                                      ),
                                      child: Slider(
                                        min: 0.0,
                                        max: hasKnownDuration
                                            ? totalDuration.inSeconds.toDouble()
                                            : 1.0,
                                        value: position.inSeconds
                                            .toDouble()
                                            .clamp(
                                              0.0,
                                              (hasKnownDuration
                                                      ? totalDuration.inSeconds
                                                      : 1)
                                                  .toDouble(),
                                            ),
                                        onChangeStart: (_) =>
                                            _updateInteractionState(true),
                                        onChanged: hasKnownDuration
                                            ? (value) {
                                                audioProvider.seek(
                                                  Duration(
                                                    seconds: value.round(),
                                                  ),
                                                );
                                              }
                                            : null,
                                        onChangeEnd: (_) =>
                                            _updateInteractionState(false),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                  ),
                  SizedBox(width: 4 * scaleFactor),
                  // 3. TOTAL/BUFFERED TIME
                  StreamBuilder<Duration>(
                    stream: audioProvider.bufferedPositionStream,
                    initialData: audioProvider.audioPlayer.bufferedPosition,
                    builder: (context, bufferedSnapshot) {
                      final buffered = bufferedSnapshot.data ?? Duration.zero;
                      final totalUnknown =
                          isUnknown && buffered.inMilliseconds == 0;
                      return _buildTimeBadge(
                        context: context,
                        text: totalUnknown
                            ? unknownLabel
                            : formatDuration(
                                hasKnownDuration ? totalDuration : buffered,
                              ),
                        scaleFactor: scaleFactor,
                        alignRight: true,
                        isSimple: isSimple,
                        role: _timeRoleTotal,
                      );
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTimeBadge({
    required BuildContext context,
    required String text,
    required double scaleFactor,
    required bool alignRight,
    required bool isSimple,
    required int role,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final bool isElapsed = role == _timeRoleElapsed;
    final badgeColor = isSimple
        ? scheme.onSurface.withValues(alpha: 0.06)
        : (isElapsed
              ? scheme.primary.withValues(alpha: 0.14)
              : scheme.onSurface.withValues(alpha: 0.08));
    final textColor = isSimple
        ? (isElapsed ? scheme.onSurface : scheme.onSurfaceVariant)
        : (isElapsed
              ? scheme.primary
              : scheme.onSurface.withValues(alpha: 0.92));
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 6 * scaleFactor,
        vertical: 2 * scaleFactor,
      ),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6 * scaleFactor),
      ),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12.5 * scaleFactor,
          fontFamily: 'Roboto',
          fontFeatures: [const FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
