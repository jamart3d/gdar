import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// A wrapper widget that provides a continuous, global animation clock
/// to its descendants.
///
/// This allows multiple widgets (like [AnimatedGradientBorder]) to sync
/// their animations to a single "master clock," ensuring that animations
/// don't reset or de-sync when navigating between screens.
class RgbClockWrapper extends StatefulWidget {
  final Widget child;
  final double animationSpeed;

  const RgbClockWrapper({
    super.key,
    required this.child,
    this.animationSpeed = 1.0,
  });

  @override
  State<RgbClockWrapper> createState() => _RgbClockWrapperState();
}

class _RgbClockWrapperState extends State<RgbClockWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Default duration for 1.0x speed.
    // 3000ms is the base duration we used previously in AnimatedGradientBorder.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // Debug print removed for production

    _updateDuration();
  }

  @override
  void didUpdateWidget(RgbClockWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationSpeed != oldWidget.animationSpeed) {
      _updateDuration();
    }
  }

  void _updateDuration() {
    // Avoid division by zero
    final speed = widget.animationSpeed <= 0 ? 0.1 : widget.animationSpeed;
    // Setting duration on a running controller applies to the NEXT tick/cycle
    // but doesn't reset the current value.
    _controller.duration = Duration(milliseconds: (3000 / speed).round());

    // Validating if we need to start it if it's not running (e.g. first init)
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // We provide BOTH the Animation<double> (for widgets that just want the value)
    // AND the AnimationController (for widgets that need to pause/resume it).
    return MultiProvider(
      providers: [
        ListenableProvider<Animation<double>>.value(value: _controller.view),
        ListenableProvider<AnimationController>.value(value: _controller),
      ],
      child: widget.child,
    );
  }
}
