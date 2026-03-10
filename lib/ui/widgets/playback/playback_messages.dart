import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/utils.dart';
import 'package:shakedown/ui/widgets/playback/dev_audio_hud.dart';

class PlaybackMessages extends StatefulWidget {
  final TextAlign textAlign;
  final bool showDivider;
  final bool compactDevHud;
  final bool showStatusLine;
  final bool showDevHudInline;

  const PlaybackMessages({
    super.key,
    this.textAlign = TextAlign.center,
    this.showDivider = true,
    this.compactDevHud = false,
    this.showStatusLine = true,
    this.showDevHudInline = true,
  });

  @override
  State<PlaybackMessages> createState() => _PlaybackMessagesState();
}

class _PlaybackMessagesState extends State<PlaybackMessages>
    with WidgetsBindingObserver {
  String? _agentMessage;
  String? _notificationMessage;
  String? _engineStateString;
  String? _engineContextState;
  Timer? _notificationTimer;
  StreamSubscription? _agentSubscription;
  StreamSubscription? _notificationSubscription;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _engineStateSubscription;
  StreamSubscription? _engineContextSubscription;
  bool _isAppVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    final audioProvider = context.read<AudioProvider>();

    _agentSubscription?.cancel();
    _notificationSubscription?.cancel();
    _playerStateSubscription?.cancel();

    _agentSubscription =
        audioProvider.bufferAgentNotificationStream.listen((event) {
      if (mounted) {
        setState(() {
          _agentMessage = event.message;
        });
      }
    });

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

    _playerStateSubscription = audioProvider.playerStateStream.listen((state) {
      if (state.playing &&
          state.processingState == ProcessingState.ready &&
          _agentMessage != null) {
        if (mounted) {
          if (mounted) {
            setState(() {
              _agentMessage = null;
            });
          }
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

    _engineContextSubscription?.cancel();
    _engineContextSubscription = audioProvider
        .audioPlayer.engineContextStateStream
        .listen((contextState) {
      if (mounted) {
        setState(() {
          _engineContextState = contextState;
        });
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _agentSubscription?.cancel();
    _notificationSubscription?.cancel();
    _notificationTimer?.cancel();
    _playerStateSubscription?.cancel();
    _engineStateSubscription?.cancel();
    _engineContextSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // On web/desktop, a window can remain visible while unfocused ("inactive").
    // Treat that state as visible so the HUD does not collapse unexpectedly.
    _isAppVisible = state == AppLifecycleState.resumed ||
        state == AppLifecycleState.inactive;
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider?>();
    final isFruitTheme = themeProvider?.themeStyle == ThemeStyle.fruit;
    final isWebUi = kIsWeb && !context.watch<DeviceService>().isTv;
    final showDevHud =
        isWebUi && settingsProvider.showDevAudioHud && widget.showDevHudInline;
    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
    final double labelsFontSize = 12.0 * scaleFactor;
    final String? fontFamily = isFruitTheme ? null : 'Roboto';

    if (!widget.showStatusLine && _notificationMessage == null && !showDevHud) {
      return const SizedBox.shrink();
    }

    if (widget.compactDevHud && !widget.showStatusLine) {
      return DevAudioHud(
        audioProvider: audioProvider,
        settingsProvider: settingsProvider,
        playerState: audioProvider.audioPlayer.playerState,
        labelsFontSize: labelsFontSize,
        colorScheme: colorScheme,
        fontFamily: fontFamily,
        compact: true,
        isAppVisible: _isAppVisible,
        engineStateString: _engineStateString,
        engineContextState: _engineContextState,
        agentMessage: _agentMessage,
        notificationMessage: _notificationMessage,
      );
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
          final pos = audioProvider.audioPlayer.position;
          final buf = audioProvider.audioPlayer.bufferedPosition;
          final diff = (buf - pos).inSeconds;
          final countdown = diff - 5;

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

        final hasStatusText = statusText.isNotEmpty;
        final children = <Widget>[
          if (hasStatusText)
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

        final otherChildren = [
          if (settingsProvider.showPlaybackMessages) ...[
            if (!widget.showDivider && hasStatusText) const SizedBox(width: 10),
            if (widget.showDivider && hasStatusText) ...[
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
          ],
        ];

        final rows = <Widget>[];

        if (widget.showStatusLine && hasStatusText) {
          rows.add(
            FittedBox(
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
            ),
          );
        }

        if (showDevHud) {
          if (rows.isNotEmpty) {
            rows.add(const SizedBox(height: 4));
          }
          rows.add(DevAudioHud(
            audioProvider: audioProvider,
            settingsProvider: settingsProvider,
            playerState: playerState,
            labelsFontSize: labelsFontSize,
            colorScheme: colorScheme,
            fontFamily: fontFamily,
            compact: widget.compactDevHud,
            isAppVisible: _isAppVisible,
            engineStateString: _engineStateString,
            engineContextState: _engineContextState,
            agentMessage: _agentMessage,
            notificationMessage: _notificationMessage,
          ));
        }

        if (rows.isEmpty) return const SizedBox.shrink();

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rows,
        );
      },
    );
  }
}
