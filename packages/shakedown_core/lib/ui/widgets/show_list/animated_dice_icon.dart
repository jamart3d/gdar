import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_tooltip.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:lucide_icons/lucide_icons.dart';

class AnimatedDiceIcon extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String? tooltip;
  final bool changeFaces;

  final bool useLucide;
  final bool enableHaptics;
  final bool naked;
  final bool disableSquash;
  final Color? iconColor;

  const AnimatedDiceIcon({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.tooltip,
    this.changeFaces = true,
    this.enableHaptics = false,
    this.useLucide = false,
    this.naked = false,
    this.disableSquash = false,
    this.iconColor,
  });

  @override
  State<AnimatedDiceIcon> createState() => _AnimatedDiceIconState();
}

class _AnimatedDiceIconState extends State<AnimatedDiceIcon>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _idleController;
  int _staticFace = 2; // Default to 2 to avoid "1" looking like a reset
  double _staticAngle = 0.0;
  int _lastHapticFace = 1;

  // Roll direction logic
  bool _rollLeft = false;
  List<int> _rollSequence = [];
  bool _hapticsEnabledForCurrentRoll = false;

  // Internal variable to enable slow idle rotation
  final bool _enableIdleRotation = false;

  @override
  void initState() {
    super.initState();
    _randomizeStaticState();
    _generateRollSequence();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _syncRollDuration();

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _controller.addListener(_onAnimationTick);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _hapticsEnabledForCurrentRoll) {
        // Landing "Thud" haptic
        final isTv = context.read<DeviceService>().isTv;
        if (!isTv) {
          logger.t('AnimatedDiceIcon: Landing Haptic (status=completed)');
          AppHaptics.mediumImpact(context.read<DeviceService>());
        }
      }
    });

    if (widget.isLoading) {
      _controller.repeat();
    } else if (_enableIdleRotation) {
      _idleController.repeat();
    }
  }

  void _syncRollDuration() {
    final settingsProvider = context.read<SettingsProvider>();
    _controller.duration = settingsProvider.performanceMode
        ? const Duration(milliseconds: 500)
        : const Duration(seconds: 2);
  }

  void _generateRollSequence() {
    // 3 or 4 faces
    final int count = 3 + math.Random().nextInt(2);
    _rollSequence = List.generate(count, (_) => 2 + math.Random().nextInt(5));

    // Ensure last face is different from current static face so it doesn't "land" where it started
    while (_rollSequence.last == _staticFace) {
      _rollSequence[_rollSequence.length - 1] = 2 + math.Random().nextInt(5);
    }
  }

  void _randomizeStaticState() {
    _staticFace = 2 + math.Random().nextInt(5);
    // Always start flat for a cleaner initial look (e.g. from splash)
    _staticAngle = 0.0;
  }

  @override
  void didUpdateWidget(AnimatedDiceIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      logger.d(
        'AnimatedDiceIcon: Roll STARTED (isLoading=true, enableHaptics=${widget.enableHaptics})',
      );
      _syncRollDuration();
      _rollLeft = !_rollLeft;
      _hapticsEnabledForCurrentRoll = widget.enableHaptics;
      _generateRollSequence();
      _controller.forward(from: 0.0);
      if (_enableIdleRotation) _idleController.stop();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      logger.d('AnimatedDiceIcon: Roll ENDED (isLoading=false)');
      _controller.stop();
      if (_enableIdleRotation) {
        _idleController.value = 0;
        _idleController.repeat();
      }
      setState(() {
        if (_rollSequence.isNotEmpty) {
          _staticFace = _rollSequence.last;
        }
        // Ensure perfectly flat landing
        _staticAngle = 0.0;
      });
    }
  }

  void _onAnimationTick() {
    if (!_controller.isAnimating && !widget.isLoading) return;

    if (_rollSequence.isEmpty) return;

    final double t = _controller.value;
    final int phaseCount = _rollSequence.length; // 3 or 4
    // Calculate current index based on time
    final int index = (t * phaseCount).floor().clamp(0, phaseCount - 1);

    final int face = _rollSequence[index];

    if (widget.changeFaces && face != _lastHapticFace) {
      if (_hapticsEnabledForCurrentRoll) {
        final isTv = context.read<DeviceService>().isTv;
        if (!isTv) {
          logger.t(
            'AnimatedDiceIcon: Face Change Haptic -> $face (t: ${t.toStringAsFixed(2)})',
          );
          AppHaptics.lightImpact(context.read<DeviceService>());
        }
      }
      _lastHapticFace = face;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = widget.iconColor ?? colorScheme.primary;
    final settingsProvider = context.watch<SettingsProvider>();
    final effectiveScale = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );
    final scaledIconSize = 32.0 * effectiveScale;

    final Widget iconContent = AnimatedBuilder(
      animation: Listenable.merge([_controller, _idleController]),
      builder: (context, child) {
        double angle;
        double scaleX = 1.0;
        double scaleY = 1.0;

        int currentFace = _staticFace;

        if (_controller.isAnimating) {
          final t = _controller.value;
          final bool isSimpleTheme = settingsProvider.performanceMode;

          // --- Rotation (Spin) ---
          final directionMultiplier = _rollLeft ? -1.0 : 1.0;
          final double turns = isSimpleTheme ? 0.25 : 1.0;
          angle = t * 2 * math.pi * turns * directionMultiplier;

          // --- Squash & Stretch (Landing Bump) ---
          if (settingsProvider.useNeumorphism || widget.disableSquash) {
            scaleX = scaleY = 1.0;
          } else {
            double scale;
            if (t < 0.8) {
              final double pulse = math.sin(t * 10 * math.pi);
              scale = 1.0 + (0.08 * pulse * pulse);
            } else {
              final double t2 = (t - 0.8) / 0.2;
              final double bump = math.sin(math.pow(t2, 0.5) * math.pi);
              scale = 1.0 + (0.12 * bump);
            }
            scaleX = scale;
            scaleY = scale;
          }

          // --- Face Selection ---
          if (widget.changeFaces && _rollSequence.isNotEmpty) {
            final int phaseCount = _rollSequence.length;
            final int index = (t * phaseCount).floor().clamp(0, phaseCount - 1);
            currentFace = _rollSequence[index];
          }
        } else if (widget.isLoading) {
          angle = 0.0;
          scaleX = scaleY = 1.0;
          if (_rollSequence.isNotEmpty) {
            currentFace = _rollSequence.last;
          }
        } else {
          if (_enableIdleRotation) {
            final directionMultiplier = _rollLeft ? -1.0 : 1.0;
            angle =
                _staticAngle +
                (_idleController.value * 2 * math.pi * directionMultiplier);
          } else {
            angle = _staticAngle;
          }
        }

        return Transform.rotate(
          angle: angle,
          child: Transform(
            transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
            alignment: Alignment.center,
            child: widget.useLucide
                ? Icon(
                    _getLucideDiceIcon(currentFace),
                    size: scaledIconSize,
                    color: iconColor,
                  )
                : CustomPaint(
                    size: Size(scaledIconSize, scaledIconSize),
                    painter: DicePainter(
                      face: currentFace,
                      color: colorScheme.primaryContainer,
                      dotColor: colorScheme.onPrimaryContainer,
                    ),
                  ),
          ),
        );
      },
    );

    if (widget.naked) {
      return iconContent;
    }

    final bool isFruit =
        context.watch<ThemeProvider>().themeStyle == ThemeStyle.fruit;

    Widget button = IconButton(
      iconSize: scaledIconSize,
      padding: const EdgeInsets.all(12.0),
      onPressed: widget.onPressed,
      tooltip: isFruit ? null : widget.tooltip,
      style: IconButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      icon: iconContent,
    );

    if (isFruit && widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      button = FruitTooltip(message: widget.tooltip!, child: button);
    }

    return SizedBox(
      width: 56.0 * effectiveScale,
      height: 48.0 * effectiveScale,
      child: FittedBox(fit: BoxFit.scaleDown, child: button),
    );
  }

  IconData _getLucideDiceIcon(int face) {
    switch (face) {
      case 1:
        return LucideIcons.dice1;
      case 2:
        return LucideIcons.dice2;
      case 3:
        return LucideIcons.dice3;
      case 4:
        return LucideIcons.dice4;
      case 5:
        return LucideIcons.dice5;
      case 6:
        return LucideIcons.dice6;
      default:
        return LucideIcons.dice5;
    }
  }
}

