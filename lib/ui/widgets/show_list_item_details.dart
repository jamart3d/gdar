import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:provider/provider.dart';

/// A widget that displays a list of sources (SHNIDs) for a given show.
/// This is used within an expanded [ShowListCard] on the main screen.
class ShowListItemDetails extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // This widget should only be built for shows with multiple sources.
    if (show.sources.length <= 1) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: height,
      child: _buildSourceSelection(context),
    );
  }

  Widget _buildSourceSelection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor = settingsProvider.scaleTrackList ? 1.4 : 1.0;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: show.sources.length,
      itemBuilder: (context, index) {
        final source = show.sources[index];
        final isSourcePlaying = playingSourceId == source.id;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: isSourcePlaying
                ? colorScheme.tertiaryContainer.withOpacity(0.7)
                : colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSourceTapped(source),
              onLongPress: () => onSourceLongPress(source),
              child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12 * scaleFactor),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.shadow.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
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
                    if (!settingsProvider.hideTrackCountInSourceList)
                      Container(
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
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
