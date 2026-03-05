import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:shakedown/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

class InterfaceSection extends StatelessWidget {
  final double scaleFactor;
  final bool initiallyExpanded;

  const InterfaceSection({
    super.key,
    required this.scaleFactor,
    required this.initiallyExpanded,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    return SectionCard(
      key: const ValueKey('interface_section'),
      scaleFactor: scaleFactor,
      title: 'Interface',
      icon: Icons.view_quilt_outlined,
      lucideIcon: LucideIcons.layout,
      initiallyExpanded: initiallyExpanded,
      children: [
        // 1. General UI Group
        if (context.read<DeviceService>().isTv)
          TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Premium TV Highlight',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Animated gradient and glow on focused items',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * scaleFactor))),
            value: settingsProvider.oilTvPremiumHighlight,
            onChanged: (value) {
              AppHaptics.lightImpact(context.read<DeviceService>());
              context.read<SettingsProvider>().toggleOilTvPremiumHighlight();
            },
            secondary: Icon(
                isFruit ? LucideIcons.sparkles : Icons.auto_awesome_rounded),
          ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('UI Scale',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Increase text size across the app',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.uiScale,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleUiScale();
          },
          secondary:
              Icon(isFruit ? LucideIcons.type : Icons.text_fields_rounded),
        ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Show Splash Screen',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Show a loading screen on startup',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.showSplashScreen,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleShowSplashScreen();
          },
          secondary:
              Icon(isFruit ? LucideIcons.rocket : Icons.rocket_launch_rounded),
        ),

        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),

        // 2. Date & Time Group
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Show date first in show cards',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Display the date before the venue',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.dateFirstInShowCard,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleDateFirstInShowCard();
          },
          secondary:
              Icon(isFruit ? LucideIcons.calendar : Icons.date_range_rounded),
        ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Show Day of Week',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Includes the day name in dates',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.showDayOfWeek,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleShowDayOfWeek();
          },
          secondary:
              Icon(isFruit ? LucideIcons.calendarDays : Icons.today_rounded),
        ),
        if (settingsProvider.showDayOfWeek)
          TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Abbreviate Day of Week',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Use short day names (e.g., Sat)',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * scaleFactor))),
            value: settingsProvider.abbreviateDayOfWeek,
            onChanged: (value) {
              AppHaptics.lightImpact(context.read<DeviceService>());
              context.read<SettingsProvider>().toggleAbbreviateDayOfWeek();
            },
            secondary:
                Icon(isFruit ? LucideIcons.text : Icons.short_text_rounded),
          ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Abbreviate Month',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Use short month names (e.g., Aug)',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.abbreviateMonth,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleAbbreviateMonth();
          },
          secondary: Icon(isFruit
              ? LucideIcons.calendarRange
              : Icons.calendar_view_month_rounded),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),

        // 3. List Sorting & Badges
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Sort Oldest First',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Show earliest shows at the top',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.sortOldestFirst,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleSortOldestFirst();
          },
          secondary: Icon(isFruit ? LucideIcons.list : Icons.sort_rounded),
        ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Show SHNID Badge (Single Source)',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Display SHNID number on card if only one source',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.showSingleShnid,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleShowSingleShnid();
          },
          secondary: Icon(isFruit ? LucideIcons.hash : Icons.looks_one_rounded),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),

        // 4. Track List Options
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Show Track Numbers',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Display track numbers in lists',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.showTrackNumbers,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleShowTrackNumbers();
          },
          secondary:
              Icon(isFruit ? LucideIcons.listOrdered : Icons.pin_rounded),
        ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Hide Track Duration',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Hide duration and center track titles',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.hideTrackDuration,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleHideTrackDuration();
          },
          secondary:
              Icon(isFruit ? LucideIcons.timerOff : Icons.timer_off_rounded),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),

        // 5. Gestures Group
        SwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: Text('Enable Swipe to Block',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 16 * scaleFactor)),
          subtitle: Text('Allows swiping list items to block them',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(fontSize: 12 * scaleFactor)),
          value: settingsProvider.enableSwipeToBlock,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleEnableSwipeToBlock();
          },
          secondary:
              Icon(isFruit ? LucideIcons.moveHorizontal : Icons.swipe_rounded),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
      ],
    );
  }
}
