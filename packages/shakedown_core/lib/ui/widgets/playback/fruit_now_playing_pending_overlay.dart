import 'package:flutter/material.dart';

class FruitNowPlayingPendingOverlay extends StatefulWidget {
  final ColorScheme colorScheme;
  final double scaleFactor;
  final bool glassEnabled;
  final bool isLoading;
  final double barHeightBase;
  final double borderRadiusBase;
  final double sweepWidthGlassBase;
  final double sweepWidthSolidBase;
  final double sweepOverflowFactor;
  final double beadWidthGlassBase;
  final double beadWidthSolidBase;
  final double baseAlphaGlass;
  final double baseAlphaSolid;
  final double sweepAlphaGlass;
  final double sweepAlphaSolid;
  final double coreAlphaGlass;
  final double coreAlphaSolid;
  final double haloAlphaGlass;
  final double haloAlphaSolid;
  final double beadBlurGlass;
  final double beadBlurSolid;
  final double beadSpreadGlass;
  final double beadSpreadSolid;
  final Key beadKey;

  const FruitNowPlayingPendingOverlay({
    super.key,
    required this.colorScheme,
    required this.scaleFactor,
    required this.glassEnabled,
    required this.isLoading,
    this.barHeightBase = 3.0,
    this.borderRadiusBase = 4.0,
    this.sweepWidthGlassBase = 84.0,
    this.sweepWidthSolidBase = 66.0,
    this.sweepOverflowFactor = 0.22,
    this.beadWidthGlassBase = 18.0,
    this.beadWidthSolidBase = 14.0,
    this.baseAlphaGlass = 0.18,
    this.baseAlphaSolid = 0.24,
    this.sweepAlphaGlass = 0.76,
    this.sweepAlphaSolid = 0.92,
    this.coreAlphaGlass = 0.44,
    this.coreAlphaSolid = 0.60,
    this.haloAlphaGlass = 0.32,
    this.haloAlphaSolid = 0.26,
    this.beadBlurGlass = 10.0,
    this.beadBlurSolid = 7.0,
    this.beadSpreadGlass = 0.7,
    this.beadSpreadSolid = 0.45,
    this.beadKey = const Key('fruit_pending_progress_bead'),
  });

  @override
  State<FruitNowPlayingPendingOverlay> createState() =>
      _FruitNowPlayingPendingOverlayState();
}

class _FruitNowPlayingPendingOverlayState
    extends State<FruitNowPlayingPendingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double barHeight = widget.barHeightBase * widget.scaleFactor;
    final BorderRadius borderRadius = BorderRadius.circular(
      widget.borderRadiusBase * widget.scaleFactor,
    );
    final Color sweepColor = widget.isLoading
        ? widget.colorScheme.primary
        : widget.colorScheme.tertiary;

    return RepaintBoundary(
      child: SizedBox(
        height: barHeight,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double travel = _controller.value;
                final double pulse = 1.0 - ((travel - 0.5).abs() * 2.0);
                final double sweepWidth =
                    (widget.glassEnabled
                        ? widget.sweepWidthGlassBase
                        : widget.sweepWidthSolidBase) *
                    widget.scaleFactor;
                final double sweepOverflow =
                    sweepWidth * widget.sweepOverflowFactor;
                final double sweepTravelWidth =
                    (constraints.maxWidth + (sweepOverflow * 2.0) - sweepWidth)
                        .clamp(0.0, double.infinity);
                final double sweepLeft =
                    -sweepOverflow + (sweepTravelWidth * travel);
                final double beadWidth =
                    (widget.glassEnabled
                        ? widget.beadWidthGlassBase
                        : widget.beadWidthSolidBase) *
                    widget.scaleFactor;
                final double beadHeight = barHeight;
                final double beadTravelWidth =
                    (constraints.maxWidth - beadWidth).clamp(
                      0.0,
                      double.infinity,
                    );
                final double beadLeft = beadTravelWidth * travel;
                final double baseAlpha = widget.glassEnabled
                    ? widget.baseAlphaGlass
                    : widget.baseAlphaSolid;
                final double sweepAlpha = widget.glassEnabled
                    ? widget.sweepAlphaGlass
                    : widget.sweepAlphaSolid;
                final double coreAlpha = widget.glassEnabled
                    ? widget.coreAlphaGlass
                    : widget.coreAlphaSolid;
                final double haloAlpha = widget.glassEnabled
                    ? widget.haloAlphaGlass
                    : widget.haloAlphaSolid;

                return ClipRRect(
                  borderRadius: borderRadius,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                widget.colorScheme.primary.withValues(
                                  alpha: baseAlpha,
                                ),
                                widget.colorScheme.tertiary.withValues(
                                  alpha: baseAlpha * 0.96,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: sweepLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                sweepColor.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: coreAlpha),
                                sweepColor.withValues(alpha: sweepAlpha),
                                Colors.white.withValues(alpha: coreAlpha),
                                sweepColor.withValues(alpha: 0.0),
                                Colors.transparent,
                              ],
                              stops: const [
                                0.0,
                                0.12,
                                0.28,
                                0.5,
                                0.72,
                                0.88,
                                1.0,
                              ],
                            ),
                          ),
                          child: SizedBox(width: sweepWidth, height: barHeight),
                        ),
                      ),
                      Positioned(
                        left: beadLeft,
                        top: 0,
                        child: Container(
                          key: widget.beadKey,
                          width: beadWidth,
                          height: beadHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              999 * widget.scaleFactor,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(
                                  alpha: 0.82 + (pulse * 0.1),
                                ),
                                sweepColor.withValues(alpha: 0.92),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: sweepColor.withValues(alpha: haloAlpha),
                                blurRadius: widget.glassEnabled
                                    ? widget.beadBlurGlass
                                    : widget.beadBlurSolid,
                                spreadRadius:
                                    (widget.glassEnabled
                                        ? widget.beadSpreadGlass
                                        : widget.beadSpreadSolid) *
                                    pulse,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
