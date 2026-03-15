import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/ui/widgets/playback/fruit_now_playing_card.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/utils/web_runtime.dart';

class FruitTrackList extends StatefulWidget {
  final Show trackShow;
  final double scaleFactor;
  final double topOffset;
  final double bottomOffset;

  const FruitTrackList({
    super.key,
    required this.trackShow,
    required this.scaleFactor,
    this.topOffset = 0,
    this.bottomOffset = 0,
  });

  @override
  State<FruitTrackList> createState() => _FruitTrackListState();
}

class _FruitTrackListState extends State<FruitTrackList> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _nowPlayingKey = GlobalKey();
  bool _isOffScreenTop = false;
  bool _isOffScreenBottom = false;
  int _lastObservedTrackIndex = -1;

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

    if (containerBox == null) return;

    bool offTop = false;
    bool offBottom = false;

    if (box != null) {
      // Inline card is in the tree, use actual position
      final position = box.localToGlobal(Offset.zero, ancestor: containerBox);
      final viewportHeight = containerBox.size.height;
      final cardHeight = box.size.height;

      offTop = position.dy < widget.topOffset;
      offBottom = (position.dy + cardHeight) > viewportHeight;
    } else {
      // Inline card is NOT in the tree (off-screen).
      // We need to determine if it's off-top or off-bottom.
      if (_scrollController.hasClients) {
        final audioProvider = context.read<AudioProvider>();
        final currentTrackIndex = audioProvider.audioPlayer.currentIndex ?? 0;

        // Simple heuristic: if we are at offset 0, and item is not found,
        // it's likely further down the list.
        // If offset is high, and item is not found, we check if it's likely above.
        // Better: Compare index with estimated scroll position.
        // Assuming average item height of 80px.
        final estimatedTopIndex = _scrollController.offset / 80.0;

        if (currentTrackIndex < estimatedTopIndex) {
          offTop = true;
          offBottom = false;
        } else {
          offTop = false;
          offBottom = true;
        }
      }
    }

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
    final settingsProvider = context.watch<SettingsProvider>();
    final currentTrackIndex = audioProvider.audioPlayer.currentIndex ?? 0;
    final tracks = audioProvider.currentSource?.tracks ?? [];

    final bool isSimple = settingsProvider.performanceMode;
    final bool disableBlur = isSimple || isWasmSafeMode();
    final bool isWebMobile =
        kIsWeb && MediaQuery.sizeOf(context).shortestSide < 700;
    final double stickyBlurSigma = isWebMobile ? 4 : 8;

    // Use a simplified version for the sticky overlay
    Widget buildStickyCard(int index) {
      if (audioProvider.currentTrack == null) return const SizedBox.shrink();
      return FruitNowPlayingCard(
        trackShow: widget.trackShow,
        track: audioProvider.currentTrack!,
        index: index + 1,
        scaleFactor: widget.scaleFactor,
        showNext: false,
      );
    }

    if (currentTrackIndex != _lastObservedTrackIndex) {
      _lastObservedTrackIndex = currentTrackIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) => _handleScroll());
    }

    return Stack(
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            _handleScroll();
            return false;
          },
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.fromLTRB(
              24.0 * widget.scaleFactor, // px-6
              110.0 *
                  widget
                      .scaleFactor, // Avoid overlap with fixed 80px header + breather
              24.0 * widget.scaleFactor,
              (140.0 + widget.bottomOffset) *
                  widget.scaleFactor, // pb-tabbar + dynamic mini-player
            ),
            itemCount: tracks.length,
            itemBuilder: (context, i) {
              final isPlayed = i <= currentTrackIndex;
              final opacity = isPlayed ? 1.0 : 0.6;
              final isCurrent =
                  i == currentTrackIndex && audioProvider.currentTrack != null;

              if (isCurrent && settingsProvider.fruitStickyNowPlaying) {
                return Opacity(
                  // Hide original when sticky is active at top or bottom
                  opacity: (_isOffScreenTop || _isOffScreenBottom) ? 0.0 : 1.0,
                  child: Padding(
                    key: _nowPlayingKey,
                    padding: EdgeInsets.symmetric(
                      vertical: 20 * widget.scaleFactor,
                    ),
                    child: FruitNowPlayingCard(
                      trackShow: widget.trackShow,
                      track: audioProvider.currentTrack!,
                      index: i + 1,
                      scaleFactor: widget.scaleFactor,
                      showNext: false,
                    ),
                  ),
                );
              }

              // If it's the current track but sticky is OFF, render as a regular item
              // but tagged with the key so we can still track its position if needed
              return Opacity(
                opacity: opacity,
                child: _buildTrackItem(
                  context: context,
                  track: tracks[i],
                  index: i,
                  isActive: isCurrent,
                  audioProvider: audioProvider,
                  key: isCurrent ? _nowPlayingKey : null,
                ),
              );
            },
          ),
        ),
        // Sticky Top
        if (settingsProvider.fruitStickyNowPlaying && _isOffScreenTop)
          Positioned(
            top: widget.topOffset,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: disableBlur
                  ? Container(
                      padding: EdgeInsets.fromLTRB(
                        24 * widget.scaleFactor,
                        20 * widget.scaleFactor,
                        24 * widget.scaleFactor,
                        20 * widget.scaleFactor,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      child: buildStickyCard(currentTrackIndex),
                    )
                  : BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: stickyBlurSigma,
                        sigmaY: stickyBlurSigma,
                      ),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          24 * widget.scaleFactor,
                          20 * widget.scaleFactor,
                          24 * widget.scaleFactor,
                          20 * widget.scaleFactor,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.1),
                          border: Border(
                            bottom: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.05),
                            ),
                          ),
                        ),
                        child: buildStickyCard(currentTrackIndex),
                      ),
                    ),
            ),
          ),
        // Sticky Bottom
        if (settingsProvider.fruitStickyNowPlaying && _isOffScreenBottom)
          Positioned(
            bottom: 100 * widget.scaleFactor, // Above tab bar
            left: 0,
            right: 0,
            child: ClipRRect(
              child: disableBlur
                  ? Container(
                      padding: EdgeInsets.fromLTRB(
                        24 * widget.scaleFactor,
                        20 * widget.scaleFactor,
                        24 * widget.scaleFactor,
                        20 * widget.scaleFactor,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      child: buildStickyCard(currentTrackIndex),
                    )
                  : BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: stickyBlurSigma,
                        sigmaY: stickyBlurSigma,
                      ),
                      child: Container(
                        padding: EdgeInsets.fromLTRB(
                          24 * widget.scaleFactor,
                          20 * widget.scaleFactor,
                          24 * widget.scaleFactor,
                          20 * widget.scaleFactor,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.1),
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.05),
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
    Key? key,
  }) {
    return _FruitTrackRow(
      key: key,
      track: track,
      index: index,
      audioProvider: audioProvider,
      scaleFactor: widget.scaleFactor,
      isActive: isActive,
    );
  }
}

