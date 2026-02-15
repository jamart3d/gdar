import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class RainbowColorPicker extends StatelessWidget {
  final double scaleFactor;

  const RainbowColorPicker({
    super.key,
    required this.scaleFactor,
  });

  static const List<Color> rainbowColors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final currentColor = settingsProvider.seedColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            'Theme Color',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16 * scaleFactor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        SizedBox(
          height: 70 * scaleFactor,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            itemCount: rainbowColors.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                final isSelected = currentColor == null;
                return _buildColorItem(
                  context,
                  null,
                  isSelected,
                  'DEF',
                );
              }

              final color = rainbowColors[index - 1];
              final isSelected = currentColor?.toARGB32() == color.toARGB32();
              return _buildColorItem(
                context,
                color,
                isSelected,
                null,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildColorItem(
      BuildContext context, Color? color, bool isSelected, String? label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: TvFocusWrapper(
        onTap: () {
          context.read<SettingsProvider>().setSeedColor(color);
        },
        borderRadius: BorderRadius.circular(35),
        child: Container(
          width: 50 * scaleFactor,
          height: 50 * scaleFactor,
          decoration: BoxDecoration(
            color: color ?? colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: isSelected ? 3 * scaleFactor : 1 * scaleFactor,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      spreadRadius: 2,
                    )
                  ]
                : null,
          ),
          child: label != null
              ? Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                )
              : isSelected
                  ? Center(
                      child: Icon(
                        Icons.check,
                        color: ThemeData.estimateBrightnessForColor(color!) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black,
                        size: 24 * scaleFactor,
                      ),
                    )
                  : null,
        ),
      ),
    );
  }
}
