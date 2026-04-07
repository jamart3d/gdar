part of 'tv_playback_screen.dart';

extension _PlaybackScreenBuild on PlaybackScreenState {
  Widget _buildScreen(BuildContext context) {
    final AudioProvider audioProvider = context.watch<AudioProvider>();
    final SettingsProvider settingsProvider = context.watch<SettingsProvider>();
    final ThemeProvider themeProvider = context.watch<ThemeProvider>();
    final bool isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final bool isTv = context.watch<DeviceService>().isTv;

    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final double scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    final Show? currentShow = audioProvider.currentShow;
    final Source? currentSource = audioProvider.currentSource;

    // In TV dual-pane mode the right pane sits on top of the shared
    // FloatingSpheresBackground - use transparent so that layer shows through.
    final Color backgroundColor = widget.isPane
        ? Colors.transparent
        : Colors.black;
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final bool isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    if (currentShow == null || currentSource == null) {
      return _buildEmptyPlaybackState(
        context: context,
        backgroundColor: backgroundColor,
        colorScheme: colorScheme,
        isFruit: isFruit,
        scaleFactor: scaleFactor,
        settingsProvider: settingsProvider,
        theme: theme,
      );
    }

    _syncPlaybackPositionIfNeeded(
      audioProvider: audioProvider,
      currentSource: currentSource,
      isFruit: isFruit,
      isTv: isTv,
      stickyNowPlaying: settingsProvider.fruitStickyNowPlaying,
    );

    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double baseHeight = settingsProvider.uiScale ? 75.0 : 96.0;
    final double fruitOffset = isFruit ? 80.0 : 0.0;
    final double minPanelHeight =
        (baseHeight * scaleFactor) + bottomPadding + fruitOffset;

    final double screenHeight = MediaQuery.of(context).size.height;
    final bool showHud = kIsWeb && settingsProvider.showDevAudioHud;
    final double minExpandedHeight = (showHud ? 320.0 : 260.0) * scaleFactor;
    final double targetMaxHeight = minPanelHeight + minExpandedHeight;
    final double maxPanelHeight = targetMaxHeight.clamp(
      screenHeight *
          (kIsWeb
              ? (settingsProvider.uiScale ? 0.52 : 0.48)
              : (settingsProvider.uiScale ? 0.42 : 0.40)),
      screenHeight * 0.85,
    );

    const double appBarHeight = 80.0;
    final double immersiveTopPadding =
        MediaQuery.paddingOf(context).top + appBarHeight;

    final Widget playbackContent = _buildPlaybackContent(
      audioProvider: audioProvider,
      backgroundColor: backgroundColor,
      colorScheme: colorScheme,
      currentShow: currentShow,
      currentSource: currentSource,
      immersiveTopPadding: immersiveTopPadding,
      isTv: isTv,
      maxPanelHeight: maxPanelHeight,
      minPanelHeight: minPanelHeight,
      settingsProvider: settingsProvider,
    );

    if (widget.isPane) {
      // backgroundColor is already Colors.transparent in pane mode;
      // wrapping in a Container here is a no-op but kept for future overrides.
      return ColoredBox(color: backgroundColor, child: playbackContent);
    }

    if (isFruit) {
      return _buildFruitPlaybackScaffold(
        context: context,
        audioProvider: audioProvider,
        backgroundColor: backgroundColor,
        currentShow: currentShow,
        scaleFactor: scaleFactor,
        settingsProvider: settingsProvider,
      );
    }

    return _buildStandardPlaybackScaffold(
      backgroundColor: backgroundColor,
      bottomPadding: bottomPadding,
      currentShow: currentShow,
      currentSource: currentSource,
      isTrueBlackMode: isTrueBlackMode,
      isTv: isTv,
      maxPanelHeight: maxPanelHeight,
      minPanelHeight: minPanelHeight,
      playbackContent: playbackContent,
      settingsProvider: settingsProvider,
    );
  }

  void _syncPlaybackPositionIfNeeded({
    required AudioProvider audioProvider,
    required Source currentSource,
    required bool isFruit,
    required bool isTv,
    required bool stickyNowPlaying,
  }) {
    final bool trackChanged =
        audioProvider.currentTrack?.title != _lastTrackTitle ||
        audioProvider.currentTrack?.trackNumber != _lastTrackNumber;
    final bool stickyToggledOn = stickyNowPlaying && _lastStickyState == false;
    final bool isInitialBuild = _lastStickyState == null;
    final bool shouldScrollOnInitial =
        isInitialBuild && (isFruit || !widget.isPane);

    if (!(trackChanged || stickyToggledOn || shouldScrollOnInitial)) {
      return;
    }

    final String? oldTrackTitle = _lastTrackTitle;
    final int? oldTrackNumber = _lastTrackNumber;

    _lastTrackTitle = audioProvider.currentTrack?.title;
    _lastTrackNumber = audioProvider.currentTrack?.trackNumber;
    _lastStickyState = stickyNowPlaying;

    final bool capturedIsTv = isTv;
    final bool wasOldTrackFocused =
        capturedIsTv &&
        _trackListFocusNode.hasFocus &&
        oldTrackTitle != null &&
        oldTrackNumber != null &&
        (_trackFocusNodes[_getListIndexForTrack(
                  currentSource,
                  oldTrackTitle,
                  oldTrackNumber,
                )]
                ?.hasFocus ??
            false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bool listHasFocus = capturedIsTv && _trackListFocusNode.hasFocus;
      final bool shouldSyncFocus = !listHasFocus || wasOldTrackFocused;
      final bool isPanelOpen = _panelPositionNotifier.value > 0.1;
      _scrollToCurrentTrack(
        !isInitialBuild,
        maxVisibleY: isPanelOpen ? 0.4 : 1.0,
        syncFocus: shouldSyncFocus,
      );
    });
  }
}
