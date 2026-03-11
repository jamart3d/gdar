import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';
import 'package:shakedown/ui/widgets/theme/fruit_tooltip.dart';
import 'package:shakedown/utils/utils.dart';

/// Developer-facing HUD that shows engine state, buffering, and recent messages.
///
/// Intended for Web use only; callers should guard with `kIsWeb` and the
/// `showDevAudioHud` setting before including.
class DevAudioHud extends StatefulWidget {
  final AudioProvider audioProvider;
  final SettingsProvider settingsProvider;
  final PlayerState? playerState;
  final double labelsFontSize;
  final ColorScheme colorScheme;
  final String? fontFamily;
  final bool compact;
  final bool isAppVisible;
  final String? engineStateString;
  final String? engineContextState;
  final String? agentMessage;
  final String? notificationMessage;

  // New fields for error/issue reporting
  final String? lastIssueMessage;
  final DateTime? lastIssueAt;
  final VoidCallback? onClearIssue;

  const DevAudioHud({
    super.key,
    required this.audioProvider,
    required this.settingsProvider,
    required this.playerState,
    required this.labelsFontSize,
    required this.colorScheme,
    required this.fontFamily,
    this.compact = false,
    this.isAppVisible = true,
    this.engineStateString,
    this.engineContextState,
    this.agentMessage,
    this.notificationMessage,
    this.lastIssueMessage,
    this.lastIssueAt,
    this.onClearIssue,
  });

  @override
  State<DevAudioHud> createState() => _DevAudioHudState();
}

class _DevAudioHudState extends State<DevAudioHud> {
  Timer? _heartbeatPulseTimer;
  bool _heartbeatPulseOn = false;

  @override
  void dispose() {
    _heartbeatPulseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = widget.audioProvider;
    final settingsProvider = widget.settingsProvider;
    final labelsFontSize = widget.labelsFontSize;

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
            final hasLiveSignal = widget.isAppVisible &&
                (widget.playerState != null ||
                    buffered > Duration.zero ||
                    nextBuffered > Duration.zero ||
                    (widget.engineStateString != null &&
                        widget.engineStateString!.isNotEmpty));

            if (!hasLiveSignal) return const SizedBox.shrink();

            final snapshot = _composeDevHudSnapshot(
              audioProvider,
              settingsProvider,
              widget.playerState,
              buffered,
              nextBuffered,
              widget.engineStateString,
              widget.engineContextState,
              widget.agentMessage,
              widget.notificationMessage,
            );

            if (snapshot.isEmpty) return const SizedBox.shrink();

            final heartbeatActive = settingsProvider.hybridBackgroundMode ==
                    HybridBackgroundMode.heartbeat &&
                (widget.playerState?.playing ?? false) &&
                widget.isAppVisible;
            _syncHeartbeatPulse(heartbeatActive);

            if (!widget.compact) {
              return Text(
                snapshot,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: widget.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.9,
                  ),
                  fontWeight: FontWeight.w600,
                  fontSize: labelsFontSize * 0.92,
                  fontFamily: widget.fontFamily ?? 'RobotoMono',
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              );
            }

