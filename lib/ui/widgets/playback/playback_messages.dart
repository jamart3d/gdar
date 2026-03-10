import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/utils.dart';
import 'package:shakedown/ui/widgets/theme/fruit_tooltip.dart';

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
  Timer? _heartbeatPulseTimer;
  bool _heartbeatPulseOn = false;
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
    _heartbeatPulseTimer?.cancel();
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
      return _buildDevHud(
        context,
        audioProvider,
        settingsProvider,
        labelsFontSize,
        colorScheme,
        fontFamily,
        audioProvider.audioPlayer.playerState,
        compact: true,
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
          rows.add(_buildDevHud(
            context,
            audioProvider,
            settingsProvider,
            labelsFontSize,
            colorScheme,
            fontFamily,
            playerState,
            compact: widget.compactDevHud,
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

  Widget _buildDevHud(
      BuildContext context,
      AudioProvider audioProvider,
      SettingsProvider settingsProvider,
      double labelsFontSize,
      ColorScheme colorScheme,
      String? fontFamily,
      PlayerState? playerState,
      {required bool compact}) {
    return StreamBuilder<Duration>(
      stream: audioProvider.bufferedPositionStream,
      initialData: audioProvider.audioPlayer.bufferedPosition,
      builder: (context, bufferedSnapshot) {
        final buffered = bufferedSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: audioProvider.nextTrackBufferedStream,
          initialData: audioProvider.audioPlayer.nextTrackBuffered,
          builder: (context, nextSnapshot) {
            final nextBuffered = nextSnapshot.data ?? Duration.zero;
            final hasLiveSignal = _isAppVisible &&
                (playerState != null ||
                    buffered > Duration.zero ||
                    nextBuffered > Duration.zero ||
                    (_engineStateString != null &&
                        _engineStateString!.isNotEmpty));

            if (!hasLiveSignal) {
              return const SizedBox.shrink();
            }

            final snapshot = _composeDevHudSnapshot(
              audioProvider,
              settingsProvider,
              playerState,
              buffered,
              nextBuffered,
            );

            if (snapshot.isEmpty) return const SizedBox.shrink();

            final heartbeatActive = settingsProvider.hybridBackgroundMode ==
                    HybridBackgroundMode.heartbeat &&
                (playerState?.playing ?? false) &&
                _isAppVisible;
            _syncHeartbeatPulse(heartbeatActive);

            if (!compact) {
              return Text(
                snapshot,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                  fontSize: labelsFontSize * 0.92,
                  fontFamily: fontFamily ?? 'RobotoMono',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            }

            final fields = _snapshotFields(snapshot);

            return Container(
              key: const ValueKey('hud_always_expanded'),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(
                      alpha: 0.78,
                    ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 360;
                  final keys = narrow
                      ? const [
                          'ENG',
                          'TX',
                          'HF',
                          'BG',
                          'AE',
                          'PF',
                          'PS',
                          'P',
                          'BUF',
                          'HD',
                          'E',
                          'ST',
                          'SIG',
                          'MSG'
                        ]
                      : const [
                          'ENG',
                          'TX',
                          'HF',
                          'BG',
                          'AE',
                          'PF',
                          'PS',
                          'P',
                          'POS',
                          'BUF',
                          'HD',
                          'NX',
                          'E',
                          'ST',
                          'SIG',
                          'MSG'
                        ];
                  final bool isFruitMode = context.watch<ThemeProvider?>()?.themeStyle == ThemeStyle.fruit;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildHeartbeatDot(
                        labelsFontSize,
                        colorScheme,
                        active: heartbeatActive,
                      ),
                      const SizedBox(height: 6),
                      _buildHudFieldWrap(
                        fields: fields,
                        orderedKeys: keys,
                        labelsFontSize: labelsFontSize,
                        colorScheme: colorScheme,
                        fontFamily: fontFamily,
                        isFruit: isFruitMode,
                      ),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildHeartbeatDot(double labelsFontSize, ColorScheme colorScheme,
      {required bool active}) {
    final size = labelsFontSize * 0.62;
    final color = !active
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.35)
        : (_heartbeatPulseOn
            ? colorScheme.primary
            : colorScheme.primary.withValues(alpha: 0.45));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }

  void _syncHeartbeatPulse(bool active) {
    if (!active) {
      _heartbeatPulseTimer?.cancel();
      _heartbeatPulseTimer = null;
      if (_heartbeatPulseOn) {
        _heartbeatPulseOn = false;
      }
      return;
    }

    if (_heartbeatPulseTimer != null) return;
    _heartbeatPulseOn = true;
    _heartbeatPulseTimer =
        Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted || !_isAppVisible) return;
      setState(() => _heartbeatPulseOn = !_heartbeatPulseOn);
    });
  }

  Map<String, String> _snapshotFields(String snapshot) {
    final fields = <String, String>{};
    for (final segment in snapshot.split(' • ')) {
      final sep = segment.indexOf(':');
      if (sep <= 0 || sep >= segment.length - 1) continue;
      final key = segment.substring(0, sep).trim();
      final value = segment.substring(sep + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      fields[key] = value;
    }
    return fields;
  }

  Widget _buildHudFieldWrap({
    required Map<String, String> fields,
    required List<String> orderedKeys,
    required double labelsFontSize,
    required ColorScheme colorScheme,
    required String? fontFamily,
    required bool isFruit,
  }) {
    final chips = <Widget>[];
    for (final key in orderedKeys) {
      final value = fields[key];
      if (value == null) continue;
      Widget chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$key:$value',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.96),
            fontWeight: FontWeight.w700,
            fontSize: labelsFontSize * 0.84,
            fontFamily: fontFamily ?? 'RobotoMono',
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      );
      if (isFruit) {
        final tooltip = _hudFieldTooltip(key, value);
        if (tooltip.isNotEmpty) {
          chip = FruitTooltip(
            message: tooltip,
            child: chip,
          );
        }
      }
      chips.add(chip);
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: chips,
    );
  }

  String _composeDevHudSnapshot(
    AudioProvider audioProvider,
    SettingsProvider sp,
    PlayerState? playerState,
    Duration buffered,
    Duration nextBuffered,
  ) {
    final position = audioProvider.audioPlayer.position;
    final duration = audioProvider.audioPlayer.duration;
    final durationText = duration == null ? '--:--' : formatDuration(duration);
    final headroom = buffered - position;
    final headroomSec = headroom.inSeconds;
    final headroomText = '${headroomSec >= 0 ? '+' : ''}${headroomSec}s';
    final err = (audioProvider.error != null && audioProvider.error!.isNotEmpty)
        ? 'ERR'
        : 'OK';
    final signal =
        (_notificationMessage != null && _notificationMessage!.isNotEmpty)
            ? 'NTF'
            : (_agentMessage != null && _agentMessage!.isNotEmpty)
                ? 'AGT'
                : '--';
    final rawMsg = (_notificationMessage != null &&
            _notificationMessage!.trim().isNotEmpty)
        ? _notificationMessage!.trim()
        : (_agentMessage != null && _agentMessage!.trim().isNotEmpty)
            ? _agentMessage!.trim()
            : '--';
    final msg = rawMsg == '--' ? rawMsg : _compactMessage(rawMsg);

    final effectiveMode = sp.audioEngineMode == AudioEngineMode.auto
        ? audioProvider.audioPlayer.activeMode
        : sp.audioEngineMode;
    final mode = _shortMode(effectiveMode);
    final transition = _shortTransition(sp.trackTransitionMode);
    final handoff = _shortHandoff(sp.hybridHandoffMode);
    final background = _shortBackground(sp.hybridBackgroundMode);
    final activeEngine = _shortActiveEngine(_engineContextState, effectiveMode);
    final prefetch =
        sp.webPrefetchSeconds < 0 ? 'G' : '${sp.webPrefetchSeconds}s';
    final processing = _shortProcessing(playerState?.processingState);
    final player = _shortPlayerState(playerState);
    final engineState = _shortEngineState(_engineStateString);

    return 'ENG:$mode • TX:$transition • HF:$handoff • BG:$background • '
        'AE:$activeEngine • '
        'PF:$prefetch • PS:$processing • P:$player • '
        'POS:${formatDuration(position)}/$durationText • '
        'BUF:${formatDuration(buffered)} • HD:$headroomText • '
        'NX:${formatDuration(nextBuffered)} • '
        'E:$err • ST:$engineState • SIG:$signal • MSG:$msg';
  }

  String _compactMessage(String value) {
    final cleaned = value
        .replaceAll('\n', ' ')
        .replaceAll('•', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= 26) return cleaned;
    return '${cleaned.substring(0, 25)}…';
  }

  String _shortMode(AudioEngineMode mode) {
    switch (mode) {
      case AudioEngineMode.webAudio:
        return 'WBA';
      case AudioEngineMode.html5:
        return 'H5';
      case AudioEngineMode.standard:
        return 'STD';
      case AudioEngineMode.passive:
        return 'PAS';
      case AudioEngineMode.hybrid:
        return 'HYB';
      case AudioEngineMode.auto:
        return 'AUT';
    }
  }

  String _shortTransition(String mode) {
    if (mode == 'crossfade') return 'XFD';
    if (mode == 'gapless') return 'GLS';
    return 'GAP';
  }

  String _shortHandoff(HybridHandoffMode mode) {
    switch (mode) {
      case HybridHandoffMode.immediate:
        return 'IMM';
      case HybridHandoffMode.none:
        return 'OFF';
      case HybridHandoffMode.buffered:
        return 'BUF';
    }
  }

  String _shortBackground(HybridBackgroundMode mode) {
    switch (mode) {
      case HybridBackgroundMode.video:
        return 'VID';
      case HybridBackgroundMode.heartbeat:
        return 'HBT';
      case HybridBackgroundMode.none:
        return 'OFF';
      case HybridBackgroundMode.html5:
        return 'H5';
    }
  }

  String _shortActiveEngine(String? contextState, AudioEngineMode mode) {
    if (mode != AudioEngineMode.hybrid) return '--';
    if (contextState == null || contextState.isEmpty) return '?';
    if (contextState.contains('hybrid_background')) return 'BG';
    if (contextState.contains('hybrid_foreground')) return 'FG';
    return '?';
  }

  String _shortPlayerState(PlayerState? state) {
    final processing = state?.processingState;
    if (processing == ProcessingState.loading) return 'LD';
    if (processing == ProcessingState.buffering) return 'BUF';
    if (processing == ProcessingState.completed) return 'END';
    if (processing == ProcessingState.idle) return 'IDL';
    if (state?.playing ?? false) return 'PLY';
    return 'PAU';
  }

  String _shortProcessing(ProcessingState? processing) {
    if (processing == ProcessingState.loading) return 'LD';
    if (processing == ProcessingState.buffering) return 'BUF';
    if (processing == ProcessingState.ready) return 'RDY';
    if (processing == ProcessingState.completed) return 'END';
    return 'IDL';
  }

  String _shortEngineState(String? state) {
    if (state == null || state.isEmpty) return 'IDLE';
    if (state == 'handoff_countdown') return 'HFDN';
    if (state == 'suspended_by_os') return 'SUSP';
    return state.length > 4 ? state.substring(0, 4).toUpperCase() : state;
  }

  String _hudFieldTooltip(String key, String value) {
    switch (key) {
      case 'ENG':
        return 'Engine mode: $value';
      case 'TX':
        return 'Track transition: $value';
      case 'HF':
        return 'Hybrid handoff mode: $value';
      case 'BG':
        return 'Hybrid background mode: $value';
      case 'AE':
        return 'Active audio engine: $value';
      case 'PF':
        return 'Prefetch window (seconds): $value';
      case 'PS':
        return 'Processing state: $value';
      case 'P':
        return 'Player state: $value';
      case 'POS':
        return 'Position/duration: $value';
      case 'BUF':
        return 'Buffered amount: $value';
      case 'HD':
        return 'Headroom: $value';
      case 'NX':
        return 'Next buffered position: $value';
      case 'E':
        return 'Error flag: $value';
      case 'ST':
        return 'Engine status: $value';
      case 'SIG':
        return 'Signal source: $value';
      case 'MSG':
        return 'Message: $value';
      default:
        return '$key: $value';
    }
  }
}
