import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:gdar_fruit/ui/widgets/settings/about_section.dart';
import 'package:gdar_fruit/ui/widgets/settings/appearance_section.dart';
import 'package:gdar_fruit/ui/widgets/settings/collection_statistics.dart';
import 'package:gdar_fruit/ui/widgets/settings/data_section.dart';
import 'package:gdar_fruit/ui/widgets/settings/interface_section.dart';
import 'package:gdar_fruit/ui/widgets/settings/playback_section.dart';
import 'package:gdar_fruit/ui/widgets/settings/source_filter_settings.dart';
import 'package:gdar_fruit/ui/widgets/settings/usage_instructions_section.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/utils/color_generator.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/providers/update_provider.dart';
import 'package:shakedown_core/ui/widgets/onboarding/update_banner.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:gdar_fruit/ui/screens/tv_settings_screen.dart';
import 'package:gdar_fruit/ui/widgets/fruit_tab_bar.dart';
import 'package:gdar_fruit/ui/widgets/theme/fruit_icon_button.dart';
import 'package:gdar_fruit/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:gdar_fruit/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gdar_fruit/ui/screens/fruit_tab_host_screen.dart';
import 'package:gdar_fruit/ui/screens/show_list_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String? highlightSetting;
  final bool showFontSelection;
  final bool showFruitTabBar;
  final VoidCallback? onBackRequested;

  const SettingsScreen({
    super.key,
    this.highlightSetting,
    this.showFontSelection = false,
    this.showFruitTabBar = true,
    this.onBackRequested,
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
      _activeHighlightKey = widget.highlightSetting;
      _highlightTriggerCount = 1;

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

  Future<void> _openPlaybackScreen() async {
    final localContext = context;
    // Pause global clock
    try {
      localContext.read<AnimationController>().stop();
    } catch (_) {}

    await Navigator.of(localContext).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const FruitTabHostScreen(initialTab: 0),
        transitionDuration: Duration.zero,
      ),
      (route) => false,
    );

    // Resume clock
    if (localContext.mounted) {
      try {
        final controller = localContext.read<AnimationController>();
        unawaited(controller.repeat());
      } catch (_) {}
    }
  }

  void _handleAndroidBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ShowListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (context.read<DeviceService>().isTv) {
      return const TvSettingsScreen();
    }

    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    final updateProvider = context.watch<UpdateProvider>();

    Color? backgroundColor;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    if (!isFruit &&
        !isTrueBlackMode &&
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
        surfaceTintColor: Colors.transparent,
      ),
    );

    final List<Widget> slivers = [
      if (isFruit)
        SliverToBoxAdapter(
          child: SizedBox(height: MediaQuery.paddingOf(context).top + 80),
        )
      else
        SliverAppBar.large(
          title: const Text('Settings'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => _handleAndroidBack(context),
          ),
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
          SupportSection(scaleFactor: scaleFactor),
          UsageInstructionsSection(
            scaleFactor: scaleFactor,
            initiallyExpanded: widget.highlightSetting == 'usage_instructions',
          ),
          AppearanceSection(
            key: const ValueKey('appearance_section'),
            scaleFactor: scaleFactor,
            initiallyExpanded: widget.highlightSetting == 'appearance',
            showFontSelection: widget.showFontSelection,
          ),
          InterfaceSection(
            scaleFactor: scaleFactor,
            initiallyExpanded: widget.highlightSetting == 'interface',
          ),
          const SourceFilterSettings(key: ValueKey('source_filter_section')),
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
            isHighlightSettingMatching: widget.highlightSetting == 'playback',
          ),
          Builder(builder: (context) {
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
    ];

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
          body: Stack(
            children: [
              CustomScrollView(slivers: slivers),
              if (isFruit)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildFruitHeader(context),
                ),
            ],
          ),
          bottomNavigationBar: isFruit && widget.showFruitTabBar
              ? FruitTabBar(
                  selectedIndex: 3,
                  onTabSelected: (index) {
                    if (index == 0) {
                      _openPlaybackScreen();
                    } else if (index == 1) {
                      Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const FruitTabHostScreen(initialTab: 1),
                          transitionDuration: Duration.zero,
                        ),
                        (route) => false,
                      );
                    } else if (index == 2) {
                      final showListProvider = context.read<ShowListProvider>();
                      showListProvider.setIsChoosingRandomShow(true);
                      final resetMs =
                          context.read<SettingsProvider>().performanceMode
                              ? 600
                              : 2400;
                      unawaited(Future<void>.delayed(
                        Duration(milliseconds: resetMs),
                        () {
                          if (showListProvider.isChoosingRandomShow) {
                            showListProvider.setIsChoosingRandomShow(false);
                          }
                        },
                      ));
                      if (mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const FruitTabHostScreen(
                              initialTab: 1,
                              triggerRandomOnStart: true,
                            ),
                            transitionDuration: Duration.zero,
                          ),
                          (route) => false,
                        );
                      }
                    }
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildFruitHeader(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    const bool isWeb = kIsWeb;

    final headerContent = Container(
      height: MediaQuery.paddingOf(context).top + 80,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Row(
          children: [
            _buildFruitHeaderButton(
              context,
              icon: LucideIcons.chevronLeft,
              onPressed:
                  widget.onBackRequested ?? () => Navigator.of(context).pop(),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ),
            _buildFruitHeaderButton(
              context,
              icon: Theme.of(context).brightness == Brightness.dark
                  ? LucideIcons.sun
                  : LucideIcons.moon,
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ],
        ),
      ),
    );

    if (isWeb) {
      final baseColor = Theme.of(context).colorScheme.surface;
      return Container(
        decoration: BoxDecoration(
          color: baseColor.withValues(alpha: 0.9),
          border: Border(
            bottom: BorderSide(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.1),
              width: 1.0,
            ),
          ),
        ),
        child: headerContent,
      );
    }

    return ShaderMask(
      shaderCallback: (bounds) {
        return const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black, Colors.transparent],
          stops: [0.7, 1.0],
        ).createShader(bounds);
      },
      blendMode: BlendMode.dstIn,
      child: LiquidGlassWrapper(
        enabled: themeProvider.themeStyle == ThemeStyle.fruit &&
            settingsProvider.fruitEnableLiquidGlass,
        showBorder: false,
        blur: 25,
        opacity: 0.85,
        borderRadius: BorderRadius.zero,
        child: headerContent,
      ),
    );
  }

  Widget _buildFruitHeaderButton(BuildContext context,
      {required IconData icon, required VoidCallback onPressed}) {
    final settingsProvider = context.watch<SettingsProvider>();
    final useNeumorphic =
        settingsProvider.useNeumorphism && !settingsProvider.useTrueBlack;

    if (useNeumorphic) {
      return NeumorphicWrapper(
        isCircle: true,
        borderRadius: 100,
        intensity: 0.8,
        color: Colors.transparent,
        child: LiquidGlassWrapper(
          enabled: !kIsWeb,
          borderRadius: BorderRadius.circular(100),
          opacity: 0.12,
          blur: 8,
          child: FruitIconButton(
            icon: Icon(icon),
            onPressed: onPressed,
            size: 20,
            padding: 10,
          ),
        ),
      );
    }

    return FruitIconButton(
      icon: Icon(icon),
      onPressed: onPressed,
      size: 20,
      padding: 10,
    );
  }
}
