import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shakedown_core/utils/app_date_utils.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/ui/screens/playback_screen.dart';
import 'package:shakedown_core/ui/screens/settings_screen.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/shnid_badge.dart';
import 'package:shakedown_core/ui/widgets/src_badge.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/widgets/fruit_tab_bar.dart';
import 'package:shakedown_core/ui/screens/fruit_tab_host_screen.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_ui.dart';

class TrackListScreen extends StatefulWidget {
  final Show show;
  final Source source;

  const TrackListScreen({super.key, required this.show, required this.source});

  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  static const double _fruitHeaderTopGap = 14.0;
  static const double _fruitHeaderBodyHeight = 92.0;

  Uri _archiveUriForSource(Source source) {
    final String fallback = 'https://archive.org/details/${source.id}';
    if (source.tracks.isEmpty) {
      return Uri.parse(fallback);
    }

    final String? transformed = transformArchiveUrl(source.tracks.first.url);
    if (transformed == null || transformed.isEmpty) {
      return Uri.parse(fallback);
    }
    return Uri.parse(transformed);
  }

  Future<void> _openPlaybackScreen() async {
    if (context.read<DeviceService>().isTv) return;
    final isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;

    // In Fruit mode, always route through the tab host so Playback/Library
    // actions stay in the same navigation container.
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

    final localContext = context;
    // Pause global clock
    try {
      localContext.read<AnimationController>().stop();
    } catch (_) {}

    await Navigator.of(localContext).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlaybackScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(
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

    // Resume clock
    if (localContext.mounted) {
      try {
        final controller = localContext.read<AnimationController>();
        unawaited(controller.repeat());
      } catch (_) {}
    }
  }

  Future<void> _playShowFromHeader() async {
    unawaited(AppHaptics.selectionClick(context.read<DeviceService>()));
    final ap = context.read<AudioProvider>();
    if (ap.currentShow != null && ap.currentShow!.name != widget.show.name) {
      await ap.stopAndClear();
    }
    unawaited(ap.playSource(widget.show, widget.source));
    await _openPlaybackScreen();
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isTv = context.watch<DeviceService>().isTv;

    return Scaffold(
      appBar: themeProvider.themeStyle == ThemeStyle.fruit
          ? null
          : AppBar(
              // Title is empty as requested
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
                                        // Direct toggle since we don't have explicit setPlayed(bool) yet
                                        // or just use togglePlayed if it matches logic
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

                    final Widget btn = IconButton(
                      icon: Icon(
                        isFruit ? LucideIcons.settings : Icons.settings_rounded,
                      ),
                      iconSize: 24.0,
                      onPressed: () async {
                        // Pause global clock
                        try {
                          context.read<AnimationController>().stop();
                        } catch (_) {}

                        unawaited(
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder:
                                  (context, animation, secondaryAnimation) =>
                                      const SettingsScreen(),
                              transitionDuration: Duration.zero,
                            ),
                          ),
                        );

                        // Resume clock
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
                          isCircle: false, // Map to rounded square
                          borderRadius: 12.0,
                          intensity: 1.2,
                          color: Colors.transparent,
                          child: LiquidGlassWrapper(
                            enabled: !isTv,
                            borderRadius: BorderRadius.circular(12.0),
                            opacity: 0.08,
                            blur: 5.0,
                            child: btn,
                          ),
                        ),
                      );
                    }

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: kIsWeb ? (isFruit ? 16.0 : 8.0) : 8.0,
                      ),
                      child: btn,
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
                      _fruitHeaderTopGap +
                      _fruitHeaderBodyHeight,
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top + _fruitHeaderTopGap,
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
    for (var track in source.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName]!.add(track);
    }

    final List<dynamic> listItems = [];
    // Add Header Key
    listItems.add('SHOW_HEADER');

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
        } else if (item is String) {
          return _buildSetHeader(context, item);
        } else if (item is Track) {
          // Pass absolute index of the track in the source for playback
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
            _fruitHeaderTopGap +
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
    // USE CENTRALIZED SCALING
    final scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );
    final colorScheme = Theme.of(context).colorScheme;

    String dateText = AppDateUtils.formatDate(
      widget.show.date,
      settings: settingsProvider,
    );

    // USE CENTRALIZED METRICS
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

            // No full-screen player transitions on TV. Instead, return to main and focus player.
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
                      var tween = Tween(
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

          Widget cardChild;

          final isTv = context.read<DeviceService>().isTv;

          Widget content = Column(children: [headerContent]);

          cardChild = content;

          Widget card = Card(
            elevation: 0,
            color: usePremium
                ? Colors.transparent
                : colorScheme.surfaceContainerHigh,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: cardChild,
          );

          if (usePremium && !isTv) {
            card = NeumorphicWrapper(
              borderRadius: 24,
              intensity: 1.0,
              color: Colors.transparent,
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
            final ap = context.watch<AudioProvider>();
            return TvFocusWrapper(
              autofocus: true,
              onTap: () async {
                if (ap.currentShow != null &&
                    ap.currentShow!.name != widget.show.name) {
                  await ap.stopAndClear();
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
        color: colorScheme.onSurfaceVariant.withValues(
          alpha: 0.04,
        ), // Subtle tint
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

    // USE CENTRALIZED SCALING
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
                color: Colors.transparent,
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
    final tp = context.watch<ThemeProvider>();
    final isFruit = tp.themeStyle == ThemeStyle.fruit;

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
          dotColor = Colors.orange;
        } else {
          dotColor = const Color(0xFF2E7D32); // Darker Green
        }
      } else if (isNext) {
        final nextBuffered = audioProvider.nextTrackBuffered;
        final engineState = audioProvider.engineState;

        if (nextBuffered != null && nextBuffered > Duration.zero) {
          dotColor = Colors.green;
        } else if (engineState == 'prefetching' || engineState == 'fetching') {
          dotColor = Colors.orange;
        }
      }

      final double contentOpacity = isUpcoming ? 0.6 : 1.0;

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Opacity(
                opacity: contentOpacity,
                child: Text(
                  track.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: isCurrentTrack ? FontWeight.w900 : FontWeight.w700,
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
      );
    }

    // USE CENTRALIZED STYLES
    final titleStyle = AppTypography.body(context).copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      // Color comes from Theme.bodyLarge (colorScheme.onSurface usually),
      // we can explicitly set it if needed but inherited is fine.
    );

    final durationStyle = AppTypography.tiny(context).copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontFeatures: [const FontFeature.tabularFigures()],
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

        Widget itemContent = Padding(
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
              onTap: null, // Restrict playback to the play icon
              borderRadius: BorderRadius.circular(16),
              child: itemContent,
            ),
          );
        }

        final Widget item = Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: itemContent,
        );

        final isTv = context.read<DeviceService>().isTv;

        if (usePremium && isCurrentTrack && !isTv) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: NeumorphicWrapper(
              borderRadius: 16,
              intensity: 1.0,
              color: Colors.transparent,
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

  Widget _buildFruitHeader(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final double scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );
    String dateText = '';
    try {
      final dateTime = DateTime.parse(widget.show.date);
      dateText = DateFormat('EEEE, MMMM d, y').format(dateTime);
    } catch (_) {
      dateText = AppDateUtils.formatDate(
        widget.show.date,
        settings: settingsProvider,
      );
    }

    final catalog = CatalogService();
    final String ratingKey = widget.source.id;
    final Uri archiveUri = _archiveUriForSource(widget.source);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0 * scaleFactor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFruitNavButton(
            context,
            icon: LucideIcons.chevronLeft,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.15,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 5 * scaleFactor),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFruitInlinePlayButton(
                      context,
                      onPressed: _playShowFromHeader,
                    ),
                    SizedBox(width: 8 * scaleFactor),
                    Flexible(
                      child: Text(
                        '${widget.show.venue}, ${widget.show.location}'
                            .toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6 * scaleFactor),
                ValueListenableBuilder(
                  valueListenable: CatalogService().ratingsListenable,
                  builder: (context, _, _) {
                    final int rating = catalog.getRating(ratingKey);
                    final bool isPlayed = catalog.isPlayed(ratingKey);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RatingControl(
                          key: ValueKey('${ratingKey}_${rating}_$isPlayed'),
                          rating: rating,
                          isPlayed: isPlayed,
                          compact: true,
                          size: 20 * scaleFactor,
                          onTap: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => RatingDialog(
                                initialRating: rating,
                                sourceId: widget.source.id,
                                sourceUrl: widget.source.tracks.isNotEmpty
                                    ? widget.source.tracks.first.url
                                    : null,
                                isPlayed: isPlayed,
                                onRatingChanged: (newRating) {
                                  catalog.setRating(ratingKey, newRating);
                                },
                                onPlayedChanged: (bool newIsPlayed) {
                                  if (newIsPlayed != isPlayed) {
                                    catalog.togglePlayed(ratingKey);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        if ((widget.source.src ?? '').isNotEmpty) ...[
                          SizedBox(width: 8 * scaleFactor),
                          SrcBadge(
                            src: widget.source.src ?? '',
                            scaleFactor: scaleFactor,
                          ),
                        ],
                        SizedBox(width: 4 * scaleFactor),
                        ShnidBadge(
                          text: widget.source.id,
                          scaleFactor: scaleFactor,
                          uri: archiveUri,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          _buildFruitMenuButton(
            context,
            onPressed: () => _showFruitOptionsMenu(context, scaleFactor),
          ),
        ],
      ),
    );
  }

  Future<void> _showFruitOptionsMenu(
    BuildContext context,
    double scaleFactor,
  ) async {
    final settingsProvider = context.read<SettingsProvider>();
    final size = MediaQuery.sizeOf(context);
    final double topPadding = MediaQuery.paddingOf(context).top;

    final RelativeRect position = RelativeRect.fromLTRB(
      size.width - 24 * scaleFactor,
      topPadding + 70 * scaleFactor,
      24 * scaleFactor,
      0,
    );

    await showMenu(
      context: context,
      position: position,
      elevation: settingsProvider.performanceMode ? 4 : 0,
      color: settingsProvider.performanceMode
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24 * scaleFactor),
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      items: [
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
  }

  Widget _buildFruitMenuButton(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: FruitActionButton(
          icon: LucideIcons.moreHorizontal,
          onPressed: onPressed,
          tooltip: 'Track list options',
        ),
      ),
    );
  }

  Widget _buildFruitInlinePlayButton(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primary.withValues(alpha: 0.12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.18),
            width: 0.8,
          ),
        ),
        child: Icon(LucideIcons.play, size: 12, color: colorScheme.primary),
      ),
    );
  }

  Widget _buildFruitNavButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: FruitActionButton(icon: icon, onPressed: onPressed),
      ),
    );
  }
}
