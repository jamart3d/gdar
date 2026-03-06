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
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/utils/app_haptics.dart';

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
      final Color starColor =
          isFruit ? colorScheme.primary : Colors.orangeAccent;
      final Brightness brightness = Theme.of(context).brightness;
      // In light mode, the alpha needs to be slightly higher to be visible against frosted glass
      final Color emptyColor = brightness == Brightness.light
          ? colorScheme.outline.withValues(alpha: 0.35)
          : colorScheme.onSurfaceVariant.withValues(alpha: 0.2);

      Widget innerStars = rating == -1
          ? Semantics(
              label: 'Blocked show',
              child: Icon(
                isFruit ? Icons.star : LucideIcons.star,
                size: scaledSize * 1.0, // Increased size
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
              itemPadding: EdgeInsets.symmetric(
                  horizontal:
                      isFruit ? 1.0 : 0.0), // 2px gap to match HTML space-x-0.5
              itemSize: scaledSize * 1.0, // Increased size from 0.9 to 1.0
              ignoreGestures: true,
              ratingWidget: RatingWidget(
                full: Icon(isFruit ? Icons.star_rate_rounded : LucideIcons.star,
                    color: (rating == 0 && isPlayed)
                        ? colorScheme.outline.withValues(alpha: 0.5)
                        : starColor),
                half: Icon(isFruit ? Icons.star_rate_rounded : LucideIcons.star,
                    color: starColor),
                empty: Icon(
                    isFruit ? Icons.star_rate_rounded : LucideIcons.star,
                    color: emptyColor),
              ),
              onRatingUpdate: (_) {},
            );

      if (compact) {
        content = innerStars;
      } else {
        content = NeumorphicWrapper(
          enabled: true,
          isCircle: false,
          borderRadius: 12,
          intensity: 0.8,
          color: Colors.transparent,
          child: LiquidGlassWrapper(
            enabled: true,
            showBorder: false, // Maintain no-sharp-edge rule
            borderRadius: BorderRadius.circular(12),
            opacity: brightness == Brightness.light ? 0.15 : 0.08,
            blur: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: innerStars,
            ),
          ),
        );
      }
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
              full: Icon(isFruit ? Icons.star : Icons.star,
                  color: isFruit ? colorScheme.primary : Colors.amber),
              half: Icon(isFruit ? Icons.star_half : Icons.star_half,
                  color: isFruit ? colorScheme.primary : Colors.amber),
              empty: Icon(isFruit ? Icons.star_border : Icons.star_border,
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
        AppHaptics.selectionClick(context.read<DeviceService>());
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
    final isTv = context.read<DeviceService>().isTv;
    final isFruitNeumorphic = isFruit &&
        settingsProvider.useNeumorphism &&
        !settingsProvider.useTrueBlack &&
        !isTv; // Spec: STICKLY AVOID LiquidGlassWrapper on TV

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
                Builder(builder: (context) {
                  final pill = Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isFruitNeumorphic
                          ? colorScheme.tertiaryContainer
                              .withValues(alpha: 0.25)
                          : colorScheme.tertiaryContainer
                              .withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.sourceId!,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: colorScheme.onTertiaryContainer
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  );

                  if (isTv) {
                    return TvFocusWrapper(
                      onTap: () {
                        if (widget.sourceUrl != null &&
                            widget.sourceUrl!.isNotEmpty) {
                          launchArchivePage(widget.sourceUrl!, context);
                        } else {
                          launchArchiveDetails(widget.sourceId!, context);
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: pill,
                    );
                  }

                  if (isFruitNeumorphic) {
                    return NeumorphicWrapper(
                      borderRadius: 8,
                      intensity: 0.9,
                      color: Colors.transparent,
                      child: LiquidGlassWrapper(
                        enabled: true,
                        showBorder: false,
                        borderRadius: BorderRadius.circular(8),
                        opacity: 0.12,
                        blur: 10.0,
                        child: GestureDetector(
                          onTap: () {
                            if (widget.sourceUrl != null &&
                                widget.sourceUrl!.isNotEmpty) {
                              launchArchivePage(widget.sourceUrl!, context);
                            } else {
                              launchArchiveDetails(widget.sourceId!, context);
                            }
                          },
                          child: pill,
                        ),
                      ),
                    );
                  }
                  return GestureDetector(
                    onTap: () {
                      if (widget.sourceUrl != null &&
                          widget.sourceUrl!.isNotEmpty) {
                        launchArchivePage(widget.sourceUrl!, context);
                      } else {
                        launchArchiveDetails(widget.sourceId!, context);
                      }
                    },
                    child: pill,
                  );
                }),
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
                                  AppHaptics.selectionClick(
                                      context.read<DeviceService>());
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
                                  AppHaptics.selectionClick(
                                      context.read<DeviceService>());
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
                                        : (isFruit
                                            ? colorScheme.primary
                                            : Colors.orangeAccent),
                                  ),
                                  half: Icon(
                                    isFruit
                                        ? LucideIcons.star
                                        : Icons.star_half_rounded,
                                    color: isFruit
                                        ? colorScheme.primary
                                        : Colors.orangeAccent,
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
                                  AppHaptics.selectionClick(
                                      context.read<DeviceService>());
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
                                  borderRadius: 16,
                                  intensity: 1.0,
                                  color: Colors.transparent,
                                  child: LiquidGlassWrapper(
                                    enabled: true,
                                    showBorder: false,
                                    borderRadius: BorderRadius.circular(16),
                                    opacity: 0.08,
                                    blur: 18.0,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      child: ratingBar,
                                    ),
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
                        final chip = Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: isFruitNeumorphic
                                ? colorScheme.secondaryContainer
                                    .withValues(alpha: 0.2)
                                : colorScheme.secondaryContainer
                                    .withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Played ${count}x',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        );
                        if (isFruitNeumorphic) {
                          return NeumorphicWrapper(
                            borderRadius: 20,
                            intensity: 0.7,
                            isPressed: true,
                            color: Colors.transparent,
                            child: LiquidGlassWrapper(
                              enabled: true,
                              showBorder: false,
                              borderRadius: BorderRadius.circular(20),
                              opacity: 0.06,
                              blur: 8.0,
                              child: chip,
                            ),
                          );
                        }
                        return chip;
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
          Divider(
              height: 1,
              color: isFruitNeumorphic
                  ? colorScheme.outline.withValues(alpha: 0.12)
                  : null),
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
        Divider(
            height: 1,
            color: isFruitNeumorphic
                ? colorScheme.outline.withValues(alpha: 0.12)
                : null),
        _buildActionOption(
          context,
          'Block (Red Star)',
          Icons.star,
          isFruitNeumorphic
              ? Colors.redAccent.withValues(alpha: 0.85)
              : Colors.redAccent,
          -1,
        ),
        Divider(
            height: 1,
            color: isFruitNeumorphic
                ? colorScheme.outline.withValues(alpha: 0.12)
                : null),
        _buildActionOption(
          context,
          'Clear Rating',
          Icons.star,
          isFruitNeumorphic
              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
              : Colors.grey,
          0,
        ),
        const SizedBox(height: 8),
      ],
    );

    if (isTv) {
      content = Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: content,
          ),
        ),
      );
    } else if (isFruitNeumorphic) {
      content = LiquidGlassWrapper(
        enabled: true,
        showBorder: false, // Seamless Vapor feel
        borderRadius: BorderRadius.circular(24),
        opacity: 0.35, // Slightly more subtle for deep glass look
        blur: 30, // Deeper blur for the dialog back-plate
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
      elevation: (isFruitNeumorphic || isTv) ? 0 : null,
      backgroundColor: (isFruitNeumorphic || isTv) ? Colors.transparent : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: (isFruitNeumorphic || isTv)
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
