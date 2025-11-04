import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class ShowListCard extends StatelessWidget {
  final Show show;
  final bool isExpanded;
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ShowListCard({
    super.key,
    required this.show,
    required this.isExpanded,
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
    required this.onLongPress,
  });

  static const Duration _animationDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final cardBorderColor = isPlaying
        ? colorScheme.primary
        : show.hasFeaturedTrack
        ? colorScheme.tertiary
        : colorScheme.outlineVariant;
    final bool shouldShowBadge = show.sources.length > 1 ||
        (show.sources.length == 1 && settingsProvider.showSingleShnid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isExpanded ? 2 : 0,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
              color: cardBorderColor,
              width: (isPlaying || show.hasFeaturedTrack) ? 2 : 1),
        ),
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.easeInOutCubicEmphasized,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: isExpanded
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : colorScheme.surface,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: onTap,
              onLongPress: onLongPress,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: AnimatedSwitcher(
                        duration: _animationDuration,
                        child: isLoading
                            ? Container(
                          key: ValueKey('loader_${show.name}'),
                          width: 36,
                          height: 36,
                          padding: const EdgeInsets.all(8),
                          child: const CircularProgressIndicator(
                              strokeWidth: 2.5),
                        )
                            : AnimatedRotation(
                          key: ValueKey('icon_${show.name}'),
                          turns: isExpanded ? 0.5 : 0,
                          duration: _animationDuration,
                          curve: Curves.easeInOutCubicEmphasized,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: isExpanded
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                                size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(show.venue,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                  color: colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text(show.formattedDate,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.15)),
                        ],
                      ),
                    ),
                    if (shouldShowBadge)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: _buildBadge(context, show),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, Show show) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    final String badgeText;
    if (show.sources.length == 1 && settingsProvider.showSingleShnid) {
      badgeText = show.sources.first.id.replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      badgeText = '${show.sources.length}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      constraints: const BoxConstraints(maxWidth: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondaryContainer.withOpacity(0.7),
            colorScheme.secondaryContainer.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: Text(
        badgeText,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }
}
