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
import 'package:shakedown/utils/font_layout_config.dart';
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
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
    // Map of internal value to display name and TextStyle
    final Map<String, TextStyle?> fonts = {
      'default': const TextStyle(fontFamily: 'Roboto'), // Enforce Roboto
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
                        fontSize: 18 * scaleFactor,
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

  Widget _buildClickableLink(
      BuildContext context, String text, String url, double scaleFactor,
      {IconData? icon}) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: icon != null ? Icon(icon, color: colorScheme.primary) : null,
      title: Text(
        text,
        style: TextStyle(
          color: colorScheme.primary,
          decoration: TextDecoration.underline,
          fontSize: 12.0 * scaleFactor,
        ),
      ),
      onTap: () => _launchUrl(url),
    );
  }

  Widget _buildWeightRow(
      BuildContext context, String label, String weight, double scaleFactor,
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
              fontSize: 12.0 * scaleFactor,
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
              fontSize: 12.0 * scaleFactor,
              color: isActive
                  ? (isBest
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant)
                  : colorScheme.outline,
              fontWeight:
                  isBest && isActive ? FontWeight.bold : FontWeight.normal,
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
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

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
                    scaleFactor: scaleFactor,
                    title: 'Usage Instructions',
                    icon: Icons.help_outline,
                    children: [
                      ListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.shuffle_rounded),
                        title: Text('Random Selection',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12.0 * scaleFactor),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.play_circle_outline_rounded),
                        title: Text('Player Controls',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12.0 * scaleFactor),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.search_rounded),
                        title: Text('Search',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12.0 * scaleFactor),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.star_rate_rounded),
                        title: Text('Rate Show',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12.0 * scaleFactor),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.block_rounded),
                        title: Text('Quick Block',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12.0 * scaleFactor),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.touch_app_rounded),
                        title: Text('Expand Show',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12.0 * scaleFactor),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.link_rounded),
                        title: Text('View Source Page',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12.0 * scaleFactor),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.copy_rounded),
                        title: Text('Share Track with Friends',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12.0 * scaleFactor),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.content_paste_rounded),
                        title: Text('Play from Shared Link',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text.rich(
                          TextSpan(
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 12.0 * scaleFactor),
                            children: const [
                              TextSpan(
                                  text: 'Paste',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                  text:
                                      ' a shared track link from your clipboard into search to jump directly to it.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  SectionCard(
                    scaleFactor: scaleFactor,
                    title: 'Appearance',
                    icon: Icons.palette_outlined,
                    children: [
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Dark',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Dynamic Color',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text('Theme from wallpaper',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
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
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text('True Black',
                              style: TextStyle(fontSize: 15 * scaleFactor)),
                          subtitle: Text('Shadows and blur disabled',
                              style: TextStyle(fontSize: 12.0 * scaleFactor)),
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
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: const Icon(Icons.palette_rounded),
                          title: Text('Custom Theme Color',
                              style: TextStyle(fontSize: 15 * scaleFactor)),
                          subtitle: Text('Overrides the default theme color',
                              style: TextStyle(fontSize: 12.0 * scaleFactor)),
                          onTap: () => _showColorPickerDialog(context),
                          trailing: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color:
                                  settingsProvider.seedColor ?? Colors.purple,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.outline,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Glow Border',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        value: settingsProvider.glowMode > 0,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .setGlowMode(value ? 65 : 0); // 65% or Off
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              fontSize: 12.0 * scaleFactor),
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
                                      width: 35 * scaleFactor,
                                      child: Text(
                                        '${settingsProvider.glowMode}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                                fontSize: 12.0 * scaleFactor),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Highlight Playing with RGB',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text('Animate border with RGB colors',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        value: settingsProvider.highlightPlayingWithRgb,
                        onChanged: (value) {
                          final provider = context.read<SettingsProvider>();
                          provider.toggleHighlightPlayingWithRgb();
                          // If turning RGB OFF and True Black is ON, turn off Glow too
                          if (!value && provider.useTrueBlack) {
                            provider.setGlowMode(0);
                          }
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
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontSize: 12.0 * scaleFactor),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        leading: const Icon(Icons.text_format_rounded),
                        title: Text('App Font',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text(
                            _getFontDisplayName(settingsProvider.appFont),
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        onTap: () => _showFontSelectionDialog(context),
                      ),
                    ],
                  ),

                  SectionCard(
                    scaleFactor: scaleFactor,
                    title: 'Interface',
                    icon: Icons.view_quilt_outlined,
                    children: [
                      // 1. General UI Group
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('UI Scale',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text('Increase text size across the app',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        value: settingsProvider.uiScale,
                        onChanged: (value) {
                          context.read<SettingsProvider>().toggleUiScale();
                        },
                        secondary: const Icon(Icons.text_fields_rounded),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Show Splash Screen',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text('Show a loading screen on startup',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Show date first in show cards',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text('Display the date before the venue',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        value: settingsProvider.dateFirstInShowCard,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleDateFirstInShowCard();
                        },
                        secondary: const Icon(Icons.date_range_rounded),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Show Day of Week',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text('Includes the day name in dates',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
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
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text('Abbreviate Day of Week',
                              style: TextStyle(fontSize: 15 * scaleFactor)),
                          subtitle: Text('Use short day names (e.g., Sat)',
                              style: TextStyle(fontSize: 12.0 * scaleFactor)),
                          value: settingsProvider.abbreviateDayOfWeek,
                          onChanged: (value) {
                            context
                                .read<SettingsProvider>()
                                .toggleAbbreviateDayOfWeek();
                          },
                          secondary: const Icon(Icons.short_text_rounded),
                        ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Abbreviate Month',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text('Use short month names (e.g., Aug)',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Sort Oldest First',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text('Show earliest shows at the top',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        value: settingsProvider.sortOldestFirst,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleSortOldestFirst();
                        },
                        secondary: const Icon(Icons.sort_rounded),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Show SHNID Badge (Single Source)',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text(
                            'Display SHNID number on card if only one source',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
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
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Show Track Numbers',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text('Display track numbers in lists',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        value: settingsProvider.showTrackNumbers,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleShowTrackNumbers();
                        },
                        secondary: const Icon(Icons.pin_rounded),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Hide Track Duration',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text('Hide duration and center track titles',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
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
                    scaleFactor: scaleFactor,
                    title: 'Random Playback',
                    icon: Icons.shuffle_rounded,
                    children: [
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Play Random Show on Completion',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text(
                            'When a show ends, play another one randomly',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        value: settingsProvider.playRandomOnCompletion,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .togglePlayRandomOnCompletion();
                        },
                        secondary: const Icon(Icons.repeat_rounded),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Play Random Show on Startup',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text(
                            'Start playing a random show when the app opens',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        value: settingsProvider.playRandomOnStartup,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .togglePlayRandomOnStartup();
                        },
                        secondary: const Icon(Icons.start_rounded),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Only Select Unplayed Shows',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text(
                            'Random playback will prefer unplayed shows',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        value: settingsProvider.randomOnlyUnplayed,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleRandomOnlyUnplayed();
                        },
                        secondary: const Icon(Icons.new_releases_rounded),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Only Select High Rated Shows',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text(
                            'Random playback will prefer shows rated 2+ stars',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        value: settingsProvider.randomOnlyHighRated,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleRandomOnlyHighRated();
                        },
                        secondary: const Icon(Icons.star_rate_rounded),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Exclude Already Played Shows',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text(
                            'Random playback will never select shows you have played',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
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
                                      fontSize: 12.0 * scaleFactor,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              _buildWeightRow(
                                  context, 'Unplayed', '50x', scaleFactor,
                                  isActive: true, // Always active
                                  isBest: true),
                              _buildWeightRow(
                                  context, '3 Stars', '30x', scaleFactor,
                                  isActive:
                                      !settingsProvider.randomOnlyUnplayed),
                              _buildWeightRow(
                                  context, '2 Stars', '20x', scaleFactor,
                                  isActive:
                                      !settingsProvider.randomOnlyUnplayed),
                              _buildWeightRow(
                                  context, '1 Star', '10x', scaleFactor,
                                  isActive: !settingsProvider
                                          .randomOnlyUnplayed &&
                                      !settingsProvider.randomOnlyHighRated),
                              _buildWeightRow(
                                  context, 'Played', '5x', scaleFactor,
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
                    scaleFactor: scaleFactor,
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
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text('Play on Tap',
                              style: TextStyle(fontSize: 15 * scaleFactor)),
                          subtitle: Text('Tap track in inactive source to play',
                              style: TextStyle(fontSize: 12.0 * scaleFactor)),
                          value: settingsProvider.playOnTap,
                          onChanged: (value) {
                            HapticFeedback.lightImpact();
                            context.read<SettingsProvider>().togglePlayOnTap();
                          },
                          secondary: const Icon(Icons.touch_app_rounded),
                        ),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Show Playback Messages',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text(
                            'Display detailed status, buffered time, and errors',
                            style: TextStyle(fontSize: 12.0 * scaleFactor)),
                        value: settingsProvider.showPlaybackMessages,
                        onChanged: (value) {
                          context
                              .read<SettingsProvider>()
                              .toggleShowPlaybackMessages();
                        },
                        secondary: const Icon(Icons.message_rounded),
                      ),
                      SwitchListTile(
                        dense: true,
                        visualDensity: VisualDensity.compact,
                        title: Text('Advanced Cache',
                            style: TextStyle(fontSize: 15 * scaleFactor)),
                        subtitle: Text(
                          settingsProvider.offlineBuffering
                              ? 'Cached ${audioProvider.cachedTrackCount} of (${audioProvider.currentSource?.tracks.length ?? 0} + 5) tracks'
                              : 'Cache tracks to disk for deep sleep playback',
                          style: TextStyle(fontSize: 12.0 * scaleFactor),
                        ),
                        value: settingsProvider.offlineBuffering,
                        onChanged: (value) {
                          HapticFeedback.lightImpact();
                          context
                              .read<SettingsProvider>()
                              .toggleOfflineBuffering();
                        },
                        secondary:
                            const Icon(Icons.download_for_offline_rounded),
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
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      leading: Icon(Icons.library_books_rounded,
                          color: Theme.of(context).colorScheme.primary),
                      title: Text(
                        'Manage Rated Shows',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14 * scaleFactor,
                        ),
                      ),
                      trailing:
                          const Icon(Icons.arrow_forward_ios_rounded, size: 12),
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
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          leading: Icon(Icons.info_outline,
                              color: Theme.of(context).colorScheme.primary),
                          title: Text(
                            'About App',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14 * scaleFactor),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded,
                              size: 12),
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
                          scaleFactor,
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
