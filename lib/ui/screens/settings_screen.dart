import 'package:flutter/material.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/theme_provider.dart';
import 'package:gdar/ui/screens/about_screen.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

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
          // General Settings
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            title: Text(
              'General',
              style: TextStyle(
                  color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
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
          const Divider(),
          // Playback Settings
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            title: Text(
              'Playback',
              style: TextStyle(
                  color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Play Random Show on Completion'),
            subtitle: const Text('When a show ends, play another one randomly'),
            value: settingsProvider.playRandomOnCompletion,
            onChanged: (value) {
              context.read<SettingsProvider>().togglePlayRandomOnCompletion();
            },
            secondary: const Icon(Icons.shuffle_rounded),
          ),
          SwitchListTile(
            title: const Text('Play on Tap'),
            subtitle: const Text('Tap track in inactive source to play'),
            value: settingsProvider.playOnTap,
            onChanged: (value) {
              context.read<SettingsProvider>().togglePlayOnTap();
            },
            secondary: const Icon(Icons.touch_app_rounded),
          ),
          const Divider(),
          // UI Settings
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            title: Text(
              'Interface',
              style: TextStyle(
                  color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
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
            title: const Text('Show SHNID Badge (Single Source)'),
            subtitle:
            const Text('Display SHNID number on card if only one source'),
            value: settingsProvider.showSingleShnid,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleShowSingleShnid();
            },
            secondary: const Icon(Icons.looks_one_rounded),
          ),
          SwitchListTile(
            title: const Text('Hide Track Count in Source List'),
            subtitle:
            const Text('Hide "X tracks" next to SHNID in expanded view'),
            value: settingsProvider.hideTrackCountInSourceList,
            onChanged: (value) {
              context
                  .read<SettingsProvider>()
                  .toggleHideTrackCountInSourceList();
            },
            secondary: const Icon(Icons.format_list_numbered_rtl_rounded),
          ),
          const Divider(),
          // Accessibility
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            title: Text(
              'Accessibility',
              style: TextStyle(
                  color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
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
          const Divider(),
          // Material You Features
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 16, top: 8),
            title: Text(
              'Material You Features',
              style: TextStyle(
                  color: colorScheme.primary, fontWeight: FontWeight.bold),
            ),
          ),
          SwitchListTile(
            title: const Text('Dynamic Color'),
            subtitle: const Text("Theme the app from your device's wallpaper"),
            value: settingsProvider.useDynamicColor,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleUseDynamicColor();
            },
            secondary: const Icon(Icons.color_lens_rounded),
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
              context.read<SettingsProvider>().toggleUseSharedAxisTransition();
            },
            secondary: const Icon(Icons.open_in_new_rounded),
          ),
          const Divider(),
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
