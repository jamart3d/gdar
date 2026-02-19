import 'dart:async';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/utils.dart';

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
  StreamSubscription? _agentSubscription;
  StreamSubscription? _playerStateSubscription;

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
  }

  @override
  void dispose() {
    _agentSubscription?.cancel();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isTv = context.read<DeviceService>().isTv;
    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
    final double labelsFontSize = 12.0 * scaleFactor;

    // On TV force default system font regardless of app font setting
    final String? fontFamily = isTv ? 'Roboto' : null;

    if (!settingsProvider.showPlaybackMessages) {
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

        if (_agentMessage != null) {
          statusText = _agentMessage!;
          statusColor = colorScheme.error;
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
        ];

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: widget.textAlign == TextAlign.center
              ? MainAxisAlignment.center
              : widget.textAlign == TextAlign.right
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: children,
        );
      },
    );
  }
}
