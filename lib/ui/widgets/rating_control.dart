import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown/utils/utils.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown/providers/theme_provider.dart';

class RatingControl extends StatelessWidget {
  final int rating;
  final VoidCallback? onTap;
  final double size;
  final bool isPlayed;
  final bool compact;

  const RatingControl({
    super.key,
    required this.rating,
    this.onTap,
    this.size = 24.0,
    this.isPlayed = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final scaledSize = AppTypography.responsiveFontSize(context, size);

    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final isFruitNeumorphic = isFruit &&
        settingsProvider.useNeumorphism &&
        !settingsProvider.useTrueBlack;

    Widget content;

    if (isFruitNeumorphic) {
      final Color starColor = colorScheme.primary;
      final Color emptyColor =
          colorScheme.onSurfaceVariant.withValues(alpha: 0.2);

      content = NeumorphicWrapper(
        enabled: true,
        isCircle: false,
        borderRadius: 12,
        intensity: 1.0,
        color: Colors.transparent,
        child: LiquidGlassWrapper(
          enabled: true,
          borderRadius: BorderRadius.circular(12),
          opacity: 0.08,
          blur: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: rating == -1
                ? Semantics(
                    label: 'Blocked show',
                    child: Icon(
                      LucideIcons.star,
                      size: scaledSize * 0.9,
                      color: Colors.redAccent.withValues(alpha: 0.9),
                    ),
                  )
                : RatingBar(
                    initialRating:
                        (rating == 0 && isPlayed) ? 1.0 : rating.toDouble(),
                    minRating: 1,
                    direction: Axis.horizontal,
                    allowHalfRating: false,
                    itemCount: 3,
                    itemSize: scaledSize * 0.9,
                    ignoreGestures: true,
                    ratingWidget: RatingWidget(
                      full: Icon(LucideIcons.star,
                          color: (rating == 0 && isPlayed)
                              ? colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.4)
                              : starColor),
                      half: Icon(LucideIcons.star, color: starColor),
                      empty: Icon(LucideIcons.star, color: emptyColor),
                    ),
                    onRatingUpdate: (_) {},
                  ),
          ),
        ),
      );
    } else {
      if (rating == -1) {
        content = Semantics(
          label: 'Blocked show',
          child: Icon(
            isFruit ? LucideIcons.star : Icons.star,
            size: scaledSize,
            color: Colors.red,
          ),
        );
      } else if (rating == 0 && isPlayed) {
        content = Semantics(
          key: ValueKey('rating_0_played_$isPlayed'),
          label: 'Played, unrated',
          child: RatingBar(
            initialRating: 1,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 3,
            itemSize: scaledSize,
            ignoreGestures: true,
            ratingWidget: RatingWidget(
              full: Icon(isFruit ? LucideIcons.star : Icons.star,
                  color: Colors.grey),
              half: Icon(isFruit ? LucideIcons.star : Icons.star_half,
                  color: Colors.grey),
              empty: Icon(isFruit ? LucideIcons.star : Icons.star_border,
                  color: Colors.grey),
            ),
            onRatingUpdate: (_) {},
          ),
        );
      } else {
        content = Semantics(
          key: ValueKey('rating_$rating'),
          label: 'Rated $rating stars',
          child: RatingBar(
            initialRating: rating.toDouble(),
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 3,
            itemSize: scaledSize,
            ignoreGestures: true,
            ratingWidget: RatingWidget(
              full: Icon(isFruit ? LucideIcons.star : Icons.star,
                  color: Colors.amber),
              half: Icon(isFruit ? LucideIcons.star : Icons.star_half,
                  color: Colors.amber),
              empty: Icon(isFruit ? LucideIcons.star : Icons.star_border,
                  color: Colors.grey),
            ),
            onRatingUpdate: (_) {},
          ),
        );
      }
    }

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap!();
      },
      child: compact
          ? content
          : ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              child: Center(child: content),
            ),
    );
  }
}

