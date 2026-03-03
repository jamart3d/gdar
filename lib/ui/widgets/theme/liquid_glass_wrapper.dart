import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/device_service.dart';

/// A wrapper widget that applies a "liquid glass" effect.
/// Uses BackdropFilter for blur and semi-transparent colors.
class LiquidGlassWrapper extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool enabled;

  const LiquidGlassWrapper({
    super.key,
    required this.child,
    this.blur = 15.0,
    this.opacity = 0.7,
    this.borderRadius,
    this.color,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;

    final dev = context.watch<DeviceService>();
    final bool isAllowedPlatform = kIsWeb && !dev.isTv;

    final sp = context.watch<SettingsProvider>();
    final settingsMode = sp.performanceMode;
    final isPlaying = context.watch<AudioProvider>().isPlaying;

    // Web optimization: Lower blur sigma during playback
    final double effectiveBlur =
        (kIsWeb && isPlaying) ? (blur / 2.5).clamp(8.0, 15.0) : blur;

    final baseColor = color ??
        (Theme.of(context).brightness == Brightness.dark
            ? Colors.black
            : Colors.white);

    // Bypasses the expensive graphical blur pass if in simple performance mode
    // OR if we are on a platform that shouldn't have high-end liquid glass effects.
    if (settingsMode || !isAllowedPlatform) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Container(
          decoration: BoxDecoration(
            color: baseColor.withValues(
                alpha: !isAllowedPlatform
                    ? (opacity > 0.5 ? 1.0 : opacity * 2.0).clamp(0.0, 1.0)
                    : opacity),
            borderRadius: borderRadius,
            border: Border.all(
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
            border: Border.all(
              color: baseColor.withValues(alpha: 0.1),
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
