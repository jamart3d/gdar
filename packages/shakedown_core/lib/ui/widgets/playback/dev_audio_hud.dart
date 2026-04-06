import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:marquee/marquee.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/hud_snapshot.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_tooltip.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/utils/utils.dart';

part 'dev_audio_hud_build.dart';
part 'dev_audio_hud_fields.dart';
part 'dev_audio_hud_helpers.dart';
part 'dev_audio_hud_painter.dart';

/// Developer-facing HUD that shows engine state, buffering, and recent
/// messages.
///
/// Intended for Web use only; callers should guard with `kIsWeb` and the
/// `showDevAudioHud` setting before including.
class DevAudioHud extends StatefulWidget {
  final AudioProvider audioProvider;
  final SettingsProvider settingsProvider;
  final double labelsFontSize;
  final ColorScheme colorScheme;
  final String? fontFamily;
  final bool compact;
  final bool isAppVisible;

  const DevAudioHud({
    super.key,
    required this.audioProvider,
    required this.settingsProvider,
    required this.labelsFontSize,
    required this.colorScheme,
    required this.fontFamily,
    this.compact = false,
    this.isAppVisible = true,
  });

  @override
  State<DevAudioHud> createState() => _DevAudioHudState();
}

class _DevAudioHudState extends State<DevAudioHud> {
  static const int _driftHistoryMaxPoints = 120;
  static const int _headroomHistoryMaxPoints = 180;
  static const int _netHistoryMaxPoints = 60;

  Timer? _heartbeatPulseTimer;
  bool _heartbeatPulseOn = false;
  final List<double> _driftHistory = <double>[];
  final List<double> _headroomHistory = <double>[];
  final List<double> _netHistory = <double>[];
  final List<double> _schHistory = <double>[];
  final List<double> _decHistory = <double>[];
  final List<double> _bctHistory = <double>[];
  bool _prevFetchInFlight = false;
  double? _lastAppendedNetMs;
  DateTime? _fetchInFlightSince;
  DateTime? _bgHiddenSince;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _heartbeatPulseTimer?.cancel();
    super.dispose();
  }

  void _syncHeartbeatPulse(bool isPlaying) {
    if (!isPlaying) {
      if (_heartbeatPulseTimer != null) {
        _heartbeatPulseTimer!.cancel();
        _heartbeatPulseTimer = null;
        _heartbeatPulseOn = false;
      }
      return;
    }

    _heartbeatPulseTimer ??= Timer.periodic(const Duration(milliseconds: 900), (
      timer,
    ) {
      if (!mounted || !widget.isAppVisible) return;
      _safeSetState(() {
        _heartbeatPulseOn = !_heartbeatPulseOn;
      });
    });
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

  @override
  Widget build(BuildContext context) {
    // Note: In production, this is usually gated by kIsWeb at the call site.
    // We allow it here regardless of kIsWeb to enable unit testing on all platforms.
    return _buildHud(context);
  }
}
