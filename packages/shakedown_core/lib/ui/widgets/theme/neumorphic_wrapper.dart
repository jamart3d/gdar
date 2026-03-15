import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';

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
  final bool disableInSnappyUi;

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
    this.disableInSnappyUi = true,
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
        ? Colors.white.withValues(
            alpha: 0.05 * intensity,
          ) // Subtle edge highlight
        : Colors.white.withValues(alpha: 0.95 * intensity);

    final Color darkShadowColor = isDark
        ? Colors.black.withValues(
            alpha: 0.5 * intensity,
          ) // Pure black shadow cast
        : const Color(0xFFA3B1C6).withValues(
            alpha: 1.0 * intensity,
          ); // Light mode custom drop shadow matching mock

    if (isPressed) {
      return [
        BoxShadow(
          color: darkShadowColor.withValues(alpha: darkShadowColor.a * 0.45),
          offset: offset * 0.4,
          blurRadius: blur * 0.4,
          spreadRadius: -spread,
        ),
        BoxShadow(
          color: lightShadowColor.withValues(alpha: lightShadowColor.a * 0.3),
          offset: -offset * 0.4,
          blurRadius: blur * 0.4,
          spreadRadius: -spread,
        ),
      ];
    } else {
      return [
        // Deep Soft Shadow
        BoxShadow(
          color: darkShadowColor.withValues(alpha: darkShadowColor.a * 0.8),
          offset: offset,
          blurRadius: blur,
          spreadRadius: spread,
        ),
        // Sharp Ambient Occlusion (Web Fix)
        BoxShadow(
          color: darkShadowColor.withValues(alpha: darkShadowColor.a * 0.25),
          offset: offset * 0.5,
          blurRadius: blur * 0.5,
          spreadRadius: -1,
        ),
        // Bright Glare
        BoxShadow(
          color: lightShadowColor,
          offset: -offset,
          blurRadius: blur,
          spreadRadius: spread,
        ),
        // Secondary Specular Highlight
        BoxShadow(
          color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.5),
          offset: -offset * 0.2,
          blurRadius: 1,
          spreadRadius: -0.5,
        ),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    if (!settingsProvider.useNeumorphism ||
        themeProvider.themeStyle != ThemeStyle.fruit) {
      return child;
    }

    if (disableInSnappyUi && settingsProvider.performanceMode) {
      return child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tp = context.read<ThemeProvider>();
    final isFruit = tp.themeStyle == ThemeStyle.fruit;
    final isLiquidGlassOff =
        isFruit && !settingsProvider.fruitEnableLiquidGlass;

    final baseColor = color ?? Theme.of(context).scaffoldBackgroundColor;
    final activeStyle = style ?? settingsProvider.neumorphicStyle;
    final isConcave = activeStyle == NeumorphicStyle.concave;
    final currentOffset = isConcave ? -offset : offset;

    final shadows = getShadows(
      context: context,
      intensity: isLiquidGlassOff ? intensity * 0.7 : intensity,
      blur: blur,
      spread: spread,
      offset: currentOffset,
      isPressed: isPressed,
    );

    // Subtle edge rim for "Liquid Glass" look
    // Disable or reduce significantly when glass is off
    final rimColor = isLiquidGlassOff
        ? Colors.transparent
        : (isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.6));

    final decoration = BoxDecoration(
      color: baseColor,
      shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
      borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
      border: isLiquidGlassOff ? null : Border.all(color: rimColor, width: 0.6),
      gradient: isPressed
          ? null
          : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor.withValues(alpha: isDark ? 1.0 : 0.98),
                baseColor.withValues(alpha: isDark ? 0.95 : 0.92),
              ],
            ),
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
