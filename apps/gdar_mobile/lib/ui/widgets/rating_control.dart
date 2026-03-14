import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:gdar_mobile/ui/styles/app_typography.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:gdar_mobile/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';

class RatingControl extends StatelessWidget {
  final int rating;
  final VoidCallback? onTap;
  final double size;
  final bool isPlayed;
  final bool compact;
  final bool enforceMinTapTarget;

  const RatingControl({
    super.key,
    required this.rating,
    this.onTap,
    this.size = 24.0,
    this.isPlayed = false,
    this.compact = false,
    this.enforceMinTapTarget = false,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final scaledSize = AppTypography.responsiveFontSize(context, size);

    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final isTv = context.watch<DeviceService>().isTv;
    final isFruitNeumorphic = isFruit &&
        settingsProvider.useNeumorphism &&
        !settingsProvider.useTrueBlack &&
        !isTv;

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
          enabled: !isTv && !settingsProvider.performanceMode,
          isCircle: false,
          borderRadius: 12,
          intensity: 0.8,
          color: settingsProvider.performanceMode
              ? colorScheme.surfaceContainerHighest
              : Colors.transparent,
          child: LiquidGlassWrapper(
            enabled: !isTv && !settingsProvider.performanceMode,
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
      // Android / Expressive Style (RADICALLY DIFFERENT from Fruit)
      if (rating == -1) {
        content = Semantics(
          label: 'Blocked show',
          child: Icon(
            Icons.star_rounded,
            size: scaledSize,
            color: Colors.redAccent,
          ),
        );
      } else {
        content = Semantics(
          label: rating == 0 && isPlayed
              ? 'Played, unrated'
              : 'Rated $rating stars',
          child: RatingBar(
            initialRating: (rating == 0 && isPlayed) ? 1.0 : rating.toDouble(),
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: false,
            itemCount: 3,
            itemSize: scaledSize,
            itemPadding: const EdgeInsets.symmetric(horizontal: 1.0),
            ignoreGestures: true,
            ratingWidget: RatingWidget(
              full: Icon(
                Icons.star_rounded,
                color: (rating == 0 && isPlayed)
                    ? colorScheme.outline.withValues(alpha: 0.5)
                    : Colors.amber,
              ),
              half: const Icon(Icons.star_half_rounded, color: Colors.amber),
              empty: Icon(
                Icons.star_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.1),
              ),
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
          ? content // No wrapping/padding for compact layouts
          : (enforceMinTapTarget
              ? ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth:
                        ((scaledSize * 1.35).clamp(40.0, 48.0)).toDouble(),
                    minHeight:
                        ((scaledSize * 1.35).clamp(40.0, 48.0)).toDouble(),
                  ),
                  child: Center(child: content),
                )
              : ConstrainedBox(
                  constraints:
                      const BoxConstraints(minWidth: 48, minHeight: 48),
                  child: Center(child: content),
                )),
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
              Text(
                'Rate Show',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: isFruit ? FontWeight.w800 : null,
                  fontFamily: isFruit ? 'Inter' : null,
                ),
              ),
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
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 1.5),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: colorScheme.onTertiaryContainer
                                .withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                      ),
                      child: Text(
                        widget.sourceId!,
                        style: textTheme.titleMedium?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
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
                      enabled: !settingsProvider.performanceMode,
                      color: settingsProvider.performanceMode
                          ? colorScheme.tertiaryContainer
                          : Colors.transparent,
                      child: LiquidGlassWrapper(
                        enabled: !settingsProvider.performanceMode,
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
                                        ? Icons.star_rate_rounded
                                        : Icons.star_rounded,
                                    color: (_currentRating == 0 && _isPlayed)
                                        ? Colors.blueGrey.withValues(alpha: 0.4)
                                        : (isFruit
                                            ? colorScheme.primary
                                            : Colors.orangeAccent),
                                  ),
                                  half: Icon(
                                    isFruit
                                        ? Icons.star_rate_rounded
                                        : Icons.star_half_rounded,
                                    color: isFruit
                                        ? colorScheme.primary
                                        : Colors.orangeAccent,
                                  ),
                                  empty: Icon(
                                    isFruit
                                        ? Icons.star_rate_rounded
                                        : Icons.star_rounded,
                                    color: isFruit
                                        ? colorScheme.onSurface
                                            .withValues(alpha: 0.1)
                                        : Colors.blueGrey
                                            .withValues(alpha: 0.3),
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
                                  enabled: !isTv &&
                                      !settingsProvider.performanceMode,
                                  isPressed: true,
                                  borderRadius: 16,
                                  intensity: 1.0,
                                  color: settingsProvider.performanceMode
                                      ? colorScheme.surfaceContainerHighest
                                      : Colors.transparent,
                                  child: LiquidGlassWrapper(
                                    enabled: !isTv &&
                                        !settingsProvider.performanceMode,
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
                            enabled: !isTv && !settingsProvider.performanceMode,
                            color: settingsProvider.performanceMode
                                ? colorScheme.secondaryContainer
                                : Colors.transparent,
                            child: LiquidGlassWrapper(
                              enabled:
                                  !isTv && !settingsProvider.performanceMode,
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
            subtitle: isFruit
                ? Text(
                    'MARK AS PLAYED',
                    style: textTheme.labelSmall?.copyWith(
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  )
                : null,
            value: _isPlayed,
            onChanged: (value) async {
              if (!value && _isPlayed) {
                // Confirm before un-marking
                final confirmed = await _showScaledConfirmationDialog(
                  context,
                  'Mark as Unplayed?',
                  'This will remove the show from your played list.',
                  isTv,
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
          isFruit ? Icons.star_rate_rounded : Icons.star,
          isFruitNeumorphic
              ? Colors.redAccent.withValues(alpha: 0.85)
              : Colors.redAccent,
          -1,
          isTv,
        ),
        Divider(
            height: 1,
            color: isFruitNeumorphic
                ? colorScheme.outline.withValues(alpha: 0.12)
                : null),
        _buildActionOption(
          context,
          'Clear Rating',
          isFruit ? Icons.star_rate_rounded : Icons.star,
          isFruitNeumorphic
              ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
              : Colors.grey,
          0,
          isTv,
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
        enabled: !isTv && !settingsProvider.performanceMode,
        showBorder: false, // Seamless Vapor feel
        borderRadius: BorderRadius.circular(24),
        opacity: 0.35, // Slightly more subtle for deep glass look
        blur: 30, // Deeper blur for the dialog back-plate
        child: NeumorphicWrapper(
          enabled: !isTv && !settingsProvider.performanceMode,
          color: settingsProvider.performanceMode
              ? colorScheme.surface
              : Colors.transparent,
          borderRadius: 16,
          intensity: 1.1,
          child: Material(
            color: settingsProvider.performanceMode
                ? colorScheme.surface
                : Colors.transparent,
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
      Color color, int rating, bool isTv) {
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
            isTv,
          );
          if (confirmed != true) return;
        } else if (rating == 0 && _currentRating > 0) {
          // Confirm before clearing a rating
          final confirmed = await _showScaledConfirmationDialog(
            context,
            'Clear Rating?',
            'Are you sure you want to remove the rating for this show?',
            isTv,
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
      BuildContext context, String title, String content, bool isTv) {
    final settingsProvider = context.read<SettingsProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.5 : 1.0;

    final colorScheme = Theme.of(context).colorScheme;
    final isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;
    final isFruitNeumorphic = isFruit &&
        settingsProvider.useNeumorphism &&
        !settingsProvider.useTrueBlack &&
        !isTv;

    return showDialog<bool>(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scaleFactor),
        ),
        child: isFruitNeumorphic
            ? Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: LiquidGlassWrapper(
                  enabled: !settingsProvider.performanceMode,
                  borderRadius: BorderRadius.circular(24),
                  opacity: 0.4,
                  blur: 25,
                  child: NeumorphicWrapper(
                    enabled: !settingsProvider.performanceMode,
                    borderRadius: 24,
                    color: settingsProvider.performanceMode
                        ? colorScheme.surface
                        : Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Inter')),
                          const SizedBox(height: 16),
                          Text(content,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(fontFamily: 'Inter')),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel',
                                    style: TextStyle(
                                        color: colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                        fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: colorScheme.primary,
                                  foregroundColor: colorScheme.onPrimary,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text('Confirm',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : AlertDialog(
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
