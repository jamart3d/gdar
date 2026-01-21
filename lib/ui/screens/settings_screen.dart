import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shakedown/providers/audio_provider.dart';
// import 'package:google_fonts/google_fonts.dart'; // Removed
import 'package:shakedown/providers/settings_provider.dart';

import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/screens/about_screen.dart';
import 'package:shakedown/utils/color_generator.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:shakedown/ui/widgets/settings/source_filter_settings.dart';
import 'package:shakedown/ui/widgets/settings/collection_statistics.dart';
import 'package:shakedown/ui/screens/rated_shows_screen.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart'; // Add import
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsScreen extends StatefulWidget {
  final String? highlightSetting;

  const SettingsScreen({super.key, this.highlightSetting});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, GlobalKey> _settingKeys = {};

  @override
  void initState() {
    super.initState();
    // Register keys for highlightable settings
    if (widget.highlightSetting != null) {
      _settingKeys[widget.highlightSetting!] = GlobalKey();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlight();
      });
    }
  }

  void _scrollToHighlight() {
    final key = _settingKeys[widget.highlightSetting];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubicEmphasized,
        alignment: 0.5, // Center in viewport
      );
    }
  }

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

  void _showFontSelectionDialog(BuildContext context) {
    final settingsProvider = context.read<SettingsProvider>();
    // Map of internal value to display name and TextStyle
    final Map<String, TextStyle?> fonts = {
      'default': null,
      'caveat': const TextStyle(fontFamily: 'Caveat'),
      'permanent_marker': const TextStyle(fontFamily: 'Permanent Marker'),
      'rock_salt': const TextStyle(fontFamily: 'RockSalt'),
    };

    final Map<String, String> displayNames = {
      'default': 'Default (Roboto)',
      'caveat': 'Caveat',
      'permanent_marker': 'Permanent Marker',
      'rock_salt': 'Rock Salt',
    };

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select App Font'),
          content: SingleChildScrollView(
            child: RadioGroup<String>(
              groupValue: settingsProvider.appFont,
              onChanged: (String? value) {
                if (value != null) {
                  settingsProvider.setAppFont(value);
                  Navigator.of(context).pop();
                }
              },
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: fonts.entries.map((entry) {
                  return RadioListTile<String>(
                    title: Text(
                      displayNames[entry.key]!,
                      style: entry.value?.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    value: entry.key,
                  );
                }).toList(),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _getFontDisplayName(String fontKey) {
    switch (fontKey) {
      case 'caveat':
        return 'Caveat';
      case 'permanent_marker':
        return 'Permanent Marker';

      case 'rock_salt':
        return 'Rock Salt';
      default:
        return 'Default (Roboto)';
    }
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
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

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

    // Create a theme that includes the background color override if applicable
    final baseTheme = Theme.of(context);
    final effectiveBackgroundColor =
        backgroundColor ?? baseTheme.scaffoldBackgroundColor;

    final effectiveTheme = baseTheme.copyWith(
      scaffoldBackgroundColor: effectiveBackgroundColor,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: effectiveBackgroundColor,
        surfaceTintColor:
            Colors.transparent, // Disable tint to align with scaffold
      ),
    );

    return AnimatedTheme(
      data: effectiveTheme,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: settingsProvider.uiScale
              ? const TextScaler.linear(1.2)
              : const TextScaler.linear(1.0),
        ),
        child: Scaffold(
          // No explicit background color needed; inherits from Theme
          body: CustomScrollView(
            slivers: [
              const SliverAppBar.large(
                title: Text('Settings'),
                // No explicit background color needed
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
                                      ' the ? icon in the app bar to play a random show. Selection respects "Random\u00A0Playback"\u00A0settings.\n'),
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
                                      ' the mini-player to open the full playback\u00A0screen.\n'),
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
                        leading: const Icon(Icons.link_rounded),
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
                      ListTile(
                        leading: const Icon(Icons.copy_rounded),
                        title: const Text('Share Track with Friends'),
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
                                      ' the share icon on the playback screen to copy track details to your clipboard. Send this to a friend!'),
                            ],
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.content_paste_rounded),
                        title: const Text('Play from Shared Link'),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context).textTheme.bodyMedium,
                            children: const [
                              TextSpan(
                                  text: 'Paste',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' a shared link into the search bar to instantly start playback at that track. The app will scroll to the show and navigate to the player automatically.'),
                            ],
                          ),
                        ),
                        isThreeLine: true,
                      ),
                    ],
                  ),

                  SectionCard(
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
                    children: [
                      SwitchListTile(
                        title: const Text('Dark'),
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
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
                        subtitle: const Text('Theme from wallpaper'),
                        value: settingsProvider.useDynamicColor,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          context
                              .read<SettingsProvider>()
                              .toggleUseDynamicColor();
                        },
                        secondary: const Icon(Icons.color_lens_rounded),
                      ),
                      // True Black Mode (only in Dark Mode)
                      if (isDarkMode)
                        SwitchListTile(
                          title: const Text('True Black'),
                          subtitle: const Text('Shadows and blur disabled'),
                          value: settingsProvider.useTrueBlack,
                          onChanged: (value) {
                            HapticFeedback.lightImpact();
                            context
                                .read<SettingsProvider>()
                                .toggleUseTrueBlack();
                          },
                          secondary: const Icon(Icons.brightness_1_rounded),
                        ),
                      if (!settingsProvider.useDynamicColor)
                        ListTile(
                          leading: const Icon(Icons.palette_rounded),
                          title: const Text('Custom Theme Color'),
                          subtitle:
                              const Text('Overrides the default theme color'),
                          onTap: () => _showColorPickerDialog(context),
                          trailing: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color:
                                  settingsProvider.seedColor ?? Colors.purple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.outline,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      SwitchListTile(
                        title: const Text('Glow Border'),
                        value: settingsProvider.glowMode > 0,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .setGlowMode(value ? 100 : 0); // Full or Off
                        },
                        secondary: const Icon(Icons.blur_on_rounded),
                      ),
                      if (settingsProvider.glowMode > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      'Intensity',
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                    ),
                                    Expanded(
                                      child: Slider(
                                        value: settingsProvider.glowMode
                                            .toDouble(),
                                        min: 10,
                                        max: 100,
                                        divisions: 18, // 10, 15, 20, ..., 100
                                        onChanged: (value) {
                                          context
                                              .read<SettingsProvider>()
                                              .setGlowMode(value.round());
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 40,
                                      child: Text(
                                        '${settingsProvider.glowMode}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                    const SizedBox(
                                        width: 16), // Balance spacing
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                              AnimatedGradientBorder(
                                borderRadius:
                                    24, // Matches standard SegmentedButton radius
                                borderWidth: 3,
                                colors: const [
                                  Colors.red,
                                  Colors.yellow,
                                  Colors.green,
                                  Colors.cyan,
                                  Colors.blue,
                                  Colors.purple,
                                  Colors.red,
                                ],
                                showGlow: true,
                                // Glow mirrors the global logic:
                                // If "Glow Border" is ON (1) or HALF (2), we show shadow.
                                showShadow: settingsProvider.glowMode > 0,
                                // Use percentage-based glow intensity
                                glowOpacity:
                                    0.5 * (settingsProvider.glowMode / 100.0),
                                animationSpeed:
                                    settingsProvider.rgbAnimationSpeed,
                                // Ignore global clock locally so the preview animates even if the
                                // global clock is paused by the ShowListScreen behind us.
                                ignoreGlobalClock: true,
                                // Transparent background to blend with SectionCard
                                backgroundColor: Colors.transparent,
                                child: SegmentedButton<double>(
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
                                  selected: {
                                    settingsProvider.rgbAnimationSpeed
                                  },
                                  onSelectionChanged:
                                      (Set<double> newSelection) {
                                    context
                                        .read<SettingsProvider>()
                                        .setRgbAnimationSpeed(
                                            newSelection.first);
                                  },
                                  showSelectedIcon: false,
                                  style: ButtonStyle(
                                    // Match proper inner radius (24 - 3 = 21)
                                    shape: WidgetStateProperty.all(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(21)),
                                    ),
                                    // Make border transparent to let gradient show
                                    side: WidgetStateProperty.all(
                                        BorderSide.none),
                                    backgroundColor:
                                        WidgetStateProperty.resolveWith<Color?>(
                                      (states) {
                                        // Always use transparent background for a cleaner look
                                        // Rely on text color to show selection
                                        return Colors.transparent;
                                      },
                                    ),
                                    foregroundColor:
                                        WidgetStateProperty.resolveWith<Color?>(
                                      (states) {
                                        if (states
                                            .contains(WidgetState.selected)) {
                                          return Theme.of(context)
                                              .colorScheme
                                              .primary;
                                        }
                                        // Unselected: Use white70 in dark mode for contrast, or default grey
                                        final isDark =
                                            Theme.of(context).brightness ==
                                                Brightness.dark;
                                        return isDark ? Colors.white70 : null;
                                      },
                                    ),
                                    textStyle: WidgetStateProperty.resolveWith<
                                        TextStyle?>(
                                      (states) {
                                        // Rock Salt doesn't support bold well, and we rely on color for highlight.
                                        // Returning null allows it to inherit the Theme's labelLarge (which has the correct font).
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ListTile(
                        leading: const Icon(Icons.text_format_rounded),
                        title: const Text('App Font'),
                        subtitle:
                            Text(_getFontDisplayName(settingsProvider.appFont)),
                        onTap: () => _showFontSelectionDialog(context),
                      ),
                    ],
                  ),

                  SectionCard(
                    title: 'Interface',
                    icon: Icons.view_quilt_outlined,
                    children: [
                      // 1. General UI Group
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
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),

                      // 2. Date & Time Group
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
                        title: const Text('Show Day of Week'),
                        subtitle: const Text('Includes the day name in dates'),
                        value: settingsProvider.showDayOfWeek,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleShowDayOfWeek();
                        },
                        secondary: const Icon(Icons.today_rounded),
                      ),
                      if (settingsProvider.showDayOfWeek)
                        SwitchListTile(
                          title: const Text('Abbreviate Day of Week'),
                          subtitle:
                              const Text('Use short day names (e.g., Sat)'),
                          value: settingsProvider.abbreviateDayOfWeek,
                          onChanged: (value) {
                            context
                                .read<SettingsProvider>()
                                .toggleAbbreviateDayOfWeek();
                          },
                          secondary: const Icon(Icons.short_text_rounded),
                        ),
                      SwitchListTile(
                        title: const Text('Abbreviate Month'),
                        subtitle:
                            const Text('Use short month names (e.g., Aug)'),
                        value: settingsProvider.abbreviateMonth,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleAbbreviateMonth();
                        },
                        secondary:
                            const Icon(Icons.calendar_view_month_rounded),
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),

                      // 3. List Sorting & Badges
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
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),

                      // 4. Track List Options
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
                      SwitchListTile(
                        title: const Text('Exclude Played from Random'),
                        subtitle: const Text(
                            'Removes played shows from the selection pool'),
                        value: settingsProvider.randomExcludePlayed,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleRandomExcludePlayed();
                        },
                        secondary: const Icon(Icons.history_toggle_off_rounded),
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
                                  isActive: !settingsProvider
                                          .randomOnlyUnplayed &&
                                      !settingsProvider.randomExcludePlayed),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SectionCard(
                    title: 'Playback',
                    icon: Icons.play_circle_outline,
                    initiallyExpanded:
                        widget.highlightSetting == 'play_on_tap' ||
                            widget.highlightSetting == 'playback_messages',
                    children: [
                      _HighlightableSetting(
                        startWithHighlight:
                            widget.highlightSetting == 'play_on_tap',
                        settingKey: _settingKeys['play_on_tap'],
                        child: SwitchListTile(
                          title: const Text('Play on Tap'),
                          subtitle: const Text(
                              'Tap track in inactive source to play'),
                          value: settingsProvider.playOnTap,
                          onChanged: (value) {
                            HapticFeedback.lightImpact();
                            context.read<SettingsProvider>().togglePlayOnTap();
                          },
                          secondary: const Icon(Icons.touch_app_rounded),
                        ),
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
                        .withValues(alpha: 0.3),
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
                        .withValues(alpha: 0.3),
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

class _HighlightableSetting extends StatefulWidget {
  final Widget child;
  final bool startWithHighlight;
  final GlobalKey? settingKey;

  const _HighlightableSetting({
    required this.child,
    this.startWithHighlight = false,
    this.settingKey,
  });

  @override
  State<_HighlightableSetting> createState() => _HighlightableSettingState();
}

class _HighlightableSettingState extends State<_HighlightableSetting>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));

    // Wait until build context is available to read theme
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colorScheme = Theme.of(context).colorScheme;
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.startWithHighlight) {
      // Pulse 3 times
      _controller.forward().then((_) => _controller.reverse().then((_) =>
          _controller.forward().then((_) => _controller.reverse().then((_) =>
              _controller.forward().then((_) => _controller.reverse())))));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          key: widget.settingKey,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
