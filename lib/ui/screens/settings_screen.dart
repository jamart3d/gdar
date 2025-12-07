import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/providers/theme_provider.dart';
import 'package:gdar/ui/screens/about_screen.dart';
import 'package:gdar/utils/color_generator.dart';
import 'package:gdar/ui/screens/rated_shows_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
              paletteType: PaletteType.hsl,
              pickerAreaHeightPercent: 0.0,
              enableAlpha: false,
              showLabel: false,
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

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  Widget _buildClickableLink(BuildContext context, String text, String url,
      {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: icon != null ? Icon(icon, color: colorScheme.primary) : null,
      title: Text(
        text,
        style: TextStyle(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
        ),
      ),
      onTap: () => _launchUrl(url),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    Color? backgroundColor;
    // Only apply custom background color if NOT in "True Black" mode.
    // True Black mode = Dark Mode + Custom Seed + No Dynamic Color.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode &&
        (!settingsProvider.useDynamicColor || settingsProvider.halfGlowDynamic);

    if (!isTrueBlackMode &&
        settingsProvider.highlightCurrentShowCard &&
        audioProvider.currentShow != null) {
      String seed = audioProvider.currentShow!.name;
      if (audioProvider.currentShow!.sources.length > 1 &&
          audioProvider.currentSource != null) {
        seed = audioProvider.currentSource!.id;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }

    return AnimatedTheme(
      data: Theme.of(context),
      duration: const Duration(milliseconds: 500),
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: settingsProvider.uiScale
              ? const TextScaler.linear(1.2)
              : const TextScaler.linear(1.0),
        ),
        child: Scaffold(
          backgroundColor: backgroundColor,
          appBar: AppBar(
            backgroundColor: backgroundColor,
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
                    subtitle: const Text('Enable Dark Mode'),
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
                    subtitle: const Text(
                        "Theme the app from your device's wallpaper"),
                    value: settingsProvider.useDynamicColor,
                    onChanged: (value) {
                      context.read<SettingsProvider>().toggleUseDynamicColor();
                    },
                    secondary: const Icon(Icons.color_lens_rounded),
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette_rounded),
                    title: const Text('Custom Theme Color'),
                    subtitle: const Text('Overrides the default theme color'),
                    enabled: !settingsProvider.useDynamicColor,
                    onTap: () => _showColorPickerDialog(context),
                    trailing: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: settingsProvider.seedColor ?? Colors.purple,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colorScheme.outline,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  if (settingsProvider.useDynamicColor)
                    SwitchListTile(
                      title: const Text('True Black And Half Glow'),
                      subtitle: const Text(
                          'Use true black background with reduced glow'),
                      value: settingsProvider.halfGlowDynamic,
                      onChanged: (value) {
                        context
                            .read<SettingsProvider>()
                            .toggleHalfGlowDynamic();
                      },
                      secondary: const Icon(Icons.light_mode_outlined),
                    ),
                  SwitchListTile(
                    title: const Text('Glow Border'),
                    subtitle:
                        const Text('Show a glowing gradient border on cards'),
                    value: settingsProvider.showGlowBorder,
                    onChanged: (value) {
                      context.read<SettingsProvider>().toggleShowGlowBorder();
                    },
                    secondary: const Icon(Icons.blur_on_rounded),
                  ),
                  SwitchListTile(
                    title: const Text('Highlight Playing with RGB'),
                    subtitle: const Text('Animate border with RGB colors'),
                    value: settingsProvider.highlightPlayingWithRgb,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .toggleHighlightPlayingWithRgb();
                    },
                    secondary: const Icon(Icons.animation_rounded),
                  ),
                  if (settingsProvider.highlightPlayingWithRgb)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RGB Animation Speed',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 8),
                          SegmentedButton<double>(
                            segments: const [
                              ButtonSegment(
                                value: 1.0,
                                label: Text('1x'),
                                icon: Icon(Icons.speed),
                              ),
                              ButtonSegment(
                                value: 0.5,
                                label: Text('0.5x'),
                              ),
                              ButtonSegment(
                                value: 0.25,
                                label: Text('0.25x'),
                              ),
                              ButtonSegment(
                                value: 0.1,
                                label: Text('0.1x'),
                              ),
                            ],
                            selected: {settingsProvider.rgbAnimationSpeed},
                            onSelectionChanged: (Set<double> newSelection) {
                              context
                                  .read<SettingsProvider>()
                                  .setRgbAnimationSpeed(newSelection.first);
                            },
                            showSelectedIcon: false,
                          ),
                        ],
                      ),
                    ),
                  SwitchListTile(
                    title: const Text('Handwriting Font'),
                    subtitle: const Text('Use a handwritten style font'),
                    value: settingsProvider.useHandwritingFont,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .toggleUseHandwritingFont();
                    },
                    secondary: const Icon(Icons.edit_rounded),
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
                    title: const Text('Hide Track Duration'),
                    subtitle:
                        const Text('Hide duration and center track titles'),
                    value: settingsProvider.hideTrackDuration,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .toggleHideTrackDuration();
                    },
                    secondary: const Icon(Icons.timer_off_rounded),
                  ),
                  SwitchListTile(
                    title: const Text('Sort Oldest First'),
                    subtitle: const Text('Show earliest shows at the top'),
                    value: settingsProvider.sortOldestFirst,
                    onChanged: (value) {
                      context.read<SettingsProvider>().toggleSortOldestFirst();
                    },
                    secondary: const Icon(Icons.sort_rounded),
                  ),
                  SwitchListTile(
                    title: const Text('Show date first in show cards'),
                    subtitle: const Text('Display the date before the venue'),
                    value: settingsProvider.dateFirstInShowCard,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .toggleDateFirstInShowCard();
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
                    title: const Text('UI Scale'),
                    subtitle: const Text('Increase text size across the app'),
                    value: settingsProvider.uiScale,
                    onChanged: (value) {
                      context.read<SettingsProvider>().toggleUiScale();
                    },
                    secondary: const Icon(Icons.text_fields_rounded),
                  ),
                  SwitchListTile(
                    title: const Text('Show Splash Screen'),
                    subtitle: const Text('Show a loading screen on startup'),
                    value: settingsProvider.showSplashScreen,
                    onChanged: (value) {
                      context.read<SettingsProvider>().toggleShowSplashScreen();
                    },
                    secondary: const Icon(Icons.rocket_launch_rounded),
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
                    subtitle:
                        const Text('Tap track in inactive source to play'),
                    value: settingsProvider.playOnTap,
                    onChanged: (value) {
                      context.read<SettingsProvider>().togglePlayOnTap();
                    },
                    secondary: const Icon(Icons.touch_app_rounded),
                  ),
                  SwitchListTile(
                    title: const Text('Play Random Show on Completion'),
                    subtitle: const Text(
                        'When a show ends, play another one randomly'),
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
                    subtitle: const Text(
                        'Start playing a random show when the app opens'),
                    value: settingsProvider.playRandomOnStartup,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .togglePlayRandomOnStartup();
                    },
                    secondary: const Icon(Icons.play_circle_filled_rounded),
                  ),
                  SwitchListTile(
                    title: const Text('Only Select Unplayed Shows'),
                    subtitle: const Text(
                        'Random playback will prefer unplayed shows'),
                    value: settingsProvider.randomOnlyUnplayed,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .toggleRandomOnlyUnplayed();
                    },
                    secondary: const Icon(Icons.new_releases_rounded),
                  ),
                  SwitchListTile(
                    title: const Text('Only Select High Rated Shows'),
                    subtitle: const Text(
                        'Random playback will prefer shows rated 2+ stars'),
                    value: settingsProvider.randomOnlyHighRated,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .toggleRandomOnlyHighRated();
                    },
                    secondary: const Icon(Icons.star_rounded),
                  ),
                  SwitchListTile(
                    title: const Text('Show Playback Messages'),
                    subtitle: const Text(
                        'Display detailed status, buffered time, and errors'),
                    value: settingsProvider.showPlaybackMessages,
                    onChanged: (value) {
                      context
                          .read<SettingsProvider>()
                          .toggleShowPlaybackMessages();
                    },
                    secondary: const Icon(Icons.message_rounded),
                  ),
                ],
              ),

              // Usage Instructions
              ExpansionTile(
                leading: const Icon(Icons.book),
                title: const Text('Usage Instructions'),
                children: [
                  ListTile(
                    leading: const Icon(Icons.shuffle_rounded),
                    title: const Text('Random Selection'),
                    subtitle: const Text(
                        'Tap the ? icon in the app bar to play a random show from the collection. Long-press a show card to play a random source from that show.'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.play_circle_outline_rounded),
                    title: const Text('Player Controls'),
                    subtitle: const Text(
                        'Tap the mini-player to open the full playback screen. Long-press the mini-player to stop playback and clear the queue.'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.search_rounded),
                    title: const Text('Search'),
                    subtitle: const Text(
                        'Tap the search icon in the app bar to filter shows by venue or date.'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.star_rate_rounded),
                    title: const Text('Rate Show'),
                    subtitle: const Text(
                        'Tap the stars icon on a show card to rate it.'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.block_rounded),
                    title: const Text('Quick Block'),
                    subtitle: const Text(
                        'Swipe left on a show card (or source) to quickly block it (-1 rating).'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.touch_app_rounded),
                    title: const Text('Expand Show'),
                    subtitle: const Text(
                        'Tap a show card to see available sources (SHNIDs).'),
                  ),
                  ListTile(
                    leading: const Icon(Icons.open_in_new_rounded),
                    title: const Text('View Source Page'),
                    subtitle: const Text(
                        'Tap a source ID (SHNID) to open the Internet Archive page.'),
                  ),
                ],
              ),

              // Statistics
              Builder(builder: (context) {
                final showListProvider = context.watch<ShowListProvider>();
                final allShows = showListProvider.allShows;

                int totalShows = allShows.length;
                int totalSources = 0;
                int totalSongs = 0;
                int totalDurationSeconds = 0;

                for (var show in allShows) {
                  totalSources += show.sources.length;
                  for (var source in show.sources) {
                    totalSongs += source.tracks.length;
                    for (var track in source.tracks) {
                      totalDurationSeconds += track.duration;
                    }
                  }
                }

                final duration = Duration(seconds: totalDurationSeconds);
                final days = duration.inDays;
                final hours = duration.inHours % 24;
                final minutes = duration.inMinutes % 60;

                // Rating Stats
                int playedCount = settingsProvider.playedShows.length;
                int unplayedCount = totalShows - playedCount; // Approximate
                int rated3 = settingsProvider.showRatings.values
                    .where((r) => r == 3)
                    .length;
                int rated2 = settingsProvider.showRatings.values
                    .where((r) => r == 2)
                    .length;
                int rated1 = settingsProvider.showRatings.values
                    .where((r) => r == 1)
                    .length;
                int ratedBlock = settingsProvider.showRatings.values
                    .where((r) => r == -1)
                    .length;

                return ExpansionTile(
                  leading: const Icon(Icons.bar_chart_rounded),
                  title: const Text('Collection Statistics'),
                  children: [
                    ListTile(
                      title: const Text('Total Shows'),
                      trailing: Text('$totalShows',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ListTile(
                      title: const Text('Total Sources (SHNIDs)'),
                      trailing: Text('$totalSources',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ListTile(
                      title: const Text('Total Songs'),
                      trailing: Text('$totalSongs',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ListTile(
                      title: const Text('Total Runtime'),
                      trailing: Text('${days}d ${hours}h ${minutes}m',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Played Shows'),
                      trailing: Text('$playedCount',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ListTile(
                      title: const Text('Unplayed Shows (Approx)'),
                      trailing: Text('$unplayedCount',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('3 Star Ratings'),
                      trailing: Text('$rated3',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ListTile(
                      title: const Text('2 Star Ratings'),
                      trailing: Text('$rated2',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ListTile(
                      title: const Text('1 Star Ratings'),
                      trailing: Text('$rated1',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    ListTile(
                      title: const Text('Blocked (Red Star)'),
                      trailing: Text('$ratedBlock',
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.library_books_rounded),
                      title: const Text('Manage Rated Shows'),
                      subtitle: const Text('View and unblock shows'),
                      trailing:
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const RatedShowsScreen()),
                        );
                      },
                    ),
                  ],
                );
              }),

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
              const SizedBox(height: 20),
              _buildClickableLink(
                context,
                'Consider donating to The Internet Archive',
                'https://archive.org/donate/',
                icon: Icons.favorite,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
