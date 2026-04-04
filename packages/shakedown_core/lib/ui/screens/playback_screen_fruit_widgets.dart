part of 'playback_screen.dart';

class _FruitCarModeStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final double scaleFactor;

  const _FruitCarModeStatCard({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FruitSurface(
      borderRadius: BorderRadius.circular(18 * scaleFactor),
      blur: 14,
      opacity: 0.82,
      child: SizedBox(
        height: _fruitCarModeChipCardHeight(scaleFactor),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scaleFactor,
            vertical: 12 * scaleFactor,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18 * scaleFactor),
            border: Border.all(color: accentColor.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: FontConfig.resolve('Inter'),
                  fontSize: 9 * scaleFactor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: 10 * scaleFactor),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: FontConfig.resolve('Inter'),
                  fontSize: 17 * scaleFactor,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FruitCarModeControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double scaleFactor;

  const _FruitCarModeControlButton({
    required this.icon,
    required this.onPressed,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;

    return SizedBox(
      height: 112 * scaleFactor,
      child: GestureDetector(
        onTap: onPressed,
        child: FruitSurface(
          borderRadius: BorderRadius.circular(28 * scaleFactor),
          blur: 16,
          opacity: 0.84,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(28 * scaleFactor),
              border: Border.all(
                color: colorScheme.onSurface.withValues(
                  alpha: isEnabled ? 0.08 : 0.04,
                ),
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 42 * scaleFactor,
                color: isEnabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

double _fruitCarModeChipCardHeight(double scaleFactor) => 74 * scaleFactor;

class _FruitCarModePlayButton extends StatelessWidget {
  final bool isBusy;
  final bool isPlaying;
  final VoidCallback onPressed;
  final double scaleFactor;

  const _FruitCarModePlayButton({
    required this.isBusy,
    required this.isPlaying,
    required this.onPressed,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final glassEnabled = settings.fruitEnableLiquidGlass;
    final BorderRadius borderRadius = BorderRadius.circular(999);

    final innerButton = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: glassEnabled
              ? [
                  colorScheme.primary.withValues(alpha: 0.94),
                  colorScheme.primaryContainer.withValues(alpha: 0.72),
                ]
              : [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.78),
                ],
        ),
        border: Border.all(
          color: glassEnabled
              ? Colors.white.withValues(alpha: 0.22)
              : colorScheme.primary.withValues(alpha: 0.08),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(
              alpha: glassEnabled ? 0.18 : 0.24,
            ),
            blurRadius: (glassEnabled ? 20 : 28) * scaleFactor,
            spreadRadius: glassEnabled ? 0 : 2 * scaleFactor,
            offset: Offset(0, (glassEnabled ? 6 : 10) * scaleFactor),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: glassEnabled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                )
              : null,
        ),
        child: Center(
          child: isBusy
              ? SizedBox(
                  width: 34 * scaleFactor,
                  height: 34 * scaleFactor,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Icon(
                  isPlaying ? LucideIcons.pause : LucideIcons.play,
                  size: 58 * scaleFactor,
                  color: colorScheme.onPrimary,
                ),
        ),
      ),
    );

    return SizedBox(
      width: 152 * scaleFactor,
      height: 152 * scaleFactor,
      child: GestureDetector(
        onTap: onPressed,
        child: glassEnabled
            ? FruitSurface(
                borderRadius: borderRadius,
                blur: 20,
                opacity: 0.34,
                padding: EdgeInsets.all(10 * scaleFactor),
                child: innerButton,
              )
            : innerButton,
      ),
    );
  }
}

class _FruitCarModePendingProgressOverlay extends StatefulWidget {
  final ColorScheme colorScheme;
  final double scaleFactor;
  final bool isLoading;

  const _FruitCarModePendingProgressOverlay({
    super.key,
    required this.colorScheme,
    required this.scaleFactor,
    required this.isLoading,
  });

  @override
  State<_FruitCarModePendingProgressOverlay> createState() =>
      _FruitCarModePendingProgressOverlayState();
}

class _FruitCarModePendingProgressOverlayState
    extends State<_FruitCarModePendingProgressOverlay>
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
    final double barHeight = 16.0 * widget.scaleFactor;
    final BorderRadius borderRadius = BorderRadius.circular(
      999 * widget.scaleFactor,
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
                final double sweepWidth = 88.0 * widget.scaleFactor;
                final double sweepOverflow = sweepWidth * 0.18;
                final double sweepTravelWidth =
                    (constraints.maxWidth + (sweepOverflow * 2.0) - sweepWidth)
                        .clamp(0.0, double.infinity);
                final double sweepLeft =
                    -sweepOverflow + (sweepTravelWidth * travel);
                final double beadWidth = 18.0 * widget.scaleFactor;
                final double beadTravelWidth =
                    (constraints.maxWidth - beadWidth).clamp(
                      0.0,
                      double.infinity,
                    );
                final double beadLeft = beadTravelWidth * travel;

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
                                  alpha: 0.14,
                                ),
                                widget.colorScheme.tertiary.withValues(
                                  alpha: 0.14,
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
                                Colors.white.withValues(alpha: 0.2),
                                sweepColor.withValues(alpha: 0.6),
                                Colors.white.withValues(alpha: 0.2),
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
                          key: const Key(
                            'fruit_car_mode_pending_progress_bead',
                          ),
                          width: beadWidth,
                          height: barHeight,
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(
                                  alpha: 0.8 + (pulse * 0.08),
                                ),
                                sweepColor.withValues(alpha: 0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: sweepColor.withValues(alpha: 0.26),
                                blurRadius: 8,
                                spreadRadius: 0.4 * pulse,
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
