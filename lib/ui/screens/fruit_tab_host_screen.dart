import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';
import 'package:shakedown/ui/widgets/fruit_tab_bar.dart';

class FruitTabHostScreen extends StatefulWidget {
  final int initialTab;
  final String? settingsHighlight;

  const FruitTabHostScreen({
    super.key,
    this.initialTab = 1,
    this.settingsHighlight,
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

  @override
  void initState() {
    super.initState();
    final safeInitialTab =
        _tabToPage.containsKey(widget.initialTab) ? widget.initialTab : 1;
    _selectedTab = safeInitialTab;
    _pageController = PageController(initialPage: _tabToPage[_selectedTab]!);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _selectedTab != 1) return;
      final audioProvider = context.read<AudioProvider>();
      if (audioProvider.currentShow != null) {
        await _scrollLibraryToCurrentShow();
      }
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

  Future<void> _selectTab(int tabIndex) async {
    if (tabIndex == 2) {
      if (_isHandlingRandomTab) return;
      _isHandlingRandomTab = true;
      final audioProvider = context.read<AudioProvider>();
      final showListProvider = context.read<ShowListProvider>();
      try {
        if (audioProvider.pendingRandomShowRequest != null) {
          await audioProvider.playPendingSelection();
          await _selectTab(0);
          return;
        }

        if (showListProvider.isChoosingRandomShow) {
          return;
        }

        showListProvider.setIsChoosingRandomShow(true);
        unawaited(audioProvider.playRandomShow());
        // Safety reset in case downstream listeners are not mounted yet.
        unawaited(Future<void>.delayed(const Duration(milliseconds: 2400), () {
          if (!mounted) return;
          if (showListProvider.isChoosingRandomShow) {
            showListProvider.setIsChoosingRandomShow(false);
          }
        }));
        await _selectTab(0);
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
      }));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
