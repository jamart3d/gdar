import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';

import 'package:shakedown_core/ui/widgets/theme/fruit_switch.dart';

class TvSwitchListTile extends StatelessWidget {
  final Widget? title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Widget? secondary;
  final bool dense;
  final VisualDensity? visualDensity;

  const TvSwitchListTile({
    super.key,
    this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.secondary,
    this.dense = false,
    this.visualDensity,
  });

  @override
  Widget build(BuildContext context) {
    if (context.read<DeviceService>().isTv) {
      return TvFocusWrapper(
        onTap: () {
          onChanged?.call(!value);
          AppHaptics.lightImpact(context.read<DeviceService>());
        },
        borderRadius: BorderRadius.circular(12),
        child: IgnorePointer(
          ignoring: true, // Let TvFocusWrapper handle interactions
          child: SwitchListTile(
            title: title,
            subtitle: subtitle,
            value: value,
            onChanged:
                onChanged, // Ignored by IgnorePointer, but keeping for structure
            secondary: secondary,
            dense: dense,
            visualDensity: visualDensity,
            // Remove internal padding/margins if needed for TV wrapper
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          ),
        ),
      );
    }

    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final useNeumorphism = context.watch<SettingsProvider>().useNeumorphism;

    Widget content;

    if (isFruit) {
      // Clean Apple-style list tile for switches
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            if (secondary != null) ...[
              secondary!,
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (title != null) title!,
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    DefaultTextStyle(
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.6),
                          ),
                      child: subtitle!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            FruitSwitch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      );
    } else {
      content = SwitchListTile(
        title: title,
        subtitle: subtitle,
        value: value,
        onChanged: onChanged,
        secondary: secondary,
        dense: dense,
        visualDensity: visualDensity,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      );
    }

    // Original M3 Neumorphic fallback (only for non-Fruit)
    if (useNeumorphism && !isFruit) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: NeumorphicWrapper(
          borderRadius: 16,
          style: value ? NeumorphicStyle.convex : NeumorphicStyle.concave,
          intensity: value ? 1.0 : 0.8,
          child: content,
        ),
      );
    }

    return content;
  }
}
