part of 'audio_provider.dart';

mixin _AudioProviderControls on ChangeNotifier, _AudioProviderState {
  Future<void> playSource(
    Show show,
    Source source, {
    int initialIndex = 0,
    Duration? initialPosition,
  });

  Future<int> _fadeVolume({
    required double from,
    required double to,
    required Duration duration,
  }) async {
    _fadeId++;
    final currentFadeId = _fadeId;
    const steps = 15;
    final stepDurationMs = duration.inMilliseconds ~/ steps;
    final diff = to - from;

    if (stepDurationMs <= 0) {
      await _audioPlayer.setVolume(to);
      return currentFadeId;
    }

    for (var i = 1; i <= steps; i++) {
      await Future.delayed(Duration(milliseconds: stepDurationMs));
      if (_fadeId != currentFadeId) return currentFadeId;
      final volume = from + (diff * (i / steps));
      await _audioPlayer.setVolume(volume);
    }

    if (_fadeId == currentFadeId) {
      await _audioPlayer.setVolume(to);
    }
    return currentFadeId;
  }

  Future<void> play() async {
    try {
      if (_isWeb && (_settingsProvider?.usePlayPauseFade ?? true)) {
        await _audioPlayer.setVolume(0.0);
        unawaited(_audioPlayer.play().catchError((e, stack) {
          logger.e('AudioProvider: play() engine failed: $e');
        }));
        await _fadeVolume(
          from: 0.0,
          to: 1.0,
          duration: const Duration(milliseconds: 150),
        );
        return;
      }

      await _audioPlayer.play();
    } catch (e) {
      logger.e('AudioProvider: play() failed: $e');
    }
  }

  Future<void> resume() => play();

  Future<void> pause() async {
    try {
      if (_isWeb && (_settingsProvider?.usePlayPauseFade ?? true)) {
        final fadeId = await _fadeVolume(
          from: 1.0,
          to: 0.0,
          duration: const Duration(milliseconds: 150),
        );

        // If a new fade started (e.g. from play()), we should NOT pause the
        // engine because that would interrupt the new play request.
        if (_fadeId != fadeId) {
          logger.d('AudioProvider: pause() aborted; newer transition started.');
          return;
        }

        await _audioPlayer.pause();
        await _audioPlayer.setVolume(1.0);
        return;
      }

      await _audioPlayer.pause();
    } catch (e) {
      logger.e('AudioProvider: pause() failed: $e');
    }
  }

  Future<void> stop() => _audioPlayer.stop();

  Future<void> seekToNext() => _audioPlayer.seekToNext();

  Future<void> seekToPrevious() => _audioPlayer.seekToPrevious();

  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  Future<void> retryCurrentSource() async {
    if (_currentShow == null || _currentSource == null) {
      logger.w('retryCurrentSource: No current show or source to retry.');
      return;
    }

    var localIndex = 0;
    if (_audioPlayer.currentIndex != null) {
      try {
        final sequence = _audioPlayer.sequence;
        if (sequence.isNotEmpty &&
            _audioPlayer.currentIndex! < sequence.length) {
          final currentItem =
              sequence[_audioPlayer.currentIndex!].tag as MediaItem;
          localIndex = currentItem.extras?['track_index'] as int? ?? 0;
        }
      } catch (e) {
        logger.w('retryCurrentSource: Error resolving local index: $e');
        localIndex = _audioPlayer.currentIndex!;
      }
    }

    logger.i(
      'retryCurrentSource: Retrying ${_currentShow!.name} at local index '
      '$localIndex',
    );
    await playSource(_currentShow!, _currentSource!, initialIndex: localIndex);
  }

  void seekToTrack(int localIndex) {
    if (_currentSource == null) return;

    final playerState = _audioPlayer.processingState;
    final isStuck =
        playerState == ProcessingState.loading ||
        playerState == ProcessingState.buffering;
    final sequence = _audioPlayer.sequence;

    if (isStuck &&
        (sequence.isEmpty || _audioPlayer.currentIndex != localIndex)) {
      logger.i(
        'seekToTrack: Player is stuck/loading. Re-triggering playSource at '
        'index $localIndex',
      );
      if (_currentShow != null) {
        unawaited(
          playSource(_currentShow!, _currentSource!, initialIndex: localIndex),
        );
        return;
      }
    }

    int? globalIndex;
    for (var i = 0; i < sequence.length; i++) {
      final source = sequence[i];
      if (source.tag is MediaItem) {
        final item = source.tag as MediaItem;
        final sourceId = item.extras?['source_id'] as String?;
        final trackIndex = item.extras?['track_index'] as int?;

        if (sourceId == _currentSource!.id && trackIndex == localIndex) {
          globalIndex = i;
          break;
        }
      }
    }

    if (globalIndex != null) {
      _audioPlayer.seek(Duration.zero, index: globalIndex);
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
      return;
    }

    try {
      _audioPlayer.seek(Duration.zero, index: localIndex);
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
    } catch (e) {
      logger.e('seekToTrack fallback failed: $e');
    }
  }
}