class RatingDialog extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final String? sourceId;
  final String? sourceUrl;
  final bool isPlayed;
  final ValueChanged<bool>? onPlayedChanged;

  const RatingDialog({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
    this.sourceId,
    this.sourceUrl,
    this.isPlayed = false,
    this.onPlayedChanged,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late bool _isPlayed;
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _isPlayed = widget.isPlayed;
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final isFruitNeumorphic = isFruit &&
        settingsProvider.useNeumorphism &&
        !settingsProvider.useTrueBlack;

    Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 12.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Rate Show', style: textTheme.titleLarge),
              if (widget.sourceId != null && widget.sourceId!.isNotEmpty) ...[
                const SizedBox(width: 16),
                InkWell(
                  onTap: () {
                    if (widget.sourceUrl != null &&
                        widget.sourceUrl!.isNotEmpty) {
                      launchArchivePage(widget.sourceUrl!, context);
                    } else {
                      launchArchiveDetails(widget.sourceId!, context);
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color:
                          colorScheme.tertiaryContainer.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.onTertiaryContainer,
                            width: 1.5,
                          ),
                        ),
                      ),
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Text(
                        widget.sourceId!,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: Column(
              children: [
                IgnorePointer(
                  ignoring: _currentRating == -1,
                  child: Opacity(
                    opacity: _currentRating == -1 ? 0.3 : 1.0,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: TvFocusWrapper(
                          onKeyEvent: (node, event) {
                            if (event is KeyDownEvent) {
                              if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft) {
                                final newRating =
                                    (_currentRating - 1).clamp(1, 3);
                                if (newRating != _currentRating) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _currentRating = newRating;
                                  });
                                  widget.onRatingChanged(newRating);
                                }
                                return KeyEventResult.handled;
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight) {
                                final newRating =
                                    (_currentRating + 1).clamp(1, 3);
                                if (newRating != _currentRating) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _currentRating = newRating;
                                  });
                                  widget.onRatingChanged(newRating);
                                }
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Builder(
                            builder: (context) {
                              final settingsProvider =
                                  context.watch<SettingsProvider>();
                              final themeProvider =
                                  context.watch<ThemeProvider>();
                              final isFruitNeumorphic =
                                  themeProvider.themeStyle ==
                                          ThemeStyle.fruit &&
                                      settingsProvider.useNeumorphism &&
                                      !settingsProvider.useTrueBlack;

                              Widget ratingBar = RatingBar(
                                initialRating:
                                    (_currentRating == 0 && _isPlayed)
                                        ? 1.0
                                        : (_currentRating > 0
                                            ? _currentRating.toDouble()
                                            : 0.0),
                                minRating: 1,
                                direction: Axis.horizontal,
                                allowHalfRating: false,
                                itemCount: 3,
                                itemSize: AppTypography.responsiveFontSize(
                                    context, 40.0),
                                itemPadding:
                                    const EdgeInsets.symmetric(horizontal: 4.0),
                                ratingWidget: RatingWidget(
                                  full: Icon(
                                    isFruit
                                        ? LucideIcons.star
                                        : Icons.star_rounded,
                                    color: (_currentRating == 0 && _isPlayed)
                                        ? Colors.blueGrey.withValues(alpha: 0.4)
                                        : Colors.orangeAccent,
                                  ),
                                  half: Icon(
                                    isFruit
                                        ? LucideIcons.star
                                        : Icons.star_half_rounded,
                                    color: Colors.orangeAccent,
                                  ),
                                  empty: Icon(
                                    isFruit
                                        ? LucideIcons.star
                                        : Icons.star_rounded,
                                    color:
                                        Colors.blueGrey.withValues(alpha: 0.3),
                                  ),
                                ),
                                onRatingUpdate: (rating) {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _currentRating = rating.toInt();
                                  });
                                  widget.onRatingChanged(rating.toInt());
                                },
                              );

                              if (isFruitNeumorphic) {
                                return NeumorphicWrapper(
                                  enabled: true,
                                  isPressed: true,
                                  borderRadius: 12,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: ratingBar,
                                  ),
                                );
                              }
                              return ratingBar;
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.sourceId != null) ...[
                  const SizedBox(height: 8),
                  ValueListenableBuilder(
                    valueListenable: CatalogService().playCountsListenable,
                    builder: (context, box, _) {
                      final count = box.get(widget.sourceId!) ?? 0;
                      if (count > 0) {
                        return Text(
                          'Played ${count}x',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
        if (widget.onPlayedChanged != null) ...[
          const Divider(height: 1),
          TvSwitchListTile(
            title: const Text('Mark as Played'),
            secondary: Icon(
              _isPlayed
                  ? (isFruit
                      ? LucideIcons.checkCircle
                      : Icons.check_circle_rounded)
                  : (isFruit ? LucideIcons.circle : Icons.circle_outlined),
              color: _isPlayed ? colorScheme.primary : colorScheme.outline,
            ),
            value: _isPlayed,
            onChanged: (value) async {
              if (!value && _isPlayed) {
                // Confirm before un-marking
                final confirmed = await _showScaledConfirmationDialog(
                  context,
                  'Mark as Unplayed?',
                  'This will remove the show from your played list.',
                );

                if (confirmed != true) return;
              }

              setState(() {
                _isPlayed = value;
              });
              widget.onPlayedChanged?.call(value);
            },
          ),
        ],
        const Divider(height: 1),
        _buildActionOption(
          context,
          'Block (Red Star)',
          isFruit ? LucideIcons.star : Icons.star_rounded,
          Colors.redAccent,
          -1,
        ),
        const Divider(height: 1),
        _buildActionOption(
          context,
          'Clear Rating',
          isFruit ? LucideIcons.star : Icons.star_rounded,
          Colors.grey,
          0,
        ),
        const SizedBox(height: 8),
      ],
    );

    if (isFruitNeumorphic) {
      content = LiquidGlassWrapper(
        enabled: true,
        borderRadius: BorderRadius.circular(16),
        opacity: 0.4, // Higher opacity for dialog legibility
        blur: 25,
        child: NeumorphicWrapper(
          enabled: true,
          borderRadius: 16,
          intensity: 1.1,
          child: Material(
            color: Colors.transparent,
            child: content,
          ),
        ),
      );
    }

    return Dialog(
      elevation: isFruitNeumorphic ? 0 : null,
      backgroundColor: isFruitNeumorphic ? Colors.transparent : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: isFruitNeumorphic
          ? content
          : ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: content,
            ),
    );
  }

  Widget _buildActionOption(BuildContext context, String text, IconData icon,
      Color color, int rating) {
    final isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;
    return TvListTile(
      onTap: () async {
        // Confirmation Logic
        if (rating == -1 && _currentRating > 0) {
          // Confirm before blocking a rated show
          final confirmed = await _showScaledConfirmationDialog(
            context,
            'Block Show?',
            'This show has a rating. Blocking it will remove the rating.',
          );
          if (confirmed != true) return;
        } else if (rating == 0 && _currentRating > 0) {
          // Confirm before clearing a rating
          final confirmed = await _showScaledConfirmationDialog(
            context,
            'Clear Rating?',
            'Are you sure you want to remove the rating for this show?',
          );
          if (confirmed != true) return;
        }

        setState(() {
          _currentRating = rating;
        });
        widget.onRatingChanged(rating);
        if (context.mounted) Navigator.pop(context);
      },
      leading: Icon(icon, color: color),
      title: Text(text),
      trailing: _currentRating == rating
          ? Icon(isFruit ? LucideIcons.check : Icons.check, size: 16)
          : null,
    );
  }

  Future<bool?> _showScaledConfirmationDialog(
      BuildContext context, String title, String content) {
    final settingsProvider = context.read<SettingsProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.5 : 1.0;

    return showDialog<bool>(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scaleFactor),
        ),
        child: AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
