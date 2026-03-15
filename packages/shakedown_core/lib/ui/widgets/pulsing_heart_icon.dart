import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PulsingHeartIcon extends StatefulWidget {
  final double scaleFactor;
  final bool isFruit;

  const PulsingHeartIcon({
    super.key,
    required this.scaleFactor,
    required this.isFruit,
  });

  @override
  State<PulsingHeartIcon> createState() => _PulsingHeartIconState();
}

class _PulsingHeartIconState extends State<PulsingHeartIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 2), // Pause
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(scale: _scaleAnimation.value, child: child);
      },
      child: Icon(
        widget.isFruit ? LucideIcons.heart : Icons.favorite,
        size: 20 * widget.scaleFactor,
        color: Colors.pinkAccent,
      ),
    );
  }
}
