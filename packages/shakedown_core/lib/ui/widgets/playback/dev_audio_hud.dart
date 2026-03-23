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
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_tooltip.dart';
import 'package:shakedown_core/utils/utils.dart';

/// Developer-facing HUD that shows engine state, buffering, and recent messages.
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
  bool _prevFetchInFlight = false;
  double? _lastAppendedNetMs;
  DateTime? _fetchInFlightSince;

  // BGT: cumulative background time tracking
  Duration _totalBgtDuration = Duration.zero;
  DateTime? _bgHiddenSince;
  @override
  void initState() {
    super.initState();
    // Ensure lists are ready for Web/JS runtime immediately
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

  @override
  Widget build(BuildContext context) {
    final audioProvider = widget.audioProvider;
    final labelsFontSize = widget.labelsFontSize;

    return StreamBuilder<HudSnapshot>(
      stream: audioProvider.hudSnapshotStream,
      initialData: audioProvider.currentHudSnapshot,
      builder: (context, snapshot) {
        final hud = snapshot.data;
        if (hud == null) return const SizedBox.shrink();

        _syncHeartbeatPulse(hud.isPlaying);
        _trackBgt(hud);
        _trackNet(hud);

        if (!widget.compact) {
          final summary = hud
              .toMap()
              .entries
              .map((e) => '${e.key}:${e.value}')
              .join(' • ');
          return Text(
            summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: labelsFontSize * 0.92,
              fontFamily: widget.fontFamily ?? 'RobotoMono',
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          );
        }

        final fields = {
          ...hud.toMap(),
          'SHD': _computeShield(hud),
          'GAP': _computeGap(hud),
          'BGT': _computeBgt(),
          'PM': widget.settingsProvider.performanceMode ? 'ON' : 'OFF',
          'NET': _computeNetDisplay(hud),
          'LG': _computeLastGap(hud),
        };
        final isFruitMode =
            context.read<ThemeProvider?>()?.themeStyle == ThemeStyle.fruit;
        final isFruitGlassOn =
            isFruitMode && (widget.settingsProvider.fruitEnableLiquidGlass);

        final theme = Theme.of(context);
        final isDarkMode = theme.brightness == Brightness.dark;
        final isTrueBlack =
            isDarkMode &&
            (context.read<SettingsProvider?>()?.useTrueBlack ?? false);

        final hudPadding = widget.compact
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 5)
            : const EdgeInsets.symmetric(horizontal: 8, vertical: 6);

        Widget hudContent = Container(
          key: const ValueKey('hud_always_expanded'),
          width: double.infinity,
          padding: hudPadding,
          decoration: BoxDecoration(
            color: isTrueBlack
                ? Colors.black
                : isFruitGlassOn
                ? Colors.transparent
                : Theme.of(context).colorScheme.surface.withValues(
                    alpha: isFruitMode ? 0.85 : 0.78,
                  ),
            borderRadius: BorderRadius.circular(isFruitMode ? 14 : 10),
            border: isTrueBlack
                ? Border.all(
                    color: widget.colorScheme.onSurface.withValues(alpha: 0.2),
                    width: 1.0,
                  )
                : (isFruitMode
                      ? Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                          width: 0.5,
                        )
                      : null),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              const keys = [
                'DFT',
                'HD',
                'BUF',
                'NX',
                'PF',
                'HF',
                'TX',
                'DET',
                'BG',
                'STB',
                'ENG',
                'AE',
                'V',
                'E',
                'ST',
                'PS',
                'SHD',
                'GAP',
                'BGT',
                'PM',
                'NET',
                'LG',
                'SIG',
                'MSG',
              ];

              return _buildHudFieldWrap(
                fields: fields,
                orderedKeys: keys,
                labelsFontSize: labelsFontSize,
                colorScheme: widget.colorScheme,
                fontFamily: widget.fontFamily,
                isFruit: isFruitMode,
                isTrueBlack: isTrueBlack,
                heartbeatActive: hud.hbActive,
                heartbeatNeeded: hud.hbNeeded,
                heartbeatEnabledBySettings: hud.heartbeatEnabledBySettings,
                isPlaying: hud.isPlaying,
                isHandoffCountdown: hud.isHandoffCountdown,
              );
            },
          ),
        );

        if (isFruitMode && !isTrueBlack) {
          hudContent = Padding(
            padding: EdgeInsets.symmetric(vertical: widget.compact ? 1.0 : 2.0),
            child: LiquidGlassWrapper(
              borderRadius: BorderRadius.circular(14),
              opacity: 0.85,
              child: hudContent,
            ),
          );
        }

        return hudContent;
      },
    );
  }

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
    if (_driftHistory.length > _driftHistoryMaxPoints) {
      _driftHistory.removeAt(0);
    }
  }

  void _appendHeadroomSample(String? rawValue) {
    final sample = _parseDriftValue(rawValue);
    if (sample == null) return;
    _headroomHistory.add(sample);
    if (_headroomHistory.length > _headroomHistoryMaxPoints) {
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
      if (_netHistory.length > _netHistoryMaxPoints) _netHistory.removeAt(0);
    }
  }

  String _computeNetDisplay(HudSnapshot hud) {
    if (hud.fetchInFlight) {
      final elapsed = _fetchInFlightSince != null
          ? DateTime.now().difference(_fetchInFlightSince!).inMilliseconds
          : 0;
      return '${(elapsed / 1000.0).toStringAsFixed(1)}s\u2026';
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

  Widget _buildHudFieldWrap({
    required Map<String, String> fields,
    required List<String> orderedKeys,
    required double labelsFontSize,
    required ColorScheme colorScheme,
    required String? fontFamily,
    required bool isFruit,
    required bool isTrueBlack,
    required bool heartbeatActive,
    required bool heartbeatNeeded,
    required bool heartbeatEnabledBySettings,
    required bool isPlaying,
    bool isHandoffCountdown = false,
  }) {
    const chipSpacing = 8.0;
    const sparklineChipWidth = 84.0;
    if (isPlaying) {
      _appendDriftSample(fields['DFT']);
      _appendHeadroomSample(fields['HD']);
    }
    final telemetryChips = <Widget>[];
    final sparklineValueChips = <Widget>[];
    final trendChips = <Widget>[];
    Widget? bgChip;
    Widget? detChip;
    Widget? errorChip;
    Widget? sigChip;
    Widget? msgChip;

    // High contrast overrides for handoff countdown
    final baseTextColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.96);
    final keyTextColor = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final chipBgColor = isTrueBlack
        ? Colors.black.withValues(alpha: 0.0)
        : colorScheme.onSurface.withValues(alpha: 0.06);

    final trendChipWidth = math.max(
      _heartbeatStackWidth(labelsFontSize),
      sparklineChipWidth,
    );
    final trendChipHeight = _heartbeatStackHeight(labelsFontSize);
    Widget buildTrendChip(
      List<double> history,
      String label,
      Color strokeColor, {
      double alpha = 0.92,
    }) {
      return Container(
        width: trendChipWidth,
        height: trendChipHeight,
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
              child: CustomPaint(
                size: Size(trendChipWidth, trendChipHeight),
                painter: _HudSparklinePainter(
                  values: history,
                  baseline: 0,
                  strokeColor: strokeColor.withValues(alpha: alpha),
                  guideColor: keyTextColor.withValues(alpha: 0.45),
                ),
              ),
            ),
            Positioned(
              bottom: 1,
              right: 2,
              child: Text(
                label,
                style: TextStyle(
                  color: keyTextColor.withValues(alpha: 0.6),
                  fontSize: labelsFontSize * 0.65,
                  fontWeight: FontWeight.w900,
                  fontFamily: fontFamily ?? 'RobotoMono',
                ),
              ),
            ),
          ],
        ),
      );
    }

    trendChips.add(
      buildTrendChip(_driftHistory, 'DFT', baseTextColor, alpha: 1.0),
    );
    trendChips.add(buildTrendChip(_headroomHistory, 'HD', baseTextColor));
    trendChips.add(
      buildTrendChip(_netHistory, 'NET', Colors.amberAccent, alpha: 0.9),
    );
    // Standalone heartbeat removed from top row, now integrated into SIG below.

    for (final key in orderedKeys) {
      final value = fields[key];
      if (value == null) continue;
      final bool isDynamic = key == 'MSG';

      // Determine the fixed width for the chip background (Precision Safe Shave)
      double? chipWidth;
      if (!isDynamic) {
        chipWidth = 48; // Default
        switch (key) {
          case 'DFT':
          case 'HD':
            chipWidth = 76;
            break;
          case 'NET':
            chipWidth = 68;
            break;
          case 'DET':
            chipWidth = 38; // Slightly tighter as requested
            break;
          case 'ENG':
            chipWidth = 44;
            break;
          case 'SIG':
            chipWidth = 36;
            break;
          case 'BG':
            chipWidth = 68; // Tightened for internal dots
            break;
          case 'HF':
          case 'TX':
          case 'ST':
          case 'PF':
          case 'PS':
            chipWidth = 54;
            break;
          case 'V':
          case 'AE':
            chipWidth = 48;
            break;
          case 'SHD':
          case 'GAP':
            chipWidth = 52;
            break;
          case 'BGT':
            chipWidth = 62;
            break;
          case 'PM':
            chipWidth = 44;
            break;
          case 'E':
            chipWidth = 36;
            break;
          case 'LG':
            chipWidth = 58;
            break;
        }
      }

      // Centralized Dynamic Styling Logic
      Color finalChipBgColor = chipBgColor;
      Color finalBaseTextColor = baseTextColor;
      Color finalKeyTextColor = keyTextColor;
      bool hasClickableBorder = false;

      // 1. Interactive Logic (Clickable Hints)
      const interactiveKeys = ['ENG', 'HF', 'BG', 'STB', 'PF'];
      if (interactiveKeys.contains(key)) {
        hasClickableBorder = true;
      }

      // 2. State-Based Color Logic
      if (key == 'E' && value != 'OK' && value != '--') {
        finalChipBgColor = Colors.redAccent.withValues(alpha: 0.9);
        finalBaseTextColor = Colors.white;
        finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
      } else if (key == 'HD') {
        final driftValue = _parseDriftValue(value) ?? 0.0;
        if (driftValue < 0) {
          finalChipBgColor = Colors.redAccent.withValues(alpha: 0.8);
          finalBaseTextColor = Colors.white;
        } else if (driftValue < 5) {
          finalChipBgColor = Colors.orange.withValues(alpha: 0.8);
          finalBaseTextColor = Colors.black;
        } else if (driftValue > 20) {
          finalBaseTextColor = Colors.green;
        }
      } else if (key == 'PS') {
        if (value == 'BUF' || value == 'LD') {
          finalChipBgColor = Colors.orange.withValues(alpha: 0.7);
          finalBaseTextColor = Colors.black;
        } else if (value == 'RDY') {
          finalBaseTextColor = Colors.green;
        }
      } else if (key == 'AE') {
        final isSurvival = value.contains('+');
        if (value.startsWith('WA')) {
          finalBaseTextColor = Colors.cyan.shade700;
        } else if (value.startsWith('H5')) {
          finalBaseTextColor = Colors.lightBlueAccent;
        }
        if (isSurvival) {
          finalChipBgColor = Colors.indigoAccent.withValues(alpha: 0.85);
          finalBaseTextColor = Colors.white;
          finalKeyTextColor = Colors.white.withValues(alpha: 0.82);
        }
      } else if (key == 'SIG') {
        if (value == 'ISS') {
          finalChipBgColor = Colors.redAccent.withValues(alpha: 0.9);
          finalBaseTextColor = Colors.white;
        } else if (value == 'NTF') {
          finalChipBgColor = Colors.orange.withValues(alpha: 0.8);
          finalBaseTextColor = Colors.black;
        } else if (value == 'AGT') {
          finalBaseTextColor = Colors.lightBlueAccent;
        }
      } else if (key == 'ST') {
        if (isHandoffCountdown) {
          finalChipBgColor = Colors.orange.withValues(alpha: 0.9);
          finalBaseTextColor = Colors.black;
          finalKeyTextColor = Colors.black.withValues(alpha: 0.8);
        } else if (value == 'SUSP') {
          finalChipBgColor = Colors.redAccent.withValues(alpha: 0.8);
          finalBaseTextColor = Colors.white;
        }
      } else if (key == 'NX' && value != '00:00' && value != '--') {
        finalBaseTextColor = Colors.green;
      } else if (key == 'DFT') {
        final drift = _parseDriftValue(value) ?? 0.0;
        if (drift.abs() > 0.1) {
          finalBaseTextColor = Colors.redAccent;
        }
      } else if (key == 'V' && value.startsWith('HID')) {
        finalBaseTextColor = Colors.lightBlueAccent;
      } else if (key == 'STB') {
        if (value == 'STB') finalBaseTextColor = Colors.green;
        if (value == 'BAL') finalBaseTextColor = Colors.lightBlueAccent;
        if (value == 'MAX') finalBaseTextColor = Colors.orangeAccent;
      } else if (key == 'SHD') {
        switch (value) {
          case 'OK':
            finalChipBgColor = Colors.green.withValues(alpha: 0.7);
            finalBaseTextColor = Colors.white;
            finalKeyTextColor = Colors.white.withValues(alpha: 0.75);
            break;
          case 'SOFT':
            finalChipBgColor = Colors.amber.withValues(alpha: 0.75);
            finalBaseTextColor = Colors.black;
            finalKeyTextColor = Colors.black.withValues(alpha: 0.7);
            break;
          case 'RISK':
          case 'DEAD':
            finalChipBgColor = Colors.redAccent.withValues(alpha: 0.85);
            finalBaseTextColor = Colors.white;
            finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
            break;
        }
      } else if (key == 'GAP') {
        switch (value) {
          case 'RDY':
            finalBaseTextColor = Colors.green;
            break;
          case 'LOW':
          case 'MISS':
            finalChipBgColor = Colors.redAccent.withValues(alpha: 0.9);
            finalBaseTextColor = Colors.white;
            finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
            break;
        }
      } else if (key == 'BGT' && value != '--') {
        finalBaseTextColor = Colors.lightBlueAccent;
      } else if (key == 'PM') {
        if (value == 'ON') {
          finalChipBgColor = Colors.amber.withValues(alpha: 0.75);
          finalBaseTextColor = Colors.black;
          finalKeyTextColor = Colors.black.withValues(alpha: 0.7);
        }
      } else if (key == 'NET') {
        if (value.endsWith('\u2026')) {
          // In-flight: amber pulse
          finalBaseTextColor = Colors.amberAccent;
        } else if (value != '--') {
          // Parse ms value from display string for color thresholding
          double? netMs;
          if (value.endsWith('ms')) {
            netMs = double.tryParse(value.replaceAll('ms', ''));
          } else if (value.endsWith('s')) {
            final sec = double.tryParse(value.replaceAll('s', ''));
            if (sec != null) netMs = sec * 1000;
          }
          if (netMs != null) {
            if (netMs < 800) {
              finalBaseTextColor = Colors.green;
            } else if (netMs < 2000) {
              finalChipBgColor = Colors.orange.withValues(alpha: 0.8);
              finalBaseTextColor = Colors.black;
              finalKeyTextColor = Colors.black.withValues(alpha: 0.7);
            } else {
              finalChipBgColor = Colors.redAccent.withValues(alpha: 0.85);
              finalBaseTextColor = Colors.white;
              finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
            }
          }
        }
      } else if (key == 'LG') {
        if (value != '--') {
          final gapMs = _parseGapMs(value);
          if (gapMs < 5) {
            finalBaseTextColor = Colors.green;
          } else if (gapMs < 50) {
            finalChipBgColor = Colors.amber.withValues(alpha: 0.75);
            finalBaseTextColor = Colors.black;
            finalKeyTextColor = Colors.black.withValues(alpha: 0.7);
          } else {
            finalChipBgColor = Colors.redAccent.withValues(alpha: 0.85);
            finalBaseTextColor = Colors.white;
            finalKeyTextColor = Colors.white.withValues(alpha: 0.8);
          }
        }
      }

      Widget chip = Container(
        constraints: chipWidth != null
            ? BoxConstraints(minWidth: chipWidth)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 2.3, vertical: 2),
        decoration: BoxDecoration(
          color: finalChipBgColor,
          borderRadius: BorderRadius.circular(6),
          border: hasClickableBorder
              ? Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.4),
                  width: 1.0,
                )
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${key == 'DET' ? 'D' : key}:',
              style: TextStyle(
                color: finalKeyTextColor,
                fontWeight: FontWeight.w700,
                fontSize: labelsFontSize * 0.84,
                fontFamily: fontFamily ?? 'RobotoMono',
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (key == 'MSG' && value.length > 30)
              Flexible(
                child: SizedBox(
                  height: labelsFontSize * 1.2,
                  child: Marquee(
                    text: value,
                    style: TextStyle(
                      color: finalBaseTextColor,
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
                ),
              )
            else if (key == 'MSG')
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: finalBaseTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: labelsFontSize * 0.84,
                    fontFamily: fontFamily ?? 'RobotoMono',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              )
            else if (key == 'AE' && value.contains('+'))
              Flexible(
                child: RichText(
                  overflow: TextOverflow.ellipsis,
                  text: TextSpan(
                    style: TextStyle(
                      color: finalBaseTextColor,
                      fontWeight: FontWeight.w700,
                      fontSize: labelsFontSize * 0.84,
                      fontFamily: fontFamily ?? 'RobotoMono',
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                    children: [
                      TextSpan(text: value.replaceAll('+', '')),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 220),
                          opacity: _heartbeatPulseOn ? 1.0 : 0.4,
                          child: Text(
                            '+',
                            style: TextStyle(
                              color: finalBaseTextColor,
                              fontWeight: FontWeight.w700,
                              fontSize: labelsFontSize * 0.84,
                              fontFamily: fontFamily ?? 'RobotoMono',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    color: finalBaseTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: labelsFontSize * 0.84,
                    fontFamily: fontFamily ?? 'RobotoMono',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            if (key == 'BG' && heartbeatEnabledBySettings) ...[
              const SizedBox(width: 4),
              RepaintBoundary(
                child: _buildTrafficLightHeartbeat(
                  labelsFontSize,
                  colorScheme,
                  active: heartbeatActive,
                  needed: heartbeatNeeded,
                  enabledBySettings: true,
                  isPlaying: isPlaying,
                  horizontal: true,
                ),
              ),
            ],
            if (hasClickableBorder)
              Padding(
                padding: const EdgeInsets.only(left: 1),
                child: Icon(
                  Icons.arrow_drop_down,
                  size: labelsFontSize * 0.9,
                  color: finalKeyTextColor,
                ),
              ),
          ],
        ),
      );

      // Wrap MSG chip in GestureDetector for clearing issues
      if (key == 'MSG') {
        chip = GestureDetector(
          onTap: () => widget.audioProvider.clearLastIssue(),
          child: chip,
        );
      }

      // Wrap interactive chips in GestureDetector for popup menus
      if (interactiveKeys.contains(key)) {
        chip = GestureDetector(
          onTapDown: (details) => _showHudMenu(
            context: context,
            globalPosition: details.globalPosition,
            key: key,
            sp: widget.settingsProvider,
          ),
          child: MouseRegion(cursor: SystemMouseCursors.click, child: chip),
        );
      }

      final tooltip = _hudFieldTooltip(key, value);
      if (tooltip.isNotEmpty) {
        if (isFruit) {
          chip = FruitTooltip(message: tooltip, child: chip);
        } else {
          chip = Tooltip(
            message: tooltip,
            preferBelow: false,
            verticalOffset: 20,
            child: chip,
          );
        }
      }

      if (key == 'V') {
        chip = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: chip,
        );
      }

      if (key == 'DET') {
        detChip = chip;
      } else if (key == 'E') {
        errorChip = chip;
      } else if (key == 'DFT' || key == 'HD') {
        sparklineValueChips.add(chip);
      } else if (key == 'BG') {
        bgChip = chip;
      } else if (key == 'SIG') {
        sigChip = chip;
      } else if (key == 'MSG') {
        msgChip = chip;
      } else {
        telemetryChips.add(chip);
      }
    }

    final middleRowChips = <Widget>[];
    middleRowChips.addAll(sparklineValueChips);
    if (bgChip != null) {
      middleRowChips.add(bgChip);
    }
    middleRowChips.addAll(telemetryChips);

    final sigAndMsgChildren = <Widget>[];
    if (detChip != null) {
      sigAndMsgChildren.add(detChip);
    }
    if (errorChip != null) {
      sigAndMsgChildren.add(errorChip);
    }
    if (sigChip != null) {
      sigAndMsgChildren.add(sigChip);
    }
    if (msgChip != null) {
      sigAndMsgChildren.add(msgChip);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: chipSpacing,
          runSpacing: chipSpacing,
          children: trendChips,
        ),
        if (middleRowChips.isNotEmpty) const SizedBox(height: chipSpacing),
        if (middleRowChips.isNotEmpty)
          Wrap(
            spacing: chipSpacing,
            runSpacing: chipSpacing,
            children: middleRowChips,
          ),
        if (sigAndMsgChildren.isNotEmpty) ...[
          const SizedBox(height: chipSpacing),
          Wrap(
            spacing: chipSpacing,
            runSpacing: chipSpacing,
            crossAxisAlignment: WrapCrossAlignment.start,
            children: sigAndMsgChildren,
          ),
        ],
      ],
    );
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
          desc = 'Immediate — swap to WebAudio as soon as loaded';
        }
        if (value == 'BND') {
          desc = 'End — swap at the next track boundary';
        }
        if (value == 'OFF') {
          desc = 'Disabled — stay on HTML5, no WebAudio handoff';
        }
        if (value == 'BUF') {
          desc = 'Mid — wait until HTML5 buffer is exhausted, then swap';
        }
        return 'Hybrid Handoff Mode: $desc ($value)';
      case 'BG':
        String desc = 'Unknown';
        if (value == 'VID') {
          desc =
              'Video Overlay — silent video keeps WebAudio alive in background';
        }
        if (value == 'HBT') {
          desc =
              'Heartbeat — silent audio clock keeps WebAudio alive in background';
        }
        if (value == 'OFF') {
          desc = 'Disabled — no background survival, may throttle on mobile';
        }
        if (value == 'H5') {
          desc = 'HTML5 Keepalive — hands off to HTML5 in background';
        }
        final dotLegend = value == 'HBT'
            ? ' | Dots: 🔴 needed but inactive (risk) · 🟠 not needed (desktop) · 🟢 active (protected)'
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
          return 'Active Engine: unknown — engine context not yet reported';
        }
        String aeDesc = 'Unknown';
        if (value.startsWith('WA')) {
          aeDesc =
              'Web Audio API — low-latency, gapless, needs full buffer decoded. Shown in dark cyan.';
        }
        if (value.startsWith('H5')) {
          aeDesc =
              'HTML5 <audio> element — streaming, background-safe. Shown in blue.';
        }
        if (value.startsWith('VI')) {
          aeDesc =
              'Video Overlay — silent video trick keeps WebAudio alive in background.';
        }
        if (value.startsWith('HBT')) {
          aeDesc =
              'Heartbeat — silent audio clock preventing browser throttle.';
        }
        if (value.startsWith('BG')) {
          aeDesc = 'Generic background engine.';
        }
        if (value.startsWith('FG')) {
          aeDesc = 'Generic foreground engine.';
        }
        String aeSuffix = '';
        if (value.endsWith('+')) {
          aeSuffix = ' | +: survival mode active (indigo chip).';
        }
        return 'Active Engine: $aeDesc$aeSuffix';
      case 'V':
        if (value.startsWith('VIS')) {
          return 'Tab Visible — app is in the foreground ($value)';
        }
        return 'Tab Hidden — app is in the background ($value). Audio may throttle on mobile.';
      case 'DFT':
        return 'Tick Drift: $value — time between engine heartbeats. Lower = more stable playback.';
      case 'PF':
        if (value == 'G') {
          return 'Prefetch: Greedy — fetch full track immediately. '
              'Required by WebAudio engine (needs full buffer decoded upfront).';
        }
        return 'Prefetch Window: pre-load $value of the next track. '
            'Applies to HTML5/Hybrid engines only.';
      case 'PS':
        String desc = 'Unknown';
        if (value == 'LD') desc = 'Loading — fetching audio data';
        if (value == 'BUF') {
          desc = 'Buffering — waiting for enough data to play';
        }
        if (value == 'RDY') desc = 'Ready — playing normally';
        if (value == 'END') desc = 'Completed — reached end of playlist';
        if (value == 'IDL') desc = 'Idle — no track loaded';
        return 'Processing State: $desc';
      case 'P':
        return 'Player State: $value — whether audio is playing or paused';
      case 'BUF':
        return 'Current Track Buffered: $value of this track is downloaded';
      case 'HD':
        return 'Buffer Headroom: $value ahead of playback position. Positive = smooth, negative = risk of stall.';
      case 'NX':
        if (value == '--' || value == '00:00') {
          return 'Next Track Buffer: nothing buffered yet';
        }
        return 'Next Track Buffer: $value of the next track is pre-loaded and ready for gapless playback';
      case 'E':
        if (value == 'OK') return 'No errors';
        if (value == '--') return 'Error status not available';
        return 'Error detected: $value — tap MSG chip for details';
      case 'ST':
        return 'Engine Context: $value — internal state of the active audio engine';
      case 'SIG':
        String sigDesc = value;
        if (value == 'ISS') sigDesc = 'Issue detected';
        if (value == 'NTF') sigDesc = 'Notification';
        if (value == 'AGT') sigDesc = 'Agent update';
        if (value == 'OK') sigDesc = 'All clear';
        return 'Signal: $sigDesc — tap MSG for details';
      case 'MSG':
        return 'Status Message — tap to dismiss. $value';
      case 'TX':
        String txDesc = 'Unknown';
        if (value == 'XFD') txDesc = 'Crossfade';
        if (value == 'GAP') txDesc = 'Gapless';
        if (value == 'OFF') txDesc = 'Off';
        return 'Track Transition Mode: $txDesc ($value)';
      case 'SHD':
        String shdDesc = 'Unknown';
        if (value == 'ON') shdDesc = 'Active (session protected)';
        if (value == 'OFF') shdDesc = 'Disabled';
        if (value == 'N/A') shdDesc = 'Not Available';
        return 'Session Shield (background protection): $shdDesc ($value)';
      case 'GAP':
        String gapDesc = 'Unknown';
        if (value == 'RDY') gapDesc = 'Ready (next track buffered)';
        if (value == 'NO') gapDesc = 'Not ready';
        if (value == 'N/A') gapDesc = 'Not applicable';
        return 'Gapless Readiness (next track pre-loaded): $gapDesc ($value)';
      case 'BGT':
        return 'Background Time: $value total time the tab has been hidden this session';
      case 'PM':
        String pmDesc = value == 'ON'
            ? 'Enabled (effects reduced)'
            : 'Disabled';
        return 'Performance Mode: $pmDesc ($value)';
      case 'NET':
        if (value == '--') {
          return 'Network TTFB: no fetch recorded yet (WebAudio engine only)';
        }
        if (value.endsWith('\u2026')) {
          return 'Network TTFB: fetch in progress ($value) — time since request started';
        }
        return 'Network TTFB (archive.org time-to-first-byte): $value'
            ' | Green <800ms · Orange 800ms–2s · Red >2s';
      case 'LG':
        if (value == '--') {
          return 'Last Gap: no track transition yet';
        }
        return 'Last Gap: $value between previous track ending and current track starting.'
            ' Green <5ms (seamless) · Amber 5–50ms (minor gap) · Red >50ms (audible gap)';
      default:
        return '$key: $value';
    }
  }
}

class _HudSparklinePainter extends CustomPainter {
  final List<double> values;
  final double baseline;
  final Color strokeColor;
  final Color guideColor;

  const _HudSparklinePainter({
    required this.values,
    required this.baseline,
    required this.strokeColor,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = guideColor
      ..strokeWidth = 1;
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      guidePaint,
    );

    if (values.isEmpty || size.width <= 1 || size.height <= 1) {
      return;
    }

    var minV = values.first;
    var maxV = values.first;
    for (final v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }

    final lo = math.min(minV, baseline);
    final hi = math.max(maxV, baseline);
    final range = (hi - lo).abs() < 0.001 ? 1.0 : (hi - lo);
    final sampleCount = values.length;
    final xStep = sampleCount <= 1
        ? size.width
        : size.width / (sampleCount - 1);

    final path = Path();
    for (var i = 0; i < sampleCount; i++) {
      final x = i * xStep;
      final normalized = (values[i] - lo) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HudSparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.baseline != baseline ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.guideColor != guideColor;
  }
}
