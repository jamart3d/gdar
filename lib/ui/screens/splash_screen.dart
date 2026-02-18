import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';

import 'package:shakedown/ui/widgets/shakedown_title.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_dual_pane_layout.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/utils/font_layout_config.dart';

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
        _showListProvider.hasCheckedArchive &&
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
        final nextScreen =
            isTv ? const TvDualPaneLayout() : const ShowListScreen();

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              final curvedAnimation = CurvedAnimation(
                parent: animation,
                curve: Curves.easeInOutCubic,
              );
              return FadeTransition(opacity: curvedAnimation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 2500),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showListProvider = context.watch<ShowListProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final effectiveScale =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    return Scaffold(
        body: SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: const ShakedownTitle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            AnimatedOpacity(
              opacity: _isNavigating ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (settingsProvider.isFirstRun)
                      _buildChecklistItem(
                        label: 'Hey Now!',
                        isDone: true,
                        scaleFactor: effectiveScale,
                      )
                    else
                      _buildChecklistItem(
                        label: 'Reading settings...',
                        isDone: true,
                        scaleFactor: effectiveScale,
                      ),
                    const SizedBox(height: 12),

                    // 1. Shnids Count
                    AnimatedBuilder(
                        animation: _countController,
                        builder: (context, child) {
                          int count = _shnidCountAnimation.value;
                          bool isDone = _countController.status ==
                              AnimationStatus.completed;
                          bool isLoading = showListProvider.isLoading;

                          String label;
                          if (isLoading) {
                            label = 'Loading data...';
                          } else if (!isDone) {
                            label = 'Found $count shnids...';
                          } else {
                            label = '$count shnids loaded';
                          }

                          return _buildChecklistItem(
                            label: label,
                            isDone: isDone,
                            scaleFactor: effectiveScale,
                          );
                        }),

                    const SizedBox(height: 12),

                    // 2. Shows Count
                    AnimatedBuilder(
                        animation: _countController,
                        builder: (context, child) {
                          int count = _showCountAnimation.value;
                          bool isDone = _countController.status ==
                              AnimationStatus.completed;
                          bool isLoading = showListProvider.isLoading;

                          String label;
                          if (isLoading) {
                            label = 'Processing shows...';
                          } else if (!isDone) {
                            label = 'Found $count shows...';
                          } else {
                            label = '$count shows ready';
                          }

                          return _buildChecklistItem(
                            label: label,
                            isDone: isDone,
                            scaleFactor: effectiveScale,
                          );
                        }),

                    const SizedBox(height: 12),

                    // 3. Archive Check
                    _buildChecklistItem(
                      label: showListProvider.hasCheckedArchive
                          ? (showListProvider.isArchiveReachable
                              ? 'Archive.org reachable'
                              : 'Archive.org ?')
                          : 'Checking archive.org...',
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
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ));
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
                    size: AppTypography.responsiveFontSize(context, 20.0))
                : SizedBox(
                    width: 14 * scaleFactor,
                    height: 14 * scaleFactor,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, key: const ValueKey('loading')),
                  ),
          ),
        ),
        SizedBox(width: 12 * scaleFactor),
        Container(
          // Allow width to grow slightly with scale, but cap it to prevent overflow
          constraints: BoxConstraints(
              maxWidth: 320.0 * (scaleFactor < 1.0 ? 1.0 : scaleFactor)),
          child: Text(
            label,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: AppTypography.responsiveFontSize(context, baseSize),
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
