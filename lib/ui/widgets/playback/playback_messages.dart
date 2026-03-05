import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/utils.dart';
import 'package:shakedown/providers/theme_provider.dart';

class PlaybackMessages extends StatefulWidget {
  final TextAlign textAlign;
  final bool showDivider;

  const PlaybackMessages({
    super.key,
    this.textAlign = TextAlign.center,
    this.showDivider = true,
  });

  @override
  State<PlaybackMessages> createState() => _PlaybackMessagesState();
}

class _PlaybackMessagesState extends State<PlaybackMessages> {
  String? _agentMessage;
  String? _notificationMessage;
  String? _engineStateString;
  Timer? _notificationTimer;
  StreamSubscription? _agentSubscription;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _engineStateSubscription;

  @override
  void initState() {
    super.initState();
    _subscribeToStreams();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    final audioProvider = context.read<AudioProvider>();

    _agentSubscription?.cancel();
    _agentSubscription =
        audioProvider.bufferAgentNotificationStream.listen((event) {
      if (mounted) {
        setState(() {
          _agentMessage = event.message;
        });
      }
    });

    _notificationSubscription?.cancel();
    _notificationSubscription = audioProvider.notificationStream.listen((msg) {
      if (mounted) {
        setState(() {
          _notificationMessage = msg;
        });
        _notificationTimer?.cancel();
        _notificationTimer = Timer(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _notificationMessage = null;
            });
          }
        });
      }
    });

    _playerStateSubscription?.cancel();
    _playerStateSubscription = audioProvider.playerStateStream.listen((state) {
      // Clear agent message if we are actively playing again
      if (state.playing &&
          state.processingState == ProcessingState.ready &&
          _agentMessage != null) {
        if (mounted) {
          setState(() {
            _agentMessage = null;
          });
        }
      }
    });

    _engineStateSubscription?.cancel();
    _engineStateSubscription =
        audioProvider.audioPlayer.engineStateStringStream.listen((stateStr) {
      if (mounted) {
        setState(() {
          _engineStateString = stateStr;
        });
      }
    });
  }

  @override
  void dispose() {
    _agentSubscription?.cancel();
    _notificationSubscription?.cancel();
    _notificationTimer?.cancel();
    _playerStateSubscription?.cancel();
    _engineStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isFruit =
        context.watch<ThemeProvider>().themeStyle == ThemeStyle.fruit;
    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
    final double labelsFontSize = 12.0 * scaleFactor;

    // Force default system/Roboto font regardless of app font setting
    final String? fontFamily = isFruit ? null : 'Roboto';

    if (!settingsProvider.showPlaybackMessages &&
        _notificationMessage == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<PlayerState>(
      stream: audioProvider.playerStateStream,
      initialData: audioProvider.audioPlayer.playerState,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing ?? false;

        String statusText = '';
        Color? statusColor;

        if (_notificationMessage != null) {
          statusText = _notificationMessage!;
          statusColor = colorScheme.primary;
        } else if (_agentMessage != null) {
          statusText = _agentMessage!;
          statusColor = colorScheme.error;
        } else if (_engineStateString == 'handoff_countdown') {
          // Calculate remaining buffer time manually since we update once a second
          final pos = audioProvider.audioPlayer.position;
          final buf = audioProvider.audioPlayer.bufferedPosition;
          final diff = (buf - pos).inSeconds;
          final countdown =
              diff - 5; // Handoff happens 5 seconds before buffer ends

          if (countdown > 0) {
            statusText = 'Handoff in ${countdown}s...';
            statusColor = colorScheme.primary;
          } else {
            statusText = 'Handing off to WebAudio...';
            statusColor = colorScheme.primary;
          }
        } else if (processingState == ProcessingState.loading) {
          statusText = 'Loading...';
        } else if (processingState == ProcessingState.buffering) {
          statusText = 'Buffering...';
        } else if (processingState == ProcessingState.ready) {
          statusText = playing ? 'Playing' : 'Paused';
        } else if (processingState == ProcessingState.completed) {
          statusText = 'Completed';
        }

        if (statusText.isEmpty) return const SizedBox.shrink();

        final children = [
          Text(
            statusText,
            style: TextStyle(
              color: statusColor ?? colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: labelsFontSize,
              fontFamily: fontFamily,
            ),
          ),
        ];

        // If explicitly disabled by user, only show the notification/agent message if it exists
        if (!settingsProvider.showPlaybackMessages) {
          return FittedBox(
            fit: BoxFit.scaleDown,
            alignment: widget.textAlign == TextAlign.center
                ? Alignment.center
                : widget.textAlign == TextAlign.right
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: children,
            ),
          );
        }

        final otherChildren = [
          if (widget.showDivider) ...[
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: labelsFontSize,
                fontFamily: fontFamily,
              ),
            ),
            const SizedBox(width: 8),
          ],
          StreamBuilder<Duration>(
            stream: audioProvider.bufferedPositionStream,
            initialData: audioProvider.audioPlayer.bufferedPosition,
            builder: (context, bufferedSnapshot) {
              final buffered = bufferedSnapshot.data ?? Duration.zero;
              return Text(
                'Buffered: ${formatDuration(buffered)}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: labelsFontSize,
                  fontFamily: fontFamily,
                ),
              );
            },
          ),
          if (kIsWeb)
            StreamBuilder<Duration?>(
              stream: audioProvider.nextTrackBufferedStream,
              initialData: audioProvider.audioPlayer.nextTrackBuffered,
              builder: (context, nextBufferedSnapshot) {
                final nextBuffered = nextBufferedSnapshot.data;
                if (nextBuffered == null) {
                  return const SizedBox.shrink();
                }
                // On Web, show 0:00 if we have next track data but haven't started buffering yet.
                // This prevents the UI from jumping in and out.
                if (nextBuffered == Duration.zero && !kIsWeb) {
                  return const SizedBox.shrink();
                }

                return Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '•',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: labelsFontSize,
                          fontFamily: fontFamily,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Next: ${formatDuration(nextBuffered)}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: labelsFontSize,
                          fontFamily: fontFamily,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ];

        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: widget.textAlign == TextAlign.center
              ? Alignment.center
              : widget.textAlign == TextAlign.right
                  ? Alignment.centerRight
                  : Alignment.centerLeft,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: widget.textAlign == TextAlign.center
                ? MainAxisAlignment.center
                : widget.textAlign == TextAlign.right
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
            children: [...children, ...otherChildren],
          ),
        );
      },
    );
  }
}