class _FruitTrackRow extends StatefulWidget {
  final Track track;
  final int index;
  final AudioProvider audioProvider;
  final double scaleFactor;
  final bool isActive;

  const _FruitTrackRow({
    super.key,
    required this.track,
    required this.index,
    required this.audioProvider,
    required this.scaleFactor,
    this.isActive = false,
  });

  @override
  State<_FruitTrackRow> createState() => _FruitTrackRowState();
}

class _FruitTrackRowState extends State<_FruitTrackRow> {
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final showTrackNumbers = settingsProvider.showTrackNumbers;
    final hideDuration = settingsProvider.hideTrackDuration;

    void activate() {
      AppHaptics.lightImpact(context.read<DeviceService>());
      widget.audioProvider.audioPlayer.seek(Duration.zero, index: widget.index);
    }

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: 'Track ${widget.index + 1}: ${widget.track.title}',
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: true,
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (value) {
            setState(() => _isFocused = value);
          },
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                activate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: activate,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _isPressed ? 0.6 : (_isFocused ? 0.85 : 1.0),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 8.0 * widget.scaleFactor, // px-2
                  vertical:
                      (settingsProvider.fruitDenseList ? 8.0 : 16.0) *
                      widget.scaleFactor, // RESPECT DENSE TOGGLE
                ),
                decoration: BoxDecoration(
                  color: widget.isActive
                      ? colorScheme.primary.withValues(alpha: 0.05)
                      : Colors.transparent,
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isActive
                          ? colorScheme.primary.withValues(alpha: 0.2)
                          : colorScheme.onSurface.withValues(alpha: 0.08),
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
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
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
                                fontSize:
                                    15 * widget.scaleFactor, // text-base-ish
                                fontWeight: widget.isActive
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: widget.isActive
                                    ? colorScheme.primary
                                    : colorScheme.onSurface.withValues(
                                        alpha: 0.8,
                                      ),
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
                          fontFamily: 'Roboto',
                          fontSize: 10 * widget.scaleFactor, // text-[10px]
                          fontWeight: FontWeight.w500, // font-medium
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
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

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0:00';
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
