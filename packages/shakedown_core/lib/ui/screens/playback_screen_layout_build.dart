part of 'playback_screen.dart';

extension _PlaybackScreenLayoutBuild on PlaybackScreenState {
  Widget _buildEmptyPlaybackState({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Color backgroundColor,
    required ColorScheme colorScheme,
    required bool isFruit,
    required double scaleFactor,
    required ThemeData theme,
  }) {
    final showListProvider = context.watch<ShowListProvider>();
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
              const FruitActivityIndicator(),
              const SizedBox(height: 24),
              Text(
                'SELECTING RANDOM SHOW...',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontFamily: isFruit ? 'Inter' : null,
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
                  fontFamily: isFruit ? 'Inter' : null,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              if (!isFruit)
                FruitTextAction(
                  onPressed: audioProvider.playRandomShow,
                  label: 'Play Random Show',
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlaybackContent({
    required AudioProvider audioProvider,
    required Color backgroundColor,
    required ColorScheme colorScheme,
    required Show currentShow,
    required Source currentSource,
    required double immersiveTopPadding,
    required bool isFruit,
    required double minPanelHeight,
    required double maxPanelHeight,
    required SettingsProvider settingsProvider,
  }) {
    return ValueListenableBuilder<double>(
      valueListenable: _panelPositionNotifier,
      builder: (context, panelPosition, _) {
        if (widget.isPane) {
          return _buildPanePlaybackContent(
            audioProvider: audioProvider,
            colorScheme: colorScheme,
            currentShow: currentShow,
            currentSource: currentSource,
            isFruit: isFruit,
            settingsProvider: settingsProvider,
          );
        }

        return _buildTrackListOverlayContent(
          audioProvider: audioProvider,
          backgroundColor: backgroundColor,
          currentSource: currentSource,
          immersiveTopPadding: immersiveTopPadding,
          maxPanelHeight: maxPanelHeight,
          minPanelHeight: minPanelHeight,
          panelPosition: panelPosition,
        );
      },
    );
  }

  Widget _buildPanePlaybackContent({
    required AudioProvider audioProvider,
    required ColorScheme colorScheme,
    required Show currentShow,
    required Source currentSource,
    required bool isFruit,
    required SettingsProvider settingsProvider,
  }) {
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
                        fontFamily: isFruit
                            ? 'Inter'
                            : FontConfig.resolve('RockSalt'),
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface.withValues(alpha: 0.70),
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
                            valueListenable: CatalogService().ratingsListenable,
                            builder: (context, _, _) {
                              final rating = CatalogService().getRating(
                                currentSource.id,
                              );
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
                          fontFamily: isFruit
                              ? 'Inter'
                              : FontConfig.resolve('RockSalt'),
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
                            fontFamily: isFruit
                                ? 'Inter'
                                : FontConfig.resolve('RockSalt'),
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
                    _scrollToCurrentTrack(true, force: true, alignment: 0.3);
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

                    if (index <= firstVisible + 1 || index >= lastVisible - 1) {
                      _scrollToCurrentTrack(true, forceTargetIndex: index);
                    }
                  },
                  onWrapAround: _focusTrack,
                ),
              ),
              if (context.watch<DeviceService>().isTv &&
                  !settingsProvider.hideTvScrollbars)
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

  Widget _buildTrackListOverlayContent({
    required AudioProvider audioProvider,
    required Color backgroundColor,
    required Source currentSource,
    required double immersiveTopPadding,
    required double maxPanelHeight,
    required double minPanelHeight,
    required double panelPosition,
  }) {
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
  }

  Widget _buildStandardPlaybackScaffold({
    required Color backgroundColor,
    required double bottomPadding,
    required Show currentShow,
    required Source currentSource,
    required bool isTrueBlackMode,
    required bool isTv,
    required double maxPanelHeight,
    required double minPanelHeight,
    required Widget playbackContent,
    required SettingsProvider settingsProvider,
  }) {
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
              onWebStuckReset: _buildWebStuckResetHandler(),
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
