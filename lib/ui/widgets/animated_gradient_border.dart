import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final bool ignoreGlobalClock;

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
    this.ignoreGlobalClock = false,
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  AnimationController? _localController;

  @override
  void initState() {
    super.initState();
    // We defer initialization logic to build() or didChangeDependencies()
    // because we need access to context/Provider.
  }

  /// Helper to get or create the local controller if global isn't found.
  AnimationController _ensureLocalController() {
    if (_localController != null) return _localController!;
    _localController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (3000 / widget.animationSpeed).round()),
    )..repeat();
    return _localController!;
  }

  @override
  void didUpdateWidget(AnimatedGradientBorder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animationSpeed != oldWidget.animationSpeed &&
        _localController != null) {
      _localController!.duration =
          Duration(milliseconds: (3000 / widget.animationSpeed).round());
      if (_localController!.isAnimating) {
        _localController!.repeat();
      }
    }
  }

  @override
  void dispose() {
    _localController?.dispose();
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

    // Try to get the global master clock
    Animation<double>? globalAnimation;
    if (!widget.ignoreGlobalClock) {
      try {
        // Use Provider.of with listen: false to check for the global animation
        // without triggering a rebuild on every tick (AnimatedBuilder handles that).
        // We use try-catch because explicitly checking for existence isn't directly supported.
        globalAnimation =
            Provider.of<Animation<double>>(context, listen: false);
      } catch (_) {
        // Provider not found, fall back to local controller
        globalAnimation = null;
      }
    }

    final Animation<double> animation;
    if (globalAnimation != null) {
      animation = globalAnimation;
      // If we had a local one (e.g. context changed), dispose it
      _localController?.dispose();
      _localController = null;
    } else {
      // Fallback to local clock
      animation = _ensureLocalController().view;
    }

    final colors = widget.colors ??
        [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.tertiary,
          Theme.of(context).colorScheme.secondary,
          Theme.of(context).colorScheme.primary,
        ];

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return CustomPaint(
          painter: _GradientBorderPainter(
            colors: colors,
            borderRadius: widget.borderRadius,
            borderWidth: widget.borderWidth,
            rotation: animation.value * 2 * 3.14159,
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

    // 1. Draw RGB Shadow
    if (showShadow) {
      // Create a gradient that rotates internally
      final gradient = SweepGradient(
        colors:
            colors.map((c) => c.withValues(alpha: c.a * glowOpacity)).toList(),
        transform: GradientRotation(rotation),
      );

      final shadowPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12)
        ..style = PaintingStyle.stroke
        ..strokeWidth =
            borderWidth + 8.0; // Slightly wider than border for glow

      // We draw the shadow slightly larger to ensure it peeks out
      final shadowRRect = RRect.fromRectAndRadius(
          rect.inflate(2.0), Radius.circular(borderRadius + 2.0));

      canvas.drawRRect(shadowRRect, shadowPaint);
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
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.showShadow != showShadow ||
        oldDelegate.glowOpacity != glowOpacity;
  }
}
