import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/ui/widgets/playback/track_list_items.dart';
import 'package:shakedown_core/ui/widgets/playback/track_list_set_header.dart';
import 'package:shakedown_core/ui/widgets/playback/track_list_tile.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_reload_dialog.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';

class TrackListView extends StatelessWidget {
  static const double _tvTrackCardRadius = 12.0;

  const TrackListView({
    super.key,
    required this.source,
    required this.bottomPadding,
    this.topPadding = 0.0,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.audioProvider,
    this.trackFocusNodes,
    this.trackListFocusNode,
    this.onFocusLeft,
    this.onFocusRight,
    this.onTrackFocused,
    this.onWrapAround,
    this.initialScrollIndex,
    this.initialScrollAlignment = 0.0,
  });

  final Source source;
  final double bottomPadding;
  final double topPadding;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final AudioProvider audioProvider;
  final Map<int, FocusNode>? trackFocusNodes;
  final FocusNode? trackListFocusNode;
  final VoidCallback? onFocusLeft;
  final VoidCallback? onFocusRight;
  final ValueChanged<int>? onTrackFocused;
  final void Function(int, {bool shouldScroll})? onWrapAround;
  final int? initialScrollIndex;
  final double initialScrollAlignment;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;
    final isTv = context.watch<DeviceService>().isTv;
    final layout = buildTrackListLayout(source);
    final firstTrackListIndex = layout.trackIndexToItemIndex[0] ?? 1;
    final lastTrackListIndex =
        layout.trackIndexToItemIndex[source.tracks.length - 1] ??
        (layout.items.length - 1);

    var resolvedInitialIndex = initialScrollIndex ?? 0;
    final currentTrack = audioProvider.currentTrack;
    if (initialScrollIndex == null && currentTrack != null) {
      for (var i = 0; i < layout.items.length; i++) {
        final item = layout.items[i];
        if (item is TrackListTrackItem &&
            item.track.title == currentTrack.title &&
            item.track.trackNumber == currentTrack.trackNumber) {
          resolvedInitialIndex = i;
          break;
        }
      }
    }

