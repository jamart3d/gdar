import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/section_card.dart';
import 'package:shakedown_core/ui/widgets/settings/interface/interface_group_header.dart';
import 'package:shakedown_core/ui/widgets/settings/interface/interface_tiles.dart';
import 'package:shakedown_core/utils/app_haptics.dart';

class InterfaceSection extends StatelessWidget {
  const InterfaceSection({
    super.key,
    required this.scaleFactor,
    required this.initiallyExpanded,
  });

  final double scaleFactor;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final isTv = context.read<DeviceService>().isTv;

    return SectionCard(
      key: const ValueKey('interface_section'),
      scaleFactor: scaleFactor,
      title: 'Interface',
      icon: Icons.view_quilt_outlined,
      lucideIcon: LucideIcons.layout,
      initiallyExpanded: initiallyExpanded,
      children: [
        ...buildInterfaceGroupHeader(
          label: 'General',
          isFruit: isFruit,
          addTopSpacing: false,
        ),
        if (isTv) ...[
          buildInterfaceSwitchTile(
            context: context,
            scaleFactor: scaleFactor,
            title: 'Hide TV Scrollbars',
            subtitle: 'Removes visible scrollbars for a cleaner look',
            value: settingsProvider.hideTvScrollbars,
            onChanged: (_) => triggerInterfaceToggle(
              context,
              context.read<SettingsProvider>().toggleHideTvScrollbars,
            ),
            secondary: interfaceIcon(
              isFruit: isFruit,
              fruitIcon: LucideIcons.eyeOff,
              materialIcon: Icons.visibility_off_rounded,
            ),
          ),
          buildInterfaceSwitchTile(
            context: context,
            scaleFactor: scaleFactor,
            title: 'TV Highlight',
            subtitle: 'Animated gradient and glow on focused items',
            value: settingsProvider.oilTvPremiumHighlight,
            onChanged: (_) => triggerInterfaceToggle(
              context,
              context.read<SettingsProvider>().toggleOilTvPremiumHighlight,
            ),
            secondary: interfaceIcon(
              isFruit: isFruit,
              fruitIcon: LucideIcons.sparkles,
              materialIcon: Icons.auto_awesome_rounded,
            ),
          ),
          buildInterfaceSwitchTile(
            context: context,
            scaleFactor: scaleFactor,
            title: 'Background Spheres',
            subtitle: 'Floating ambient spheres behind the home layout',
            value: settingsProvider.enableTvBackgroundSpheres,
            onChanged: (_) => triggerInterfaceToggle(
              context,
              context.read<SettingsProvider>().toggleEnableTvBackgroundSpheres,
            ),
            secondary: const Icon(Icons.bubble_chart_rounded),
          ),
          if (settingsProvider.enableTvBackgroundSpheres)
            buildSphereAmountSelector(
              context: context,
              scaleFactor: scaleFactor,
              settingsProvider: settingsProvider,
            ),
        ],
        if (!settingsProvider.carMode)
          buildInterfaceSwitchTile(
            context: context,
            scaleFactor: scaleFactor,
            title: 'UI Scale',
            subtitle: 'Increase text size across the app',
            value: settingsProvider.uiScale,
            onChanged: (_) => triggerInterfaceToggle(
              context,
              context.read<SettingsProvider>().toggleUiScale,
            ),
            secondary: interfaceIcon(
              isFruit: isFruit,
              fruitIcon: LucideIcons.type,
              materialIcon: Icons.text_fields_rounded,
            ),
          ),
        if (isFruit && !isTv)
          buildInterfaceSwitchTile(
            context: context,
            scaleFactor: scaleFactor,
            title: 'Car Mode',
            subtitle: 'Use the driving-friendly playback layout',
            value: settingsProvider.carMode,
            onChanged: (_) => triggerInterfaceToggle(
              context,
              context.read<SettingsProvider>().toggleCarMode,
            ),
            secondary: interfaceIcon(
              isFruit: isFruit,
              fruitIcon: LucideIcons.rocket,
              materialIcon: Icons.directions_car_rounded,
            ),
          ),
        if (isFruit && !isTv)
          buildInterfaceSwitchTile(
            context: context,
            scaleFactor: scaleFactor,
            title: 'Floating Spheres',
            subtitle: 'Animated background for car mode playback',
            value: settingsProvider.fruitFloatingSpheres,
            onChanged: (_) => triggerInterfaceToggle(
              context,
              context.read<SettingsProvider>().toggleFruitFloatingSpheres,
            ),
            secondary: interfaceIcon(
              isFruit: isFruit,
              fruitIcon: LucideIcons.circle,
              materialIcon: Icons.bubble_chart_rounded,
            ),
          ),
        if (isFruit && !isTv && kIsWeb)
          buildInterfaceSwitchTile(
            context: context,
            scaleFactor: scaleFactor,
            title: 'Keep Screen On',
            subtitle: 'Prevents the device from sleeping during playback.',
            value: settingsProvider.preventSleep,
            onChanged: (_) => triggerInterfaceToggle(
              context,
              context.read<SettingsProvider>().togglePreventSleep,
            ),
            secondary: interfaceIcon(
              isFruit: isFruit,
              fruitIcon: LucideIcons.monitor,
              materialIcon: Icons.sensor_window_rounded,
            ),
          ),
        buildInterfaceSwitchTile(
          context: context,
          scaleFactor: scaleFactor,
          title: 'Show Splash Screen',
          subtitle: 'Show a loading screen on startup',
          value: settingsProvider.showSplashScreen,
          onChanged: (_) => triggerInterfaceToggle(
            context,
            context.read<SettingsProvider>().toggleShowSplashScreen,
          ),
          secondary: interfaceIcon(
            isFruit: isFruit,
            fruitIcon: LucideIcons.rocket,
            materialIcon: Icons.rocket_launch_rounded,
          ),
        ),
        if (!isTv)
          buildInterfaceSwitchTile(
            context: context,
            scaleFactor: scaleFactor,
            title: 'Haptic Feedback',
            subtitle: 'Vibrate on interactions (PWA/Mobile)',
            value: settingsProvider.enableHaptics,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleEnableHaptics();
              AppHaptics.lightImpact(
                context.read<DeviceService>(),
                enabled: value,
              );
            },
            secondary: interfaceIcon(
              isFruit: isFruit,
              fruitIcon: LucideIcons.vibrate,
              materialIcon: Icons.vibration,
            ),
          ),
        ...buildInterfaceGroupHeader(label: 'Date & Time', isFruit: isFruit),
        buildInterfaceSwitchTile(
          context: context,
          scaleFactor: scaleFactor,
          title: 'Show date first in show cards',
          subtitle: 'Display the date before the venue',
          value: settingsProvider.dateFirstInShowCard,
          onChanged: (_) => triggerInterfaceToggle(
            context,
            context.read<SettingsProvider>().toggleDateFirstInShowCard,
          ),
          secondary: interfaceIcon(
            isFruit: isFruit,
            fruitIcon: LucideIcons.calendar,
            materialIcon: Icons.date_range_rounded,
          ),
        ),
        buildInterfaceSwitchTile(
          context: context,
          scaleFactor: scaleFactor,
          title: 'Show Day of Week',
          subtitle: 'Includes the day name in dates',
          value: settingsProvider.showDayOfWeek,
          onChanged: (_) => triggerInterfaceToggle(
            context,
            context.read<SettingsProvider>().toggleShowDayOfWeek,
          ),
          secondary: interfaceIcon(
            isFruit: isFruit,
            fruitIcon: LucideIcons.calendarDays,
            materialIcon: Icons.today_rounded,
          ),
        ),
        if (settingsProvider.showDayOfWeek)
          buildInterfaceSwitchTile(
            context: context,
            scaleFactor: scaleFactor,
            title: 'Abbreviate Day of Week',
            subtitle: 'Use short day names (e.g., Sat)',
            value: settingsProvider.abbreviateDayOfWeek,
            onChanged: (_) => triggerInterfaceToggle(
              context,
              context.read<SettingsProvider>().toggleAbbreviateDayOfWeek,
            ),
            secondary: interfaceIcon(
              isFruit: isFruit,
              fruitIcon: LucideIcons.text,
              materialIcon: Icons.short_text_rounded,
            ),
          ),
        buildInterfaceSwitchTile(
          context: context,
          scaleFactor: scaleFactor,
          title: 'Abbreviate Month',
          subtitle: 'Use short month names (e.g., Aug)',
          value: settingsProvider.abbreviateMonth,
          onChanged: (_) => triggerInterfaceToggle(
            context,
            context.read<SettingsProvider>().toggleAbbreviateMonth,
          ),
          secondary: interfaceIcon(
            isFruit: isFruit,
            fruitIcon: LucideIcons.calendarRange,
            materialIcon: Icons.calendar_view_month_rounded,
          ),
        ),
        ...buildInterfaceGroupHeader(label: 'Library Cards', isFruit: isFruit),
        buildInterfaceSwitchTile(
          context: context,
          scaleFactor: scaleFactor,
          title: 'Sort Oldest First',
          subtitle: 'Show earliest shows at the top',
          value: settingsProvider.sortOldestFirst,
          onChanged: (_) => triggerInterfaceToggle(
            context,
            context.read<SettingsProvider>().toggleSortOldestFirst,
          ),
          secondary: interfaceIcon(
            isFruit: isFruit,
            fruitIcon: LucideIcons.list,
            materialIcon: Icons.sort_rounded,
          ),
        ),
        buildInterfaceSwitchTile(
          context: context,
          scaleFactor: scaleFactor,
          title: 'Show SHNID Badge (Single Source)',
          subtitle: 'Display SHNID number on card if only one source',
          value: settingsProvider.showSingleShnid,
          onChanged: (_) => triggerInterfaceToggle(
            context,
            context.read<SettingsProvider>().toggleShowSingleShnid,
          ),
          secondary: interfaceIcon(
            isFruit: isFruit,
            fruitIcon: LucideIcons.hash,
            materialIcon: Icons.looks_one_rounded,
          ),
        ),
        ...buildInterfaceGroupHeader(label: 'Track List', isFruit: isFruit),
        buildInterfaceSwitchTile(
          context: context,
          scaleFactor: scaleFactor,
          title: 'Show Track Numbers',
          subtitle: 'Display track numbers in lists',
          value: settingsProvider.showTrackNumbers,
          onChanged: (_) => triggerInterfaceToggle(
            context,
            context.read<SettingsProvider>().toggleShowTrackNumbers,
          ),
          secondary: interfaceIcon(
            isFruit: isFruit,
            fruitIcon: LucideIcons.listOrdered,
            materialIcon: Icons.pin_rounded,
          ),
        ),
        buildInterfaceSwitchTile(
          context: context,
          scaleFactor: scaleFactor,
          title: 'Hide Track Duration',
          subtitle: 'Hide duration and center track titles',
          value: settingsProvider.hideTrackDuration,
          onChanged: (_) => triggerInterfaceToggle(
            context,
            context.read<SettingsProvider>().toggleHideTrackDuration,
          ),
          secondary: interfaceIcon(
            isFruit: isFruit,
            fruitIcon: LucideIcons.timerOff,
            materialIcon: Icons.timer_off_rounded,
          ),
        ),
        ...buildInterfaceGroupHeader(label: 'Navigation', isFruit: isFruit),
        if (!isTv)
          isFruit
              ? buildInterfaceSwitchTile(
                  context: context,
                  scaleFactor: scaleFactor,
                  title: 'Enable Swipe to Block',
                  subtitle: 'Allows swiping list items to block them',
                  value: settingsProvider.enableSwipeToBlock,
                  onChanged: (_) => triggerInterfaceToggle(
                    context,
                    context.read<SettingsProvider>().toggleEnableSwipeToBlock,
                  ),
                  secondary: swipeToBlockFruitIcon,
                )
              : buildMaterialInterfaceSwitchTile(
                  context: context,
                  scaleFactor: scaleFactor,
                  title: 'Enable Swipe to Block',
                  subtitle: 'Allows swiping list items to block them',
                  value: settingsProvider.enableSwipeToBlock,
                  onChanged: (_) => triggerInterfaceToggle(
                    context,
                    context.read<SettingsProvider>().toggleEnableSwipeToBlock,
                  ),
                  secondary: swipeToBlockMaterialIcon,
                ),
        if (isFruit)
          buildInterfaceSwitchTile(
            context: context,
            scaleFactor: scaleFactor,
            title: 'Hide Tab Text',
            subtitle: 'Hide labels under tab bar icons',
            value: settingsProvider.hideTabText,
            onChanged: (_) => triggerInterfaceToggle(
              context,
              context.read<SettingsProvider>().toggleHideTabText,
            ),
            secondary: const Icon(LucideIcons.eyeOff),
          ),
      ],
    );
  }
}
