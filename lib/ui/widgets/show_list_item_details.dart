import 'package:flutter/material.dart';
import 'package:gdar/ui/widgets/animated_gradient_border.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/widgets/rating_control.dart';
import 'package:provider/provider.dart';

/// A widget that displays a list of sources (SHNIDs) for a given show.
/// This is used within an expanded [ShowListCard] on the main screen.
class ShowListItemDetails extends StatefulWidget {
  final Show show;
  final String? playingSourceId;
  final double height;
  final Function(Source) onSourceTapped;
  final Function(Source) onSourceLongPress;

  const ShowListItemDetails({
    super.key,
    required this.show,
    required this.playingSourceId,
    required this.height,
    required this.onSourceTapped,
    required this.onSourceLongPress,
  });

  @override
  State<ShowListItemDetails> createState() => _ShowListItemDetailsState();
}

class _ShowListItemDetailsState extends State<ShowListItemDetails> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // This widget should only be built for shows with multiple sources.
    if (widget.show.sources.length <= 1) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: _buildSourceSelection(context),
    );
  }

  Widget _buildSourceSelection(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    final colorScheme = Theme.of(context).colorScheme;

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode &&
        (!settingsProvider.useDynamicColor || settingsProvider.halfGlowDynamic);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.show.sources.length,
      itemBuilder: (context, index) {
        final source = widget.show.sources[index];
        final isPlaying = widget.playingSourceId == source.id;

        // Shadow Visibility:
        // 1. Strict True Black (!useDynamicColor): NO Shadow.
        // 2. Half Glow (useDynamicColor && halfGlowDynamic): YES Shadow (Half Opacity).
        // 3. Standard Dark (useDynamicColor && !halfGlowDynamic): YES Shadow (Full Opacity).
        bool showShadow = !(isDarkMode && !settingsProvider.useDynamicColor);
        double glowOpacity = settingsProvider.halfGlowDynamic ? 0.5 : 1.0;

        if (isPlaying && settingsProvider.highlightPlayingWithRgb) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Dismissible(
              key: ValueKey(source.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.block, color: Colors.white, size: 24),
              ),
              onDismissed: (direction) {
                final audioProvider = context.read<AudioProvider>();
                audioProvider.stopAndClear();
                settingsProvider.setRating(source.id, -1);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Blocked Source "${source.id}"'),
                    action: SnackBarAction(
                      label: 'UNDO',
                      onPressed: () {
                        settingsProvider.setRating(source.id, 0);
                      },
                    ),
                  ),
                );
              },
              child: AnimatedGradientBorder(
                borderRadius: 20,
                borderWidth: 4,
                colors: const [
                  Colors.red,
                  Colors.yellow,
                  Colors.green,
                  Colors.cyan,
                  Colors.blue,
                  Colors.purple,
                  Colors.red,
                ],
                showGlow: true,
                showShadow: showShadow,
                glowOpacity: glowOpacity,
                animationSpeed: settingsProvider.rgbAnimationSpeed,
                backgroundColor: isTrueBlackMode
                    ? Colors.black
                    : colorScheme.tertiaryContainer,
                child: _buildSourceItem(
                  context,
                  source,
                  isPlaying,
                  scaleFactor,
                  16,
                  showBorder: false,
                ),
              ),
            ),
          );
        }

        // Wrap the item in Dismissible for swipe-to-block functionality.
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Dismissible(
            key: ValueKey(source.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16.0),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.block, color: Colors.white, size: 24),
            ),
            onDismissed: (direction) {
              // Stop playback if this specific source is playing
              if (isPlaying) {
                final audioProvider = context.read<AudioProvider>();
                audioProvider.stopAndClear();
              }

              // Mark as Blocked (Red Star / -1)
              settingsProvider.setRating(source.id, -1);

              // Show Undo Snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Blocked Source "${source.id}"'),
                  action: SnackBarAction(
                    label: 'UNDO',
                    onPressed: () {
                      settingsProvider.setRating(source.id, 0);
                    },
                  ),
                ),
              );
            },
            child: _buildSourceItem(
              context,
              source,
              isPlaying,
              scaleFactor,
              20,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSourceItem(
    BuildContext context,
    Source source,
    bool isSourcePlaying,
    double scaleFactor,
    double borderRadius, {
    bool showBorder = true,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode &&
        (!settingsProvider.useDynamicColor || settingsProvider.halfGlowDynamic);

    Color itemBackgroundColor;
    if (isTrueBlackMode) {
      // In True Black mode, background is always black
      itemBackgroundColor = Colors.black;
    } else {
      // Standard behavior
      itemBackgroundColor = isSourcePlaying
          ? colorScheme.tertiaryContainer
          : colorScheme.secondaryContainer;
    }

    return Material(
      color: itemBackgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: (showBorder && (isSourcePlaying || isTrueBlackMode))
              ? Border.all(
                  color: isSourcePlaying
                      ? colorScheme.tertiary
                      : colorScheme.outlineVariant,
                  width: isSourcePlaying ? 2 : 1)
              : null,
          boxShadow: (isTrueBlackMode && !isSourcePlaying)
              ? []
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(borderRadius),
                  onTap: () => widget.onSourceTapped(source),
                  onLongPress: () => widget.onSourceLongPress(source),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12 * scaleFactor),
              child: Row(
                children: [
                  Expanded(
                    child: IgnorePointer(
                      child: Text(
                        source.id,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.apply(fontSizeFactor: scaleFactor)
                            .copyWith(
                              color: isSourcePlaying
                                  ? colorScheme.onTertiaryContainer
                                  : colorScheme.onSecondaryContainer,
                              fontWeight: isSourcePlaying
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      color: Colors.transparent,
                      child: RatingControl(
                        rating: settingsProvider.getRating(source.id),
                        size: 18 * scaleFactor,
                        onTap: isSourcePlaying
                            ? () async {
                                final currentRating =
                                    settingsProvider.getRating(source.id);
                                await showDialog(
                                  context: context,
                                  builder: (context) => RatingDialog(
                                    initialRating: currentRating,
                                    sourceId: source.id,
                                    sourceUrl: source.tracks.isNotEmpty
                                        ? source.tracks.first.url
                                        : null,
                                    onRatingChanged: (newRating) {
                                      settingsProvider.setRating(
                                          source.id, newRating);
                                    },
                                  ),
                                );
                              }
                            : null,
                      ),
                    ),
                  ),
                  if (!settingsProvider.hideTrackCountInSourceList)
                    IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSourcePlaying
                              ? colorScheme.tertiary.withOpacity(0.1)
                              : colorScheme.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${source.tracks.length}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isSourcePlaying
                                        ? colorScheme.onTertiaryContainer
                                        : colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
