part of 'dev_audio_hud.dart';

extension _DevAudioHudHelpers on _DevAudioHudState {
  void _showHudMenu({
    required BuildContext context,
    required Offset globalPosition,
    required String key,
    required SettingsProvider sp,
  }) async {
    final RenderBox? overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlay == null) return;

    List<PopupMenuEntry<dynamic>> items = [];

    switch (key) {
      case 'ENG':
        final modes = AudioEngineMode.values.where(
          (mode) =>
              mode != AudioEngineMode.standard &&
              mode != AudioEngineMode.passive,
        );
        items = modes.map((mode) {
          final active = sp.audioEngineMode == mode;
          return PopupMenuItem(
            value: mode,
            child: Text(
              'Engine: ${mode.name.toUpperCase()}',
              style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? widget.colorScheme.primary : null,
              ),
            ),
          );
        }).toList();
        break;
      case 'HF':
        items = HybridHandoffMode.values.map((mode) {
          final active = sp.hybridHandoffMode == mode;
          return PopupMenuItem(
            value: mode,
            child: Text(
              'Handoff: ${mode.name.toUpperCase()}',
              style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? widget.colorScheme.primary : null,
              ),
            ),
          );
        }).toList();
        break;
      case 'BG':
        items = HybridBackgroundMode.values.map((mode) {
          final active = sp.hybridBackgroundMode == mode;
          return PopupMenuItem(
            value: mode,
            child: Text(
              'Background: ${mode.name.toUpperCase()}',
              style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? widget.colorScheme.primary : null,
              ),
            ),
          );
        }).toList();
        break;
      case 'STB':
        items = HiddenSessionPreset.values.map((preset) {
          final active = sp.hiddenSessionPreset == preset;
          return PopupMenuItem(
            value: preset,
            child: Text(
              'Preset: ${preset.name.toUpperCase()}',
              style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? widget.colorScheme.primary : null,
              ),
            ),
          );
        }).toList();
        break;
      case 'PF':
        items = [30, 60].map((val) {
          final active = sp.webPrefetchSeconds == val;
          return PopupMenuItem(
            value: val,
            child: Text(
              'Prefetch: ${val}s',
              style: TextStyle(
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
                color: active ? widget.colorScheme.primary : null,
              ),
            ),
          );
        }).toList();
        break;
    }

    if (items.isEmpty) return;

    final result = await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        globalPosition & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: items,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );

    if (result == null) return;
    if (result is AudioEngineMode) {
      if (result == sp.audioEngineMode) return;
      sp.setAudioEngineMode(result);
      if (context.mounted) {
        showRestartMessage(context, 'Engine change requires relaunch.');
      }
    } else if (result is HybridHandoffMode) {
      if (result == sp.hybridHandoffMode) return;
      sp.setHybridHandoffMode(result);
      if (context.mounted) {
        showMessage(context, 'Handoff: ${result.name.toUpperCase()}');
      }
    } else if (result is HybridBackgroundMode) {
      if (result == sp.hybridBackgroundMode) return;
      sp.setHybridBackgroundMode(result);
      if (context.mounted) {
        showMessage(context, 'Background: ${result.name.toUpperCase()}');
      }
    } else if (result is HiddenSessionPreset) {
      if (result == sp.hiddenSessionPreset) return;
      sp.setHiddenSessionPreset(result);
      if (context.mounted) {
        showRestartMessage(context, 'Preset change requires relaunch.');
      }
    } else if (result is int && key == 'PF') {
      if (result == sp.webPrefetchSeconds) return;
      sp.setWebPrefetchSeconds(result);
      if (context.mounted) {
        showMessage(context, 'Prefetch: ${result}s');
      }
    }
  }

  Widget _buildTrafficLightHeartbeat(
    double labelsFontSize,
    ColorScheme colorScheme, {
    required bool active,
    required bool needed,
    required bool enabledBySettings,
    required bool isPlaying,
    bool horizontal = false,
  }) {
    if (!enabledBySettings) return const SizedBox.shrink();

    final size = labelsFontSize * 0.44;

    Widget buildDot(
      Color activeColor,
      bool isCurrentlyActive,
      bool shouldFlash,
    ) {
      Color finalColor;
      final pulseActive =
          _heartbeatPulseOn && isPlaying && shouldFlash && isCurrentlyActive;

      if (!isPlaying) {
        finalColor = activeColor.withValues(alpha: 0.12);
      } else if (isCurrentlyActive) {
        if (shouldFlash) {
          finalColor = _heartbeatPulseOn
              ? activeColor
              : activeColor.withValues(alpha: 0.35);
        } else {
          finalColor = activeColor;
        }
      } else {
        finalColor = activeColor.withValues(alpha: 0.12);
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: size,
        height: size,
        margin: horizontal
            ? const EdgeInsets.symmetric(horizontal: 1.2)
            : const EdgeInsets.symmetric(vertical: 0.8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: finalColor,
          boxShadow: [
            if (pulseActive)
              BoxShadow(
                color: activeColor.withValues(alpha: 0.3),
                blurRadius: 4,
                spreadRadius: 1,
              ),
          ],
        ),
      );
    }

    final dots = [
      buildDot(Colors.redAccent, needed && !active, true),
      buildDot(Colors.orange, !needed, false),
      buildDot(Colors.greenAccent, active, true),
    ];

    if (horizontal) {
      return Row(mainAxisSize: MainAxisSize.min, children: dots);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: dots),
    );
  }

  double _heartbeatStackWidth(double labelsFontSize) {
    final size = labelsFontSize * 0.44;
    return size + 5;
  }

  double _heartbeatStackHeight(double labelsFontSize) {
    final size = labelsFontSize * 0.44;
    return (size * 3) + (0.8 * 2 * 3) + 4;
  }

  double? _parseDriftValue(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'-?\d+(?:\.\d+)?').firstMatch(raw);
    if (match == null) return null;
    return double.tryParse(match.group(0)!);
  }

  void _appendDriftSample(String? rawValue) {
    final sample = _parseDriftValue(rawValue);
    if (sample == null) return;
    _driftHistory.add(sample);
    if (_driftHistory.length > _DevAudioHudState._driftHistoryMaxPoints) {
      _driftHistory.removeAt(0);
    }
  }

  void _appendHeadroomSample(String? rawValue) {
    final sample = _parseDriftValue(rawValue);
    if (sample == null) return;
    _headroomHistory.add(sample);
    if (_headroomHistory.length > _DevAudioHudState._headroomHistoryMaxPoints) {
      _headroomHistory.removeAt(0);
    }
  }

  void _trackNet(HudSnapshot hud) {
    if (hud.fetchInFlight && !_prevFetchInFlight) {
      _fetchInFlightSince = DateTime.now();
    } else if (!hud.fetchInFlight && _prevFetchInFlight) {
      _fetchInFlightSince = null;
    }
    _prevFetchInFlight = hud.fetchInFlight;
    final ms = hud.fetchTtfbMs;
    if (ms != null && !hud.fetchInFlight && ms != _lastAppendedNetMs) {
      _lastAppendedNetMs = ms;
      _netHistory.add(ms);
      if (_netHistory.length > _DevAudioHudState._netHistoryMaxPoints) {
        _netHistory.removeAt(0);
      }
    }
  }

  String _computeNetDisplay(HudSnapshot hud) {
    if (hud.fetchInFlight) {
      final elapsed = _fetchInFlightSince != null
          ? DateTime.now().difference(_fetchInFlightSince!).inMilliseconds
          : 0;
      return '${(elapsed / 1000.0).toStringAsFixed(1)}s...';
    }
    final ms = hud.fetchTtfbMs;
    if (ms == null) return '--';
    if (ms < 1000) return '${ms.round()}ms';
    return '${(ms / 1000.0).toStringAsFixed(1)}s';
  }

  String _computeLastGap(HudSnapshot hud) {
    final ms = hud.lastGapMs;
    if (ms == null) return '--';
    if (ms < 1) return '0ms';
    if (ms < 1000) return '${ms.round()}ms';
    return '${(ms / 1000.0).toStringAsFixed(1)}s';
  }

  void _trackBgt(HudSnapshot hud) {
    final isHidden = hud.visibility.startsWith('HID') && hud.isPlaying;
    if (isHidden && _bgHiddenSince == null) {
      _bgHiddenSince = DateTime.now();
    } else if (!isHidden && _bgHiddenSince != null) {
      _totalBgtDuration += DateTime.now().difference(_bgHiddenSince!);
      _bgHiddenSince = null;
    }
  }

  String _computeBgt() {
    var total = _totalBgtDuration;
    if (_bgHiddenSince != null) {
      total += DateTime.now().difference(_bgHiddenSince!);
    }
    if (total == Duration.zero) return '--';
    final h = total.inHours;
    final m = total.inMinutes.remainder(60);
    final s = total.inSeconds.remainder(60);
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String _computeShield(HudSnapshot hud) {
    if (!hud.isPlaying) return '--';
    if (!hud.visibility.startsWith('HID')) return 'VIS';
    if (hud.hbActive) return 'OK';
    final bg = hud.background;
    if (bg == 'OFF' || bg == 'NONE' || bg == '--') return 'DEAD';
    if (hud.hbNeeded) return 'RISK';
    return 'SOFT';
  }

  String _computeGap(HudSnapshot hud) {
    if (!hud.isPlaying) return '--';
    if (hud.handoff == 'OFF') return 'OFF';
    final nxEmpty = hud.nextBuffered == '--' || hud.nextBuffered == '00:00';
    if (nxEmpty && !hud.isHandoffCountdown) return '--';
    final prefetchSec = widget.settingsProvider.webPrefetchSeconds.toDouble();
    final nxSec = _parseDurationToSeconds(hud.nextBuffered) ?? 0.0;
    final nxFraction = (nxSec / prefetchSec).clamp(0.0, 1.0);
    if (hud.isHandoffCountdown && nxFraction < 0.05) return 'MISS';
    if (hud.isHandoffCountdown && nxFraction < 0.4) return 'LOW';
    if (nxFraction >= 0.5) return 'RDY';
    return 'WAIT';
  }

  double? _parseDurationToSeconds(String? raw) {
    if (raw == null || raw == '--' || raw == '00:00' || raw.isEmpty) {
      return null;
    }
    final parts = raw.split(':');
    if (parts.length < 2) return double.tryParse(raw);
    try {
      final mins = double.parse(parts[0]);
      final secs = double.parse(parts[1]);
      return (mins * 60) + secs;
    } catch (_) {
      return null;
    }
  }

  double _parseGapMs(String raw) {
    if (raw.endsWith('ms')) {
      return double.tryParse(raw.replaceAll('ms', '')) ?? 0;
    }
    if (raw.endsWith('s')) {
      return (double.tryParse(raw.replaceAll('s', '')) ?? 0) * 1000;
    }
    return 0;
  }

  String _hudFieldTooltip(String key, String value) {
    switch (key) {
      case 'ENG':
        String desc = 'Unknown';
        if (value == 'WBA') desc = 'WebAudio';
        if (value == 'H5') desc = 'HTML5';
        if (value == 'STD') desc = 'Standard';
        if (value == 'PAS') desc = 'Passive';
        if (value == 'HYB') desc = 'Hybrid';
        if (value == 'AUT') desc = 'Auto';
        return 'Configured Engine Mode: $desc ($value)';
      case 'DET':
        String profile = 'Unknown';
        if (value == 'L') profile = 'Low Performance (Mobile/Old)';
        if (value == 'P') profile = 'PWA (Installed App)';
        if (value == 'D') profile = 'Desktop (High Performance)';
        if (value == 'W') profile = 'Standard Web Browser';
        return 'Detected Hardware Profile: $profile ($value)';
      case 'HF':
        String desc = 'Unknown';
        if (value == 'IMM') {
          desc = 'Immediate - swap to WebAudio as soon as loaded';
        }
        if (value == 'BND') {
          desc = 'End - swap at the next track boundary';
        }
        if (value == 'OFF') {
          desc = 'Disabled - stay on HTML5, no WebAudio handoff';
        }
        if (value == 'BUF') {
          desc = 'Mid - wait until HTML5 buffer is exhausted, then swap';
        }
        return 'Hybrid Handoff Mode: $desc ($value)';
      case 'BG':
        String desc = 'Unknown';
        if (value == 'VID') {
          desc =
              'Video Overlay - silent video keeps WebAudio alive in background';
        }
        if (value == 'HBT') {
          desc =
              'Heartbeat - silent audio clock keeps WebAudio alive in background';
        }
        if (value == 'OFF') {
          desc = 'Disabled - no background survival, may throttle on mobile';
        }
        if (value == 'H5') {
          desc = 'HTML5 Keepalive - hands off to HTML5 in background';
        }
        final dotLegend = value == 'HBT'
            ? ' | Dots: needed but inactive (risk) | not needed (desktop) | active (protected)'
            : '';
        return 'Background Survival: $desc$dotLegend';
      case 'STB':
        String desc = 'Unknown';
        if (value == 'STB') desc = 'Stability (Safe)';
        if (value == 'BAL') desc = 'Balanced';
        if (value == 'MAX') desc = 'Maximum (Performance)';
        return 'Session Stability Preset: $desc ($value)';
      case 'AE':
        if (value == '--') {
          return 'Active Engine: not applicable (non-hybrid mode)';
        }
        if (value == '?') {
          return 'Active Engine: unknown - engine context not yet reported';
        }
        String aeDesc = 'Unknown';
        if (value.startsWith('WA')) {
          aeDesc =
              'Web Audio API - low-latency, gapless, needs full buffer decoded upfront.';
        }
        if (value.startsWith('H5')) {
          aeDesc = 'HTML5 <audio> element - streaming, background-safe.';
        }
        if (value.startsWith('VI')) {
          aeDesc =
              'Video Overlay - silent video trick keeps WebAudio alive in background.';
        }
        if (value.startsWith('HBT')) {
          aeDesc =
              'Heartbeat - silent audio clock preventing browser throttle.';
        }
        if (value.startsWith('BG')) {
          aeDesc = 'Generic background engine.';
        }
        if (value.startsWith('FG')) {
          aeDesc = 'Generic foreground engine.';
        }
        final aeSuffix = value.endsWith('+')
            ? ' | +: survival mode active.'
            : '';
        return 'Active Engine: $aeDesc$aeSuffix';
      case 'V':
        if (value.startsWith('VIS')) {
          return 'Tab Visible - app is in the foreground ($value)';
        }
        return 'Tab Hidden - app is in the background ($value). Audio may throttle on mobile.';
      case 'DFT':
        return 'Tick Drift: $value - time between engine heartbeats. Lower = more stable playback.';
      case 'PF':
        if (value == 'G') {
          return 'Prefetch: Greedy - fetch full track immediately. Required by WebAudio.';
        }
        return 'Prefetch Window: pre-load $value of the next track.';
      case 'PS':
        String desc = 'Unknown';
        if (value == 'LD') {
          desc = 'Loading - fetching audio data';
        }
        if (value == 'BUF') {
          desc = 'Buffering - waiting for enough data to play';
        }
        if (value == 'RDY') {
          desc = 'Ready - playing normally';
        }
        if (value == 'END') {
          desc = 'Completed - reached end of playlist';
        }
        if (value == 'IDL') {
          desc = 'Idle - no track loaded';
        }
        return 'Processing State: $desc';
      case 'P':
        return 'Player State: $value - whether audio is playing or paused';
      case 'BUF':
        return 'Current Track Buffered: $value of this track is downloaded';
      case 'HD':
        return 'Buffer Headroom: $value ahead of playback position.';
      case 'NX':
        if (value == '--' || value == '00:00') {
          return 'Next Track Buffer: nothing buffered yet';
        }
        return 'Next Track Buffer: $value of the next track is pre-loaded.';
      case 'E':
        if (value == 'OK') return 'No errors';
        if (value == '--') return 'Error status not available';
        return 'Error detected: $value - tap MSG chip for details';
      case 'ST':
        return 'Engine Context: $value - internal state of the active audio engine';
      case 'SIG':
        String sigDesc = value;
        if (value == 'ISS') sigDesc = 'Issue detected';
        if (value == 'NTF') sigDesc = 'Notification';
        if (value == 'AGT') sigDesc = 'Agent update';
        if (value == 'OK') sigDesc = 'All clear';
        return 'Signal: $sigDesc - tap MSG for details';
      case 'MSG':
        return 'Status Message - tap to dismiss. $value';
      case 'TX':
        String txDesc = 'Unknown';
        if (value == 'XFD') txDesc = 'Crossfade';
        if (value == 'GAP') txDesc = 'Gapless';
        if (value == 'OFF') txDesc = 'Off';
        return 'Track Transition Mode: $txDesc ($value)';
      case 'SHD':
        return 'Session Shield (background protection): $value';
      case 'GAP':
        return 'Gapless Readiness (next track pre-loaded): $value';
      case 'BGT':
        return 'Background Time: $value total time the tab has been hidden this session';
      case 'PM':
        final pmDesc = value == 'ON' ? 'Enabled (effects reduced)' : 'Disabled';
        return 'Performance Mode: $pmDesc ($value)';
      case 'NET':
        if (value == '--') {
          return 'Network TTFB: no fetch recorded yet (WebAudio engine only)';
        }
        if (value.endsWith('...')) {
          return 'Network TTFB: fetch in progress ($value) - time since request started';
        }
        return 'Network TTFB (archive.org time-to-first-byte): $value';
      case 'LG':
        if (value == '--') {
          return 'Last Gap: no track transition yet';
        }
        return 'Last Gap: $value between previous and current track.';
      default:
        return '$key: $value';
    }
  }
}
