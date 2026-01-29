import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/section_card.dart';

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

    return SectionCard(
      key: const ValueKey('interface_section'),
      scaleFactor: scaleFactor,
      title: 'Interface',
      icon: Icons.view_quilt_outlined,
      initiallyExpanded: initiallyExpanded,
      children: [
        // 1. General UI Group
        SwitchListTile(
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
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().toggleUiScale();
          },
          secondary: const Icon(Icons.text_fields_rounded),
        ),
        SwitchListTile(
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
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().toggleShowSplashScreen();
          },
          secondary: const Icon(Icons.rocket_launch_rounded),
        ),

        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),

        // 2. Date & Time Group
        SwitchListTile(
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
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().toggleDateFirstInShowCard();
          },
          secondary: const Icon(Icons.date_range_rounded),
        ),
        SwitchListTile(
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
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().toggleShowDayOfWeek();
          },
          secondary: const Icon(Icons.today_rounded),
        ),
        if (settingsProvider.showDayOfWeek)
          SwitchListTile(
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
              HapticFeedback.lightImpact();
              context.read<SettingsProvider>().toggleAbbreviateDayOfWeek();
            },
            secondary: const Icon(Icons.short_text_rounded),
          ),
        SwitchListTile(
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
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().toggleAbbreviateMonth();
          },
          secondary: const Icon(Icons.calendar_view_month_rounded),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),

        // 3. List Sorting & Badges
        SwitchListTile(
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
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().toggleSortOldestFirst();
          },
          secondary: const Icon(Icons.sort_rounded),
        ),
        SwitchListTile(
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
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().toggleShowSingleShnid();
          },
          secondary: const Icon(Icons.looks_one_rounded),
        ),
        const SizedBox(height: 8),
        const Divider(),
        const SizedBox(height: 8),

        // 4. Track List Options
        SwitchListTile(
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
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().toggleShowTrackNumbers();
          },
          secondary: const Icon(Icons.pin_rounded),
        ),
        SwitchListTile(
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
            HapticFeedback.lightImpact();
            context.read<SettingsProvider>().toggleHideTrackDuration();
          },
          secondary: const Icon(Icons.timer_off_rounded),
        ),
      ],
    );
  }
}
