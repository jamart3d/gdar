import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';
import 'package:shakedown_core/ui/screens/settings_screen.dart';
import 'package:shakedown_core/ui/screens/show_list_screen.dart';
import 'package:shakedown_core/ui/widgets/fruit_tab_bar.dart';

class FruitTabHostScreen extends StatefulWidget {
  final int initialTab;
  final String? settingsHighlight;
  final bool triggerRandomOnStart;

  const FruitTabHostScreen({
    super.key,
    this.initialTab = 1,
    this.settingsHighlight,
    this.triggerRandomOnStart = false,
  });

  @override
  State<FruitTabHostScreen> createState() => _FruitTabHostScreenState();
}

class _FruitTabHostScreenState extends State<FruitTabHostScreen> {
  static const Map<int, int> _tabToPage = {0: 0, 1: 1, 3: 2};
  static const Map<int, int> _pageToTab = {0: 0, 1: 1, 2: 3};

  late final PageController _pageController;
  final GlobalKey<ShowListScreenState> _showListKey =
      GlobalKey<ShowListScreenState>();
  int _selectedTab = 1;
  bool _isHandlingRandomTab = false;
  bool _didRedirectToAndroid = false;

  @override
  void initState() {
    super.initState();
    final safeInitialTab = _tabToPage.containsKey(widget.initialTab)
        ? widget.initialTab
        : 1;
    _selectedTab = safeInitialTab;
    _pageController = PageController(initialPage: _tabToPage[_selectedTab]!);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _selectedTab != 1) return;
      final audioProvider = context.read<AudioProvider>();
      if (audioProvider.currentShow != null) {
        await _scrollLibraryToCurrentShow();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.triggerRandomOnStart) return;
      unawaited(_selectTab(2));
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _scrollLibraryToCurrentShow() async {
    for (int i = 0; i < 8; i++) {
      if (!mounted || _selectedTab != 1) return;
      final state = _showListKey.currentState;
      if (state != null) {
        await state.scrollToCurrentShowFromTab();
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  void _scheduleRandomReset(ShowListProvider showListProvider) {
    final resetMs = context.read<SettingsProvider>().performanceMode
        ? 600
        : 2400;
    unawaited(
      Future<void>.delayed(Duration(milliseconds: resetMs), () {
        if (!mounted) return;
        if (showListProvider.isChoosingRandomShow) {
          showListProvider.setIsChoosingRandomShow(false);
        }
      }),
    );
  }

  void _jumpToPlayTabImmediate() {
    if (!mounted || _selectedTab == 0) return;
    if (!_pageController.hasClients) return;

    setState(() => _selectedTab = 0);
    _pageController.jumpToPage(_tabToPage[0]!);
  }

  Future<void> _selectTab(int tabIndex) async {
    if (tabIndex == 2) {
      if (_isHandlingRandomTab) return;
      _isHandlingRandomTab = true;
      final audioProvider = context.read<AudioProvider>();
      final showListProvider = context.read<ShowListProvider>();

      try {
        // 1. INSTANT FEEDBACK: Highlight the tab and start the roll animation immediately
        setState(() => _selectedTab = 2);
        showListProvider.setIsChoosingRandomShow(true);

        // 2. SAFETY: If the show list hasn't even loaded yet (first click after boot),
        // we must wait for it, otherwise playRandomShow() will fail silently.
        if (showListProvider.allShows.isEmpty && showListProvider.isLoading) {
          debugPrint('Dice: Waiting for show list initialization...');
          await showListProvider.initializationComplete;
        }

        if (audioProvider.pendingRandomShowRequest != null) {
          await audioProvider.playPendingSelection();
          audioProvider.clearPendingRandomShowRequest();
          if (mounted && _selectedTab == 2) {
            await Future<void>.delayed(const Duration(milliseconds: 50));
            _jumpToPlayTabImmediate();
          }
          return;
        }

        // 3. TRIGGER SELECTION: Wait for the random show to be picked
        debugPrint('Dice: Triggering playRandomShow...');
        final picked = await audioProvider.playRandomShow();

        if (picked == null) {
          debugPrint(
            'Dice: No show was picked (list might be empty or filtered).',
          );
        }

        // 4. TRANSITION: Jump to Playback only if user hasn't navigated away
        // (guard against race: user taps Library while playRandomShow() is awaiting)
        if (mounted && _selectedTab == 2) {
          await Future<void>.delayed(const Duration(milliseconds: 100));
          _jumpToPlayTabImmediate();
        }

        _scheduleRandomReset(showListProvider);
      } catch (e) {
        debugPrint('Dice Error: $e');
        if (mounted && _selectedTab == 2) _jumpToPlayTabImmediate();
      } finally {
        _isHandlingRandomTab = false;
      }
      return;
    }

    final pageIndex = _tabToPage[tabIndex];
    if (pageIndex == null) return;

    final settings = context.read<SettingsProvider>();
    final audioProvider = context.read<AudioProvider>();
    final shouldScrollToCurrent = audioProvider.currentShow != null;

    if (tabIndex == 1 && tabIndex == _selectedTab) {
      if (shouldScrollToCurrent) {
        await _scrollLibraryToCurrentShow();
      }
      return;
    }

    if (tabIndex == _selectedTab) return;

    setState(() => _selectedTab = tabIndex);
    final useAnimatedFruitTransitions =
        settings.fruitEnableLiquidGlass && !settings.performanceMode;

    if (useAnimatedFruitTransitions) {
      await _pageController.animateToPage(
        pageIndex,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _pageController.jumpToPage(pageIndex);
    }

    if (tabIndex == 1 && shouldScrollToCurrent) {
      await _scrollLibraryToCurrentShow();
      // Older devices may attach/build list slightly later; retry once.
      unawaited(
        Future<void>.delayed(const Duration(milliseconds: 250), () async {
          if (!mounted || _selectedTab != 1) return;
          await _scrollLibraryToCurrentShow();
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    if (themeProvider.themeStyle != ThemeStyle.fruit) {
      if (!_didRedirectToAndroid) {
        _didRedirectToAndroid = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Widget target;
          if (_selectedTab == 0) {
            target = const PlaybackScreen(showFruitTabBar: false);
          } else if (_selectedTab == 3) {
            target = SettingsScreen(
              showFruitTabBar: false,
              highlightSetting: widget.settingsHighlight,
            );
          } else {
            target = const ShowListScreen(showFruitTabBar: false);
          }
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => target));
        });
      }

      if (_selectedTab == 0) {
        return const PlaybackScreen(showFruitTabBar: false);
      }
      if (_selectedTab == 3) {
        return SettingsScreen(
          showFruitTabBar: false,
          highlightSetting: widget.settingsHighlight,
        );
      }
      return const ShowListScreen(showFruitTabBar: false);
    }

    return Scaffold(
      extendBody: true,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        scrollDirection: Axis.vertical,
        onPageChanged: (page) {
          final tab = _pageToTab[page];
          if (tab != null && tab != _selectedTab) {
            setState(() => _selectedTab = tab);
          }
        },
        children: [
          PlaybackScreen(
            showFruitTabBar: false,
            onBackRequested: () => _selectTab(1),
          ),
          ShowListScreen(
            key: _showListKey,
            showFruitTabBar: false,
            onOpenPlaybackRequested: () => _selectTab(0),
            onSettingsRequested: () => _selectTab(3),
            skipStartupRandom: widget.triggerRandomOnStart,
          ),
          SettingsScreen(
            showFruitTabBar: false,
            onBackRequested: () => _selectTab(1),
            highlightSetting: widget.settingsHighlight,
          ),
        ],
      ),
      bottomNavigationBar: FruitTabBar(
        selectedIndex: _selectedTab,
        onTabSelected: _selectTab,
      ),
    );
  }
}
