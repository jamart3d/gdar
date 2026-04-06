import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FruitNowPlayingTransportGlyph extends StatefulWidget {
  final bool isPlaying;
  final bool isPending;
  final bool glassEnabled;
  final Color color;
  final double size;

  const FruitNowPlayingTransportGlyph({
    super.key,
    required this.isPlaying,
    required this.isPending,
    required this.glassEnabled,
    required this.color,
    required this.size,
  });

  @override
  State<FruitNowPlayingTransportGlyph> createState() =>
      _FruitNowPlayingTransportGlyphState();
}

class _FruitNowPlayingTransportGlyphState
    extends State<FruitNowPlayingTransportGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.isPending) {
      _shimmerController.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant FruitNowPlayingTransportGlyph oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPending && !_shimmerController.isAnimating) {
      _shimmerController.repeat();
    } else if (!widget.isPending && _shimmerController.isAnimating) {
      _shimmerController.stop();
      _shimmerController.value = 0.0;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconData = widget.isPlaying ? LucideIcons.pause : LucideIcons.play;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(
          begin: widget.isPending ? 0.72 : 0.9,
          end: 1.0,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: widget.isPending
          ? AnimatedBuilder(
              key: const ValueKey('pending'),
              animation: _shimmerController,
              builder: (context, _) {
                final t = _shimmerController.value;
                final pulse = 1.0 - ((t - 0.5).abs() * 2.0);
                final shimmerX = ((t * 2.0) - 1.0) * (widget.size * 0.6);
                return SizedBox(
                  key: const Key('fruit_pending_transport_halo'),
                  width: widget.size,
                  height: widget.size,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Transform.scale(
                        scale: 0.92 + (pulse * 0.18),
                        child: Container(
                          width: widget.size * 1.04,
                          height: widget.size * 1.04,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                widget.color.withValues(
                                  alpha: widget.glassEnabled ? 0.26 : 0.20,
                                ),
                                widget.color.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        width: widget.size * 0.9,
                        height: widget.size * 0.9,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(
                            alpha: widget.glassEnabled ? 0.18 : 0.14,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withValues(
                                alpha: widget.glassEnabled ? 0.18 : 0.12,
                              ),
                              blurRadius: widget.glassEnabled ? 10 : 6,
                              spreadRadius: pulse * 0.8,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: widget.size * 0.48,
                        height: widget.size * 0.48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.color.withValues(alpha: 0.88),
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(shimmerX, 0),
                        child: Transform.rotate(
                          angle: -0.35,
                          child: Container(
                            width: widget.size * 0.22,
                            height: widget.size * 0.92,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(widget.size),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  widget.color.withValues(alpha: 0.0),
                                  widget.color.withValues(alpha: 0.95),
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.2, 0.55, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            )
          : Icon(
              key: ValueKey<String>('icon-$iconData'),
              iconData,
              size: widget.size,
              color: widget.color,
            ),
    );
  }
}
