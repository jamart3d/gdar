import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Tier of sphere density for [FloatingSpheresBackground].
///
/// - [tiny] — used by Fruit car mode only (6 spheres, preserves legacy look).
/// - [small] — default for TV, Sabrina-safe (12 spheres).
/// - [medium] — mid-density ambient field (22 spheres).
/// - [more] — dense field; hardware-test before enabling as default (38 spheres).
enum SphereAmount {
  tiny(6),
  small(12),
  medium(22),
  more(38);

  const SphereAmount(this.count);

  /// Number of spheres rendered for this tier.
  final int count;
}

/// An animated background of softly floating, blurred spheres.
///
/// Designed to be mounted behind a full-screen layout inside a [Stack].
/// Wrap in [IgnorePointer] and [RepaintBoundary] at the call site.
///
/// ```dart
/// Positioned.fill(
///   child: IgnorePointer(
///     child: RepaintBoundary(
///       child: FloatingSpheresBackground(
///         colorScheme: Theme.of(context).colorScheme,
///         animate: true,
///         sphereCount: SphereAmount.small,
///       ),
///     ),
///   ),
/// )
/// ```
class FloatingSpheresBackground extends StatefulWidget {
  const FloatingSpheresBackground({
    super.key,
    required this.colorScheme,
    required this.animate,
    this.sphereCount = SphereAmount.small,
    this.speedMultiplier = 1.0,
  });

  final ColorScheme colorScheme;

  /// When false the spheres are frozen (still rendered, just not ticking).
  final bool animate;

  /// Controls how many spheres are rendered.
  final SphereAmount sphereCount;

  /// Multiplies the animation speed without affecting the simulation.
  final double speedMultiplier;

  @override
  State<FloatingSpheresBackground> createState() =>
      _FloatingSpheresBackgroundState();
}

class _FloatingSpheresBackgroundState extends State<FloatingSpheresBackground>
    with SingleTickerProviderStateMixin {
  static const Duration _logicFrameDuration = Duration(milliseconds: 48);
  static const double _wrapMargin = 0.08;

  Ticker? _ticker;
  Duration _lastElapsed = Duration.zero;
  late List<SphereNode> _spheres;
  double _fractionalTicks = 0.0;
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    _spheres = SphereNode.generate(widget.sphereCount.count);
    _ticker = createTicker(_onTick);
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant FloatingSpheresBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sphereCount != widget.sphereCount) {
      _spheres = SphereNode.generate(widget.sphereCount.count);
    }
    if (oldWidget.animate != widget.animate) {
      _syncAnimationState();
    }
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  void _syncAnimationState() {
    if (widget.animate && !(_ticker?.isActive ?? false)) {
      _lastElapsed = Duration.zero;
      _ticker?.start();
    } else if (!widget.animate && (_ticker?.isActive ?? false)) {
      _ticker?.stop();
    }
  }

  void _onTick(Duration elapsed) {
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }

    final Duration delta = elapsed - _lastElapsed;
    _lastElapsed = elapsed;

    // Convert elapsed time into "logic ticks" (48ms increments)
    final double deltaTicks =
        delta.inMicroseconds / _logicFrameDuration.inMicroseconds;

    setState(() {
      _fractionalTicks += deltaTicks;
      // We only update _tickCount for the breathing variance when we cross a full tick boundary
      // but we use the continuous delta for smooth motion.
      if (_fractionalTicks >= 1.0) {
        _tickCount += _fractionalTicks.floor();
        _fractionalTicks -= _fractionalTicks.floor();
      }

      _spheres = _spheres
          .map((s) => _advance(s, deltaTicks))
          .toList(growable: false);
    });
  }

  SphereNode _advance(SphereNode s, double deltaTicks) {
    // Create an organic breathing variance in the speed (cycles roughly every 15 seconds)
    // Offset by paletteIndex so different color tiers accelerate/decelerate at different times.
    final double breathingVariance =
        1.0 + 0.3 * math.sin((_tickCount * 0.02) + s.paletteIndex);
    final double currentSpeed =
        widget.speedMultiplier * breathingVariance * deltaTicks;

    double x = s.x + (s.vx * currentSpeed);
    double y = s.y + (s.vy * currentSpeed);
    double vx = s.vx;
    double vy = s.vy;

    double ax = s.ax;
    double ay = s.ay;

    // Bounce seamlessly off the invisible margins instead of teleporting (no looping)
    if (x < -_wrapMargin || x > 1 + _wrapMargin) {
      vx = -vx;
      ax = -ax;
      x = x.clamp(-_wrapMargin, 1 + _wrapMargin);
    }
    if (y < -_wrapMargin || y > 1 + _wrapMargin) {
      vy = -vy;
      ay = -ay;
      y = y.clamp(-_wrapMargin, 1 + _wrapMargin);
    }

    // Only apply acceleration adjustments occasionally (every ~18 logic ticks)
    if (_tickCount % 18 == 0 && _fractionalTicks < deltaTicks) {
      vx = (vx + (ax * 0.0009)).clamp(-0.0036, 0.0036);
      vy = (vy + (ay * 0.0009)).clamp(-0.0036, 0.0036);
    }

    return s.copyWith(x: x, y: y, vx: vx, vy: vy, ax: ax, ay: ay);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: FloatingSpheresPainter(
        spheres: _spheres,
        colorScheme: widget.colorScheme,
      ),
      child: const SizedBox.expand(),
    );
  }
}

