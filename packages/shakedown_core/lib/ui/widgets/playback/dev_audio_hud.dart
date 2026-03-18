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

  Timer? _heartbeatPulseTimer;
  bool _heartbeatPulseOn = false;
  final List<double> _driftHistory = <double>[];
  final List<double> _headroomHistory = <double>[];

  @override
  void dispose() {
    _heartbeatPulseTimer?.cancel();
    super.dispose();
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

        final fields = hud.toMap();
        final isFruitMode =
            context.read<ThemeProvider?>()?.themeStyle == ThemeStyle.fruit;

        return Container(
          key: const ValueKey('hud_always_expanded'),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: hud.isHandoffCountdown
                ? Colors.orange.withValues(alpha: 0.95)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(10),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final narrow = constraints.maxWidth < 360;
              final keys = narrow
                  ? const [
                      'ENG',
                      'DET',
                      'TX',
                      'HF',
                      'BG',
                      'STB',
                      'AE',
                      'V',
                      'DFT',
                      'PF',
                      'PS',
                      'BUF',
                      'HD',
                      'E',
                      'ST',
                      'SIG',
                      'MSG',
                    ]
                  : const [
                      'ENG',
                      'DET',
                      'TX',
                      'HF',
                      'BG',
                      'STB',
                      'AE',
                      'V',
                      'DFT',
                      'PF',
                      'PS',
                      'BUF',
                      'HD',
                      'NX',
                      'E',
                      'ST',
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
                heartbeatActive: hud.hbActive,
                heartbeatNeeded: hud.hbNeeded,
                heartbeatEnabledBySettings: hud.heartbeatEnabledBySettings,
                isPlaying: hud.isPlaying,
                isHandoffCountdown: hud.isHandoffCountdown,
              );
            },
          ),
        );
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
      sp.setAudioEngineMode(result);
      if (context.mounted) {
        showRestartMessage(context, 'Engine change requires relaunch.');
      }
    } else if (result is HybridHandoffMode) {
      sp.setHybridHandoffMode(result);
      if (context.mounted) {
        showRestartMessage(context, 'Handoff mode change requires relaunch.');
      }
    } else if (result is HybridBackgroundMode) {
      sp.setHybridBackgroundMode(result);
      if (context.mounted) {
        showRestartMessage(
          context,
          'Background mode change requires relaunch.',
        );
      }
    } else if (result is HiddenSessionPreset) {
      sp.setHiddenSessionPreset(result);
      if (context.mounted) {
        showRestartMessage(context, 'Preset change requires relaunch.');
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
        margin: const EdgeInsets.symmetric(vertical: 0.8),
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2.5, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(size),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          buildDot(Colors.redAccent, needed && !active, true),
          buildDot(Colors.orange, !needed, false),
          buildDot(Colors.greenAccent, active, true),
        ],
      ),
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
    _heartbeatPulseTimer = Timer.periodic(const Duration(milliseconds: 900), (
      _,
    ) {
      if (!mounted || !widget.isAppVisible) return;
      _safeSetState(() => _heartbeatPulseOn = !_heartbeatPulseOn);
    });
  }

  Widget _buildHudFieldWrap({
    required Map<String, String> fields,
    required List<String> orderedKeys,
    required double labelsFontSize,
    required ColorScheme colorScheme,
    required String? fontFamily,
    required bool isFruit,
    required bool heartbeatActive,
    required bool heartbeatNeeded,
    required bool heartbeatEnabledBySettings,
    required bool isPlaying,
    bool isHandoffCountdown = false,
  }) {
    const chipSpacing = 8.0;
    const sparklineChipWidth = 84.0;
    _appendDriftSample(fields['DFT']);
    _appendHeadroomSample(fields['HD']);

    final telemetryChips = <Widget>[];
    final sparklineValueChips = <Widget>[];
    final trendChips = <Widget>[];
    Widget? bgChip;
    Widget? detChip;
    Widget? errorChip;
    Widget? sigChip;
    Widget? msgChip;

    // High contrast overrides for handoff countdown
    final baseTextColor = isHandoffCountdown
        ? Colors.black
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.96);
    final keyTextColor = isHandoffCountdown
        ? Colors.black.withValues(alpha: 0.8)
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final chipBgColor = isHandoffCountdown
        ? Colors.black.withValues(alpha: 0.1)
        : colorScheme.onSurface.withValues(alpha: 0.06);

    final trendChipWidth = math.max(
      _heartbeatStackWidth(labelsFontSize),
      sparklineChipWidth,
    );
    final trendChipHeight = _heartbeatStackHeight(labelsFontSize);
    trendChips.add(
      Container(
        width: trendChipWidth,
        height: trendChipHeight,
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: CustomPaint(
            painter: _HudSparklinePainter(
              values: _driftHistory,
              baseline: 0,
              strokeColor: baseTextColor,
              guideColor: keyTextColor.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
    trendChips.add(
      Container(
        width: trendChipWidth,
        height: trendChipHeight,
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          child: CustomPaint(
            painter: _HudSparklinePainter(
              values: _headroomHistory,
              baseline: 0,
              strokeColor: baseTextColor.withValues(alpha: 0.92),
              guideColor: keyTextColor.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );

    if (heartbeatEnabledBySettings) {
      trendChips.add(
        _buildTrafficLightHeartbeat(
          labelsFontSize,
          colorScheme,
          active: heartbeatActive,
          needed: heartbeatNeeded,
          enabledBySettings: true,
          isPlaying: isPlaying,
        ),
      );
    }

    for (final key in orderedKeys) {
      final value = fields[key];
      if (value == null) continue;

      Widget valueWidget;
      final bool isDynamic = key == 'MSG';

      if (key == 'MSG' && value.length > 30) {
        // Implement Marquee for long messages
        valueWidget = LayoutBuilder(
          builder: (context, constraints) {
            return SizedBox(
              width: constraints.maxWidth > 0 ? constraints.maxWidth : 200,
              height: labelsFontSize * 1.2,
              child: Marquee(
                text: value,
                style: TextStyle(
                  color: baseTextColor,
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
          },
        );
      } else if (isDynamic) {
        // Dynamic width for MSG (only) to allow content to dictate size
        valueWidget = Text(
          value,
          style: TextStyle(
            color: baseTextColor,
            fontWeight: FontWeight.w700,
            fontSize: labelsFontSize * 0.84,
            fontFamily: fontFamily ?? 'RobotoMono',
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      } else {
        // Snug value widget (no fixed width here, the Container handles it)
        valueWidget = Text(
          value,
          style: TextStyle(
            color: baseTextColor,
            fontWeight: FontWeight.w700,
            fontSize: labelsFontSize * 0.84,
            fontFamily: fontFamily ?? 'RobotoMono',
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          overflow: TextOverflow.ellipsis,
        );
      }

      // Determine the fixed width for the chip background (Precision Safe Shave)
      double? chipWidth;
      if (!isDynamic) {
        chipWidth = 48; // Default
        switch (key) {
          case 'BUF':
          case 'NX':
            chipWidth = key == 'BUF' ? 68 : 79;
            break;
          case 'DFT':
            chipWidth = 66;
            break;
          case 'HD':
            chipWidth = 59;
            break;
          case 'DET':
            chipWidth = 42;
            break;
          case 'STB':
          case 'ENG':
          case 'SIG':
            chipWidth = 52;
            break;
          case 'HF':
          case 'TX':
          case 'ST':
          case 'PF':
          case 'PS':
            chipWidth = 45;
            break;
          case 'BG':
          case 'V':
          case 'AE':
            chipWidth = 38;
            break;
          case 'E':
            chipWidth = 25;
            break;
        }
      }

      Widget chip = Container(
        width: chipWidth,
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        decoration: BoxDecoration(
          color: chipBgColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$key:',
              style: TextStyle(
                color: keyTextColor,
                fontWeight: FontWeight.w700,
                fontSize: labelsFontSize * 0.84,
                fontFamily: fontFamily ?? 'RobotoMono',
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            if (key == 'MSG') Flexible(child: valueWidget) else valueWidget,
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
      const interactiveKeys = ['ENG', 'HF', 'BG', 'STB'];
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

      if (isFruit) {
        final tooltip = _hudFieldTooltip(key, value);
        if (tooltip.isNotEmpty) {
          chip = FruitTooltip(message: tooltip, child: chip);
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
    if (detChip != null &&
        (errorChip != null || sigChip != null || msgChip != null)) {
      sigAndMsgChildren.add(const SizedBox(width: chipSpacing));
    }
    if (errorChip != null) {
      sigAndMsgChildren.add(errorChip);
    }
    if (errorChip != null && (sigChip != null || msgChip != null)) {
      sigAndMsgChildren.add(const SizedBox(width: chipSpacing));
    }
    if (sigChip != null) {
      sigAndMsgChildren.add(sigChip);
    }
    if (sigChip != null && msgChip != null) {
      sigAndMsgChildren.add(const SizedBox(width: chipSpacing));
    }
    if (msgChip != null) {
      sigAndMsgChildren.add(Flexible(child: msgChip));
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sigAndMsgChildren,
          ),
        ],
      ],
    );
  }

  String _hudFieldTooltip(String key, String value) {
    switch (key) {
      case 'ENG':
        return 'Engine mode: $value';
      case 'DET':
        return 'Detected profile: $value';
      case 'TX':
        return 'Track transition: $value';
      case 'HF':
        return 'Hybrid handoff mode: $value';
      case 'BG':
        return 'Hybrid background mode: $value';
      case 'STB':
        return 'Session stability preset: $value';
      case 'AE':
        return 'Active audio engine: $value';
      case 'V':
        return 'App visibility status (VIS/HID) and duration: $value';
      case 'DFT':
        return 'JS engine tick drift (seconds since last heartbeat): $value';
      case 'PF':
        return 'Prefetch window (seconds): $value';
      case 'PS':
        return 'Processing state: $value';
      case 'P':
        return 'Player state: $value';
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