            final fields = _snapshotFields(snapshot);
            final isFruitMode =
                context.watch<ThemeProvider?>()?.themeStyle == ThemeStyle.fruit;

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
                  // "POS" removed from all keys
                  final keys = narrow
                      ? const [
                          'ENG',
                          'TX',
                          'HF',
                          'BG',
                          'AE',
                          'PF',
                          'PS',
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
                          'BUF',
                          'HD',
                          'NX',
                          'E',
                          'ST',
                          'SIG',
                          'MSG'
                        ];
                  return _buildHudFieldWrap(
                    fields: fields,
                    orderedKeys: keys,
                    labelsFontSize: labelsFontSize,
                    colorScheme: widget.colorScheme,
                    fontFamily: widget.fontFamily,
                    isFruit: isFruitMode,
                    heartbeatActive: heartbeatActive,
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
    if (!active) return const SizedBox.shrink();

    final size = labelsFontSize * 0.5; // Slightly smaller for inline use
    final color = _heartbeatPulseOn
        ? colorScheme.primary
        : colorScheme.primary.withValues(alpha: 0.45);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: size,
      height: size,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          if (_heartbeatPulseOn)
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.3),
              blurRadius: 4,
              spreadRadius: 1,
            ),
        ],
      ),
    );
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(fn);
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(fn);
    });
  }

  void _syncHeartbeatPulse(bool active) {
    if (!active) {
      _heartbeatPulseTimer?.cancel();
      _heartbeatPulseTimer = null;
      if (_heartbeatPulseOn) {
        _safeSetState(() {
          _heartbeatPulseOn = false;
        });
      }
      return;
    }

    if (_heartbeatPulseTimer != null) return;
    _heartbeatPulseOn = true;
    _heartbeatPulseTimer =
        Timer.periodic(const Duration(milliseconds: 900), (_) {
      if (!mounted || !widget.isAppVisible) return;
      _safeSetState(() => _heartbeatPulseOn = !_heartbeatPulseOn);
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
    required bool heartbeatActive,
  }) {
    final chips = <Widget>[];
    for (final key in orderedKeys) {
      final value = fields[key];
      if (value == null) continue;

      // Insert heartbeat dot before BG chip if active
      if (key == 'BG' && heartbeatActive) {
        chips.add(
          Padding(
            padding: const EdgeInsets.only(right: 2, top: 4),
            child: _buildHeartbeatDot(
              labelsFontSize,
              colorScheme,
              active: true,
            ),
          ),
        );
      }

      Widget valueWidget;
      if (key == 'MSG' && value.length > 30) {
        // Implement Marquee for long messages
        valueWidget = SizedBox(
          width: 150,
          height: labelsFontSize * 1.2,
          child: Marquee(
            text: value,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.96),
              fontWeight: FontWeight.w700,
              fontSize: labelsFontSize * 0.84,
              fontFamily: fontFamily ?? 'RobotoMono',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
            scrollAxis: Axis.horizontal,
            crossAxisAlignment: CrossAxisAlignment.start,
            blankSpace: 20.0,
            velocity: 30.0,
            pauseAfterRound: const Duration(seconds: 1),
            accelerationDuration: const Duration(seconds: 1),
            accelerationCurve: Curves.linear,
            decelerationDuration: const Duration(milliseconds: 500),
            decelerationCurve: Curves.easeOut,
          ),
        );
      } else {
        valueWidget = Text(
          value,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.96),
            fontWeight: FontWeight.w700,
            fontSize: labelsFontSize * 0.84,
            fontFamily: fontFamily ?? 'RobotoMono',
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      }

      Widget chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$key:',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
                fontSize: labelsFontSize * 0.84,
                fontFamily: fontFamily ?? 'RobotoMono',
              ),
            ),
            valueWidget,
          ],
        ),
      );

      // Wrap MSG chip in GestureDetector for clearing issues
      if (key == 'MSG') {
        chip = GestureDetector(
          onTap: widget.onClearIssue,
          child: chip,
        );
      }

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
    String? engineStateString,
    String? engineContextState,
    String? agentMessage,
    String? notificationMessage,
  ) {
    final position = audioProvider.audioPlayer.position;
    final headroom = buffered - position;
    final headroomSec = headroom.inSeconds;
    final headroomText = '${headroomSec >= 0 ? '+' : ''}${headroomSec}s';
    final err = (audioProvider.error != null && audioProvider.error!.isNotEmpty)
        ? 'ERR'
        : 'OK';

    // Priority: Last Issue > Notification > Agent Message
    final signal = (widget.lastIssueMessage != null &&
            widget.lastIssueMessage!.isNotEmpty)
        ? 'ISS'
        : (notificationMessage != null && notificationMessage.trim().isNotEmpty)
            ? 'NTF'
            : (agentMessage != null && agentMessage.trim().isNotEmpty)
                ? 'AGT'
                : '--';

    final rawMsg = (widget.lastIssueMessage != null &&
            widget.lastIssueMessage!.isNotEmpty)
        ? widget.lastIssueMessage!.trim()
        : (notificationMessage != null && notificationMessage.trim().isNotEmpty)
            ? notificationMessage.trim()
            : (agentMessage != null && agentMessage.trim().isNotEmpty)
                ? agentMessage.trim()
                : '--';

    final msg = rawMsg == '--' ? rawMsg : _compactMessage(rawMsg);

    final effectiveMode = sp.audioEngineMode == AudioEngineMode.auto
        ? audioProvider.audioPlayer.activeMode
        : sp.audioEngineMode;
    final mode = _shortMode(effectiveMode);
    final transition = _shortTransition(sp.trackTransitionMode);
    final handoff = _shortHandoff(sp.hybridHandoffMode);
    final background = _shortBackground(sp.hybridBackgroundMode);
    final activeEngine = _shortActiveEngine(engineContextState, effectiveMode);
    final prefetch =
        sp.webPrefetchSeconds < 0 ? 'G' : '${sp.webPrefetchSeconds}s';
    final processing = _shortProcessing(playerState?.processingState);
    // player variable removed
    final engineState = _shortEngineState(engineStateString);

    // "POS" fully removed from snapshot string
    return 'ENG:$mode • TX:$transition • HF:$handoff • BG:$background • '
        'AE:$activeEngine • '
        'PF:$prefetch • PS:$processing • '
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
    // No longer aggressively truncating here because we have Marquee
    if (cleaned.length <= 100) return cleaned;
    return '${cleaned.substring(0, 97)}…';
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
    if (contextState == null || contextState.isEmpty) return '?';
    if (contextState.contains('(WA)')) return 'WA';
    if (contextState.contains('(H5)')) return 'H5';
    if (contextState.contains('(VI)')) return 'VI';
    if (contextState.contains('(HBT)')) return 'HBT';
    // Legacy/Hybrid mode fallbacks
    if (contextState.contains('hybrid_background')) return 'BG';
    if (contextState.contains('hybrid_foreground')) return 'FG';
    if (mode != AudioEngineMode.hybrid) return '--';
    return '?';
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
      // Case 'POS' removed
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