class DicePainter extends CustomPainter {
  final int face;
  final Color color;
  final Color dotColor;

  DicePainter({
    required this.face,
    required this.color,
    required this.dotColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.15),
    );

    final Paint bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawRRect(rect, bodyPaint);

    final Paint dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    final double dotSize = size.width * 0.15;
    final double center = size.width / 2;
    final double left = size.width * 0.25;
    final double right = size.width * 0.75;
    final double top = size.height * 0.25;
    final double bottom = size.height * 0.75;

    void drawDot(double x, double y) {
      canvas.drawCircle(Offset(x, y), dotSize / 2, dotPaint);
    }

    switch (face) {
      case 1:
        drawDot(center, center);
        break;
      case 2:
        drawDot(right, top);
        drawDot(left, bottom);
        break;
      case 3:
        drawDot(right, top);
        drawDot(center, center);
        drawDot(left, bottom);
        break;
      case 4:
        drawDot(left, top);
        drawDot(right, top);
        drawDot(left, bottom);
        drawDot(right, bottom);
        break;
      case 5:
        drawDot(left, top);
        drawDot(right, top);
        drawDot(center, center);
        drawDot(left, bottom);
        drawDot(right, bottom);
        break;
      case 6:
        drawDot(left, top);
        drawDot(right, top);
        drawDot(left, center);
        drawDot(right, center);
        drawDot(left, bottom);
        drawDot(right, bottom);
        break;
    }
  }

  @override
  bool shouldRepaint(DicePainter oldDelegate) {
    return oldDelegate.face != face ||
        oldDelegate.color != color ||
        oldDelegate.dotColor != dotColor;
  }
}
