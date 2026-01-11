import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/screens/show_list_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  late final AnimationController _countController;
  late Animation<int> _shnidCountAnimation;
  late Animation<int> _showCountAnimation;

  late final ShowListProvider _showListProvider;
  bool _minTimeElapsed = false;
  Timer? _minTimeTimer;

  @override
  void initState() {
    super.initState();

    // Fade animation
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

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
    _fadeController.dispose();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ShowListScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final showListProvider = context.watch<ShowListProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'shakedown',
                  style: theme.textTheme.displayLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 40),

              if (settingsProvider.isFirstRun)
                _buildChecklistItem(
                  label: 'Hey Now!',
                  isDone: true,
                )
              else
                _buildChecklistItem(
                  label: 'Reading settings...',
                  isDone: true,
                ),
              const SizedBox(height: 12),

              // 1. Shnids Count
              AnimatedBuilder(
                  animation: _countController,
                  builder: (context, child) {
                    int count = _shnidCountAnimation.value;
                    bool isDone =
                        _countController.status == AnimationStatus.completed;
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
                    );
                  }),

              const SizedBox(height: 12),

              // 2. Shows Count
              AnimatedBuilder(
                  animation: _countController,
                  builder: (context, child) {
                    int count = _showCountAnimation.value;
                    bool isDone =
                        _countController.status == AnimationStatus.completed;
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
                    );
                  }),

              const SizedBox(height: 12),

              // 3. Archive Check
              _buildChecklistItem(
                label: showListProvider.hasCheckedArchive
                    ? (showListProvider.isArchiveReachable
                        ? 'Archive.org reachable'
                        : 'Archive.org unreachable (offline mode)')
                    : 'Checking archive.org...',
                isDone: showListProvider.hasCheckedArchive,
              ),

              // 4. Random Play (Conditional)
              if (settingsProvider.playRandomOnStartup) ...[
                const SizedBox(height: 12),
                _buildChecklistItem(
                  label: 'Play random show on startup',
                  isDone: true,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem({required String label, required bool isDone}) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: isDone
                ? Icon(Icons.check_circle,
                    key: const ValueKey('done'),
                    color: theme.colorScheme.primary,
                    size: 20)
                : const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, key: ValueKey('loading')),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 220, // Fixed width for alignment
          child: Text(
            label,
            style: theme.textTheme.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
