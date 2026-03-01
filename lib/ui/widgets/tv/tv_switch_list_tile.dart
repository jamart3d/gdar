import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';

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
          HapticFeedback.lightImpact();
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

    final useNeumorphism = context.watch<SettingsProvider>().useNeumorphism;

    Widget content = SwitchListTile(
      title: title,
      subtitle: subtitle,
      value: value,
      onChanged: onChanged,
      secondary: secondary,
      dense: dense,
      visualDensity: visualDensity,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    );

    if (useNeumorphism) {
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
