import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shakedown/utils/app_date_utils.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown/ui/widgets/shnid_badge.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/widgets/show_list/embedded_mini_player.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/fruit_icon_button.dart';
import 'package:shakedown/ui/widgets/fruit_tab_bar.dart';

class TrackListScreen extends StatefulWidget {
  final Show show;
  final Source source;

  const TrackListScreen({
    super.key,
    required this.show,
    required this.source,
  });

  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  OverlayEntry? _overlayEntry;

  // Logic identifying the current source/track is removed as requested.

  void _onTrackTapped(BuildContext itemContext, Source source, int trackIndex) {
    final audioProvider = context.read<AudioProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    final isCurrentSource = audioProvider.currentSource?.id == source.id;

    // If Play on Tap is disabled, prevent switching sources by tap
    if (!isCurrentSource && !settingsProvider.playOnTap) {
      unawaited(AppHaptics.mediumImpact(
          context.read<DeviceService>())); // Distinct "blocked" feedback
      _showContextualOverlay(itemContext);
      return;
    }

    unawaited(AppHaptics.selectionClick(
        context.read<DeviceService>())); // Success feedback
    audioProvider.playSource(widget.show, source, initialIndex: trackIndex);

    if (context.read<DeviceService>().isTv) {
      Navigator.of(context).pop();
      audioProvider.requestPlaybackFocus();
    }
  }

