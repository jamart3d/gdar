import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Travel positions
  // Travel positions - REMOVED

  // Internal variable to enable slow idle rotation
  final bool _enableIdleRotation = true;

  @override
  void initState() {
    super.initState();
    _randomizeStaticState();
    _generateRollSequence();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );

    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _controller.addListener(_onAnimationTick);

    if (widget.isLoading) {
      _controller.repeat();
    } else if (_enableIdleRotation) {
      _idleController.repeat();
    }
  }

  void _generateRollSequence() {
    // 3 or 4 faces
    final int count = 3 + math.Random().nextInt(2);
    _rollSequence = List.generate(count, (_) => 1 + math.Random().nextInt(6));
  }

  void _randomizeStaticState() {
    _staticFace = 2 + math.Random().nextInt(5);
    _staticAngle = (math.Random().nextDouble() - 0.5) * (math.pi / 6);
  }

  @override
  void didUpdateWidget(AnimatedDiceIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading != oldWidget.isLoading) {
      if (widget.isLoading) {
        // --- Determine Direction ---
        // Simply toggle direction for shake variety
        _rollLeft = !_rollLeft;

        _generateRollSequence();
        _controller.forward(from: 0.0);
        if (_enableIdleRotation) _idleController.stop();
      } else {
        if (_controller.isAnimating) {
          _controller.stop();
        }

        setState(() {
          _randomizeStaticState();
        });
        if (_enableIdleRotation) {
          _idleController.value = 0;
          _idleController.repeat();
        }
      }
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
      HapticFeedback.lightImpact();
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

    return IconButton(
      iconSize: 32, // explicit icon size
      padding: const EdgeInsets.all(12.0), // Standard padding (total 56x56)
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

          if (_controller.isAnimating || widget.isLoading) {
            final t = _controller.value;

            // --- Rotation (Spin) ---
            // 4 full rotations over 12s = 0.33 rotations per second. Slow spin.
            final directionMultiplier = _rollLeft ? -1.0 : 1.0;
            angle = t * 4 * 2 * math.pi * directionMultiplier;

            // --- Wobble (Scale) ---
            // A slow, readable "breathing" wobble.
            // Frequency matches roughly the duration?
            // Let's do 6 wobbles over 12s = 0.5Hz. Very slow.
            // t goes 0 -> 1.
            // Smooth Scale Pulse (Sin^2)
            // Removes cusps/shear illusion from abs(sin).
            // Range 0.0 -> 1.0 -> 0.0 smoothly.
            final double sinVal = math.sin(t * 6 * math.pi);
            final double wobble = sinVal * sinVal; // sin^2 is smooth

            // Uniform Scale Pulse (Breathing)
            final double scale = 1.0 + (0.10 * wobble);
            scaleX = scale;
            scaleY = scale;

            // --- Face Selection ---
            if (widget.changeFaces && _rollSequence.isNotEmpty) {
              final int phaseCount = _rollSequence.length;
              final int index =
                  (t * phaseCount).floor().clamp(0, phaseCount - 1);
              currentFace = _rollSequence[index];
            }
          } else {
            // Idle
            if (_enableIdleRotation) {
              final directionMultiplier = _rollLeft ? -1.0 : 1.0;
              angle = _staticAngle +
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
              child: CustomPaint(
                size: const Size(32, 32),
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
