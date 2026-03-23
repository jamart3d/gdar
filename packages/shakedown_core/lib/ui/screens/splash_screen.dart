import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/ui/navigation/route_names.dart';
import 'package:shakedown_core/ui/screens/show_list_screen.dart';
import 'package:shakedown_core/ui/screens/onboarding_screen.dart';

import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/screens/fruit_tab_host_screen.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/shakedown_title.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_dual_pane_layout.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/utils/web_perf_hint.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _countController;
  late Animation<int> _shnidCountAnimation;
  late Animation<int> _showCountAnimation;

  late final ShowListProvider _showListProvider;
  bool _minTimeElapsed = false;
  bool _isNavigating = false;
  Timer? _minTimeTimer;

  @override
  void initState() {
    super.initState();

    // Count animation (for shnids and shows)
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _shnidCountAnimation = IntTween(begin: 0, end: 0).animate(_countController);
    _showCountAnimation = IntTween(begin: 0, end: 0).animate(_countController);

    _showListProvider = context.read<ShowListProvider>();

    // Start minimum timer (2 seconds)
    _minTimeTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _minTimeElapsed = true;
        });
        _checkNavigation();
      }
    });

    _showListProvider.addListener(_onShowListUpdate);
    // Initial check
    _onShowListUpdate();
  }

  @override
  void dispose() {
    _countController.dispose();
    _minTimeTimer?.cancel();
    _showListProvider.removeListener(_onShowListUpdate);
    super.dispose();
  }

  void _onShowListUpdate() {
    if (!_showListProvider.isLoading &&
        !_countController.isAnimating &&
        _countController.status != AnimationStatus.completed) {
      // On low-power devices, skip count animation to avoid stutter
      if (isLikelyLowPowerWebDevice()) {
        _countController.value = 1.0;
        setState(() {});
        _checkNavigation();
        return;
      }
      // Loading finished, start counting animation
      setState(() {
        _shnidCountAnimation =
            IntTween(begin: 0, end: _showListProvider.totalShnids).animate(
              CurvedAnimation(
                parent: _countController,
                curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
              ),
            );
        _showCountAnimation =
            IntTween(begin: 0, end: _showListProvider.allShows.length).animate(
              CurvedAnimation(
                parent: _countController,
                curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
              ),
            );
      });
      _countController.forward().then((_) {
        if (mounted) _checkNavigation();
      });
    } else {
      _checkNavigation();
    }
  }

  void _checkNavigation() {
    final settingsProvider = context.read<SettingsProvider>();

    if (!settingsProvider.showSplashScreen) {
      _navigateToHome();
      return;
    }

    // Conditions to navigate:
    // 1. Min time elapsed
    // 2. Loading done
    // 3. Archive checked
    // 4. Count animation done
    bool countDone = _countController.status == AnimationStatus.completed;

    if (_minTimeElapsed &&
        !_showListProvider.isLoading &&
        (kIsWeb || _showListProvider.hasCheckedArchive) &&
        countDone) {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    // Ensure we only navigate once
    _showListProvider.removeListener(_onShowListUpdate);

    if (mounted) {
      setState(() {
        _isNavigating = true;
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final isTv = context.read<DeviceService>().isTv;
        final settingsProvider = context.read<SettingsProvider>();
        final useSimpleTransition = settingsProvider.performanceMode;
        final themeProvider = context.read<ThemeProvider>();
        final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

        final nextScreen = isTv
            ? const TvDualPaneLayout()
            : (settingsProvider.showOnboarding
                  ? const OnboardingScreen()
                  : (isFruit
                        ? const FruitTabHostScreen()
                        : const ShowListScreen()));
        final routeName = isTv
            ? ShakedownRouteNames.tvHome
            : (settingsProvider.showOnboarding
                  ? ShakedownRouteNames.onboarding
                  : (isFruit
                        ? ShakedownRouteNames.fruitHome
                        : ShakedownRouteNames.showList));

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            settings: RouteSettings(name: routeName),
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder: useSimpleTransition
                ? (context, animation, secondaryAnimation, child) => child
                : (context, animation, secondaryAnimation, child) {
                    final curvedAnimation = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInOutCubic,
                    );
                    return FadeTransition(
                      opacity: curvedAnimation,
                      child: child,
                    );
                  },
            transitionDuration: useSimpleTransition
                ? Duration.zero
                : const Duration(milliseconds: 2500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showListProvider = context.watch<ShowListProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    final effectiveScale = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: ShakedownTitle(
                  fontSize: 24,
                  fontKeyOverride: isFruit ? 'rock_salt' : null,
                ),
              ),
              const SizedBox(height: 40),
              AnimatedOpacity(
                opacity: _isNavigating ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: SizedBox(
                      width: settingsProvider.isTv ? 500 : 320,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (settingsProvider.isFirstRun)
                            _buildChecklistItem(
                              label: 'Hey Now!',
                              isDone: true,
                              scaleFactor: effectiveScale,
                            )
                          else
                            _buildChecklistItem(
                              label: 'settings: ready',
                              isDone: true,
                              scaleFactor: effectiveScale,
                            ),
                          const SizedBox(height: 12),

                          // 1. Shnids Count
                          AnimatedBuilder(
                            animation: _countController,
                            builder: (context, child) {
                              int count = _shnidCountAnimation.value;
                              bool isDone =
                                  _countController.status ==
                                  AnimationStatus.completed;
                              bool isLoading = showListProvider.isLoading;

                              String label;
                              if (isLoading) {
                                label = 'shnids loaded: ...';
                              } else {
                                label = 'shnids loaded: $count';
                              }

                              return _buildChecklistItem(
                                label: label,
                                isDone: isDone,
                                scaleFactor: effectiveScale,
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          // 2. Shows Count
                          AnimatedBuilder(
                            animation: _countController,
                            builder: (context, child) {
                              int count = _showCountAnimation.value;
                              bool isDone =
                                  _countController.status ==
                                  AnimationStatus.completed;
                              bool isLoading = showListProvider.isLoading;

                              String label;
                              if (isLoading) {
                                label = 'shows ready: ...';
                              } else {
                                label = 'shows ready: $count';
                              }

                              return _buildChecklistItem(
                                label: label,
                                isDone: isDone,
                                scaleFactor: effectiveScale,
                              );
                            },
                          ),

                          const SizedBox(height: 12),

                          // 3. Archive Check
                          if (!kIsWeb)
                            _buildChecklistItem(
                              label:
                                  'archive.org: ${showListProvider.hasCheckedArchive ? (showListProvider.isArchiveReachable ? 'reachable' : 'offline') : 'checking...'}',
                              isDone: showListProvider.hasCheckedArchive,
                              isSuccess: showListProvider.hasCheckedArchive
                                  ? showListProvider.isArchiveReachable
                                  : true, // Default to true while loading
                              scaleFactor: effectiveScale,
                            ),

                          // 4. Random Play (Conditional)
                          if (settingsProvider.playRandomOnStartup) ...[
                            const SizedBox(height: 12),
                            _buildChecklistItem(
                              label: 'Play random show...',
                              isDone: true,
                              scaleFactor: effectiveScale,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem({
    required String label,
    required bool isDone,
    bool isSuccess = true,
    double scaleFactor = 1.0,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme; // Use local var for consistency

    // Use a balanced base size that works well with the centralized scale factors
    const double baseSize = 16.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min, // Keep items snug together
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isDone
                ? Icon(
                    isSuccess
                        ? Icons.check_circle
                        : Icons.warning_rounded, // Use Warning for failure
                    key: ValueKey(isSuccess ? 'done' : 'error'),
                    color: isSuccess
                        ? colorScheme.primary
                        : colorScheme.error, // Red for error
                    size: AppTypography.responsiveFontSize(context, 20.0),
                  )
                : isLikelyLowPowerWebDevice()
                ? Icon(
                    Icons.radio_button_unchecked,
                    key: const ValueKey('loading_static'),
                    color: colorScheme.onSurface.withValues(alpha: 0.3),
                    size: 14 * scaleFactor,
                  )
                : SizedBox(
                    width: 14 * scaleFactor,
                    height: 14 * scaleFactor,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      key: ValueKey('loading'),
                    ),
                  ),
          ),
        ),
        SizedBox(width: 12 * scaleFactor),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: AppTypography.responsiveFontSize(context, baseSize),
              fontFeatures: [const ui.FontFeature.tabularFigures()],
              color: isSuccess ? null : colorScheme.error, // Red Text for error
              fontWeight: isSuccess ? null : FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
