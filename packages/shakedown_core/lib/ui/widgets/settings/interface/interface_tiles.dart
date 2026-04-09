import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/backgrounds/floating_spheres_background.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown_core/utils/app_haptics.dart';

Widget buildInterfaceSwitchTile({
  required BuildContext context,
  required double scaleFactor,
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
  required Widget secondary,
}) {
  final titleStyle = Theme.of(
    context,
  ).textTheme.titleMedium?.copyWith(fontSize: 16 * scaleFactor);
  final subtitleStyle = Theme.of(
    context,
  ).textTheme.bodySmall?.copyWith(fontSize: 12 * scaleFactor);

  return TvSwitchListTile(
    dense: true,
    visualDensity: VisualDensity.compact,
    title: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(title, style: titleStyle),
    ),
    subtitle: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(subtitle, style: subtitleStyle),
    ),
    value: value,
    onChanged: onChanged,
    secondary: secondary,
  );
}

Widget buildMaterialInterfaceSwitchTile({
  required BuildContext context,
  required double scaleFactor,
  required String title,
  required String subtitle,
  required bool value,
  required ValueChanged<bool> onChanged,
  required Widget secondary,
}) {
  final titleStyle = Theme.of(
    context,
  ).textTheme.titleMedium?.copyWith(fontSize: 16 * scaleFactor);
  final subtitleStyle = Theme.of(
    context,
  ).textTheme.bodySmall?.copyWith(fontSize: 12 * scaleFactor);

  return SwitchListTile(
    dense: true,
    visualDensity: VisualDensity.compact,
    title: Text(title, style: titleStyle),
    subtitle: Text(subtitle, style: subtitleStyle),
    value: value,
    onChanged: onChanged,
    secondary: secondary,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  );
}

Widget buildSphereAmountSelector({
  required BuildContext context,
  required double scaleFactor,
  required SettingsProvider settingsProvider,
}) {
  return Padding(
    padding: EdgeInsets.symmetric(
      horizontal: 16 * scaleFactor,
      vertical: 4 * scaleFactor,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sphere Amount',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12 * scaleFactor,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 6 * scaleFactor),
        SegmentedButton<SphereAmount>(
          segments: const [
            ButtonSegment(
              value: SphereAmount.small,
              label: Text('Small'),
              icon: Icon(Icons.circle_outlined),
            ),
            ButtonSegment(
              value: SphereAmount.medium,
              label: Text('Medium'),
              icon: Icon(Icons.circle),
            ),
            ButtonSegment(
              value: SphereAmount.more,
              label: Text('More'),
              icon: Icon(Icons.bubble_chart_rounded),
            ),
          ],
          selected: {settingsProvider.tvBackgroundSphereAmount},
          onSelectionChanged: (selected) {
            if (selected.isEmpty) {
              return;
            }

            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().setTvBackgroundSphereAmount(
              selected.first,
            );
          },
        ),
      ],
    ),
  );
}

void triggerInterfaceToggle(BuildContext context, VoidCallback toggle) {
  AppHaptics.lightImpact(context.read<DeviceService>());
  toggle();
}

Icon interfaceIcon({
  required bool isFruit,
  required IconData fruitIcon,
  required IconData materialIcon,
}) {
  return Icon(isFruit ? fruitIcon : materialIcon);
}

const Icon swipeToBlockFruitIcon = Icon(LucideIcons.moveHorizontal);
const Icon swipeToBlockMaterialIcon = Icon(Icons.swipe_rounded);
