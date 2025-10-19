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
            subtitle: const Text('Display the track number in the player'),
            value: settingsProvider.showTrackNumbers,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleShowTrackNumbers();
            },
            secondary: const Icon(Icons.pin_rounded),
          ),
          const Divider(),
          // The "Hide gd*" SwitchListTile has been removed.
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

