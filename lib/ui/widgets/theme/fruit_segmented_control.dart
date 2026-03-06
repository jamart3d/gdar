import 'dart:math' as math;
import 'package:flutter/material.dart';

class FruitSegmentedControl<T> extends StatelessWidget {
  final List<T> values;
  final T selectedValue;
  final ValueChanged<T> onSelectionChanged;
  final Widget Function(T value) labelBuilder;
  final double height;
  final BorderRadius? borderRadius;

  const FruitSegmentedControl({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.onSelectionChanged,
    required this.labelBuilder,
    this.height = 36,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(28);
    final selectedIndex = values.indexOf(selectedValue);

    final computedWidth = math.max(280.0, _calculateMinWidth(context));

    return Container(
      height: height,
      width: computedWidth,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: effectiveBorderRadius,
      ),
      child: Stack(
        children: [
          // Sliding segment indicator
          AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubicEmphasized,
            alignment: Alignment(
              values.length > 1
                  ? (-1.0 + (selectedIndex / (values.length - 1)) * 2)
                  : 0.0,
              0.0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / values.length,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: effectiveBorderRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Labels
          Row(
            children: values.map((value) {
              final isSelected = value == selectedValue;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onSelectionChanged(value),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: theme.textTheme.labelMedium!.copyWith(
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface
                                  .withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                        child: labelBuilder(value),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  double _calculateMinWidth(BuildContext context) {
    // Estimating minimum comfortable width based on children count
    return values.length * 64.0;
  }
}
