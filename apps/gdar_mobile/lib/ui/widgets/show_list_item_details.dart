import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart'; // Add import
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/utils/utils.dart';

import 'package:gdar_mobile/ui/widgets/source_list_item.dart';
import 'package:shakedown_core/ui/widgets/swipe_action_background.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
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
    final showListProvider = context.read<ShowListProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      itemCount: widget.show.sources.length,
      itemBuilder: (context, index) {
        final source = widget.show.sources[index];
        final isPlaying = widget.playingSourceId == source.id;

        // Common Dismissible Logic
        Future<bool> handleConfirmDismiss() async {
          // Haptic Feedback for the block action
          unawaited(AppHaptics.selectionClick(context.read<DeviceService>()));

          // Stop playback if this specific source is playing
          if (isPlaying ||
              (context.read<AudioProvider>().currentSource?.id == source.id)) {
            final audioProvider = context.read<AudioProvider>();
            unawaited(audioProvider.stopAndClear());
          }

          // Mark as Blocked (Red Star / -1)
          unawaited(context.read<CatalogService>().setRating(source.id, -1));

          showMessage(context, 'Blocked Source "${source.id}"');

          // Return true to allow "slide off" animation
          return true;
        }

        void handleOnDismissed() {
          // Optimistically remove from list to prevent "still in tree" crash.
          showListProvider.dismissSource(widget.show, source.id);
        }

        if (isPlaying && settingsProvider.highlightPlayingWithRgb) {
          return Builder(builder: (context) {
            return Dismissible(
              key: ValueKey(source.id),
              direction: settingsProvider.enableSwipeToBlock
                  ? DismissDirection.endToStart
                  : DismissDirection.none,
              dismissThresholds: const {
                DismissDirection.endToStart: 0.6,
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.block, color: Colors.white, size: 24),
              ),
              confirmDismiss: (direction) => handleConfirmDismiss(),
              onDismissed: (direction) => handleOnDismissed(),
              child: SourceListItem(
                source: source,
                isSourcePlaying: isPlaying,
                scaleFactor: scaleFactor,
                borderRadius: 20, // Match the Dismissible background radius
                showBorder: false,
                onTap: () => widget.onSourceTapped(source),
                onLongPress: () => widget.onSourceLongPress(source),
              ),
            );
          });
        }

        Widget item = SourceListItem(
          source: source,
          isSourcePlaying: isPlaying,
          scaleFactor: scaleFactor,
          borderRadius: 20,
          onTap: () => widget.onSourceTapped(source),
          onLongPress: () => widget.onSourceLongPress(source),
        );

        if (context.watch<DeviceService>().isTv) {
          item = TvFocusWrapper(
            onTap: () => widget.onSourceTapped(source),
            onLongPress: () => widget.onSourceLongPress(source),
            borderRadius: BorderRadius.circular(20),
            child: item,
          );
        }

        // Standard Item
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: Builder(builder: (context) {
            return Dismissible(
              key: ValueKey(source.id),
              direction: settingsProvider.enableSwipeToBlock
                  ? DismissDirection.endToStart
                  : DismissDirection.none,
              dismissThresholds: const {
                DismissDirection.endToStart: 0.6,
              },
              background: const SwipeActionBackground(borderRadius: 20),
              confirmDismiss: (direction) => handleConfirmDismiss(),
              onDismissed: (direction) => handleOnDismissed(),
              child: item,
            );
          }),
        );
      },
    );
  }
}
