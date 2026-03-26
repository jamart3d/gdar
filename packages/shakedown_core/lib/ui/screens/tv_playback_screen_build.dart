part of 'tv_playback_screen.dart';

extension _PlaybackScreenBuild on PlaybackScreenState {
  Widget _buildFruitTopBar(BuildContext context, double scaleFactor) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final currentShow = audioProvider.currentShow;
    if (currentShow == null) return const SizedBox.shrink();

    String dateText = '';
    try {
      final dateTime = DateTime.parse(currentShow.date);
      dateText = DateFormat('EEEE, MMMM d, y').format(dateTime);
    } catch (_) {
      dateText = currentShow.formattedDate;
    }

    final catalog = CatalogService();
    final String? ratingKey = audioProvider.currentSource?.id;
    final Source? currentSource = audioProvider.currentSource;
    int rating = 0;
    bool isPlayed = false;

    if (ratingKey != null) {
      rating = catalog.getRating(ratingKey);
      isPlayed = catalog.isPlayed(ratingKey);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0 * scaleFactor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _FruitHeaderButton(
            onTap: widget.onBackRequested ?? () => Navigator.of(context).pop(),
            icon: LucideIcons.chevronLeft,
            scaleFactor: scaleFactor,
            semanticLabel: 'Back to library',
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2 * scaleFactor),
                Text(
                  '${currentShow.venue}, ${currentShow.location}'.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 6 * scaleFactor),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RatingControl(
                      rating: rating,
                      isPlayed: isPlayed,
                      compact: true,
                      size: 20 * scaleFactor,
                      onTap: () async {
                        if (ratingKey == null) return;
                        await showDialog(
                          context: context,
                          builder: (context) => RatingDialog(
                            initialRating: rating,
                            sourceId: ratingKey,
                            isPlayed: isPlayed,
                            onRatingChanged: (newRating) {
                              catalog.setRating(ratingKey, newRating);
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 8 * scaleFactor),
                    SrcBadge(
                      src: audioProvider.currentSource?.src ?? '',
                      scaleFactor: scaleFactor,
                    ),
                    if (audioProvider.currentSource?.id != null) ...[
                      SizedBox(width: 4 * scaleFactor),
                      ShnidBadge(
                        text: audioProvider.currentSource!.id,
                        scaleFactor: scaleFactor,
                        uri: () {
                          if (currentSource == null) return null;
                          if (currentSource.tracks.isNotEmpty) {
                            final transformed = transformArchiveUrl(
                              currentSource.tracks.first.url,
                            );
                            if (transformed != null && transformed.isNotEmpty) {
                              return Uri.parse(transformed);
                            }
                          }
                          return Uri.parse(
                            'https://archive.org/details/${currentSource.id}',
                          );
                        }(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _FruitHeaderButton(
            onTap: () {
              final Size size = MediaQuery.sizeOf(context);
              final double topPadding = MediaQuery.paddingOf(context).top;
              final RelativeRect position = RelativeRect.fromLTRB(
                size.width - 24 * scaleFactor,
                topPadding + 70 * scaleFactor,
                24 * scaleFactor,
                0,
              );

              showMenu(
                context: context,
                position: position,
                elevation: settingsProvider.performanceMode ? 4 : 0,
                color: settingsProvider.performanceMode
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24 * scaleFactor),
                  side: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 1.0,
                  ),
                ),
                items: [
                  PopupMenuItem(
                    onTap: () => settingsProvider.toggleFruitStickyNowPlaying(),
                    child: SizedBox(
                      width: 200 * scaleFactor,
                      child: Row(
                        children: [
                          Icon(
                            settingsProvider.fruitStickyNowPlaying
                                ? LucideIcons.checkCircle2
                                : LucideIcons.circle,
                            size: 18 * scaleFactor,
                            color: settingsProvider.fruitStickyNowPlaying
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          SizedBox(width: 12 * scaleFactor),
                          Text(
                            'Sticky Now Playing',
                            style: TextStyle(fontSize: 14 * scaleFactor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => settingsProvider.toggleShowTrackNumbers(),
                    child: Row(
                      children: [
                        Icon(
                          settingsProvider.showTrackNumbers
                              ? LucideIcons.checkCircle2
                              : LucideIcons.circle,
                          size: 18 * scaleFactor,
                          color: settingsProvider.showTrackNumbers
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        SizedBox(width: 12 * scaleFactor),
                        Text(
                          'Track Numbers',
                          style: TextStyle(fontSize: 14 * scaleFactor),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => settingsProvider.toggleHideTrackDuration(),
                    child: Row(
                      children: [
                        Icon(
                          !settingsProvider.hideTrackDuration
                              ? LucideIcons.checkCircle2
                              : LucideIcons.circle,
                          size: 18 * scaleFactor,
                          color: !settingsProvider.hideTrackDuration
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        SizedBox(width: 12 * scaleFactor),
                        Text(
                          'Track Duration',
                          style: TextStyle(fontSize: 14 * scaleFactor),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            icon: LucideIcons.moreHorizontal,
            scaleFactor: scaleFactor,
            semanticLabel: 'Playback options',
          ),
        ],
      ),
    );
  }

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

    final currentShow = audioProvider.currentShow;
    final currentSource = audioProvider.currentSource;

    Color backgroundColor = colorScheme.surface;
    final bool isDarkMode = theme.brightness == Brightness.dark;
    final bool isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    if (currentShow != null &&
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

    if (currentShow == null || currentSource == null) {
      final ShowListProvider showListProvider = context
          .watch<ShowListProvider>();
      final bool isChoosing = showListProvider.isChoosingRandomShow;

      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: isFruit
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FruitIconButton(
                    icon: const Icon(LucideIcons.chevronLeft),
                    onPressed: () => widget.onBackRequested?.call(),
                  ),
                )
              : null,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isChoosing) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
                Text(
                  'SELECTING RANDOM SHOW...',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.primary,
                    letterSpacing: 2.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ] else ...[
                Icon(
                  LucideIcons.playCircle,
                  size: 64 * scaleFactor,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                ),
                const SizedBox(height: 24),
                Text(
                  'No show selected.',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                if (!isFruit)
                  ElevatedButton.icon(
                    onPressed: () =>
                        context.read<AudioProvider>().playRandomShow(),
                    icon: const Icon(LucideIcons.dice5),
                    label: const Text('Play Random Show'),
                  ),
              ],
            ],
          ),
        ),
      );
    }

    final bool stickyNowPlaying = settingsProvider.fruitStickyNowPlaying;
    final bool trackChanged =
        audioProvider.currentTrack?.title != _lastTrackTitle ||
        audioProvider.currentTrack?.trackNumber != _lastTrackNumber;
    final bool stickyToggledOn = stickyNowPlaying && _lastStickyState == false;
    final bool isInitialBuild = _lastStickyState == null;

    if (trackChanged || stickyToggledOn || (isInitialBuild && isFruit)) {
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
          true,
          maxVisibleY: isPanelOpen ? 0.4 : 1.0,
          syncFocus: shouldSyncFocus,
        );
      });
    }

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

    final Widget playbackContent = ValueListenableBuilder<double>(
      valueListenable: _panelPositionNotifier,
      builder: (context, panelPosition, _) {
        if (widget.isPane) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: widget.isActive ? 1.0 : 0.4,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentShow.formattedDate,
                            style: TextStyle(
                              fontFamily: FontConfig.resolve('RockSalt'),
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.70,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ValueListenableBuilder<Box<Rating>>(
                                  valueListenable:
                                      CatalogService().ratingsListenable,
                                  builder: (context, _, _) {
                                    final int rating = CatalogService()
                                        .getRating(currentSource.id);
                                    return _RatingStars(
                                      rating: rating,
                                      color: Colors.amber,
                                    );
                                  },
                                ),
                                if (currentSource.src != null) ...[
                                  const SizedBox(height: 4),
                                  SrcBadge(
                                    src: currentSource.src!,
                                    isPlaying: false,
                                    matchShnidLook: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.landmark,
                              size: 17,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              currentShow.venue,
                              style: TextStyle(
                                fontFamily: FontConfig.resolve('RockSalt'),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (currentSource.location != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 17,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                currentSource.location!,
                                style: TextStyle(
                                  fontFamily: FontConfig.resolve('RockSalt'),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TrackListView(
                        key: ValueKey(currentSource.id),
                        source: currentSource,
                        bottomPadding: 16.0,
                        topPadding: 0.0,
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        audioProvider: audioProvider,
                        trackFocusNodes: _trackFocusNodes,
                        trackListFocusNode: _trackListFocusNode,
                        initialScrollAlignment: 0.3,
                        onFocusLeft: () {
                          _scrollToCurrentTrack(
                            true,
                            force: true,
                            alignment: 0.3,
                          );
                          widget.onTrackListLeft?.call();
                        },
                        onFocusRight: widget.onTrackListRight,
                        onTrackFocused: (index) {
                          if (!_itemScrollController.isAttached) return;

                          final positions =
                              _itemPositionsListener.itemPositions.value;
                          if (positions.isEmpty) return;

                          final int firstVisible = positions.first.index;
                          final int lastVisible = positions.last.index;

                          if (index <= firstVisible + 1 ||
                              index >= lastVisible - 1) {
                            _scrollToCurrentTrack(
                              true,
                              forceTargetIndex: index,
                            );
                          }
                        },
                        onWrapAround: _focusTrack,
                      ),
                    ),
                    if (context.watch<DeviceService>().isTv)
                      TvScrollbar(
                        itemPositionsListener: _itemPositionsListener,
                        itemScrollController: _itemScrollController,
                        itemCount: _calculateTotalItems(currentSource),
                        focusNode: widget.scrollbarFocusNode,
                        onRight: widget.onScrollbarRight,
                        onLeft: _handleScrollbarLeft,
                      ),
                  ],
                ),
              ),
            ],
          );
        }

        final double dynamicBottomPadding =
            minPanelHeight +
            60.0 +
            ((maxPanelHeight - minPanelHeight) * panelPosition);

        return Stack(
          children: [
            TrackListView(
              source: currentSource,
              bottomPadding: dynamicBottomPadding,
              topPadding: immersiveTopPadding,
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              audioProvider: audioProvider,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: immersiveTopPadding,
              child: Opacity(
                opacity: (1.0 - (panelPosition * 5.0)).clamp(0.0, 1.0),
                child: Container(color: backgroundColor),
              ),
            ),
          ],
        );
      },
    );

    if (widget.isPane) {
      return Container(
        color: backgroundColor.withValues(alpha: 0.7),
        child: playbackContent,
      );
    }

    if (isFruit) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            FruitTrackList(
              trackShow: currentShow,
              scaleFactor: scaleFactor,
              topOffset: immersiveTopPadding,
              bottomOffset: settingsProvider.fruitStickyNowPlaying ? 0 : 80,
            ),
            if (!settingsProvider.fruitStickyNowPlaying &&
                audioProvider.currentTrack != null)
              Positioned(
                left: 16 * scaleFactor,
                right: 16 * scaleFactor,
                bottom: 100.0 * scaleFactor,
                child: FruitNowPlayingCard(
                  trackShow: currentShow,
                  track: audioProvider.currentTrack!,
                  index: (audioProvider.audioPlayer.currentIndex ?? 0) + 1,
                  scaleFactor: scaleFactor,
                  showNext: false,
                ),
              ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LiquidGlassWrapper(
                enabled:
                    settingsProvider.fruitEnableLiquidGlass &&
                    !settingsProvider.performanceMode,
                blur: 20,
                opacity: 0.8,
                borderRadius: BorderRadius.zero,
                child: Container(
                  height: MediaQuery.paddingOf(context).top + 80,
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                  ),
                  decoration: BoxDecoration(
                    color: settingsProvider.performanceMode
                        ? Theme.of(context).colorScheme.surface
                        : null,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.05),
                        width: 1.0,
                      ),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: _buildFruitTopBar(context, scaleFactor),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: widget.showFruitTabBar
            ? FruitTabBar(
                selectedIndex: 0,
                onTabSelected: (index) {
                  if (index == 1) {
                    Navigator.of(context).pushAndRemoveUntil(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const FruitTabHostScreen(initialTab: 1),
                        transitionDuration: Duration.zero,
                      ),
                      (route) => false,
                    );
                  } else if (index == 2) {
                    final ShowListProvider showListProvider = context
                        .read<ShowListProvider>();
                    showListProvider.setIsChoosingRandomShow(true);
                    final int resetMs =
                        context.read<SettingsProvider>().performanceMode
                        ? 600
                        : 2400;
                    unawaited(
                      Future<void>.delayed(Duration(milliseconds: resetMs), () {
                        if (showListProvider.isChoosingRandomShow) {
                          showListProvider.setIsChoosingRandomShow(false);
                        }
                      }),
                    );
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
                  } else if (index == 3) {
                    Navigator.of(context).pushAndRemoveUntil(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const FruitTabHostScreen(initialTab: 3),
                        transitionDuration: Duration.zero,
                      ),
                      (route) => false,
                    );
                  }
                },
              )
            : null,
      );
    }

    return Scaffold(
      primary: false,
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SlidingUpPanel(
            controller: _panelController,
            color: Colors.transparent,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24.0),
            ),
            boxShadow: isTrueBlackMode || isTv
                ? []
                : settingsProvider.useNeumorphism
                ? NeumorphicWrapper.getShadows(
                    context: context,
                    offset: const Offset(0, -8),
                    blur: 24,
                    intensity: 1.1,
                  )
                : [
                    BoxShadow(
                      blurRadius: 20.0,
                      color: Colors.black.withValues(alpha: 0.2),
                    ),
                  ],
            minHeight: minPanelHeight,
            maxHeight: maxPanelHeight,
            margin: EdgeInsets.zero,
            onPanelSlide: (position) {
              _panelPositionNotifier.value = position;
            },
            onPanelOpened: () {
              _scrollToCurrentTrack(true, maxVisibleY: 0.4);
            },
            panelBuilder: () => PlaybackPanel(
              currentShow: currentShow,
              currentSource: currentSource,
              minHeight: minPanelHeight,
              bottomPadding: bottomPadding,
              panelPositionNotifier: _panelPositionNotifier,
              onVenueTap: () {
                _scrollToCurrentTrack(true, force: true);
                if (_panelController.isAttached &&
                    _panelController.isPanelClosed) {
                  _panelController.open();
                }
              },
            ),
            body: playbackContent,
          ),
          ValueListenableBuilder<double>(
            valueListenable: _panelPositionNotifier,
            builder: (context, panelPosition, child) {
              return Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: PlaybackAppBar(
                  currentShow: currentShow,
                  currentSource: currentSource,
                  backgroundColor: backgroundColor,
                  panelPosition: panelPosition,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
