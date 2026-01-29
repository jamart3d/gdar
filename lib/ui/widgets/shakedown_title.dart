import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';

/// A reusable widget for the app title "Shakedown" that handles
/// consistent styling, Hero animations, and flight transitions.
class ShakedownTitle extends StatefulWidget {
  final double fontSize;
  final bool enableHero;
  final bool animateOnStart;
  final Duration shakeDelay;

  const ShakedownTitle({
    super.key,
    required this.fontSize,
    this.enableHero = true,
    this.animateOnStart = false,
    this.shakeDelay = Duration.zero,
  });

  @override
  State<ShakedownTitle> createState() => _ShakedownTitleState();
}

class _ShakedownTitleState extends State<ShakedownTitle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    // Expressive dampened sine wave for "shake"
    // 0 -> - -> + -> - -> 0 (decaying)
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: -0.05)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 15),
      TweenSequenceItem(
          tween: Tween(begin: -0.05, end: 0.05)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.05, end: -0.03)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: -0.03, end: 0.015)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 20),
      TweenSequenceItem(
          tween: Tween(begin: 0.015, end: 0.0)
              .chain(CurveTween(curve: Curves.elasticOut)), // Settle
          weight: 25),
    ]).animate(_shakeController);

    if (widget.animateOnStart) {
      // Delay to ensure Hero flight is complete if needed
      _startTimer = Timer(widget.shakeDelay, () {
        if (mounted) {
          _shakeController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    final textStyle = theme.textTheme.displayLarge?.copyWith(
      fontSize: widget.fontSize * scaleFactor,
      fontFamily: settingsProvider.appFont == 'default'
          ? 'Roboto'
          : (settingsProvider.appFont == 'rock_salt'
              ? 'RockSalt'
              : (settingsProvider.appFont == 'permanent_marker'
                  ? 'Permanent Marker'
                  : 'Caveat')),
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
      letterSpacing: 1.2,
      height: 1.4,
    );

    // Only apply rotation if strictly needed (optimization), but
    // keeping it simple: Always rotate 0 if not animating.
    final animWidget = AnimatedBuilder(
      animation: _shakeAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _shakeAnimation.value,
          child: child,
        );
      },
      child: Text(
        'Shakedown',
        style: textStyle,
        textAlign: TextAlign.center,
      ),
    );

    if (!widget.enableHero || !settingsProvider.enableShakedownTween) {
      return animWidget;
    }

    return Hero(
      tag: 'app_title',
      createRectTween: (begin, end) {
        return GravityRectTween(begin: begin, end: end);
      },
      // Custom flight shuttle to smooth out text style interpolation
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return DefaultTextStyle(
          style: DefaultTextStyle.of(toHeroContext).style,
          child: toHeroContext.widget,
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: animWidget,
      ),
    );
  }
}

/// A custom RectTween that creates a "Gravity" arc effect (parabolic curve).
/// Moves high up first, then settles into the target.
class GravityRectTween extends RectTween {
  GravityRectTween({super.begin, super.end});

  @override
  Rect lerp(double t) {
    // If t is 0 or 1, return precise begin/end
    if (t == 0) return begin!;
    if (t == 1) return end!;

    // Quadratic Bezier Curve logic
    // Control point determines the "height" of the arc.
    // We want it to go slightly "Up" relative to the path.

    // Center points
    final double startX = begin!.center.dx;
    final double startY = begin!.center.dy;
    final double endX = end!.center.dx;
    final double endY = end!.center.dy;

    // Control Point Calculation:
    // We want the curve to "bulge" upwards (negative Y).
    // Let's place the control point above the midpoint.
    // The "Up and Left" request implies we want to arc towards the top-left quadrant?
    // Actually, usually Hero flies from Center -> Top-Left (AppBar).
    // A standard arc goes straight there.
    // To go "Up then Left", we need the control Point to be near (startX, endY) or even higher (startX, endY - extra).

    // Let's aim for a control point that is horizontally near the start, but vertically significantly above the end.
    // This forces the "vertical launch" look.
    final double controlX = startX; // Stay near center horizontal for launch
    final double controlY =
        endY - 40.0; // Go 40px ABOVE the target (Very subtle arc)

    // Quadratic Bezier formula:
    // P = (1-t)^2 * P0 + 2(1-t)t * P1 + t^2 * P2
    final double curveX =
        (1 - t) * (1 - t) * startX + 2 * (1 - t) * t * controlX + t * t * endX;
    final double curveY =
        (1 - t) * (1 - t) * startY + 2 * (1 - t) * t * controlY + t * t * endY;

    // Current Size interpolation
    final double width = lerpDouble(begin!.width, end!.width, t);
    final double height = lerpDouble(begin!.height, end!.height, t);

    return Rect.fromCenter(
      center: Offset(curveX, curveY),
      width: width,
      height: height,
    );
  }

  // Helper for double lerp since `dart:ui` lerpDouble is nullable
  double lerpDouble(double a, double b, double t) {
    return a + (b - a) * t;
  }
}
