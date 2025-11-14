import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/theme_provider.dart';
import 'package:gdar/ui/screens/about_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showColorPickerDialog(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    Color pickerColor = settingsProvider.seedColor ?? Colors.purple;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: pickerColor,
              onColorChanged: (color) => pickerColor = color,
              pickerAreaHeightPercent: 0.8,
              enableAlpha: false, // Hide alpha slider
              showLabel: false, // Hide RGB/Hex labels
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('Default'),
              onPressed: () {
                settingsProvider.setSeedColor(null);
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                settingsProvider.setSeedColor(pickerColor);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Appearance Settings
          ExpansionTile(
            title: Text(
              'Appearance',
              style: TextStyle(
                  color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            children: [
              SwitchListTile(
                title: const Text('Dark Mode'),
                subtitle: const Text('Enable the true black theme'),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  context.read<ThemeProvider>().toggleTheme();
                },
                secondary: Icon(
                  themeProvider.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
              ),
              SwitchListTile(
                title: const Text('Dynamic Color'),
                subtitle:
                const Text("Theme the app from your device's wallpaper"),
                value: settingsProvider.useDynamicColor,
                onChanged: (value) {
                  context.read<SettingsProvider>().toggleUseDynamicColor();
                },
                secondary: const Icon(Icons.color_lens_rounded),
              ),
              ListTile(
                title: const Text('Custom Theme Color'),
                subtitle: const Text('Overrides the default theme color'),
                enabled: !settingsProvider.useDynamicColor,
                onTap: () => _showColorPickerDialog(context),
                trailing: settingsProvider.seedColor != null
                    ? Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: settingsProvider.seedColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colorScheme.outline,
                      width: 2,
                    ),
                  ),
                )
                    : const Icon(Icons.color_lens_outlined),
              ),
              SwitchListTile(
                title: const Text('Handwriting Font'),
                subtitle: const Text('Use a more expressive, handwritten font'),
                value: settingsProvider.useHandwritingFont,
                onChanged: (value) {
                  context.read<SettingsProvider>().toggleUseHandwritingFont();
                },
                secondary: const Icon(Icons.edit_rounded),
              ),
              SwitchListTile(
                title: const Text('Expressive Scrolling'),
                subtitle: const Text("Make the app bar react to scrolling"),
                value: settingsProvider.useSliverAppBar,
                onChanged: (value) {
                  context.read<SettingsProvider>().toggleUseSliverAppBar();
                },
                secondary: const Icon(Icons.view_day_outlined),
              ),
              SwitchListTile(
                title: const Text('Expressive Transitions'),
                subtitle:
                const Text("Use Material 3's shared axis screen transitions"),
                value: settingsProvider.useSharedAxisTransition,
                onChanged: (value) {
                  context
                      .read<SettingsProvider>()
                      .toggleUseSharedAxisTransition();
                },
                secondary: const Icon(Icons.open_in_new_rounded),
              ),
            ],
          ),

          // Interface Settings
          ExpansionTile(
            title: Text(
              'Interface',
              style: TextStyle(
                  color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            children: [
              SwitchListTile(
                title: const Text('Show Track Numbers'),
                subtitle: const Text('Display track numbers in lists'),
                value: settingsProvider.showTrackNumbers,
                onChanged: (value) {
                  context.read<SettingsProvider>().toggleShowTrackNumbers();
                },
                secondary: const Icon(Icons.pin_rounded),
              ),
              SwitchListTile(
                title: const Text('Show date first in show cards'),
                subtitle: const Text('Display the date before the venue'),
                value: settingsProvider.dateFirstInShowCard,
                onChanged: (value) {
                  context.read<SettingsProvider>().toggleDateFirstInShowCard();
                },
                secondary: const Icon(Icons.date_range_rounded),
              ),
              SwitchListTile(
                title: const Text('Show SHNID Badge (Single Source)'),
                subtitle: const Text(
                    'Display SHNID number on card if only one source'),
                value: settingsProvider.showSingleShnid,
                onChanged: (value) {
                  context.read<SettingsProvider>().toggleShowSingleShnid();
                },
                secondary: const Icon(Icons.looks_one_rounded),
              ),
              SwitchListTile(
                title: const Text('Hide Track Count in Source List'),
                subtitle: const Text(
                    'Hide "X tracks" next to SHNID in expanded view'),
                value: settingsProvider.hideTrackCountInSourceList,
                onChanged: (value) {
                  context
                      .read<SettingsProvider>()
                      .toggleHideTrackCountInSourceList();
                },
                secondary: const Icon(Icons.format_list_numbered_rtl_rounded),
              ),
            ],
          ),

          // Playback Settings
          ExpansionTile(
            title: Text(
              'Playback',
              style: TextStyle(
                  color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            children: [
              SwitchListTile(
                title: const Text('Play on Tap'),
                subtitle: const Text('Tap track in inactive source to play'),
                value: settingsProvider.playOnTap,
                onChanged: (value) {
                  context.read<SettingsProvider>().togglePlayOnTap();
                },
                secondary: const Icon(Icons.touch_app_rounded),
              ),
              SwitchListTile(
                title: const Text('Play Random Show on Completion'),
                subtitle:
                const Text('When a show ends, play another one randomly'),
                value: settingsProvider.playRandomOnCompletion,
                onChanged: (value) {
                  context
                      .read<SettingsProvider>()
                      .togglePlayRandomOnCompletion();
                },
                secondary: const Icon(Icons.shuffle_rounded),
              ),
              SwitchListTile(
                title: const Text('Play Random Show on Startup'),
                subtitle:
                const Text('Start playing a random show when the app opens'),
                value: settingsProvider.playRandomOnStartup,
                onChanged: (value) {
                  context.read<SettingsProvider>().togglePlayRandomOnStartup();
                },
                secondary: const Icon(Icons.play_circle_filled_rounded),
              ),
            ],
          ),

          // Accessibility
          ExpansionTile(
            title: Text(
              'Accessibility',
              style: TextStyle(
                  color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
            children: [
              SwitchListTile(
                title: const Text('Scale Show List'),
                subtitle: const Text('Increase size of show cards and fonts'),
                value: settingsProvider.scaleShowList,
                onChanged: (value) {
                  context.read<SettingsProvider>().toggleScaleShowList();
                },
                secondary: const Icon(Icons.zoom_in_map_rounded),
              ),
              SwitchListTile(
                title: const Text('Scale Track Lists'),
                subtitle: const Text('Increase size of track list items'),
                value: settingsProvider.scaleTrackList,
                onChanged: (value) {
                  context.read<SettingsProvider>().toggleScaleTrackList();
                },
                secondary: const Icon(Icons.format_list_bulleted_rounded),
              ),
              SwitchListTile(
                title: const Text('Scale Player Controls'),
                subtitle: const Text('Increase size of player UI elements'),
                value: settingsProvider.scalePlayer,
                onChanged: (value) {
                  context.read<SettingsProvider>().toggleScalePlayer();
                },
                secondary: const Icon(Icons.play_circle_outline_rounded),
              ),
            ],
          ),

          // About Section
          ListTile(
            leading: const Icon(Icons.info_outline_rounded),
            title: const Text('About'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
