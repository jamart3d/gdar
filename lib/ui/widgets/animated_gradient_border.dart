import 'package:flutter/material.dart';

class AnimatedGradientBorder extends StatefulWidget {
  final Widget child;
  final double borderRadius;
  final double borderWidth;
  final List<Color>? colors;
  final bool showGlow;
  final bool showShadow;
  final Color? backgroundColor;
  final double glowOpacity;
  final double animationSpeed;

  const AnimatedGradientBorder({
    super.key,
    required this.child,
    this.borderRadius = 28.0,
    this.borderWidth = 2.0,
    this.colors,
    this.showGlow = true,
    this.showShadow = true,
    this.backgroundColor,
    this.glowOpacity = 0.5,
    this.animationSpeed = 1.0,
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (3000 / widget.animationSpeed).round()),
    )..repeat();
  }

  @override
  void didUpdateWidget(AnimatedGradientBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationSpeed != oldWidget.animationSpeed) {
      _controller.duration =
          Duration(milliseconds: (3000 / widget.animationSpeed).round());
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
    if (!widget.showGlow) {
      return Container(
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
        child: widget.child,
      );
    }

    final colors = widget.colors ??
        [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.tertiary,
          Theme.of(context).colorScheme.secondary,
          Theme.of(context).colorScheme.primary,
        ];

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            colors: colors,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
            rotation: _controller.value * 2 * 3.14159,
            showShadow: widget.showShadow,
            glowOpacity: widget.glowOpacity,
          ),
          child: Padding(
            padding: EdgeInsets.all(widget.borderWidth),
            child: Container(
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(
                    widget.borderRadius - widget.borderWidth),
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

class _GradientBorderPainter extends CustomPainter {
  final List<Color> colors;
  final double borderRadius;
  final double borderWidth;
  final double rotation;
  final bool showShadow;
  final double glowOpacity;

  _GradientBorderPainter({
    required this.colors,
    required this.borderRadius,
    required this.borderWidth,
    required this.rotation,
    this.showShadow = true,
    this.glowOpacity = 0.5,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    // 1. Draw Shadow
    if (showShadow) {
      final shadowPaint = Paint()
        ..color = colors[0].withOpacity(glowOpacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawRRect(rrect.shift(const Offset(0, 1)), shadowPaint);
    }

    // 2. Draw Gradient Border
    final innerRect = rect.deflate(borderWidth);
    final innerRRect = RRect.fromRectAndRadius(
        innerRect, Radius.circular(borderRadius - borderWidth));

    // Use Path.combine for robust difference operation
    final borderPath = Path.combine(
      PathOperation.difference,
      Path()..addRRect(rrect),
      Path()..addRRect(innerRRect),
    );

    canvas.save();
    canvas.clipPath(borderPath);

    final center = rect.center;
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    final maxDim = (size.width > size.height ? size.width : size.height) * 2;
    final bigRect =
        Rect.fromCenter(center: center, width: maxDim, height: maxDim);

    final gradientPaint = Paint()
      ..shader = SweepGradient(colors: colors).createShader(bigRect);

    canvas.drawRect(bigRect, gradientPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.colors != colors ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth;
  }
}
