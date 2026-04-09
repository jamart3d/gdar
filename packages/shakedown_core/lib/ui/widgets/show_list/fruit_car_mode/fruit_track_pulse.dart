import 'package:flutter/material.dart';

class FruitCarModeTrackPulse extends StatefulWidget {
  const FruitCarModeTrackPulse({
    super.key,
    required this.colorScheme,
    required this.scaleFactor,
    required this.active,
  });

  final ColorScheme colorScheme;
  final double scaleFactor;
  final bool active;

  @override
  State<FruitCarModeTrackPulse> createState() => _FruitCarModeTrackPulseState();
}

class _FruitCarModeTrackPulseState extends State<FruitCarModeTrackPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant FruitCarModeTrackPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color pulseColor = widget.active
        ? widget.colorScheme.primary
        : widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.42);
    final double baseSize = 8 * widget.scaleFactor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = Curves.easeInOut.transform(_controller.value);
        final double scale = widget.active ? (0.9 + (t * 0.35)) : 1.0;
        final double alpha = widget.active ? (0.55 + (t * 0.35)) : 0.42;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: baseSize,
            height: baseSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pulseColor.withValues(alpha: alpha),
              boxShadow: widget.active
                  ? [
                      BoxShadow(
                        color: pulseColor.withValues(alpha: 0.22 + (t * 0.12)),
                        blurRadius: 6 * widget.scaleFactor,
                        spreadRadius: 0.8 * t,
                      ),
                    ]
                  : const [],
            ),
          ),
        );
      },
    );
  }
}
