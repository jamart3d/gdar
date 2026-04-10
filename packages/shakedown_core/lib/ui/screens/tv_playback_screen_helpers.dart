part of 'tv_playback_screen.dart';

extension _PlaybackScreenHelpers on PlaybackScreenState {
  Future<void> _safeItemScrollTo({
    required int index,
    required double alignment,
    required Duration duration,
    required Curve curve,
  }) async {
    await safeTrackListScrollTo(
      mounted: mounted,
      controller: _itemScrollController,
      index: index,
      alignment: alignment,
      duration: duration,
      curve: curve,
    );
  }

  void _safeItemJumpTo({required int index, required double alignment}) {
    safeTrackListJumpTo(
      mounted: mounted,
      controller: _itemScrollController,
      index: index,
      alignment: alignment,
    );
  }

  void _scrollToCurrentTrack(
    bool animate, {
    bool force = false,
    int? forceTargetIndex,
    double alignment = 0.3,
    double maxVisibleY = 1.0,
    bool syncFocus = false,
  }) {
    if (!mounted) return;
    final audioProvider = context.read<AudioProvider>();
    final currentTrack = audioProvider.currentTrack;
    final currentSource = audioProvider.currentSource;
    if (currentTrack == null && forceTargetIndex == null) return;
    if (currentSource == null) return;

    final Map<String, List<Track>> tracksBySet = {};
    for (final track in currentSource.tracks) {
      tracksBySet.putIfAbsent(track.setName, () => <Track>[]).add(track);
    }

    final List<Object> listItems = [];
    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName);
      listItems.addAll(tracks);
    });

    int targetIndex = forceTargetIndex ?? -1;
    if (targetIndex == -1 && currentTrack != null) {
      for (int i = 0; i < listItems.length; i++) {
        final item = listItems[i];
        if (item is Track &&
            item.title == currentTrack.title &&
            item.trackNumber == currentTrack.trackNumber) {
          targetIndex = i;
          break;
        }
      }
    }

    if (targetIndex == -1) return;

    if (_itemScrollController.isAttached) {
      final positions = _itemPositionsListener.itemPositions.value;

      bool skipScroll = false;
      if (positions.isNotEmpty) {
        if (force) {
          final isAligned = positions.any(
            (position) =>
                position.index == targetIndex &&
                (position.itemLeadingEdge - alignment).abs() < 0.05,
          );
          if (isAligned) skipScroll = true;
        } else {
          final isVisible = positions.any(
            (position) =>
                position.index == targetIndex &&
                position.itemLeadingEdge >= 0 &&
                position.itemTrailingEdge <= maxVisibleY,
          );
          if (isVisible) skipScroll = true;
        }
      }

      if (!skipScroll) {
        if (animate) {
          unawaited(
            _safeItemScrollTo(
              index: targetIndex,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              alignment: alignment,
            ),
          );
        } else {
          _safeItemJumpTo(index: targetIndex, alignment: alignment);
        }
      }
    }

    if (syncFocus && context.read<DeviceService>().isTv) {
      if (!_trackListFocusNode.hasFocus) {
        _focusTrack(targetIndex, shouldScroll: false);
      }
    }
  }

  int _getListIndexForTrack(Source? source, String? title, int? trackNumber) {
    if (source == null || title == null || trackNumber == null) return -1;

    final Map<String, List<Track>> tracksBySet = {};
    for (final track in source.tracks) {
      tracksBySet.putIfAbsent(track.setName, () => <Track>[]).add(track);
    }

    int i = 0;
    for (final entry in tracksBySet.entries) {
      i++;
      for (final track in entry.value) {
        if (track.title == title && track.trackNumber == trackNumber) return i;
        i++;
      }
    }
    return -1;
  }

  int _calculateTotalItems(Source source) {
    return calculateTrackListItems(source);
  }

  void _focusTrack(int index, {bool shouldScroll = true}) {
    if (index < 0) return;
    final audioProvider = context.read<AudioProvider>();
    final currentSource = audioProvider.currentSource;
    if (currentSource == null) return;

    for (final node in _trackFocusNodes.values) {
      if (node.hasFocus) node.unfocus();
    }

    final keysToRemove = _trackFocusNodes.keys
        .where(
          (key) =>
              (key - index).abs() > 20 &&
              !(_trackFocusNodes[key]?.hasPrimaryFocus ?? false),
        )
        .toList();
    for (final key in keysToRemove) {
      _trackFocusNodes[key]?.dispose();
      _trackFocusNodes.remove(key);
    }

    bool needsRebuild = false;
    if (!_trackFocusNodes.containsKey(index)) {
      _trackFocusNodes[index] = FocusNode();
      needsRebuild = true;
    }

    if (needsRebuild) {
      _refreshTrackFocusNodes();
    }

    if (shouldScroll && _itemScrollController.isAttached) {
      final positions = _itemPositionsListener.itemPositions.value;
      if (positions.isEmpty) return;

      bool alreadyAligned = false;
      final target = positions.where((p) => p.index == index).firstOrNull;

      if (target != null) {
        final currentEdge = target.itemLeadingEdge;
        if ((currentEdge - 0.3).abs() < 0.03) {
          alreadyAligned = true;
        } else {
          final last = positions.reduce((a, b) => a.index > b.index ? a : b);
          final first = positions.reduce((a, b) => a.index < b.index ? a : b);
          final totalItems = _calculateTotalItems(currentSource);

          if (last.index == totalItems - 1 && last.itemTrailingEdge <= 1.05) {
            if (target.itemLeadingEdge >= 0 &&
                target.itemTrailingEdge <= 1.05) {
              alreadyAligned = true;
            }
          } else if (first.index == 0 && first.itemLeadingEdge >= -0.05) {
            if (target.itemLeadingEdge >= -0.05 &&
                target.itemTrailingEdge <= 1.0) {
              alreadyAligned = true;
            }
          }
        }
      }

      if (!alreadyAligned) {
        _safeItemJumpTo(index: index, alignment: 0.3);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_trackFocusNodes[index]?.canRequestFocus ?? false)) {
        _trackFocusNodes[index]?.requestFocus();
      }
    });
  }

  void _handleScrollbarLeft() {
    final positions = _itemPositionsListener.itemPositions.value;
    int targetIndex = -1;

    if (positions.isNotEmpty) {
      final sorted = positions.toList()
        ..sort((a, b) => a.index.compareTo(b.index));

      double bestDistance = 999.0;
      for (final position in sorted) {
        final itemCenter =
            (position.itemLeadingEdge + position.itemTrailingEdge) / 2;
        final distance = (itemCenter - 0.5).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          targetIndex = position.index;
        }
      }
    }

    if (targetIndex != -1) {
      _focusTrack(targetIndex, shouldScroll: false);
      return;
    }

    final audioProvider = context.read<AudioProvider>();
    final currentSource = audioProvider.currentSource;
    final trackIndex = audioProvider.audioPlayer.currentIndex;

    if (currentSource != null && trackIndex != null) {
      int listIndex = 0;
      int trackListIndex = 0;
      final Map<String, List<Track>> tracksBySet = {};
      for (final track in currentSource.tracks) {
        tracksBySet.putIfAbsent(track.setName, () => <Track>[]).add(track);
      }

      bool found = false;
      tracksBySet.forEach((_, tracks) {
        if (found) return;
        listIndex++;
        for (final _ in tracks) {
          if (trackListIndex == trackIndex) {
            targetIndex = listIndex;
            found = true;
            return;
          }
          listIndex++;
          trackListIndex++;
        }
      });

      if (found) {
        _focusTrack(targetIndex, shouldScroll: false);
        return;
      }
    }

    _focusTrack(1, shouldScroll: false);
  }
}