/// [CustomPainter] that renders the sphere field.
///
/// Each sphere is drawn as two layered circles with [MaskFilter.blur]:
///   1. A large, faint outer glow.
///   2. A smaller, brighter soft core.
class FloatingSpheresPainter extends CustomPainter {
  const FloatingSpheresPainter({
    required this.spheres,
    required this.colorScheme,
  });

  final List<SphereNode> spheres;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);

    for (final sphere in spheres) {
      final center = Offset(size.width * sphere.x, size.height * sphere.y);
      final radius = shortestSide * sphere.radiusFactor;
      final color = _resolveColor(sphere.paletteIndex);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18);
      final corePaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.04);

      canvas.drawCircle(center, radius, glowPaint);
      canvas.drawCircle(center, radius * 0.52, corePaint);
    }
  }

  Color _resolveColor(int paletteIndex) {
    return switch (paletteIndex) {
      0 => colorScheme.primary,
      1 => colorScheme.secondary,
      2 => colorScheme.tertiary,
      _ => colorScheme.primaryContainer,
    };
  }

  @override
  bool shouldRepaint(covariant FloatingSpheresPainter oldDelegate) {
    return oldDelegate.spheres != spheres ||
        oldDelegate.colorScheme != colorScheme;
  }
}

/// Immutable data node representing a single sphere.
@immutable
class SphereNode {
  const SphereNode({
    required this.x,
    required this.y,
    required this.radiusFactor,
    required this.vx,
    required this.vy,
    required this.ax,
    required this.ay,
    required this.paletteIndex,
  });

  /// Normalised horizontal position (0..1).
  final double x;

  /// Normalised vertical position (0..1).
  final double y;

  /// Radius as a fraction of the shortest screen side.
  final double radiusFactor;
  final double vx;
  final double vy;

  /// Drift acceleration component.
  final double ax;

  /// Drift acceleration component.
  final double ay;

  /// Index into the colorScheme palette (0–3).
  final int paletteIndex;

  SphereNode copyWith({
    double? x,
    double? y,
    double? radiusFactor,
    double? vx,
    double? vy,
    double? ax,
    double? ay,
    int? paletteIndex,
  }) {
    return SphereNode(
      x: x ?? this.x,
      y: y ?? this.y,
      radiusFactor: radiusFactor ?? this.radiusFactor,
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      ax: ax ?? this.ax,
      ay: ay ?? this.ay,
      paletteIndex: paletteIndex ?? this.paletteIndex,
    );
  }

  // ---------------------------------------------------------------------------
  // Sphere generation
  // ---------------------------------------------------------------------------

