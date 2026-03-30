part of 'playback_screen.dart';

extension _PlaybackScreenBuild on PlaybackScreenState {
  Widget _buildScreen(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
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

    final Color backgroundColor = _resolveBackgroundColor(
      colorScheme: colorScheme,
      currentShow: currentShow,
      currentSource: currentSource,
      isFruit: isFruit,
      settingsProvider: settingsProvider,
      theme: theme,
    );

    if (currentShow == null || currentSource == null) {
      return _buildEmptyPlaybackState(
        context: context,
        audioProvider: audioProvider,
        backgroundColor: backgroundColor,
        colorScheme: colorScheme,
        isFruit: isFruit,
        scaleFactor: scaleFactor,
        theme: theme,
      );
    }

    _syncPlaybackPositionIfNeeded(
      audioProvider: audioProvider,
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

    final double appBarHeight = isFruit
        ? (14.0 + (92.0 * scaleFactor))
        : kToolbarHeight;
    final double immersiveTopPadding =
        MediaQuery.paddingOf(context).top + appBarHeight;

    final Widget playbackContent = _buildPlaybackContent(
      audioProvider: audioProvider,
      backgroundColor: backgroundColor,
      colorScheme: colorScheme,
      currentShow: currentShow,
      currentSource: currentSource,
      immersiveTopPadding: immersiveTopPadding,
      isFruit: isFruit,
      minPanelHeight: minPanelHeight,
      maxPanelHeight: maxPanelHeight,
      settingsProvider: settingsProvider,
    );

    if (widget.isPane) {
      return Container(
        color: backgroundColor.withValues(alpha: 0.7),
        child: playbackContent,
      );
    }

    if (isFruit) {
      return _buildFruitPlaybackScaffold(
        context: context,
        audioProvider: audioProvider,
        backgroundColor: backgroundColor,
        currentShow: currentShow,
        immersiveTopPadding: immersiveTopPadding,
        scaleFactor: scaleFactor,
        settingsProvider: settingsProvider,
      );
    }

    return _buildStandardPlaybackScaffold(
      backgroundColor: backgroundColor,
      bottomPadding: bottomPadding,
      currentShow: currentShow,
      currentSource: currentSource,
      isTrueBlackMode:
          theme.brightness == Brightness.dark && settingsProvider.useTrueBlack,
      isTv: isTv,
      maxPanelHeight: maxPanelHeight,
      minPanelHeight: minPanelHeight,
      playbackContent: playbackContent,
      settingsProvider: settingsProvider,
    );
  }

  Color _resolveBackgroundColor({
    required ColorScheme colorScheme,
    required Show? currentShow,
    required Source? currentSource,
    required bool isFruit,
    required SettingsProvider settingsProvider,
    required ThemeData theme,
  }) {
    Color backgroundColor = widget.isPane
        ? Colors.transparent
        : colorScheme.surface;
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final bool isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    if (!widget.isPane &&
        currentShow != null &&
        currentSource != null &&
        !isTrueBlackMode &&
        settingsProvider.highlightCurrentShowCard &&
        !isFruit) {
      String seed = currentShow.name;
      if (currentShow.sources.length > 1) {
        seed = currentSource.id;
      }
      backgroundColor = ColorGenerator.getColor(
        seed,
        brightness: theme.brightness,
      );
    }

    return backgroundColor;
  }

  void _syncPlaybackPositionIfNeeded({
    required AudioProvider audioProvider,
    required bool isFruit,
    required bool isTv,
    required bool stickyNowPlaying,
  }) {
    final bool trackChanged =
        audioProvider.currentTrack?.title != _lastTrackTitle;
    final bool stickyToggledOn = stickyNowPlaying && _lastStickyState == false;
    final bool isInitialBuild = _lastStickyState == null;

    if (!(trackChanged || stickyToggledOn || (isInitialBuild && isFruit))) {
      return;
    }

    _lastTrackTitle = audioProvider.currentTrack?.title;
    _lastStickyState = stickyNowPlaying;

    final bool capturedIsTv = isTv;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bool listHasFocus = capturedIsTv && _trackListFocusNode.hasFocus;
      final bool isPanelOpen = _panelPositionNotifier.value > 0.1;
      _scrollToCurrentTrack(
        true,
        maxVisibleY: isPanelOpen ? 0.4 : 1.0,
        syncFocus: !listHasFocus,
      );
    });
  }
}
