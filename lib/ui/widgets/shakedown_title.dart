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
        return MaterialRectCenterArcTween(begin: begin, end: end);
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
