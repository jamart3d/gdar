import 'package:flutter/material.dart';

class FruitNowPlayingPendingOverlay extends StatefulWidget {
  final ColorScheme colorScheme;
  final double scaleFactor;
  final bool glassEnabled;
  final bool isLoading;

  const FruitNowPlayingPendingOverlay({
    super.key,
    required this.colorScheme,
    required this.scaleFactor,
    required this.glassEnabled,
    required this.isLoading,
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
    final double barHeight = 3.0 * widget.scaleFactor;
    final BorderRadius borderRadius = BorderRadius.circular(
      4 * widget.scaleFactor,
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
                    (widget.glassEnabled ? 84.0 : 66.0) * widget.scaleFactor;
                final double sweepOverflow = sweepWidth * 0.22;
                final double sweepTravelWidth =
                    (constraints.maxWidth + (sweepOverflow * 2.0) - sweepWidth)
                        .clamp(0.0, double.infinity);
                final double sweepLeft =
                    -sweepOverflow + (sweepTravelWidth * travel);
                final double beadWidth =
                    (widget.glassEnabled ? 18.0 : 14.0) * widget.scaleFactor;
                final double beadHeight = barHeight;
                final double beadTravelWidth =
                    (constraints.maxWidth - beadWidth).clamp(
                      0.0,
                      double.infinity,
                    );
                final double beadLeft = beadTravelWidth * travel;
                final double baseAlpha = widget.glassEnabled ? 0.18 : 0.24;
                final double sweepAlpha = widget.glassEnabled ? 0.76 : 0.92;
                final double coreAlpha = widget.glassEnabled ? 0.44 : 0.60;
                final double haloAlpha = widget.glassEnabled ? 0.32 : 0.26;

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
                          key: const Key('fruit_pending_progress_bead'),
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
                                blurRadius: widget.glassEnabled ? 10 : 7,
                                spreadRadius:
                                    (widget.glassEnabled ? 0.7 : 0.45) * pulse,
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