  /// Generates [count] deterministic spheres spread across 3 depth bands.
  ///
  /// Depth bands:
  ///   - Far  (indices 0..far-1):  large, faint, slow.
  ///   - Mid  (indices far..mid-1): medium, moderate speed.
  ///   - Near (remaining):          smaller, slightly faster.
  static List<SphereNode> generate(int count) {
    // The first 6 use the original seeded values to keep Fruit visually stable
    // when [SphereAmount.tiny] is used.
    if (count <= 6) return _seeded6;

    final result = <SphereNode>[];
    final rng = math.Random(0xCAFE_BABE); // deterministic

    final farCount = (count * 0.35).round();
    final midCount = (count * 0.40).round();
    final nearCount = count - farCount - midCount;

    // Far band — large, faint, slow
    for (int i = 0; i < farCount; i++) {
      result.add(
        SphereNode(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radiusFactor: 0.18 + rng.nextDouble() * 0.12, // 0.18–0.30
          vx: _sign(rng) * (0.0006 + rng.nextDouble() * 0.0006),
          vy: _sign(rng) * (0.0005 + rng.nextDouble() * 0.0006),
          ax: _sign(rng) * (0.3 + rng.nextDouble() * 0.4),
          ay: _sign(rng) * (0.3 + rng.nextDouble() * 0.4),
          paletteIndex: i % 4,
        ),
      );
    }

    // Mid band
    for (int i = 0; i < midCount; i++) {
      result.add(
        SphereNode(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radiusFactor: 0.10 + rng.nextDouble() * 0.10, // 0.10–0.20
          vx: _sign(rng) * (0.0009 + rng.nextDouble() * 0.0008),
          vy: _sign(rng) * (0.0008 + rng.nextDouble() * 0.0008),
          ax: _sign(rng) * (0.4 + rng.nextDouble() * 0.4),
          ay: _sign(rng) * (0.4 + rng.nextDouble() * 0.4),
          paletteIndex: (i + 1) % 4,
        ),
      );
    }

    // Near band — small accents
    for (int i = 0; i < nearCount; i++) {
      result.add(
        SphereNode(
          x: rng.nextDouble(),
          y: rng.nextDouble(),
          radiusFactor: 0.06 + rng.nextDouble() * 0.06, // 0.06–0.12
          vx: _sign(rng) * (0.0012 + rng.nextDouble() * 0.0010),
          vy: _sign(rng) * (0.0010 + rng.nextDouble() * 0.0010),
          ax: _sign(rng) * (0.5 + rng.nextDouble() * 0.4),
          ay: _sign(rng) * (0.5 + rng.nextDouble() * 0.4),
          paletteIndex: (i + 2) % 4,
        ),
      );
    }

    return result;
  }

  static double _sign(math.Random rng) => rng.nextBool() ? 1.0 : -1.0;

  /// Original 6 seeded spheres — preserves the Fruit car mode visual exactly.
  static const List<SphereNode> _seeded6 = [
    SphereNode(
      x: 0.18,
      y: 0.14,
      radiusFactor: 0.22,
      vx: 0.0015,
      vy: 0.0011,
      ax: 0.7,
      ay: -0.4,
      paletteIndex: 0,
    ),
    SphereNode(
      x: 0.82,
      y: 0.18,
      radiusFactor: 0.18,
      vx: -0.0013,
      vy: 0.0010,
      ax: -0.5,
      ay: 0.6,
      paletteIndex: 1,
    ),
    SphereNode(
      x: 0.72,
      y: 0.42,
      radiusFactor: 0.16,
      vx: -0.0010,
      vy: -0.0014,
      ax: 0.4,
      ay: -0.6,
      paletteIndex: 2,
    ),
    SphereNode(
      x: 0.28,
      y: 0.52,
      radiusFactor: 0.14,
      vx: 0.0012,
      vy: -0.0011,
      ax: -0.6,
      ay: -0.3,
      paletteIndex: 3,
    ),
    SphereNode(
      x: 0.14,
      y: 0.78,
      radiusFactor: 0.20,
      vx: 0.0010,
      vy: -0.0008,
      ax: 0.5,
      ay: 0.5,
      paletteIndex: 1,
    ),
    SphereNode(
      x: 0.84,
      y: 0.84,
      radiusFactor: 0.24,
      vx: -0.0009,
      vy: -0.0012,
      ax: -0.4,
      ay: 0.4,
      paletteIndex: 0,
    ),
  ];
}
