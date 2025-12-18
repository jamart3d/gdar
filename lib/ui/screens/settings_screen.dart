import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';

import 'package:gdar/providers/theme_provider.dart';
import 'package:gdar/ui/screens/about_screen.dart';
import 'package:gdar/utils/color_generator.dart';
import 'package:gdar/ui/widgets/section_card.dart';
import 'package:gdar/ui/widgets/settings/source_filter_settings.dart';
import 'package:gdar/ui/widgets/settings/collection_statistics.dart';
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
              labelTypes: const [],
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

  Widget _buildWeightRow(BuildContext context, String label, String weight,
      {required bool isActive, bool isBest = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: textStyle?.copyWith(
              color: isActive
                  ? (isBest ? colorScheme.primary : colorScheme.onSurface)
                  : colorScheme.outline,
              decoration: isActive ? null : TextDecoration.lineThrough,
              fontWeight:
                  isBest && isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            isActive ? weight : 'Excluded',
            style: textStyle?.copyWith(
              color: isActive
                  ? (isBest
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant)
                  : colorScheme.outline,
              fontWeight:
                  isBest && isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: isActive ? null : 12,
            ),
          ),
        ],
      ),
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
          body: CustomScrollView(
            slivers: [
              SliverAppBar.large(
                backgroundColor: backgroundColor,
                title: const Text('Settings'),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  SectionCard(
                    title: 'Usage Instructions',
                    icon: Icons.help_outline,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.shuffle_rounded),
                        title: const Text('Random Selection'),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                  text: 'Tap',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' the ? icon in the app bar to play a random show. Selection respects "Random\u00A0Playback"\u00A0settings. '),
                              TextSpan(
                                  text: 'Long-press',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' a show card to play a random source from\u00A0that\u00A0show.'),
                            ],
                          ),
                        ),
                        isThreeLine: true,
                      ),
                      ListTile(
                        leading: const Icon(Icons.play_circle_outline_rounded),
                        title: const Text('Player Controls'),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                  text: 'Tap',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' the mini-player to open the full playback\u00A0screen. '),
                              TextSpan(
                                  text: 'Long-press',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' the mini-player to stop playback and clear\u00A0the\u00A0queue.'),
                            ],
                          ),
                        ),
                        isThreeLine: true,
                      ),
                      ListTile(
                        leading: const Icon(Icons.search_rounded),
                        title: const Text('Search'),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                  text: 'Tap',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' the search icon in the app bar to filter shows by venue\u00A0or\u00A0date.'),
                            ],
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.star_rate_rounded),
                        title: const Text('Rate Show'),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                  text: 'Tap',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' the stars icon on a show card to\u00A0rate\u00A0it.'),
                            ],
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.block_rounded),
                        title: const Text('Quick Block'),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                  text: 'Swipe left',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' on a show card (or source) to quickly block it\u00A0(-1\u00A0rating).'),
                            ],
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.touch_app_rounded),
                        title: const Text('Expand Show'),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                  text: 'Tap',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' a show card to see available sources (SHNIDs) (if Source Filtering\u00A0-\u00A0Highest\u00A0SHNID\u00A0is\u00A0off).'),
                            ],
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.open_in_new_rounded),
                        title: const Text('View Source Page'),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                  text: 'Tap',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' a source ID (SHNID) to open the Internet Archive\u00A0page.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SectionCard(
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
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
                          context
                              .read<SettingsProvider>()
                              .toggleUseDynamicColor();
                        },
                        secondary: const Icon(Icons.color_lens_rounded),
                      ),
                      ListTile(
                        leading: const Icon(Icons.palette_rounded),
                        title: const Text('Custom Theme Color'),
                        subtitle:
                            const Text('Overrides the default theme color'),
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
                        subtitle: const Text(
                            'Show a glowing gradient border on cards'),
                        value: settingsProvider.showGlowBorder,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleShowGlowBorder();
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

                  SectionCard(
                    title: 'Interface',
                    icon: Icons.view_quilt_outlined,
                    children: [
                      SwitchListTile(
                        title: const Text('Show Track Numbers'),
                        subtitle: const Text('Display track numbers in lists'),
                        value: settingsProvider.showTrackNumbers,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleShowTrackNumbers();
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
                          context
                              .read<SettingsProvider>()
                              .toggleSortOldestFirst();
                        },
                        secondary: const Icon(Icons.sort_rounded),
                      ),
                      SwitchListTile(
                        title: const Text('Show date first in show cards'),
                        subtitle:
                            const Text('Display the date before the venue'),
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
                          context
                              .read<SettingsProvider>()
                              .toggleShowSingleShnid();
                        },
                        secondary: const Icon(Icons.looks_one_rounded),
                      ),
                      SwitchListTile(
                        title: const Text('UI Scale'),
                        subtitle:
                            const Text('Increase text size across the app'),
                        value: settingsProvider.uiScale,
                        onChanged: (value) {
                          context.read<SettingsProvider>().toggleUiScale();
                        },
                        secondary: const Icon(Icons.text_fields_rounded),
                      ),
                      SwitchListTile(
                        title: const Text('Show Splash Screen'),
                        subtitle:
                            const Text('Show a loading screen on startup'),
                        value: settingsProvider.showSplashScreen,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleShowSplashScreen();
                        },
                        secondary: const Icon(Icons.rocket_launch_rounded),
                      ),
                    ],
                  ),

                  const SourceFilterSettings(),

                  SectionCard(
                    title: 'Random Playback',
                    icon: Icons.shuffle_rounded,
                    children: [
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
                        secondary: const Icon(Icons.repeat_rounded),
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
                        secondary: const Icon(Icons.start_rounded),
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
                      Card(
                        margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Selection Probability',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              _buildWeightRow(context, 'Unplayed', '50x',
                                  isActive: true, // Always active
                                  isBest: true),
                              _buildWeightRow(context, '3 Stars', '30x',
                                  isActive:
                                      !settingsProvider.randomOnlyUnplayed),
                              _buildWeightRow(context, '2 Stars', '20x',
                                  isActive:
                                      !settingsProvider.randomOnlyUnplayed),
                              _buildWeightRow(context, '1 Star', '10x',
                                  isActive: !settingsProvider
                                          .randomOnlyUnplayed &&
                                      !settingsProvider.randomOnlyHighRated),
                              _buildWeightRow(context, 'Played', '5x',
                                  isActive:
                                      !settingsProvider.randomOnlyUnplayed),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SectionCard(
                    title: 'Playback',
                    icon: Icons.play_circle_outline,
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

                  // Statistics
                  // Collection Statistics
                  const CollectionStatistics(),

                  // Manage Rated Shows (Moved out of Collection Statistics)
                  Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    child: ListTile(
                      leading: Icon(Icons.library_books_rounded,
                          color: Theme.of(context).colorScheme.primary),
                      title: Text(
                        'Manage Rated Shows',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
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
                  ),

                  // About Section (Not collapsible)
                  Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    elevation: 0,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(
                            'About App',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 18),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const AboutScreen()),
                            );
                          },
                        ),
                        _buildClickableLink(
                          context,
                          'Consider donating to The Internet Archive',
                          'https://archive.org/donate/',
                          icon: Icons.favorite,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 50), // Bottom padding
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
