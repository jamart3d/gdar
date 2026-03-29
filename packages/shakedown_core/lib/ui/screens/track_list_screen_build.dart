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
    final Map<String, List<Track>> tracksBySet = {};
    for (final track in source.tracks) {
      tracksBySet.putIfAbsent(track.setName, () => []).add(track);
    }

    final List<dynamic> listItems = ['SHOW_HEADER'];
    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName);
      listItems.addAll(tracks);
    });

    if (themeProvider.themeStyle == ThemeStyle.fruit) {
      return _buildFruitBody(context, listItems, bottomPadding);
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];
        if (item == 'SHOW_HEADER') {
          return _buildShowHeader(context);
        }
        if (item is String) {
          return _buildSetHeader(context, item);
        }
        if (item is Track) {
          final trackIndex = source.tracks.indexOf(item);
          return _buildTrackItem(context, item, source, trackIndex);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildFruitBody(
    BuildContext context,
    List<dynamic> listItems,
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
        for (int i = 0; i < listItems.length; i++) ...[
          if (listItems[i] is String && listItems[i] != 'SHOW_HEADER')
            _buildSetHeader(context, listItems[i] as String),
          if (listItems[i] is Track)
            _buildTrackItem(
              context,
              listItems[i] as Track,
              widget.source,
              widget.source.tracks.indexOf(listItems[i] as Track),
            ),
        ],
      ],
    );
  }

  Widget _buildShowHeader(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );
    final colorScheme = Theme.of(context).colorScheme;

    final String dateText = AppDateUtils.formatDate(
      widget.show.date,
      settings: settingsProvider,
    );

    final metrics = AppTypography.getHeaderMetrics(settingsProvider.appFont);
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    final Widget headerContent = isFruit
        ? const SizedBox.shrink()
        : Padding(
            padding: EdgeInsets.all(isFruit ? 0.0 : 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dateText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: metrics.height,
                        letterSpacing: metrics.letterSpacing,
                        color: isFruit ? colorScheme.onSurface : null,
                      )
                      .apply(fontSizeFactor: scaleFactor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stadium_rounded,
                      size: 20 * scaleFactor,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.show.venue,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing:
                                  settingsProvider.appFont == 'rock_salt'
                                  ? 1.0
                                  : (settingsProvider.appFont ==
                                            'permanent_marker'
                                        ? 0.5
                                        : 0.0),
                            )
                            .apply(fontSizeFactor: scaleFactor),
                      ),
                    ),
                  ],
                ),
                if (widget.show.location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 20 * scaleFactor,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          widget.show.location,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onSurfaceVariant)
                              .apply(fontSizeFactor: scaleFactor),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Builder(
        builder: (context) {
          final tp = context.watch<ThemeProvider>();
          final isFruit = tp.themeStyle == ThemeStyle.fruit;
          final usePremium =
              settingsProvider.useNeumorphism &&
              isFruit &&
              !settingsProvider.useTrueBlack;

          Future<void> executePlayAndNavigate() async {
            unawaited(
              context.read<AudioProvider>().playSource(
                widget.show,
                widget.source,
              ),
            );

            if (context.read<DeviceService>().isTv) {
              Navigator.of(context).pop();
              context.read<AudioProvider>().requestPlaybackFocus();
              return;
            }

            if (isFruit) {
              if (!mounted) return;
              await Navigator.of(context).pushAndRemoveUntil(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const FruitTabHostScreen(initialTab: 0),
                  transitionDuration: Duration.zero,
                ),
                (route) => false,
              );
              return;
            }

            try {
              context.read<AnimationController>().stop();
            } catch (_) {}

            await Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const PlaybackScreen(),
                transitionDuration: const Duration(milliseconds: 300),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                      const begin = Offset(0.0, 1.0);
                      const end = Offset.zero;
                      const curve = Curves.easeInOut;
                      final tween = Tween(
                        begin: begin,
                        end: end,
                      ).chain(CurveTween(curve: curve));
                      return SlideTransition(
                        position: animation.drive(tween),
                        child: child,
                      );
                    },
              ),
            );

            if (context.mounted) {
              try {
                final controller = context.read<AnimationController>();
                unawaited(controller.repeat());
              } catch (_) {}
            }
          }

          final isTv = context.read<DeviceService>().isTv;

          Widget card = Card(
            elevation: 0,
            color: usePremium
                ? const Color(0x00000000)
                : colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [headerContent]),
          );

          if (usePremium && !isTv) {
            card = NeumorphicWrapper(
              borderRadius: 24,
              intensity: 1.0,
              color: const Color(0x00000000),
              child: LiquidGlassWrapper(
                enabled: !isTv,
                borderRadius: BorderRadius.circular(24),
                opacity: 0.08,
                blur: 15.0,
                child: card,
              ),
            );
          }

          if (context.read<DeviceService>().isTv) {
            final audioProvider = context.watch<AudioProvider>();
            return TvFocusWrapper(
              autofocus: true,
              onTap: () async {
                if (audioProvider.currentShow != null &&
                    audioProvider.currentShow!.name != widget.show.name) {
                  await audioProvider.stopAndClear();
                }
                await executePlayAndNavigate();
              },
              borderRadius: BorderRadius.circular(24),
              child: card,
            );
          }

          return card;
        },
      ),
    );
  }

  Widget _buildSetHeader(BuildContext context, String setName) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    if (isFruit) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.04),
        child: Text(
          setName.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    final scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Builder(
          builder: (context) {
            final tp = context.watch<ThemeProvider>();
            final isFruit = tp.themeStyle == ThemeStyle.fruit;
            final usePremium =
                settingsProvider.useNeumorphism &&
                isFruit &&
                !settingsProvider.useTrueBlack;

            final Widget pill = Container(
              padding: EdgeInsets.symmetric(
                horizontal: 16 * scaleFactor,
                vertical: 6 * scaleFactor,
              ),
              decoration: BoxDecoration(
                color: usePremium
                    ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                    : colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                setName.toUpperCase(),
                style: Theme.of(context).textTheme.labelLarge
                    ?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                    )
                    .apply(fontSizeFactor: scaleFactor),
              ),
            );

            final isTv = context.read<DeviceService>().isTv;

            if (usePremium && !isTv) {
              return NeumorphicWrapper(
                borderRadius: 50,
                intensity: 0.8,
                isPressed: true,
                color: const Color(0x00000000),
                child: LiquidGlassWrapper(
                  enabled: !isTv,
                  borderRadius: BorderRadius.circular(50),
                  opacity: 0.05,
                  blur: 5.0,
                  child: pill,
                ),
              );
            }

            return pill;
          },
        ),
      ),
    );
  }

  Widget _buildTrackItem(
    BuildContext context,
    Track track,
    Source source,
    int index,
  ) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    Offset? tapPosition;

    Future<void> handleTrackTap(AudioProvider audioProvider) async {
      if (!settingsProvider.playOnTap) {
        final screenSize = MediaQuery.sizeOf(context);
        final pos =
            tapPosition ?? Offset(screenSize.width / 2, screenSize.height / 2);

        final result = await showMenu<String>(
          context: context,
          position: RelativeRect.fromLTRB(
            pos.dx,
            pos.dy,
            screenSize.width - pos.dx,
            screenSize.height - pos.dy,
          ),
          items: [
            PopupMenuItem<String>(
              enabled: false,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                '"Play on Tap" is off',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const PopupMenuItem<String>(
              value: 'enable',
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app_rounded, size: 16),
                  SizedBox(width: 8),
                  Text('Enable Play on Tap'),
                ],
              ),
            ),
          ],
        );

        if (result == 'enable') {
          settingsProvider.togglePlayOnTap();
        }
        return;
      }
      if (audioProvider.currentSource?.id == source.id) {
        audioProvider.seekToTrack(index);
      } else {
        unawaited(_playShowFromHeader(initialIndex: index));
      }
    }

    if (isFruit) {
      final audioProvider = context.watch<AudioProvider>();
      final currentTrackIndex = audioProvider.audioPlayer.currentIndex ?? -1;

      final isCurrentTrack =
          audioProvider.currentTrack != null &&
          audioProvider.currentTrack!.title == track.title &&
          audioProvider.currentSource?.id == source.id;

      final bool sameSource = audioProvider.currentSource?.id == source.id;
      final isUpcoming = sameSource && index > currentTrackIndex;
      final isNext = sameSource && index == currentTrackIndex + 1;

      Color dotColor = colorScheme.primary;

      if (isCurrentTrack) {
        final processingState = audioProvider.audioPlayer.processingState;
        if (processingState == ProcessingState.loading ||
            processingState == ProcessingState.buffering) {
          dotColor = const Color(0xFFFFA500);
        } else {
          dotColor = const Color(0xFF2E7D32);
        }
      } else if (isNext) {
        final nextBuffered = audioProvider.nextTrackBuffered;
        final engineState = audioProvider.engineState;

        if (nextBuffered != null && nextBuffered > Duration.zero) {
          dotColor = const Color(0xFF4CAF50);
        } else if (engineState == 'prefetching' || engineState == 'fetching') {
          dotColor = const Color(0xFFFFA500);
        }
      }

      final double contentOpacity = isUpcoming ? 0.6 : 1.0;

      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => tapPosition = details.globalPosition,
        onTap: () => handleTrackTap(audioProvider),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Opacity(
                  opacity: contentOpacity,
                  child: Text(
                    track.title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: isCurrentTrack
                          ? FontWeight.w900
                          : FontWeight.w700,
                      fontFamily: 'Inter',
                      color: isCurrentTrack
                          ? colorScheme.primary
                          : colorScheme.onSurface.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Opacity(
                opacity: contentOpacity,
                child: Text(
                  Duration(
                    seconds: track.duration,
                  ).toString().split('.').first.padLeft(8, '0').substring(3),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final titleStyle = AppTypography.body(
      context,
    ).copyWith(fontWeight: FontWeight.w400, letterSpacing: 0.25);

    final durationStyle = AppTypography.tiny(context).copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    final titleText = settingsProvider.showTrackNumbers
        ? '${track.trackNumber}. ${track.title}'
        : track.title;

    final scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    return Builder(
      builder: (context) {
        final audioProvider = context.watch<AudioProvider>();
        final themeProvider = context.watch<ThemeProvider>();
        final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
        final usePremium =
            settingsProvider.useNeumorphism &&
            isFruit &&
            !settingsProvider.useTrueBlack;

        final isCurrentTrack =
            audioProvider.currentTrack != null &&
            audioProvider.currentTrack!.title == track.title &&
            audioProvider.currentSource?.id == source.id;

        final Widget itemContent = Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12 * scaleFactor,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  titleText,
                  style: titleStyle.copyWith(
                    fontWeight: isCurrentTrack ? FontWeight.w900 : null,
                    color: isCurrentTrack ? colorScheme.primary : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: settingsProvider.hideTrackDuration
                      ? TextAlign.center
                      : TextAlign.left,
                ),
              ),
              if (!settingsProvider.hideTrackDuration) ...[
                const SizedBox(width: 16),
                Text(
                  formatDuration(Duration(seconds: track.duration)),
                  style: durationStyle,
                ),
              ],
            ],
          ),
        );

        if (context.read<DeviceService>().isTv) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: TvFocusWrapper(
              onTap: null,
              borderRadius: BorderRadius.circular(16),
              child: itemContent,
            ),
          );
        }

        final Widget item = InkWell(
          borderRadius: BorderRadius.circular(16),
          onTapDown: (details) => tapPosition = details.globalPosition,
          onTap: () => handleTrackTap(audioProvider),
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
            child: itemContent,
          ),
        );

        final isTv = context.read<DeviceService>().isTv;

        if (usePremium && isCurrentTrack && !isTv) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: NeumorphicWrapper(
              borderRadius: 16,
              intensity: 1.0,
              color: const Color(0x00000000),
              child: LiquidGlassWrapper(
                enabled: !isTv,
                borderRadius: BorderRadius.circular(16),
                opacity: 0.08,
                blur: 10.0,
                child: item,
              ),
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: item,
        );
      },
    );
  }
}
