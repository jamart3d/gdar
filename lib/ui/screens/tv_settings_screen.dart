import 'package:flutter/material.dart';
import 'package:shakedown/ui/widgets/settings/about_section.dart';
import 'package:shakedown/ui/widgets/settings/appearance_section.dart';
import 'package:shakedown/ui/widgets/settings/collection_statistics.dart';
import 'package:shakedown/ui/widgets/settings/data_section.dart';
import 'package:shakedown/ui/widgets/settings/interface_section.dart';
import 'package:shakedown/ui/widgets/settings/playback_section.dart';
import 'package:shakedown/ui/widgets/settings/source_filter_settings.dart';
import 'package:shakedown/ui/widgets/settings/usage_instructions_section.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/screens/rated_shows_screen.dart';
import 'package:shakedown/ui/screens/about_screen.dart';

class TvSettingsScreen extends StatefulWidget {
  const TvSettingsScreen({super.key});

  @override
  State<TvSettingsScreen> createState() => _TvSettingsScreenState();
}

class _TvSettingsScreenState extends State<TvSettingsScreen> {
  int _selectedIndex = 0;

  final List<String> _categories = [
    'Playback',
    'Appearance',
    'Interface',
    'Collection Statistics',
    'Sources',
    'Manage Rated Shows',
    'Help',
    'About',
  ];

  final List<IconData> _icons = [
    Icons.play_circle_outline_rounded,
    Icons.palette_outlined,
    Icons.view_quilt_outlined,
    Icons.bar_chart_rounded,
    Icons.filter_list_rounded,
    Icons.star_rounded,
    Icons.help_outline_rounded,
    Icons.info_outline_rounded,
  ];

  final Map<String, GlobalKey> _settingKeys = {};

  @override
  void initState() {
    super.initState();
    _settingKeys['prevent_screensaver'] = GlobalKey();
  }

  @override
  Widget build(BuildContext context) {
    // Determine which section to show
    Widget activeSection;
    // Common props for sections
    const scaleFactor = 1.0;
    const initiallyExpanded = true;
    // We expand all on TV because SectionCard handles "TV Mode" by being a Column

    switch (_selectedIndex) {
      case 0:
        activeSection = PlaybackSection(
          scaleFactor: scaleFactor,
          initiallyExpanded: initiallyExpanded,
          activeHighlightKey: null,
          highlightTriggerCount: 0,
          settingKeys: _settingKeys,
          onScrollToSetting: (_) {},
          isHighlightSettingMatching: false,
        );
        break;
      case 1:
        activeSection = AppearanceSection(
          scaleFactor: scaleFactor,
          initiallyExpanded: initiallyExpanded,
          showFontSelection: true,
        );
        break;
      case 2:
        activeSection = InterfaceSection(
          scaleFactor: scaleFactor,
          initiallyExpanded: initiallyExpanded,
        );
        break;
      case 3:
        activeSection = CollectionStatistics(
          initiallyExpanded: initiallyExpanded,
        );
        break;
      case 4:
        activeSection = const SourceFilterSettings();
        break;
      case 5:
        activeSection = const DataSection(
          scaleFactor: scaleFactor,
        );
        break;
      case 6:
        activeSection = UsageInstructionsSection(
          scaleFactor: scaleFactor,
          initiallyExpanded: initiallyExpanded,
        );
        break;
      case 7:
        activeSection = const AboutSection(
          scaleFactor: scaleFactor,
        );
        break;
      default:
        activeSection = const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Left Pane: Navigation
          Expanded(
            flex: 1,
            child: Container(
              color: colorScheme.surfaceContainer,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      children: [
                        Icon(Icons.settings_rounded,
                            size: 32, color: colorScheme.primary),
                        const SizedBox(width: 16),
                        Text(
                          'Settings',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurface,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedIndex == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: TvFocusWrapper(
                            onTap: () {
                              setState(() {
                                _selectedIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? colorScheme.primaryContainer
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    _icons[index],
                                    color: isSelected
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    _categories[index],
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? colorScheme.onPrimaryContainer
                                          : colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Vertical Divider
          VerticalDivider(width: 1, color: colorScheme.outlineVariant),
          // Right Pane: Content
          Expanded(
            flex: 2,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _selectedIndex == 5
                  ? const RatedShowsBody(key: ValueKey(5))
                  : _selectedIndex == 7
                      ? const SingleChildScrollView(
                          // About Body needs scrolling
                          key: ValueKey(7),
                          padding: EdgeInsets.all(32),
                          child: AboutBody(),
                        )
                      : SingleChildScrollView(
                          key: ValueKey(_selectedIndex),
                          padding: const EdgeInsets.all(32),
                          child: activeSection,
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
