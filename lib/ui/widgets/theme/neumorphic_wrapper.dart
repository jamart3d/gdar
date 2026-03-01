import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';

/// A widget that applies a Neumorphic (soft UI) effect with an Apple "Liquid Glass" aesthetic.
///
/// It uses two soft shadows for depth and a subtle internal highlight to simulate a glassy surface.
class NeumorphicWrapper extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final bool isPressed;
  final double spread;
  final double blur;
  final Offset offset;
  final Color? color;
  final bool enabled;
  final bool isCircle;
  final double intensity;
  final NeumorphicStyle? style;

  const NeumorphicWrapper({
    super.key,
    this.child = const SizedBox.shrink(),
    this.borderRadius = 14,
    this.isPressed = false,
    this.spread = 1,
    this.blur = 20, // Softer default blur for premium look
    this.offset = const Offset(5, 5),
    this.color,
    this.enabled = true,
    this.isCircle = false,
    this.intensity = 1.0,
    this.style,
  });

  static List<BoxShadow> getShadows({
    required BuildContext context,
    double intensity = 1.0,
    double blur = 20,
    double spread = 1,
    Offset offset = const Offset(5, 5),
    bool isPressed = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color lightShadowColor = isDark
        ? Colors.white.withValues(alpha: 0.08 * intensity)
        : Colors.white.withValues(alpha: 0.95 * intensity);

    final Color darkShadowColor = isDark
        ? Colors.black.withValues(alpha: 0.45 * intensity)
        : Colors.black.withValues(alpha: 0.12 * intensity);

    if (isPressed) {
      return [
        BoxShadow(
          color: lightShadowColor.withValues(alpha: lightShadowColor.a * 0.4),
          offset: offset * 0.5,
          blurRadius: blur * 0.5,
          spreadRadius: -spread,
        ),
        BoxShadow(
          color: darkShadowColor.withValues(alpha: darkShadowColor.a * 0.4),
          offset: -offset * 0.5,
          blurRadius: blur * 0.5,
          spreadRadius: -spread,
        ),
      ];
    } else {
      return [
        BoxShadow(
          color: darkShadowColor,
          offset: offset,
          blurRadius: blur,
          spreadRadius: spread,
        ),
        BoxShadow(
          color: lightShadowColor,
          offset: -offset,
          blurRadius: blur,
          spreadRadius: spread,
        ),
        // Glass highlight
        BoxShadow(
          color: Colors.white.withValues(alpha: isDark ? 0.03 : 0.4),
          offset: -offset * 0.3,
          blurRadius: 2,
          spreadRadius: -1,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final baseColor = color ?? Theme.of(context).scaffoldBackgroundColor;
    final activeStyle =
        style ?? context.read<SettingsProvider>().neumorphicStyle;
    final isConcave = activeStyle == NeumorphicStyle.concave;
    final currentOffset = isConcave ? -offset : offset;

    final shadows = getShadows(
      context: context,
      intensity: intensity,
      blur: blur,
      spread: spread,
      offset: currentOffset,
      isPressed: isPressed,
    );

    final decoration = BoxDecoration(
      color: baseColor,
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      boxShadow: shadows,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: decoration,
      child: isCircle
          ? ClipOval(child: child)
          : ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: child,
            ),
    );
  }
}
