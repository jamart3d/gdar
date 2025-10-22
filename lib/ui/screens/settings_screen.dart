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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
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
          const Divider(),
          SwitchListTile(
            title: const Text('Show Track Numbers'),
            subtitle: const Text('Display track numbers in lists'),
            value: settingsProvider.showTrackNumbers,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleShowTrackNumbers();
            },
            secondary: const Icon(Icons.pin_rounded),
          ),
          const Divider(),
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
          SwitchListTile(
            title: const Text('Show SHNID Badge (Single Source)'),
            subtitle: const Text('Display SHNID number on card if only one source'),
            value: settingsProvider.showSingleShnid,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleShowSingleShnid();
            },
            secondary: const Icon(Icons.looks_one_rounded),
          ),
          const Divider(),
          // New SwitchListTile for hiding track count
          SwitchListTile(
            title: const Text('Hide Track Count in Source List'),
            subtitle: const Text('Hide "X tracks" next to SHNID in expanded view'),
            value: settingsProvider.hideTrackCountInSourceList,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleHideTrackCountInSourceList();
            },
            secondary: const Icon(Icons.format_list_numbered_rtl_rounded), // Example icon
          ),
          const Divider(),
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