    return Focus(
      focusNode: trackListFocusNode,
      child: ScrollablePositionedList.builder(
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
        initialScrollIndex: resolvedInitialIndex,
        initialAlignment: initialScrollAlignment,
        padding: isTv
            ? EdgeInsets.fromLTRB(28, topPadding, 28, bottomPadding)
            : EdgeInsets.fromLTRB(8, topPadding, 8, bottomPadding),
        itemCount: layout.items.length,
        itemBuilder: (context, index) {
          final item = layout.items[index];
          if (item is TrackListSetHeaderItem) {
            return TrackListSetHeader(setName: item.setName);
          }
          if (item is TrackListTrackItem) {
            return _buildTrackItem(
              context,
              item.track,
              item.trackIndex,
              index,
              isTrueBlackMode,
              firstTrackListIndex,
              lastTrackListIndex,
              ValueKey(
                'track_${item.track.trackNumber}_${item.track.title}_$index',
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildTrackItem(
    BuildContext context,
    Track track,
    int trackIndex,
    int listIndex,
    bool isTrueBlackMode,
    int firstTrackListIndex,
    int lastTrackListIndex,
    Key key,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final isTv = context.watch<DeviceService>().isTv;

    return StreamBuilder<int?>(
      key: key,
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, snapshot) {
        final currentIdx = snapshot.data;
        final isPlaying = currentIdx == trackIndex;
        final scaleFactor = FontLayoutConfig.getEffectiveScale(
          context,
          settingsProvider,
        );
        final isFruit =
            context.watch<ThemeProvider>().themeStyle == ThemeStyle.fruit;
        final showMobilePlayingBorder =
            !isTv && isPlaying && settingsProvider.highlightPlayingWithRgb;

        Widget trackItem = Container(
          margin: EdgeInsets.symmetric(
            horizontal: isFruit ? 8 : 16,
            vertical: isFruit ? 2 : 1,
          ),
          decoration: BoxDecoration(
            color: showMobilePlayingBorder
                ? Colors.transparent
                : (isPlaying && !isFruit && !isTv)
                ? (isTrueBlackMode
                      ? Colors.black
                      : colorScheme.primaryContainer)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(
              isFruit ? 14 : _tvTrackCardRadius,
            ),
          ),
          child: showMobilePlayingBorder
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: const [],
                  ),
                  padding: const EdgeInsets.all(4),
                  child: AnimatedGradientBorder(
                    borderRadius: 12,
                    borderWidth: 4,
                    allowInPerformanceMode: true,
                    ignoreGlobalClock: true,
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
                    showShadow: !isTv && settingsProvider.glowMode > 0,
                    glowOpacity: 0.5 * (settingsProvider.glowMode / 100.0),
                    animationSpeed: settingsProvider.rgbAnimationSpeed,
                    child: Material(
                      color: isTrueBlackMode
                          ? Colors.black
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: TrackListTile(
                        audioProvider: audioProvider,
                        track: track,
                        trackIndex: trackIndex,
                        isPlaying: isPlaying,
                        scaleFactor: scaleFactor,
                        activeTrackIndex: currentIdx,
                        onTap: () {
                          if (!isPlaying) {
                            AppHaptics.lightImpact(
                              context.read<DeviceService>(),
                            );
                            audioProvider.captureUndoCheckpoint();
                            audioProvider.seekToTrack(trackIndex);
                          }
                        },
                        onLongPress: () =>
                            _handleLongPress(context, audioProvider, track),
                      ),
                    ),
                  ),
                )
              : Padding(
                  padding: EdgeInsets.all(isFruit ? 6.0 : 8.0),
                  child: TrackListTile(
                    audioProvider: audioProvider,
                    track: track,
                    trackIndex: trackIndex,
                    isPlaying: isPlaying,
                    scaleFactor: scaleFactor,
                    activeTrackIndex: currentIdx,
                    onTap: () {
                      if (!isPlaying) {
                        AppHaptics.lightImpact(context.read<DeviceService>());
                        audioProvider.captureUndoCheckpoint();
                        audioProvider.seekToTrack(trackIndex);
                      }
                    },
                    onLongPress: () =>
                        _handleLongPress(context, audioProvider, track),
                  ),
                ),
        );

        if (!isTv) return trackItem;

        trackItem = TvFocusWrapper(
          focusNode: trackFocusNodes?[listIndex],
          scaleOnFocus: 1.0,
          isPlaying: isPlaying,
          focusDecoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(_tvTrackCardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 16,
                spreadRadius: 4,
              ),
            ],
          ),
          focusColor: colorScheme.primary,
          borderRadius: BorderRadius.circular(_tvTrackCardRadius),
          showGlow: false,
          tightDecorativeBorder: true,
          decorativeBorderGap: 2.0,
          overridePremiumHighlight: null,
          onFocusChange: (focused) {
            if (focused) onTrackFocused?.call(listIndex);
          },
          onKeyEvent: (node, event) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
              if (event is KeyDownEvent) onFocusLeft?.call();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
              if (event is KeyDownEvent) onFocusRight?.call();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              if (trackIndex == source.tracks.length - 1) {
                if (event is KeyDownEvent) {
                  onWrapAround?.call(firstTrackListIndex);
                }
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              if (trackIndex == 0) {
                if (event is KeyDownEvent) {
                  onWrapAround?.call(lastTrackListIndex);
                }
                return KeyEventResult.handled;
              }
            }
            return KeyEventResult.ignored;
          },
          onLongPress: () => _handleLongPress(context, audioProvider, track),
          onTap: () {
            if (isPlaying) {
              if (audioProvider.isPlaying) {
                audioProvider.pause();
              } else {
                audioProvider.resume();
              }
            } else {
              AppHaptics.lightImpact(context.read<DeviceService>());
              audioProvider.captureUndoCheckpoint();
              audioProvider.seekToTrack(trackIndex);
            }
          },
          child: TrackListTile(
            audioProvider: audioProvider,
            track: track,
            trackIndex: trackIndex,
            isPlaying: isPlaying,
            scaleFactor: scaleFactor,
            activeTrackIndex: currentIdx,
            onLongPress: () => _handleLongPress(context, audioProvider, track),
          ),
        );

        return trackItem;
      },
    );
  }

  void _handleLongPress(
    BuildContext context,
    AudioProvider audioProvider,
    Track track,
  ) {
    final playerState = audioProvider.audioPlayer.processingState;
    final isStuck =
        playerState == ProcessingState.loading ||
        playerState == ProcessingState.buffering;
    final isTv = context.read<DeviceService>().isTv;
    final isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;
    final currentTrack = audioProvider.currentTrack;
    final isThisTrack =
        currentTrack != null &&
        currentTrack.title == track.title &&
        currentTrack.trackNumber == track.trackNumber;

    if (!isTv && (!isStuck || !isThisTrack)) return;

    if (isTv) {
      TvReloadDialog.show(
        context,
        onReload: () => audioProvider.retryCurrentSource(),
        onHardReset: () => audioProvider.stopAndClear(),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final colorScheme = Theme.of(context).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              Text(
                'Safety Hatch',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Is the playback stuck? Try these options to reset the engine.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  isFruit ? LucideIcons.refreshCw : Icons.refresh_rounded,
                ),
                title: const Text('Reload Current Show'),
                onTap: () {
                  Navigator.pop(context);
                  audioProvider.retryCurrentSource();
                },
              ),
              ListTile(
                leading: Icon(
                  isFruit ? LucideIcons.stopCircle : Icons.stop_circle_rounded,
                  color: colorScheme.error,
                ),
                title: Text(
                  'Emergency Reset',
                  style: TextStyle(color: colorScheme.error),
                ),
                subtitle: const Text('Clears playlist and stops all audio'),
                onTap: () {
                  Navigator.pop(context);
                  audioProvider.stopAndClear();
                },
              ),
              const Divider(),
              ListTile(
                leading: Icon(isFruit ? LucideIcons.x : Icons.close_rounded),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
