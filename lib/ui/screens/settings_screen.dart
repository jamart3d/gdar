import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/settings/about_section.dart';
import 'package:shakedown/ui/widgets/settings/appearance_section.dart';
import 'package:shakedown/ui/widgets/settings/collection_statistics.dart';
import 'package:shakedown/ui/widgets/settings/data_section.dart';
import 'package:shakedown/ui/widgets/settings/interface_section.dart';
import 'package:shakedown/ui/widgets/settings/playback_section.dart';
import 'package:shakedown/ui/widgets/settings/source_filter_settings.dart';
import 'package:shakedown/ui/widgets/settings/usage_instructions_section.dart';
import 'package:shakedown/utils/color_generator.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/providers/update_provider.dart';
import 'package:shakedown/ui/widgets/onboarding/update_banner.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/screens/tv_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String? highlightSetting;
  final bool showFontSelection;

  const SettingsScreen({
    super.key,
    this.highlightSetting,
    this.showFontSelection = false,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, GlobalKey> _settingKeys = {};
  bool _playbackExpanded = false;
  String? _activeHighlightKey;
  int _highlightTriggerCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.highlightSetting != null) {
      _settingKeys[widget.highlightSetting!] = GlobalKey();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToHighlight();
      });
    }
    // Pre-register offline_buffering key so we can scroll to it if needed
    if (!_settingKeys.containsKey('offline_buffering')) {
      _settingKeys['offline_buffering'] = GlobalKey();
    }
    if (!_settingKeys.containsKey('enable_buffer_agent')) {
      _settingKeys['enable_buffer_agent'] = GlobalKey();
    }
  }

  void _scrollToSetting(String settingKey) {
    bool needsStateUpdate = false;
    // If target is in a collapsed section, expand it first
    if (settingKey == 'offline_buffering' ||
        settingKey == 'play_on_tap' ||
        settingKey == 'playback_messages' ||
        settingKey == 'enable_buffer_agent' ||
        settingKey == 'random_playback') {
      if (!_playbackExpanded) {
        needsStateUpdate = true;
        _playbackExpanded = true;
      }
    }

    setState(() {
      if (needsStateUpdate) {
        _playbackExpanded = true;
      }
      _activeHighlightKey = settingKey;
      _highlightTriggerCount++;
    });

    // Give it a small delay to ensure the new widgets are in the tree and rendered
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final key = _settingKeys[settingKey];
      if (key?.currentContext != null) {
        Scrollable.ensureVisible(
          key!.currentContext!,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubicEmphasized,
          alignment: 0.5,
        );
      }
    });
  }

  void _scrollToHighlight() {
    final key = _settingKeys[widget.highlightSetting];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubicEmphasized,
        alignment: 0.5,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    final updateProvider = context.watch<UpdateProvider>();

    // Check for TV mode and return dedicated screen
    if (context.read<DeviceService>().isTv) {
      // We need to pass necessary props if any, or TvSettingsScreen manages its own state.
      // The current settings screen manages `highlightSetting` which might be deep-linked.
      // TvSettingsScreen doesn't support deep-linking yet, but we can add it later.
      return const TvSettingsScreen();
    }

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
              ? TextScaler.linear(
                  settingsProvider.appFont == 'rock_salt' ? 1.0 : 1.2)
              : const TextScaler.linear(1.0),
        ),
        child: Scaffold(
          // No explicit background color needed; inherits from Theme
          body: CustomScrollView(
            slivers: [
              const SliverAppBar.large(
                title: Text('Settings'),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: UpdateBanner(
                      updateInfo: updateProvider.updateInfo,
                      isSimulated: updateProvider.isSimulated,
                      onUpdateSelected: () => updateProvider.startUpdate(),
                      scaleFactor: scaleFactor,
                    ),
                  ),
                  UsageInstructionsSection(
                    scaleFactor: scaleFactor,
                    initiallyExpanded:
                        widget.highlightSetting == 'usage_instructions',
                  ),
                  AppearanceSection(
                    scaleFactor: scaleFactor,
                    initiallyExpanded: widget.highlightSetting == 'appearance',
                    showFontSelection: widget.showFontSelection,
                  ),
                  InterfaceSection(
                    scaleFactor: scaleFactor,
                    initiallyExpanded: widget.highlightSetting == 'interface',
                  ),
                  const SourceFilterSettings(
                      key: ValueKey('source_filter_section')),
                  PlaybackSection(
                    scaleFactor: scaleFactor,
                    initiallyExpanded: _playbackExpanded ||
                        widget.highlightSetting == 'play_on_tap' ||
                        widget.highlightSetting == 'playback_messages' ||
                        widget.highlightSetting == 'offline_buffering' ||
                        widget.highlightSetting == 'playback' ||
                        widget.highlightSetting == 'random_playback' ||
                        widget.highlightSetting == 'enable_buffer_agent',
                    highlightTriggerCount: _highlightTriggerCount,
                    activeHighlightKey: _activeHighlightKey,
                    settingKeys: _settingKeys,
                    onScrollToSetting: _scrollToSetting,
                    isHighlightSettingMatching:
                        widget.highlightSetting == 'playback',
                  ),
                  Builder(builder: (context) {
                    // Register key for scrolling
                    if (!_settingKeys.containsKey('collection_statistics')) {
                      _settingKeys['collection_statistics'] =
                          GlobalKey(debugLabel: 'collection_statistics');
                    }
                    return Container(
                      key: _settingKeys['collection_statistics'],
                      child: CollectionStatistics(
                        initiallyExpanded:
                            widget.highlightSetting == 'collection_statistics',
                      ),
                    );
                  }),
                  DataSection(scaleFactor: scaleFactor),
                  AboutSection(scaleFactor: scaleFactor),
                  const SizedBox(height: 50),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
