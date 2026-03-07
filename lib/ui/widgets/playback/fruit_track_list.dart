import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/ui/widgets/playback/fruit_now_playing_card.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:shakedown/providers/settings_provider.dart';

class FruitTrackList extends StatefulWidget {
  final Show trackShow;
  final double scaleFactor;
  final double topOffset;

  const FruitTrackList({
    super.key,
    required this.trackShow,
    required this.scaleFactor,
    this.topOffset = 0,
  });

  @override
  State<FruitTrackList> createState() => _FruitTrackListState();
}

class _FruitTrackListState extends State<FruitTrackList> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _nowPlayingKey = GlobalKey();
  bool _isOffScreenTop = false;
  bool _isOffScreenBottom = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
    // Initial check after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (!mounted) return;
    final RenderBox? box =
        _nowPlayingKey.currentContext?.findRenderObject() as RenderBox?;
    final RenderBox? containerBox = context.findRenderObject() as RenderBox?;

    if (box == null || containerBox == null) return;

    final position = box.localToGlobal(Offset.zero, ancestor: containerBox);
    final viewportHeight = containerBox.size.height;
    final cardHeight = box.size.height;

    final bool offTop = position.dy < widget.topOffset;
    final bool offBottom = (position.dy + cardHeight) > viewportHeight;

    if (offTop != _isOffScreenTop || offBottom != _isOffScreenBottom) {
      setState(() {
        _isOffScreenTop = offTop;
        _isOffScreenBottom = offBottom;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final currentTrackIndex = audioProvider.audioPlayer.currentIndex ?? 0;
    final tracks = audioProvider.currentSource?.tracks ?? [];

    // Use a simplified version for the sticky overlay
    Widget buildStickyCard(int index) {
      if (audioProvider.currentTrack == null) return const SizedBox.shrink();
      return FruitNowPlayingCard(
        trackShow: widget.trackShow,
        track: audioProvider.currentTrack!,
        index: index + 1,
        scaleFactor: widget.scaleFactor,
      );
    }

    return Stack(
      children: [
        ListView.builder(
          controller: _scrollController,
          padding: EdgeInsets.fromLTRB(
            24.0 * widget.scaleFactor, // px-6
            180.0 * widget.scaleFactor, // Avoid overlap with floating header
            24.0 * widget.scaleFactor,
            140.0 * widget.scaleFactor, // pb-tabbar
          ),
          itemCount: tracks.length,
          itemBuilder: (context, i) {
            final isPlayed = i <= currentTrackIndex;
            final opacity = isPlayed ? 1.0 : 0.6;

            if (i == currentTrackIndex && audioProvider.currentTrack != null) {
              return Opacity(
                // Hide original when sticky is active at top or bottom
                opacity: (_isOffScreenTop || _isOffScreenBottom) ? 0.0 : 1.0,
                child: Padding(
                  key: _nowPlayingKey,
                  padding:
                      EdgeInsets.symmetric(vertical: 20 * widget.scaleFactor),
                  child: FruitNowPlayingCard(
                    trackShow: widget.trackShow,
                    track: audioProvider.currentTrack!,
                    index: i + 1,
                    scaleFactor: widget.scaleFactor,
                  ),
                ),
              );
            }

            return Opacity(
              opacity: opacity,
              child: _buildTrackItem(
                context: context,
                track: tracks[i],
                index: i,
                isActive: false, // Card handles active state
                audioProvider: audioProvider,
              ),
            );
          },
        ),
        // Sticky Top
        if (_isOffScreenTop)
          Positioned(
            top: widget.topOffset,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24 * widget.scaleFactor,
                    20 * widget.scaleFactor, // Match list padding
                    24 * widget.scaleFactor,
                    20 * widget.scaleFactor, // Match list padding
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.1), // Glass tint
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: buildStickyCard(currentTrackIndex),
                ),
              ),
            ),
          ),
        // Sticky Bottom
        if (_isOffScreenBottom)
          Positioned(
            bottom: 110 * widget.scaleFactor, // Above tab bar
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24 * widget.scaleFactor,
                    20 * widget.scaleFactor, // Match list padding
                    24 * widget.scaleFactor,
                    20 * widget.scaleFactor, // Match list padding
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.1), // Glass tint
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  child: buildStickyCard(currentTrackIndex),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTrackItem({
    required BuildContext context,
    required Track track,
    required int index,
    required bool isActive,
    required AudioProvider audioProvider,
  }) {
    return _FruitTrackRow(
      track: track,
      index: index,
      audioProvider: audioProvider,
      scaleFactor: widget.scaleFactor,
    );
  }
}

class _FruitTrackRow extends StatefulWidget {
  final Track track;
  final int index;
  final AudioProvider audioProvider;
  final double scaleFactor;

  const _FruitTrackRow({
    required this.track,
    required this.index,
    required this.audioProvider,
    required this.scaleFactor,
  });

  @override
  State<_FruitTrackRow> createState() => _FruitTrackRowState();
}

class _FruitTrackRowState extends State<_FruitTrackRow> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final showTrackNumbers = settingsProvider.showTrackNumbers;
    final hideDuration = settingsProvider.hideTrackDuration;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        AppHaptics.lightImpact(context.read<DeviceService>());
        widget.audioProvider.audioPlayer
            .seek(Duration.zero, index: widget.index);
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isPressed ? 0.6 : 1.0,
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 8.0 * widget.scaleFactor, // px-2
            vertical: (settingsProvider.fruitDenseList ? 8.0 : 16.0) *
                widget.scaleFactor, // RESPECT DENSE TOGGLE
          ),
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
                width: 1.0,
              ),
            ),
          ),
          child: Row(
            children: [
              if (showTrackNumbers) ...[
                SizedBox(
                  width: 20 * widget.scaleFactor, // w-5
                  child: Text(
                    (widget.index + 1).toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10 * widget.scaleFactor, // text-[10px]
                      fontWeight: FontWeight.w800, // font-bold
                      color:
                          colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                SizedBox(width: 16 * widget.scaleFactor), // gap-4
              ],
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 5 * widget.scaleFactor,
                      height: 5 * widget.scaleFactor,
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 10 * widget.scaleFactor),
                    Expanded(
                      child: Text(
                        widget.track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15 * widget.scaleFactor, // text-base-ish
                          fontWeight: FontWeight.w600, // font-semibold
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!hideDuration)
                Text(
                  _formatDuration(widget.track.duration),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10 * widget.scaleFactor, // text-[10px]
                    fontWeight: FontWeight.w500, // font-medium
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0:00';
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
