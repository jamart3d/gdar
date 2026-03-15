import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/utils/web_runtime.dart';

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
  final bool enabled;
  final bool usePadding;

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
    this.enabled = true,
    this.usePadding = true,
  });

  @override
  State<AnimatedGradientBorder> createState() => _AnimatedGradientBorderState();
}

class _AnimatedGradientBorderState extends State<AnimatedGradientBorder>
    with SingleTickerProviderStateMixin {
  AnimationController? _localController;
  Animation<double>? _animationSource;
  bool _usingGlobalClock = false;

  @override
  void initState() {
    super.initState();
    // No-op, initialization happens in didChangeDependencies/ensureLocalController
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimationSource();
  }

  void _updateAnimationSource() {
    if (widget.ignoreGlobalClock) {
      _setLocalSource();
      return;
    }

    try {
      final global = Provider.of<Animation<double>>(context, listen: false);
      if (_animationSource != global) {
        setState(() {
          _animationSource = global;
          _usingGlobalClock = true;
          // Don't dispose local immediately, wait for build to finish or do it safely
        });
      }
    } catch (_) {
      _setLocalSource();
    }
  }

  void _setLocalSource() {
    final controller = _ensureLocalController();
    if (_animationSource != controller.view) {
      setState(() {
        _animationSource = controller.view;
        _usingGlobalClock = false;
      });
    }
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
      _localController!.duration = Duration(
        milliseconds: (3000 / widget.animationSpeed).round(),
      );
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
    if (isWasmSafeMode()) return widget.child;

    final sp = context.watch<SettingsProvider>();
    final performanceMode = sp.performanceMode;
    final isPlaying = context.watch<AudioProvider>().isPlaying;
    final isWebPlayback = kIsWeb && isPlaying;
    final bool disableGlow = performanceMode || isWebPlayback;

    if (!widget.enabled && widget.borderWidth <= 0) {
      return widget.child;
    }

    // 1. Ensure we have an animation source if one wasn't set in didChangeDependencies
    if (_animationSource == null) {
      _updateAnimationSource();
    }

    // 2. Safe cleanup of local controller if we've switched to global
    if (_usingGlobalClock && _localController != null) {
      final controllerToDispose = _localController;
      _localController = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controllerToDispose?.dispose();
      });
    }

    final animation = _animationSource ?? _ensureLocalController().view;

    final colors =
        widget.colors ??
        [
          Theme.of(context).colorScheme.primary,
          Theme.of(context).colorScheme.tertiary,
          Theme.of(context).colorScheme.secondary,
          Theme.of(context).colorScheme.primary,
        ];

    // STABILITY: We always return the same structure (RepaintBoundary -> CustomPaint -> Padding -> Container -> child)
    // even if disabled or showGlow is false. We simply pass 0.0 values to the painter and padding.
    // This prevents structural widget tree changes that break TV focus nodes.

    final bool isEffectActive =
        widget.enabled &&
        (widget.showGlow || widget.borderWidth > 0) &&
        !disableGlow;

    return AnimatedBuilder(
      animation: animation,
      child: widget.child,
      builder: (context, child) {
        final double spreadPadding = (isEffectActive && widget.showGlow)
            ? 18.0
            : 0.0;

        final innerContent = widget.usePadding
            ? Padding(
                padding: EdgeInsets.all(
                  isEffectActive ? widget.borderWidth : 0.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color:
                        widget.backgroundColor ?? Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(widget.borderRadius),
                  ),
                  child: child,
                ),
              )
            : child!;

        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned(
              left: -spreadPadding,
              top: -spreadPadding,
              right: -spreadPadding,
              bottom: -spreadPadding,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _GradientBorderPainter(
                    colors: colors,
                    borderRadius: widget.borderRadius,
                    borderWidth: isEffectActive ? widget.borderWidth : 0.0,
                    rotation: animation.value * 2 * 3.14159,
                    showShadow:
                        isEffectActive &&
                            !performanceMode &&
                            !isWebPlayback &&
                            !disableGlow
                        ? widget.showShadow
                        : false,
                    glowOpacity: isWebPlayback ? 0.2 : widget.glowOpacity,
                    spreadPadding: spreadPadding,
                  ),
                ),
              ),
            ),
            innerContent,
          ],
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
  final double spreadPadding;

  _GradientBorderPainter({
    required this.colors,
    required this.borderRadius,
    required this.borderWidth,
    required this.rotation,
    this.showShadow = true,
    this.glowOpacity = 0.5,
    this.spreadPadding = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (borderWidth <= 0) return;

    final rect = Rect.fromLTWH(
      spreadPadding,
      spreadPadding,
      size.width - spreadPadding * 2,
      size.height - spreadPadding * 2,
    );

    // 1. Draw RGB Shadow
    if (showShadow) {
      // Create a gradient that rotates internally
      final gradient = SweepGradient(
        colors: colors
            .map((c) => c.withValues(alpha: c.a * glowOpacity))
            .toList(),
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
        rect.inflate(2.0),
        Radius.circular(borderRadius + 2.0),
      );

      canvas.drawRRect(shadowRRect, shadowPaint);
    }

    // 2. Draw Gradient Border using stroke (much more robust on Web than Path.combine)
    final borderPaint = Paint()
      ..shader = SweepGradient(
        colors: colors,
        transform: GradientRotation(rotation),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    // Deflate the rect by half the border width so the stroke sits inside the bounds
    final strokeRect = rect.deflate(borderWidth / 2);
    final strokeRRect = RRect.fromRectAndRadius(
      strokeRect,
      Radius.circular(borderRadius - borderWidth / 2),
    );

    canvas.drawRRect(strokeRRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _GradientBorderPainter oldDelegate) {
    return oldDelegate.rotation != rotation ||
        oldDelegate.colors != colors ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.showShadow != showShadow ||
        oldDelegate.glowOpacity != glowOpacity ||
        oldDelegate.spreadPadding != spreadPadding;
  }
}
