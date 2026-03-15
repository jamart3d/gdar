import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/utils/web_runtime.dart';

/// A wrapper widget that applies a "liquid glass" effect.
/// Uses BackdropFilter for blur and semi-transparent colors.
class LiquidGlassWrapper extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool enabled;
  final bool showBorder;

  const LiquidGlassWrapper({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.7,
    this.borderRadius,
    this.color,
    this.enabled = true,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final dev = context.watch<DeviceService>();
    final bool isAllowedPlatform = kIsWeb && !dev.isTv;

    final sp = context.watch<SettingsProvider>();
    final settingsMode = sp.performanceMode;

    final tp = context.watch<ThemeProvider>();
    final bool isFruitTheme = tp.themeStyle == ThemeStyle.fruit;
    final bool isFruitGlassEnabled = sp.fruitEnableLiquidGlass;

    // Web optimization: keep blur budget conservative for mobile GPUs.
    final isLikelyWebMobile =
        kIsWeb && MediaQuery.sizeOf(context).shortestSide < 700;
    final double effectiveBlur = isLikelyWebMobile
        ? blur.clamp(4.0, 8.0)
        : (kIsWeb ? blur.clamp(6.0, 12.0) : blur);

    final baseColor =
        color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white);

    // Bypasses the expensive graphical blur pass if in simple performance mode
    // OR if we are on a platform that shouldn't have high-end liquid glass effects
    // OR if the Fruit theme is active and the user explicitly disabled the Liquid Glass setting.
    final bool shouldBypassBlur =
        settingsMode ||
        !isAllowedPlatform ||
        isWasmSafeMode() ||
        (isFruitTheme && !isFruitGlassEnabled);

    if (shouldBypassBlur) {
      // For large areas (shell/cards), we want solid background to prevent bleed-through.
      // for small elements (icons/badges), we keep the subtle translucency but without blur.
      final double effectiveOpacity =
          (isFruitTheme && !isFruitGlassEnabled && opacity > 0.5)
          ? 1.0
          : opacity;

      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Container(
          decoration: BoxDecoration(
            color: baseColor.withValues(
              alpha: !isAllowedPlatform && !shouldBypassBlur
                  ? (effectiveOpacity > 0.5 ? 1.0 : effectiveOpacity * 2.0)
                        .clamp(0.0, 1.0)
                  : effectiveOpacity,
            ),
            borderRadius: borderRadius,
            border: (isFruitTheme && !isFruitGlassEnabled) || !showBorder
                ? null
                : Border.all(
                    color: baseColor.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
          ),
          child: child,
        ),
      );
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: effectiveBlur, sigmaY: effectiveBlur),
        child: Container(
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: opacity),
            borderRadius: borderRadius,
            border: showBorder
                ? Border.all(
                    color: baseColor.withValues(alpha: 0.1),
                    width: 0.5,
                  )
                : null,
          ),
          child: child,
        ),
      ),
    );
  }
}
