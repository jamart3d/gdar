import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/logger.dart';

class AnimatedDiceIcon extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  final String? tooltip;
  final bool changeFaces;

  const AnimatedDiceIcon({
    super.key,
    required this.onPressed,
    this.isLoading = false,
    this.tooltip,
    this.changeFaces = true,
    this.enableHaptics = false,
  });

  final bool enableHaptics;

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

  // Travel positions
  // Travel positions - REMOVED

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

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    );

    _controller.addListener(_onAnimationTick);
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed &&
          _hapticsEnabledForCurrentRoll) {
        // Landing "Thud" haptic
        logger.t('AnimatedDiceIcon: Landing Haptic (status=completed)');
        HapticFeedback.mediumImpact();
      }
    });

    if (widget.isLoading) {
      _controller.repeat();
    } else if (_enableIdleRotation) {
      _idleController.repeat();
    }
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
          'AnimatedDiceIcon: Roll STARTED (isLoading=true, enableHaptics=${widget.enableHaptics})');
      _rollLeft = !_rollLeft;
      _hapticsEnabledForCurrentRoll = widget.enableHaptics;
      _generateRollSequence();
      _controller.forward(from: 0.0);
      if (_enableIdleRotation) _idleController.stop();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      logger.d('AnimatedDiceIcon: Roll ENDED (isLoading=false)');
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
        logger.t(
            'AnimatedDiceIcon: Face Change Haptic -> $face (t: ${t.toStringAsFixed(2)})');
        HapticFeedback.lightImpact();
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
    final settingsProvider = context.watch<SettingsProvider>();
    final effectiveScale =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
    final scaledIconSize = 32.0 * effectiveScale;

    return SizedBox(
      width: 56.0 * effectiveScale,
      height: kToolbarHeight, // Keep AppBar height consistency
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: IconButton(
          iconSize: scaledIconSize,
          padding:
              const EdgeInsets.all(12.0), // Standard padding (total 56x56 base)
          onPressed: widget.onPressed,
          tooltip: widget.tooltip,
          style: IconButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
          icon: AnimatedBuilder(
            animation: Listenable.merge([_controller, _idleController]),
            builder: (context, child) {
              double angle;
              double scaleX = 1.0;
              double scaleY = 1.0;

              int currentFace = _staticFace;

              if (_controller.isAnimating) {
                final t = _controller.value;

                // --- Rotation (Spin) ---
                // Exactly 1 full rotation over 2s.
                final directionMultiplier = _rollLeft ? -1.0 : 1.0;
                // Force perfectly flat landing (0 or 2pi)
                angle = t * 2 * math.pi * directionMultiplier;

                // --- Squash & Stretch (Landing Bump) ---
                // We want 3 quick pulses, and then a BIGGER bump at the end.
                // Final bump peaks at t=0.9 and settles.
                double scale;
                if (t < 0.8) {
                  // Fast cycling pulses
                  final double pulse = math.sin(t * 10 * math.pi);
                  scale = 1.0 + (0.08 * pulse * pulse);
                } else {
                  // Final landing "Thud" (Impact & Settle)
                  // Range t: 0.8 -> 1.0. normalized t2: 0 -> 1.
                  final double t2 = (t - 0.8) / 0.2;

                  // Asymmetric Bounce: Sharper rise (impact), slower settle.
                  // Uses sqrt(t2) to front-load the sine wave for "impact" feel.
                  final double bump = math.sin(math.pow(t2, 0.5) * math.pi);
                  scale = 1.0 + (0.12 * bump); // Reduced intensity (1.12x)
                }
                scaleX = scale;
                scaleY = scale;

                // --- Face Selection ---
                if (widget.changeFaces && _rollSequence.isNotEmpty) {
                  final int phaseCount = _rollSequence.length;
                  final int index =
                      (t * phaseCount).floor().clamp(0, phaseCount - 1);
                  currentFace = _rollSequence[index];
                }
              } else if (widget.isLoading) {
                // Decoupled: Finished roll but still loading.
                // Landed flat.
                angle = 0.0;
                scaleX = scaleY = 1.0;
                if (_rollSequence.isNotEmpty) {
                  currentFace = _rollSequence.last;
                }
              } else {
                // Idle
                if (_enableIdleRotation) {
                  final directionMultiplier = _rollLeft ? -1.0 : 1.0;
                  angle = _staticAngle +
                      (_idleController.value *
                          2 *
                          math.pi *
                          directionMultiplier);
                } else {
                  angle = _staticAngle;
                }
              }

              return Transform.rotate(
                angle: angle,
                child: Transform(
                  transform: Matrix4.diagonal3Values(scaleX, scaleY, 1.0),
                  alignment: Alignment.center,
                  child: CustomPaint(
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
          ),
        ),
      ),
    );
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
      Radius.circular(size.width * 0.15), // Sharper corners (standard dice)
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

    switch (face) {
      case 1:
        _drawDot(canvas, center, center, dotSize, dotPaint);
        break;
      case 2:
        _drawDot(canvas, right, top, dotSize, dotPaint);
        _drawDot(canvas, left, bottom, dotSize, dotPaint);
        break;
      case 3:
        _drawDot(canvas, right, top, dotSize, dotPaint);
        _drawDot(canvas, center, center, dotSize, dotPaint);
        _drawDot(canvas, left, bottom, dotSize, dotPaint);
        break;
      case 4:
        _drawDot(canvas, left, top, dotSize, dotPaint);
        _drawDot(canvas, right, top, dotSize, dotPaint);
        _drawDot(canvas, left, bottom, dotSize, dotPaint);
        _drawDot(canvas, right, bottom, dotSize, dotPaint);
        break;
      case 5:
        _drawDot(canvas, left, top, dotSize, dotPaint);
        _drawDot(canvas, right, top, dotSize, dotPaint);
        _drawDot(canvas, center, center, dotSize, dotPaint);
        _drawDot(canvas, left, bottom, dotSize, dotPaint);
        _drawDot(canvas, right, bottom, dotSize, dotPaint);
        break;
      case 6:
        _drawDot(canvas, left, top, dotSize, dotPaint);
        _drawDot(canvas, right, top, dotSize, dotPaint);
        _drawDot(canvas, left, center, dotSize, dotPaint);
        _drawDot(canvas, right, center, dotSize, dotPaint);
        _drawDot(canvas, left, bottom, dotSize, dotPaint);
        _drawDot(canvas, right, bottom, dotSize, dotPaint);
        break;
    }
  }

  void _drawDot(Canvas canvas, double x, double y, double r, Paint paint) {
    canvas.drawCircle(Offset(x, y), r / 2, paint);
  }

  @override
  bool shouldRepaint(DicePainter oldDelegate) {
    return oldDelegate.face != face ||
        oldDelegate.color != color ||
        oldDelegate.dotColor != dotColor;
  }
}
