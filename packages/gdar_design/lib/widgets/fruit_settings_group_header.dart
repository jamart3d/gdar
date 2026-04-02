import 'package:flutter/material.dart';
import 'package:gdar_design/tokens/spacing_tokens.dart';
import 'package:gdar_design/tokens/typography_tokens.dart';

class FruitSettingsGroupHeader extends StatelessWidget {
  final String label;
  final bool addTopSpacing;

  const FruitSettingsGroupHeader({
    super.key,
    required this.label,
    this.addTopSpacing = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: addTopSpacing
              ? GdarSpacingTokens.fruitSectionHeaderTop
              : GdarSpacingTokens.fruitSectionHeaderTopCompact,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: GdarSpacingTokens.fruitSectionHeaderHorizontal,
          ),
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: onSurface.withValues(
                alpha: GdarTypographyTokens.fruitSectionHeaderLightAlpha,
              ),
              fontWeight: GdarTypographyTokens.fruitSectionHeaderWeight,
              letterSpacing:
                  GdarTypographyTokens.fruitSectionHeaderLetterSpacing,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            GdarSpacingTokens.fruitSectionHeaderHorizontal,
            GdarSpacingTokens.fruitSectionHeaderDividerTop,
            GdarSpacingTokens.fruitSectionHeaderHorizontal,
            GdarSpacingTokens.fruitSectionHeaderDividerBottom,
          ),
          child: Divider(
            height: 1,
            thickness: 1,
            color: onSurface.withValues(
              alpha: theme.brightness == Brightness.dark
                  ? GdarTypographyTokens.fruitSectionHeaderDividerDarkAlpha
                  : GdarTypographyTokens.fruitSectionHeaderDividerLightAlpha,
            ),
          ),
        ),
      ],
    );
  }
}
