import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class TvPlaybackBar extends StatefulWidget {
  final VoidCallback? onDown;
  final VoidCallback? onUp;
  const TvPlaybackBar({super.key, this.onDown, this.onUp});

  @override
  State<TvPlaybackBar> createState() => _TvPlaybackBarState();
}

class _TvPlaybackBarState extends State<TvPlaybackBar> {
  final FocusNode _playPauseFocusNode = FocusNode();
  final FocusNode _progressFocusNode = FocusNode();

  @override
  void dispose() {
    _playPauseFocusNode.dispose();
    _progressFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final player = audioProvider.audioPlayer;
    final colorScheme = Theme.of(context).colorScheme;

    // Use a translucent "Glass" color for the capsule
    final capsuleColor =
        colorScheme.surfaceContainerHighest.withValues(alpha: 0.6);

    return Container(
      height: 64,
      width: 600, // Fixed width for the "floating capsule" look
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: capsuleColor,
        borderRadius: BorderRadius.circular(50),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // 1. Play/Pause Icon
          TvFocusWrapper(
            focusNode: _playPauseFocusNode,
            onTap: () {
              if (player.playing) {
                player.pause();
              } else {
                player.play();
              }
            },
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                  // DOWN from Play/Pause goes to Progress Indicator
                  _progressFocusNode.requestFocus();
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                  if (widget.onUp != null) {
                    widget.onUp!.call();
                    return KeyEventResult.handled;
                  }
                }
              }
              return KeyEventResult.ignored;
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                size: 32,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 2. Current Time
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              return Text(
                _formatDuration(position),
                style: TextStyle(
                  fontFamily: 'Roboto', // Monospaced-ish for time
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
          const SizedBox(width: 16),

          // 3. Progress Bar (Standard Slider)
          Expanded(
            child: TvFocusWrapper(
              focusNode: _progressFocusNode,
              borderRadius: BorderRadius.circular(20),
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                    player.seek(Duration(
                        seconds: (player.position.inSeconds - 10)
                            .clamp(0, player.duration?.inSeconds ?? 0)));
                    return KeyEventResult.handled;
                  } else if (event.logicalKey ==
                      LogicalKeyboardKey.arrowRight) {
                    player.seek(Duration(
                        seconds: (player.position.inSeconds + 10)
                            .clamp(0, player.duration?.inSeconds ?? 0)));
                    return KeyEventResult.handled;
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
                    if (widget.onDown != null) {
                      widget.onDown!.call();
                      return KeyEventResult.handled;
                    }
                  } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
                    // UP from progress goes to Play/Pause button
                    _playPauseFocusNode.requestFocus();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: StreamBuilder<Duration>(
                  stream: player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: player.durationStream,
                      builder: (context, durationSnapshot) {
                        final total = durationSnapshot.data ?? Duration.zero;
                        final maxSeconds = total.inSeconds.toDouble();
                        final value = position.inSeconds
                            .toDouble()
                            .clamp(0.0, maxSeconds > 0 ? maxSeconds : 1.0);

                        return SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6),
                            overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 12),
                            activeTrackColor: colorScheme.primary,
                            inactiveTrackColor:
                                colorScheme.onSurface.withValues(alpha: 0.2),
                            thumbColor: colorScheme.primary,
                            overlayColor:
                                colorScheme.primary.withValues(alpha: 0.2),
                          ),
                          child: ExcludeFocus(
                            child: Slider(
                              min: 0.0,
                              max: maxSeconds > 0 ? maxSeconds : 1.0,
                              value: value,
                              onChanged: (newValue) {
                                player
                                    .seek(Duration(seconds: newValue.round()));
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // 4. Total Time
          StreamBuilder<Duration?>(
            stream: player.durationStream,
            builder: (context, snapshot) {
              final duration = snapshot.data ?? Duration.zero;
              return Text(
                _formatDuration(duration),
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '${duration.inHours > 0 ? '${duration.inHours}:' : ''}$minutes:$seconds';
  }
}
