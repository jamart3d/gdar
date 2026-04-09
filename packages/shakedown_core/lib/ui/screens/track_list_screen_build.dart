part of 'track_list_screen.dart';

extension _TrackListScreenBuild on _TrackListScreenState {
  Widget _buildTrackListScreen(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isTv = context.watch<DeviceService>().isTv;

    return Scaffold(
      appBar: themeProvider.themeStyle == ThemeStyle.fruit
          ? null
          : AppBar(
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 56),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder(
                          valueListenable: CatalogService().ratingsListenable,
                          builder: (context, _, _) {
                            final String ratingKey = widget.source.id;
                            final catalog = CatalogService();
                            final isPlayed = catalog.isPlayed(ratingKey);
                            final rating = catalog.getRating(ratingKey);

                            return RatingControl(
                              key: ValueKey('${ratingKey}_${rating}_$isPlayed'),
                              rating: rating,
                              size:
                                  12 * (settingsProvider.uiScale ? 1.25 : 1.0),
                              isPlayed: isPlayed,
                              compact: true,
                              onTap: () async {
                                unawaited(
                                  showDialog(
                                    context: context,
                                    builder: (context) => RatingDialog(
                                      initialRating: catalog.getRating(
                                        ratingKey,
                                      ),
                                      sourceId: widget.source.id,
                                      sourceUrl: widget.source.tracks.isNotEmpty
                                          ? widget.source.tracks.first.url
                                          : null,
                                      isPlayed: catalog.isPlayed(ratingKey),
                                      onRatingChanged: (newRating) {
                                        catalog.setRating(ratingKey, newRating);
                                      },
                                      onPlayedChanged: (bool newIsPlayed) {
                                        if (newIsPlayed !=
                                            catalog.isPlayed(ratingKey)) {
                                          catalog.togglePlayed(ratingKey);
                                        }
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.source.src != null) ...[
                              SrcBadge(
                                src: widget.source.src!,
                                matchShnidLook: true,
                              ),
                              const SizedBox(width: 4),
                            ],
                            ShnidBadge(
                              text: widget.source.id,
                              onTap: () {
                                if (widget.source.tracks.isNotEmpty) {
                                  launchArchivePage(
                                    widget.source.tracks.first.url,
                                    context,
                                  );
                                } else {
                                  launchArchiveDetails(
                                    widget.source.id,
                                    context,
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Builder(
                  builder: (context) {
                    final themeProvider = context.watch<ThemeProvider>();
                    final settingsProvider = context.watch<SettingsProvider>();
                    final isFruit =
                        themeProvider.themeStyle == ThemeStyle.fruit;
                    final useNeumorphic =
                        settingsProvider.useNeumorphism &&
                        isFruit &&
                        !settingsProvider.useTrueBlack;

                    final Widget button = IconButton(
                      icon: Icon(
                        isFruit ? LucideIcons.settings : Icons.settings_rounded,
                      ),
                      iconSize: 24.0,
                      onPressed: () async {
                        try {
                          context.read<AnimationController>().stop();
                        } catch (_) {}

                        unawaited(
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              settings: const RouteSettings(
                                name: ShakedownRouteNames.tvSettings,
                              ),
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const SettingsScreen(),
                              transitionDuration: Duration.zero,
                            ),
                          ),
                        );

                        if (context.mounted) {
                          try {
                            final controller = context
                                .read<AnimationController>();
                            if (!controller.isAnimating) {
                              unawaited(controller.repeat());
                            }
                          } catch (_) {}
                        }
                      },
                    );

                    if (useNeumorphic && !isTv) {
                      return Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: kIsWeb ? (isFruit ? 16.0 : 8.0) : 8.0,
                        ),
                        child: NeumorphicWrapper(
                          isCircle: false,
                          borderRadius: 12.0,
                          intensity: 1.2,
                          color: const Color(0x00000000),
                          child: LiquidGlassWrapper(
                            enabled: !isTv,
                            borderRadius: BorderRadius.circular(12.0),
                            opacity: 0.08,
                            blur: 5.0,
                            child: button,
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? (isFruit ? 16.0 : 8.0) : 8.0,
                      ),
                      child: button,
                    );
                  },
                ),
              ],
            ),
      body: Stack(
        children: [
          _buildBody(),
          if (themeProvider.themeStyle == ThemeStyle.fruit)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FruitSurface(
                borderRadius: BorderRadius.zero,
                blur: 18,
                opacity: settingsProvider.performanceMode ? 0.96 : 0.82,
                child: Container(
                  height:
                      MediaQuery.paddingOf(context).top +
                      _TrackListScreenState._fruitHeaderTopGap +
                      _TrackListScreenState._fruitHeaderBodyHeight,
                  padding: EdgeInsets.only(
                    top:
                        MediaQuery.paddingOf(context).top +
                        _TrackListScreenState._fruitHeaderTopGap,
                  ),
                  decoration: BoxDecoration(
                    color: settingsProvider.performanceMode
                        ? Theme.of(context).colorScheme.surface
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: _buildFruitHeader(context),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: themeProvider.themeStyle == ThemeStyle.fruit
          ? FruitTabBar(
              selectedIndex: 1,
              onTabSelected: (index) {
                if (index == 0) {
                  _openPlaybackScreen();
                } else if (index == 1) {
                  Navigator.of(context).pushAndRemoveUntil(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
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
                        pageBuilder: (context, animation, secondaryAnimation) =>
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

  Widget _buildBody() {
    final audioProvider = context.watch<AudioProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final isDifferentShowPlaying =
        audioProvider.currentShow != null &&
        audioProvider.currentShow!.name != widget.show.name;

    final bottomPadding = isFruit
        ? (isDifferentShowPlaying ? 180.0 : 140.0)
        : (isDifferentShowPlaying ? 160.0 : 40.0);

    if (widget.show.sources.isEmpty) {
      return const Center(child: Text('No tracks available for this show.'));
    }

    final source = widget.source;
    final layout = buildTrackListLayout(source, includeShowHeader: true);

    if (themeProvider.themeStyle == ThemeStyle.fruit) {
      return _buildFruitBody(context, layout.items, bottomPadding);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding),
      itemCount: layout.items.length,
      itemBuilder: (context, index) {
        final item = layout.items[index];
        if (item is TrackListShowHeaderItem) {
          return _buildShowHeader(context);
        }
        if (item is TrackListSetHeaderItem) {
          return _buildSetHeader(context, item.setName);
        }
        if (item is TrackListTrackItem) {
          return _buildTrackItem(context, item.track, source, item.trackIndex);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFruitBody(
    BuildContext context,
    List<TrackListItem> listItems,
    double bottomPadding,
  ) {
    final double scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      context.watch<SettingsProvider>(),
    );

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top +
            _TrackListScreenState._fruitHeaderTopGap +
            (118.0 * scaleFactor),
        16,
        bottomPadding,
      ),
      children: [
        for (final item in listItems) ...[
          if (item is TrackListSetHeaderItem)
            _buildSetHeader(context, item.setName),
          if (item is TrackListTrackItem)
            _buildTrackItem(
              context,
              item.track,
              widget.source,
              item.trackIndex,
            ),
        ],
      ],
    );
  }

  Widget _buildShowHeader(BuildContext context) {
    return TrackListShowHeaderSection(
      show: widget.show,
      onTap: () => unawaited(_playShowFromHeader()),
    );
  }

  Widget _buildSetHeader(BuildContext context, String setName) {
    return TrackListSetHeaderSection(setName: setName);
  }

  Widget _buildTrackItem(
    BuildContext context,
    Track track,
    Source source,
    int index,
  ) {
    return TrackListItemTile(
      track: track,
      source: source,
      index: index,
      playShowFromHeader: ({required int initialIndex}) =>
          _playShowFromHeader(initialIndex: initialIndex),
    );
  }
}
