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
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final glassEnabled = settings.fruitEnableLiquidGlass;
    final unitMatch = RegExp(r'^([+-]?\d+(?:\.\d+)?)(ms|s)$').firstMatch(value);
    final String displayValue = unitMatch?.group(1) ?? value;
    final String? displayUnit = unitMatch?.group(2);
    final chipHorizontalPadding = 10 * scaleFactor;
    final chipVerticalPadding = 5 * scaleFactor;
    final unitRightInset = 6 * scaleFactor;
    final unitBottomInset = 5 * scaleFactor;
    final valueUnitReserve = displayUnit == null ? 0.0 : 18 * scaleFactor;

    final valueText = Text(
      displayValue,
      key: ValueKey('fruit_car_mode_stat_value_text_$label'),
      maxLines: 1,
      overflow: TextOverflow.visible,
      softWrap: false,
      style: TextStyle(
        fontFamily: FontConfig.resolve('Inter'),
        fontSize: 22 * scaleFactor,
        fontWeight: FontWeight.w900,
        color: accentColor,
      ),
    );
    final unitText = displayUnit == null
        ? null
        : Text(
            displayUnit,
            key: ValueKey('fruit_car_mode_stat_unit_text_$label'),
            maxLines: 1,
            style: TextStyle(
              fontFamily: FontConfig.resolve('Inter'),
              fontSize: 9 * scaleFactor,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.15,
              color: accentColor.withValues(alpha: 0.8),
            ),
          );

    final valueContent = glassEnabled
        ? SizedBox(
            height: 34 * scaleFactor,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                      widthFactor: displayUnit == null ? 0.9 : 0.74,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          key: const ValueKey('fruit_car_mode_stat_value_lens'),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              999 * scaleFactor,
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                              width: 0.8,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withValues(alpha: 0.18),
                                accentColor.withValues(alpha: 0.06),
                                Colors.white.withValues(alpha: 0.08),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.12),
                                blurRadius: 8 * scaleFactor,
                                offset: Offset(0, 2 * scaleFactor),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  right: valueUnitReserve,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: valueText,
                    ),
                  ),
                ),
              ],
            ),
          )
        : SizedBox(
            height: 34 * scaleFactor,
            child: Stack(
              children: [
                Positioned.fill(
                  right: valueUnitReserve,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: valueText,
                    ),
                  ),
                ),
              ],
            ),
          );

    return FruitSurface(
      key: ValueKey('fruit_car_mode_stat_card_$label'),
      borderRadius: BorderRadius.circular(18 * scaleFactor),
      blur: 14,
      opacity: 0.82,
      child: SizedBox(
        height: _fruitCarModeChipCardHeight(scaleFactor),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18 * scaleFactor),
            border: Border.all(color: accentColor.withValues(alpha: 0.16)),
          ),
          child: Stack(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: chipHorizontalPadding,
                  vertical: chipVerticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      key: ValueKey('fruit_car_mode_stat_label_text_$label'),
                      style: TextStyle(
                        fontFamily: FontConfig.resolve('Inter'),
                        fontSize: 9 * scaleFactor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.8,
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    SizedBox(height: 2 * scaleFactor),
                    valueContent,
                  ],
                ),
              ),
              if (unitText != null)
                Positioned(
                  right: unitRightInset,
                  bottom: unitBottomInset,
                  child: unitText,
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
  final VoidCallback? onLongPress;
  final double scaleFactor;

  const _FruitCarModePlayButton({
    required this.isBusy,
    required this.isPlaying,
    required this.onPressed,
    required this.onLongPress,
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
      key: const ValueKey('fruit_car_mode_play_button'),
      width: 152 * scaleFactor,
      height: 152 * scaleFactor,
      child: GestureDetector(
        onTap: onPressed,
        onLongPress: onLongPress ?? () {},
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

class _FruitCarModePendingProgressOverlay extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return FruitNowPlayingPendingOverlay(
      key: key,
      colorScheme: colorScheme,
      scaleFactor: scaleFactor,
      glassEnabled: true,
      isLoading: isLoading,
      barHeightBase: 16.0,
      borderRadiusBase: 999.0,
      sweepWidthGlassBase: 88.0,
      sweepWidthSolidBase: 88.0,
      sweepOverflowFactor: 0.18,
      beadWidthGlassBase: 18.0,
      beadWidthSolidBase: 18.0,
      baseAlphaGlass: 0.14,
      baseAlphaSolid: 0.14,
      sweepAlphaGlass: 0.6,
      sweepAlphaSolid: 0.6,
      coreAlphaGlass: 0.2,
      coreAlphaSolid: 0.2,
      haloAlphaGlass: 0.26,
      haloAlphaSolid: 0.26,
      beadBlurGlass: 8.0,
      beadBlurSolid: 8.0,
      beadSpreadGlass: 0.4,
      beadSpreadSolid: 0.4,
      beadKey: const Key('fruit_car_mode_pending_progress_bead'),
    );
  }
}