  void _showContextualOverlay(BuildContext itemContext) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final renderBox = itemContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 8,
        top: offset.dy,
        width: size.width - 16,
        height: size.height,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Builder(builder: (context) {
              final tp = context.watch<ThemeProvider>();
              final sp = context.watch<SettingsProvider>();
              final isFruit = tp.themeStyle == ThemeStyle.fruit;
              final usePremium =
                  sp.useNeumorphism && isFruit && !sp.useTrueBlack;

              final Widget pill = Container(
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(100),
                  boxShadow: usePremium
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                  border: Border.all(
                    color:
                        colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Play on Tap disabled',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () async {
                        _overlayEntry?.remove();
                        _overlayEntry = null;

                        try {
                          context.read<AnimationController>().stop();
                        } catch (_) {}

                        unawaited(Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const SettingsScreen(
                              highlightSetting: 'play_on_tap',
                            ),
                            transitionDuration: Duration.zero,
                          ),
                        ));

                        if (context.mounted) {
                          try {
                            final controller =
                                context.read<AnimationController>();
                            unawaited(controller.repeat());
                          } catch (_) {}
                        }
                      },
                      child: Text(
                        'SETTINGS',
                        style: textTheme.labelLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              );

              if (usePremium) {
                return NeumorphicWrapper(
                  borderRadius: 100,
                  intensity: 1.1,
                  color: Colors.transparent,
                  child: LiquidGlassWrapper(
                    enabled: usePremium,
                    borderRadius: BorderRadius.circular(100),
                    opacity: 0.85,
                    blur: 15.0,
                    child: pill,
                  ),
                );
              }

              return pill;
            }),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      if (_overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  Future<void> _openPlaybackScreen() async {
    if (context.read<DeviceService>().isTv) return;
    final localContext = context;
    // Pause global clock
    try {
      localContext.read<AnimationController>().stop();
    } catch (_) {}

    unawaited(Navigator.of(localContext).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlaybackScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
      ),
    ));

    // Resume clock
    if (localContext.mounted) {
      try {
        final controller = localContext.read<AnimationController>();
        unawaited(controller.repeat());
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

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
                        Flexible(
                          child: ValueListenableBuilder(
                            valueListenable: CatalogService().ratingsListenable,
                            builder: (context, _, __) {
                              final String ratingKey = widget.source.id;
                              final catalog = CatalogService();
                              final isPlayed = catalog.isPlayed(ratingKey);
                              final rating = catalog.getRating(ratingKey);

                              return RatingControl(
                                key: ValueKey(
                                    '${ratingKey}_${rating}_$isPlayed'),
                                rating: rating,
                                size: 12 *
                                    (settingsProvider.uiScale ? 1.25 : 1.0),
                                isPlayed: isPlayed,
                                compact: true,
                                onTap: () async {
                                  unawaited(showDialog(
                                    context: context,
                                    builder: (context) => RatingDialog(
                                      initialRating:
                                          catalog.getRating(ratingKey),
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
                                  ));
                                },
                              );
                            },
                          ),
                        ),
                        Flexible(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.source.src != null) ...[
                                SrcBadge(
                                  src: widget.source.src!,
                                  matchShnidLook: true,
                                ),
                                const SizedBox(width: 4),
                              ],
                              ShnidBadge(text: widget.source.id),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Builder(builder: (context) {
                  final themeProvider = context.watch<ThemeProvider>();
                  final settingsProvider = context.watch<SettingsProvider>();
                  final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
                  final useNeumorphic = settingsProvider.useNeumorphism &&
                      isFruit &&
                      !settingsProvider.useTrueBlack;

                  final Widget btn = IconButton(
                    icon: Icon(isFruit
                        ? LucideIcons.settings
                        : Icons.settings_rounded),
                    iconSize: 24.0,
                    onPressed: () async {
                      // Pause global clock
                      try {
                        context.read<AnimationController>().stop();
                      } catch (_) {}

                      unawaited(Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const SettingsScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      ));

                      // Resume clock
                      if (context.mounted) {
                        try {
                          final controller =
                              context.read<AnimationController>();
                          if (!controller.isAnimating) {
                            unawaited(controller.repeat());
                          }
                        } catch (_) {}
                      }
                    },
                  );

                  if (useNeumorphic) {
                    return Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: kIsWeb ? (isFruit ? 16.0 : 8.0) : 8.0),
                      child: NeumorphicWrapper(
                        isCircle: false, // Map to rounded square
                        borderRadius: 12.0,
                        intensity: 1.2,
                        color: Colors.transparent,
                        child: LiquidGlassWrapper(
                          enabled: true,
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
                        horizontal: kIsWeb ? (isFruit ? 16.0 : 8.0) : 8.0),
                    child: btn,
                  );
                }),
              ],
            ),
      body: Stack(
        children: [
          _buildBody(),
          if (themeProvider.themeStyle == ThemeStyle.fruit)
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 0,
              right: 0,
              child: _buildFruitHeader(context),
            ),
        ],
      ),
      bottomNavigationBar: themeProvider.themeStyle == ThemeStyle.fruit
          ? FruitTabBar(onOpenPlaybackScreen: _openPlaybackScreen)
          : null,
    );
  }

  Widget _buildBody() {
    final audioProvider = context.watch<AudioProvider>();
    final isDifferentShowPlaying = audioProvider.currentShow != null &&
        audioProvider.currentShow!.name != widget.show.name;
    final themeProvider = context.read<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
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
      BuildContext context, List<dynamic> listItems, double bottomPadding) {
    final settingsProvider = context.watch<SettingsProvider>();
    final usePremium =
        settingsProvider.useNeumorphism && !settingsProvider.useTrueBlack;

    return ListView(
      padding: EdgeInsets.fromLTRB(16, 80, 16, bottomPadding),
      children: [
        _buildShowHeader(context),
        const SizedBox(height: 24),
        Builder(builder: (context) {
          final List<Widget> tracksAndSets = [];
          for (int i = 0; i < listItems.length; i++) {
            final item = listItems[i];
            if (item == 'SHOW_HEADER') continue;
            if (item is String) {
              tracksAndSets.add(_buildSetHeader(context, item));
            } else if (item is Track) {
              final trackIndex = widget.source.tracks.indexOf(item);
              tracksAndSets.add(
                  _buildTrackItem(context, item, widget.source, trackIndex));
            }
          }

          Widget card = Container(
            decoration: BoxDecoration(
              color: usePremium
                  ? Colors.transparent
                  : Theme.of(context).colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: tracksAndSets,
            ),
          );

          if (usePremium) {
            card = NeumorphicWrapper(
              borderRadius: 28,
              intensity: 1.0,
              color: Colors.transparent,
              child: LiquidGlassWrapper(
                enabled: true,
                borderRadius: BorderRadius.circular(28),
                opacity: 0.08,
                blur: 15.0,
                child: card,
              ),
            );
          }

          return card;
        }),
      ],
    );
  }

  Widget _buildShowHeader(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    // USE CENTRALIZED SCALING
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    String dateText =
        AppDateUtils.formatDate(widget.show.date, settings: settingsProvider);

    // USE CENTRALIZED METRICS
    final metrics = AppTypography.getHeaderMetrics(settingsProvider.appFont);
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    final Widget headerContent = Padding(
      padding: EdgeInsets.all(isFruit ? 0.0 : 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            dateText,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: metrics.height,
                  letterSpacing: metrics.letterSpacing,
                  color: isFruit ? colorScheme.onSurface : null,
                )
                .apply(fontSizeFactor: scaleFactor),
          ),
          const SizedBox(height: 8),
          if (isFruit)
            Text(
              '${widget.show.venue}, ${widget.show.location}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
            )
          else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.stadium_rounded,
                    size: 20 * scaleFactor, color: colorScheme.primary),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.show.venue,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          letterSpacing: settingsProvider.appFont == 'rock_salt'
                              ? 1.0
                              : (settingsProvider.appFont == 'permanent_marker'
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
                  Icon(Icons.place_outlined,
                      size: 20 * scaleFactor,
                      color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      widget.show.location,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          )
                          .apply(fontSizeFactor: scaleFactor),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Builder(builder: (context) {
        final tp = context.watch<ThemeProvider>();
        final isFruit = tp.themeStyle == ThemeStyle.fruit;
        final usePremium = settingsProvider.useNeumorphism &&
            isFruit &&
            !settingsProvider.useTrueBlack;

        Future<void> executePlayAndNavigate() async {
          unawaited(context
              .read<AudioProvider>()
              .playSource(widget.show, widget.source));

          // No full-screen player transitions on TV. Instead, return to main and focus player.
          if (context.read<DeviceService>().isTv) {
            Navigator.of(context).pop();
            context.read<AudioProvider>().requestPlaybackFocus();
            return;
          }

          try {
            context.read<AnimationController>().stop();
          } catch (_) {}

          unawaited(Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const PlaybackScreen(),
              transitionDuration: const Duration(milliseconds: 300),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                    position: animation.drive(tween), child: child);
              },
            ),
          ));

          if (context.mounted) {
            try {
              final controller = context.read<AnimationController>();
              unawaited(controller.repeat());
            } catch (_) {}
          }
        }

        Widget cardChild;
        final ap = context.watch<AudioProvider>();
        final bool isThisShowPlaying = ap.currentShow != null &&
            ap.currentShow!.name == widget.show.name &&
            ap.isPlaying;

        final Widget metadataRow = Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ValueListenableBuilder(
                valueListenable: CatalogService().ratingsListenable,
                builder: (context, _, __) {
                  final catalog = CatalogService();
                  final String ratingKey = widget.source.id;
                  final int rating = catalog.getRating(ratingKey);
                  final bool isPlayed = catalog.isPlayed(ratingKey);

                  return RatingControl(
                    key: ValueKey('${ratingKey}_${rating}_$isPlayed'),
                    rating: rating,
                    isPlayed: isPlayed,
                    compact: true,
                    size: 15 * scaleFactor,
                    onTap: () async {
                      unawaited(showDialog(
                        context: context,
                        builder: (context) => RatingDialog(
                          initialRating: catalog.getRating(ratingKey),
                          sourceId: widget.source.id,
                          sourceUrl: widget.source.tracks.isNotEmpty
                              ? widget.source.tracks.first.url
                              : null,
                          isPlayed: catalog.isPlayed(ratingKey),
                          onRatingChanged: (newRating) {
                            catalog.setRating(ratingKey, newRating);
                          },
                          onPlayedChanged: (bool newIsPlayed) {
                            if (newIsPlayed != catalog.isPlayed(ratingKey)) {
                              catalog.togglePlayed(ratingKey);
                            }
                          },
                        ),
                      ));
                    },
                  );
                },
              ),
              const SizedBox(width: 16),
              SrcBadge(
                src: widget.source.src ?? '',
                scaleFactor: scaleFactor,
              ),
              const SizedBox(width: 16),
              // Integrated Play Button
              if (!isThisShowPlaying)
                NeumorphicWrapper(
                  isCircle: true,
                  borderRadius: 100,
                  intensity: 0.7,
                  color: Colors.transparent,
                  child: LiquidGlassWrapper(
                    enabled: usePremium,
                    borderRadius: BorderRadius.circular(100),
                    opacity: 0.14,
                    blur: 6,
                    child: FruitIconButton(
                      icon: Icon(
                        LucideIcons.play,
                        size: 18 * scaleFactor,
                        color: colorScheme.primary,
                      ),
                      size: 22 * scaleFactor,
                      padding: 8 * scaleFactor,
                      tooltip: 'Play Show',
                      onPressed: () async {
                        unawaited(AppHaptics.selectionClick(
                            context.read<DeviceService>()));
                        if (ap.currentShow != null &&
                            ap.currentShow!.name != widget.show.name) {
                          await ap.stopAndClear();
                        }
                        await executePlayAndNavigate();
                      },
                    ),
                  ),
                ),
              if (!isThisShowPlaying) const SizedBox(width: 16),
              ShnidBadge(
                text: widget.source.id,
                scaleFactor: scaleFactor,
              ),
            ],
          ),
        );

        Widget content = Column(
          children: [
            headerContent,
            if (isFruit) ...[
              metadataRow,
              if (isThisShowPlaying) ...[
                const SizedBox(height: 20),
                EmbeddedMiniPlayer(scaleFactor: scaleFactor),
              ],
            ],
          ],
        );

        if (!isFruit && !isThisShowPlaying) {
          content = Stack(
            clipBehavior: Clip.none,
            children: [
              headerContent,
              Positioned(
                bottom: 8,
                left: 8,
                child: IconButton(
                  icon: Icon(
                    Icons.play_circle_fill,
                    size: 28 * scaleFactor,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Play Show',
                  onPressed: () async {
                    unawaited(AppHaptics.selectionClick(
                        context.read<DeviceService>()));
                    if (ap.currentShow != null &&
                        ap.currentShow!.name != widget.show.name) {
                      await ap.stopAndClear();
                    }
                    await executePlayAndNavigate();
                  },
                ),
              ),
            ],
          );
        }

        if (kIsWeb) {
          cardChild = InkWell(
            onTap: () async {
              if (!isThisShowPlaying) {
                unawaited(
                    AppHaptics.selectionClick(context.read<DeviceService>()));
                if (ap.currentShow != null &&
                    ap.currentShow!.name != widget.show.name) {
                  await ap.stopAndClear();
                }
                await executePlayAndNavigate();
              }
            },
            onLongPress: () async {
              unawaited(AppHaptics.mediumImpact(context.read<DeviceService>()));
              if (ap.currentShow != null) {
                await ap.stopAndClear();
              }
              await executePlayAndNavigate();
            },
            child: content,
          );
        } else {
          cardChild = isThisShowPlaying
              ? content
              : InkWell(
                  onTap: () async {
                    if (!isThisShowPlaying) {
                      unawaited(AppHaptics.selectionClick(
                          context.read<DeviceService>()));
                      if (ap.currentShow != null &&
                          ap.currentShow!.name != widget.show.name) {
                        await ap.stopAndClear();
                      }
                      await executePlayAndNavigate();
                    }
                  },
                  onLongPress: () async {
                    unawaited(
                        AppHaptics.mediumImpact(context.read<DeviceService>()));
                    if (ap.currentShow != null) {
                      await ap.stopAndClear();
                    }
                    await executePlayAndNavigate();
                  },
                  child: content,
                );
        }

        Widget card = Card(
          elevation: 0,
          color: usePremium
              ? Colors.transparent
              : colorScheme.surfaceContainerHigh,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          clipBehavior: Clip.antiAlias,
          child: cardChild,
        );

        if (usePremium) {
          card = NeumorphicWrapper(
            borderRadius: 24,
            intensity: 1.0,
            color: Colors.transparent,
            child: LiquidGlassWrapper(
              enabled: true,
              borderRadius: BorderRadius.circular(24),
              opacity: 0.08,
              blur: 15.0,
              child: card,
            ),
          );
        }

        if (context.read<DeviceService>().isTv) {
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
      }),
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
        color:
            colorScheme.onSurfaceVariant.withValues(alpha: 0.04), // Subtle tint
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
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Builder(builder: (context) {
          final tp = context.watch<ThemeProvider>();
          final isFruit = tp.themeStyle == ThemeStyle.fruit;
          final usePremium = settingsProvider.useNeumorphism &&
              isFruit &&
              !settingsProvider.useTrueBlack;

          final Widget pill = Container(
            padding: EdgeInsets.symmetric(
                horizontal: 16 * scaleFactor, vertical: 6 * scaleFactor),
            decoration: BoxDecoration(
              color: usePremium
                  ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
                  : colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              setName.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .labelLarge
                  ?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  )
                  .apply(fontSizeFactor: scaleFactor),
            ),
          );

          if (usePremium) {
            return NeumorphicWrapper(
              borderRadius: 50,
              intensity: 0.8,
              isPressed: true,
              color: Colors.transparent,
              child: LiquidGlassWrapper(
                enabled: true,
                borderRadius: BorderRadius.circular(50),
                opacity: 0.05,
                blur: 5.0,
                child: pill,
              ),
            );
          }

          return pill;
        }),
      ),
    );
  }

  Widget _buildTrackItem(
      BuildContext context, Track track, Source source, int index) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final tp = context.watch<ThemeProvider>();
    final isFruit = tp.themeStyle == ThemeStyle.fruit;

    if (isFruit) {
      return InkWell(
        onTap: () => _onTrackTapped(context, source, index),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
          child: Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  track.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Inter',
                        color: colorScheme.onSurface.withValues(alpha: 0.9),
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                Duration(seconds: track.duration)
                    .toString()
                    .split('.')
                    .first
                    .padLeft(8, '0')
                    .substring(3),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Inter',
                    ),
              ),
            ],
          ),
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

    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    return Builder(builder: (context) {
      final audioProvider = context.watch<AudioProvider>();
      final themeProvider = context.watch<ThemeProvider>();
      final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
      final usePremium = settingsProvider.useNeumorphism &&
          isFruit &&
          !settingsProvider.useTrueBlack;

      final isCurrentTrack = audioProvider.currentTrack != null &&
          audioProvider.currentTrack!.title == track.title &&
          audioProvider.currentSource?.id == source.id;

      Widget itemContent = Padding(
        padding:
            EdgeInsets.symmetric(horizontal: 20, vertical: 12 * scaleFactor),
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
            onTap: () => _onTrackTapped(context, source, index),
            borderRadius: BorderRadius.circular(16),
            child: itemContent,
          ),
        );
      }

      final Widget item = InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _onTrackTapped(context, source, index),
        child: itemContent,
      );

      if (usePremium && isCurrentTrack) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: NeumorphicWrapper(
            borderRadius: 16,
            intensity: 1.0,
            color: Colors.transparent,
            child: LiquidGlassWrapper(
              enabled: true,
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
    });
  }

  Widget _buildFruitHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          _buildFruitNavButton(
            context,
            icon: LucideIcons.chevronLeft,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Center(
              child: Text(
                'TRACKS',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
              ),
            ),
          ),
          _buildFruitNavButton(
            context,
            icon: Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            onPressed: () {
              context.read<ThemeProvider>().toggleTheme();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFruitNavButton(BuildContext context,
      {required IconData icon, required VoidCallback onPressed}) {
    return NeumorphicWrapper(
      isCircle: true,
      borderRadius: 100,
      intensity: 0.8,
      color: Colors.transparent,
      child: LiquidGlassWrapper(
        enabled: true,
        borderRadius: BorderRadius.circular(100),
        opacity: 0.05,
        blur: 5.0,
        child: FruitIconButton(
          icon: Icon(icon),
          size: 20,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
