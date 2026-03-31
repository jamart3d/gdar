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
    return (size * 3) + (0.8 * 2 * 3) + 4 + 8.0;
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

  double? _computeScheduleLeadSeconds(HudSnapshot hud) {
    final scheduledIndex = hud.scheduledIndex;
    final scheduledStart = hud.scheduledStartContextTime;
    final currentContext = hud.ctxCurrentTime;
    if (scheduledIndex == null || scheduledIndex < 0) {
      return null;
    }
    if (scheduledStart == null || currentContext == null) {
      return null;
    }
    final leadSeconds = scheduledStart - currentContext;
    if (!leadSeconds.isFinite) return null;
    return leadSeconds;
  }

  void _appendSchSample(double? sample) {
    if (sample == null) return;
    _schHistory.add(sample);
    if (_schHistory.length > _DevAudioHudState._driftHistoryMaxPoints) {
      _schHistory.removeAt(0);
    }
  }

  void _appendDecSample(double? sample) {
    if (sample == null) return;
    _decHistory.add(sample);
    if (_decHistory.length > _DevAudioHudState._netHistoryMaxPoints) {
      _decHistory.removeAt(0);
    }
  }

  void _appendBctSample(double? sample) {
    if (sample == null) return;
    _bctHistory.add(sample);
    if (_bctHistory.length > _DevAudioHudState._netHistoryMaxPoints) {
      _bctHistory.removeAt(0);
    }
  }

  void _appendHpdSample(int? sample) {
    if (sample == null) return;
    _hpdHistory.add(sample.toDouble());
    if (_hpdHistory.length > _DevAudioHudState._netHistoryMaxPoints) {
      _hpdHistory.removeAt(0);
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
    if (ms < 1) return '${ms.toStringAsFixed(2)}ms';
    if (ms < 10) return '${ms.toStringAsFixed(1)}ms';
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

  Widget _wrapHudTooltip({
    required Widget child,
    required String key,
    required String value,
    required bool isFruit,
  }) {
    final tooltip = _hudFieldTooltip(key, value);
    if (tooltip.isEmpty) return child;
    final richTooltip = _buildHudTooltipRichMessage(tooltip);
    if (isFruit) {
      return FruitTooltip(
        message: tooltip,
        richMessage: richTooltip,
        child: child,
      );
    }
    return Tooltip(
      richMessage: richTooltip,
      preferBelow: false,
      verticalOffset: 20,
      child: child,
    );
  }

  InlineSpan _buildHudTooltipRichMessage(String text) {
    const tokenColorMap = <String, Color>{
      'WA': Colors.cyan,
      'WBA': Colors.cyan,
      'WEBAUDIO': Colors.cyan,
      'H5': Colors.lightBlueAccent,
      'HTML5': Colors.lightBlueAccent,
      'HYB': Colors.orangeAccent,
      'HYBRID': Colors.orangeAccent,
      'AUT': Colors.greenAccent,
      'AUTO': Colors.greenAccent,
      'VID': Colors.purpleAccent,
      'HBT': Colors.greenAccent,
      'OFF': Colors.redAccent,
      'STB': Colors.green,
      'BAL': Colors.lightBlueAccent,
      'MAX': Colors.orangeAccent,
      'ISS': Colors.redAccent,
      'NTF': Colors.orange,
      'AGT': Colors.lightBlueAccent,
      'VIS': Colors.green,
      'OK': Colors.green,
      'SOFT': Colors.amber,
      'RISK': Colors.redAccent,
      'DEAD': Colors.redAccent,
      'RDY': Colors.green,
      'LOW': Colors.amber,
      'MISS': Colors.redAccent,
      'IMM': Colors.cyanAccent,
      'BND': Colors.orangeAccent,
      'BUF': Colors.amber,
      'CNT': Colors.orangeAccent,
      'SUS': Colors.redAccent,
      'ACT': Colors.greenAccent,
      'LD': Colors.orangeAccent,
      'END': Colors.lightBlueAccent,
      'IDL': Colors.blueGrey,
      'ARM': Colors.amber,
      'FNC': Colors.orangeAccent,
      'PRB': Colors.orangeAccent,
      'DONE': Colors.greenAccent,
      'PWA': Colors.greenAccent,
      'L': Colors.amber,
      'P': Colors.greenAccent,
      'D': Colors.cyanAccent,
      'W': Colors.lightBlueAccent,
    };
    final tokens = tokenColorMap.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final pattern = RegExp(
      '(?<!\\w)(${tokens.map(RegExp.escape).join('|')})(?!\\w)',
    );
    final children = <InlineSpan>[];
    var cursor = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > cursor) {
        children.add(TextSpan(text: text.substring(cursor, match.start)));
      }
      final token = match.group(0)!;
      children.add(
        TextSpan(
          text: token,
          style: TextStyle(
            color: tokenColorMap[token.toUpperCase()],
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      cursor = match.end;
    }

    if (cursor < text.length) {
      children.add(TextSpan(text: text.substring(cursor)));
    }

    return TextSpan(children: children);
  }

  String _hudFieldTooltip(String key, String value) {
    switch (key) {
      case 'ENG':
        return 'Engine mode. Tap to switch. WBA=WebAudio, H5=HTML5, HYB=Hybrid, AUT=Auto.';
      case 'DET':
        return 'Runtime profile. L=low, P=PWA, D=desktop, W=web.';
      case 'HF':
        return 'Hybrid handoff mode. Tap to change. IMM=immediate, BND=boundary, BUF=buffered, OFF=stay on HTML5.';
      case 'BG':
        return 'Background strategy. Tap to change. H5=handoff, HBT=heartbeat, VID=video keepalive, OFF=disabled.';
      case 'STB':
        return 'Hidden-session preset. Tap to change. STB=stable, BAL=balanced, MAX=aggressive.';
      case 'AE':
        return value == '--'
            ? 'Current playback engine is not available yet.'
            : 'Current playback engine. WA=WebAudio, H5=HTML5. + means survival help is active.';
      case 'V':
        if (value.startsWith('VIS')) {
          return 'Tab is visible.';
        }
        return 'Tab is hidden. Mobile browsers may throttle audio.';
      case 'DFT':
        return 'Tick drift sparkline. Lower and steadier is better.';
      case 'PF':
        if (value == 'G') {
          return 'Prefetch is greedy: fetch the whole track up front.';
        }
        return 'Prefetch window for the next track. Tap to change.';
      case 'PS':
        return 'Playback state. LD=loading, BUF=buffering, RDY=ready, END=ended, IDL=idle.';
      case 'P':
        return 'Player state.';
      case 'BUF':
        return 'Buffered amount for the current track.';
      case 'HD':
        return 'Headroom sparkline. Buffer time ahead of playback.';
      case 'NX':
        if (value == '--' || value == '00:00') {
          return 'No next-track buffer yet.';
        }
        return 'Buffered amount for the next track.';
      case 'E':
        if (value == 'OK') return 'No engine error.';
        if (value == '--') return 'Error state not available.';
        return 'Engine error flag. Check MSG for detail.';
      case 'ST':
        return 'Engine state. CNT=countdown, SUS=suspended, VIS=waiting on visibility, ACT=active, RDY=ready.';
      case 'SIG':
        return 'Message type. ISS=issue, NTF=notice, AGT=agent note.';
      case 'MSG':
        return 'Latest status message. Tap to dismiss.';
      case 'TX':
        return 'Track transition mode.';
      case 'SHD':
        return 'Background protection status. VIS=visible, OK=protected, SOFT=best effort, RISK=at risk, DEAD=off.';
      case 'GAP':
        return 'Gapless readiness for the next handoff. RDY is healthy; LOW or MISS means risk.';
      case 'BGT':
        return 'Total time this tab has been in the background.';
      case 'PM':
        return 'Performance mode. ON reduces effects and visual cost.';
      case 'NET':
        if (value == '--') {
          return 'Network sparkline. No fetch sample yet.';
        }
        if (value.endsWith('...')) {
          return 'Network sparkline. A fetch is in flight.';
        }
        return 'Network sparkline. Time to first byte from Archive.';
      case 'LG':
        if (value == '--') {
          return 'No measured track gap yet.';
        }
        return 'Measured gap between the last two tracks.';
      case 'SCH':
        return 'Schedule lead. Seconds until the next WebAudio start period.';
      case 'LAT':
        return 'Output latency in milliseconds.';
      case 'DEC':
        return 'Decode time. Milliseconds spent in decodeAudioData(buffer).';
      case 'BCT':
        return 'Concat time. Milliseconds spent stitching fetch chunks.';
      case 'ERR':
        return 'Count of failed fetch or decode attempts in this session.';
      case 'WTC':
        return 'Background worker tick count.';
      case 'SR':
        return 'Active AudioContext sample rate.';
      case 'CAC':
        return 'Decoded WebAudio buffers currently cached.';
      case 'HS':
        return 'Hybrid handoff state. IDLE=idle, ARM=armed, FNC=fenced, PRB=probing, DONE=WebAudio active.';
      case 'HAT':
        return 'Total hybrid handoff attempts this session.';
      case 'HPD':
        return 'Restore sparkline. Poll cycles needed before WebAudio became ready.';
      default:
        return '$key: $value';
    }
  }
}
