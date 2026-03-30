part of 'audio_provider.dart';

mixin _AudioProviderPlayback on ChangeNotifier, _AudioProviderState {
  void clearPendingRandomShowRequest() {
    _pendingRandomShowRequest = null;
    notifyListeners();
  }

  ({Show show, Source source})? pickRandomShow({bool filterBySearch = true}) {
    final settings = _settingsProvider;
    if (settings == null) return null;

    final sourceList = filterBySearch
        ? _showListProvider?.filteredShows
        : _showListProvider?.allShows;

    if (sourceList == null || sourceList.isEmpty) {
      _setError('No shows available for playback.');
      return null;
    }

    final result = RandomShowSelector.pick(
      candidates: sourceList,
      settings: settings,
      catalog: _catalogService,
      currentShow: _currentShow,
      isSourceAllowed: (source) {
        if (_showListProvider != null) {
          return _showListProvider!.isSourceAllowed(source);
        }
        return true;
      },
    );

    if (result == null && _error == null) {
      _setError('No shows found matching criteria.');
    }

    return result;
  }

  Future<Show?> playRandomShow({
    bool filterBySearch = true,
    bool animationOnly = false,
    bool delayPlayback = false,
  }) async {
    if (_showListProvider != null &&
        _showListProvider!.isLoading &&
        _showListProvider!.allShows.isEmpty) {
      logger.i('playRandomShow: Waiting for show list initialization...');
      await _showListProvider!.initializationComplete;
      logger.i('playRandomShow: Initialization complete, proceeding.');
    }

    final selection = pickRandomShow(filterBySearch: filterBySearch);
    if (selection == null) return null;

    final show = selection.show;
    final source = selection.source;

    logger.i(
      'Playing random source: ${source.id} (Rating: '
      '${_catalogService.getRating(source.id)}, Played: '
      '${_catalogService.isPlayed(source.id)})',
    );

    _pendingRandomShowRequest = selection;
    _randomShowRequestController.add(selection);
    _hasPrequeuedNextShow = false;

    if (animationOnly) {
      logger.i(
        'playRandomShow: [TEST MODE] Skipping playback, triggering '
        'animation/scroll only.',
      );
      return show;
    }

    if (delayPlayback) {
      logger.i('playRandomShow: Playback delayed as requested.');
      _currentShow = show;
      _currentSource = source;
      _showListProvider?.setPlayingShow(show.name, source.id);
      notifyListeners();
      return show;
    }

    await playSource(show, source);
    return show;
  }

  Future<void> playPendingSelection() async {
    if (_pendingRandomShowRequest == null) {
      logger.w('playPendingSelection: No pending selection to play.');
      return;
    }

    final show = _pendingRandomShowRequest!.show;
    final source = _pendingRandomShowRequest!.source;

    logger.i('playPendingSelection: Starting playback for ${show.name}');
    await playSource(show, source);
  }

  Future<void> playSource(
    Show show,
    Source source, {
    int initialIndex = 0,
    Duration? initialPosition,
  }) async {
    final requestId = ++_playbackRequestSerial;
    _currentShow = show;
    _currentSource = source;
    _hasPrequeuedNextShow = false;
    _showListProvider?.setPlayingShow(show.name, source.id);
    _hasMarkedAsPlayed = false;
    if (_settingsProvider?.markPlayedOnStart == true &&
        !_catalogService.isPlayed(source.id)) {
      await _catalogService.markAsPlayed(source.id);
      await _catalogService.incrementPlayCount(source.id);
      _hasMarkedAsPlayed = true;
    }
    notifyListeners();

    try {
      _isSwitchingSource = true;
      await _loadAndPlayAudio(
        source,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
        requestId: requestId,
      );
    } finally {
      if (requestId == _playbackRequestSerial) {
        _isSwitchingSource = false;
        _isTransitioning = false;
      }
    }

    if (_settingsProvider?.offlineBuffering ?? false) {
      final currentTrackCount = source.tracks.length;
      final dynamicLimit = max(20, currentTrackCount + 5);
      unawaited(_audioCacheService.performCacheCleanup(maxFiles: dynamicLimit));
      unawaited(
        _audioCacheService.preloadSource(source, startIndex: initialIndex),
      );
    }
  }

  Future<bool> playFromShareString(String shareString) async {
    if (_showListProvider == null) return false;

    final data = ShareLinkParser.parse(shareString);
    if (data == null) {
      logger.w('Clipboard Playback: Could not parse share string');
      return false;
    }

    final shnid = data.shnid;
    final trackName = data.trackName;
    final position = data.position;

    logger.i(
      'Clipboard Playback: Extracted SHNID: "$shnid", Track: "$trackName", '
      'Position: $position',
    );

    try {
      Show? targetShow;
      Source? targetSource;
      var trackIndex = 0;

      for (final show in _showListProvider!.allShows) {
        for (final source in show.sources) {
          if (source.id.toLowerCase() == shnid.toLowerCase()) {
            targetShow = show;
            targetSource = source;
            logger.i('Clipboard Playback: Matched Source: "${source.id}"');
            break;
          }
        }
        if (targetSource != null) break;
      }

      if (targetShow == null || targetSource == null) {
        logger.w('Clipboard Playback: No source found for SHNID "$shnid"');
        return false;
      }

      if (trackName != null) {
        for (var i = 0; i < targetSource.tracks.length; i++) {
          if (targetSource.tracks[i].title.toLowerCase() ==
              trackName.toLowerCase()) {
            trackIndex = i;
            logger.i('Clipboard Playback: Matched track at index $i');
            break;
          }
        }
      }

      logger.i(
        'Clipboard Playback: Playing ${targetSource.id}, track $trackIndex',
      );

      await playSource(
        targetShow,
        targetSource,
        initialIndex: trackIndex,
        initialPosition: position,
      );

      _pendingRandomShowRequest = (show: targetShow, source: targetSource);
      _randomShowRequestController.add((
        show: targetShow,
        source: targetSource,
      ));

      return true;
    } catch (e) {
      logger.e('Error preparing clipboard playback: $e');
      return false;
    }
  }

  Future<void> queueRandomShow() async {
    final selection = pickRandomShow(filterBySearch: false);
    if (selection == null) {
      logger.w('Pre-queueing aborted: No show selected.');
      _isTransitioning = false;
      _hasPrequeuedNextShow = false;
      return;
    }

    final currentTrackCount = _currentSource?.tracks.length ?? 0;
    final dynamicLimit = max(20, currentTrackCount + 5);
    unawaited(_audioCacheService.performCacheCleanup(maxFiles: dynamicLimit));

    final show = selection.show;
    final source = selection.source;

    logger.i('Queueing next show: ${show.date} (${source.id})');
    Uri? artUri;
    try {
      artUri = await _audioCacheService.getAlbumArtUri();
    } catch (_) {}

    final nextSources = source.tracks.asMap().entries.map((entry) {
      final index = entry.key;
      final track = entry.value;

      return _createAudioSource(
        Uri.parse(track.url),
        MediaItem(
          id: '${show.name}_${source.id}_$index',
          album: show.venue,
          title: track.title,
          artist: show.artist,
          duration: Duration(seconds: track.duration),
          artUri: artUri,
          extras: {
            'source_id': source.id,
            'track_index': index,
            'is_prequeued_show': true,
          },
        ),
      );
    }).toList();

    try {
      await _audioPlayer.addAudioSources(nextSources);
      logger.i('Successfully appended ${nextSources.length} tracks.');
      _hasPrequeuedNextShow = true;

      if (_settingsProvider?.offlineBuffering ?? false) {
        unawaited(_audioCacheService.preloadSource(source));
      }

      _isTransitioning = false;
    } catch (e) {
      logger.w(
        'Failed to pre-queue next show (addAudioSources failed). Will load '
        'normally on track end. Error: $e',
      );
      _hasPrequeuedNextShow = false;
      _isTransitioning = false;
    }
  }

  void showNotification(String message) {
    _notificationController.add(message);
  }

  void requestPlaybackFocus() {
    _playbackFocusRequestController.add(null);
  }

  void _updateCurrentShowFromSourceId(String sourceId) {
    if (_showListProvider == null) return;

    if (!_hasMarkedAsPlayed && _currentSource != null) {
      _catalogService.markAsPlayed(_currentSource!.id);
      _catalogService.incrementPlayCount(_currentSource!.id);
      _hasMarkedAsPlayed = true;
    }

    Show? foundShow;
    Source? foundSource;

    for (final show in _showListProvider!.allShows) {
      for (final source in show.sources) {
        if (source.id == sourceId) {
          foundShow = show;
          foundSource = source;
          break;
        }
      }
      if (foundSource != null) break;
    }

    if (foundShow != null && foundSource != null) {
      logger.i(
        'Deep Sleep Transition: Detected track change to ${foundShow.date} '
        '(${foundSource.id}). Updating UI.',
      );
      _currentShow = foundShow;
      _currentSource = foundSource;
      _showListProvider?.setPlayingShow(foundShow.name, foundSource.id);
      _hasMarkedAsPlayed = false;
      _hasPrequeuedNextShow = false;
      _isTransitioning = false;
      _catalogService.recordSession(foundSource.id, showDate: foundShow.date);
      notifyListeners();
    }
  }

  void _setError(String message) {
    if (_error == message) return;

    _error = message;
    _errorController.add(message);

    final now = DateTime.now();
    if (now.difference(_lastErrorNotifyAt) <
        const Duration(milliseconds: 500)) {
      return;
    }
    _lastErrorNotifyAt = now;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _loadAndPlayAudio(
    Source source, {
    int initialIndex = 0,
    Duration? initialPosition,
    required int requestId,
  }) async {
    logger.i(
      'Loading show: ${_currentShow!.name}, source: ${source.id}, starting at '
      'index: $initialIndex',
    );
    logger.i('AudioProvider: Playing with engine: ${_audioPlayer.engineName}');

    Uri? artUri;
    try {
      artUri = await _audioCacheService.getAlbumArtUri();
    } catch (e) {
      logger.w('Failed to get album art URI: $e');
    }

    if (requestId != _playbackRequestSerial) {
      logger.i(
        'Skipping superseded playback request before queue load '
        '(source: ${source.id}, index: $initialIndex)',
      );
      return;
    }

    if (!kIsWeb) {
      try {
        if (_audioPlayer.playing ||
            _audioPlayer.processingState != ProcessingState.idle) {
          await _audioPlayer.stop();
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e) {
        logger.w('Error stopping before source switch (non-fatal): $e');
      }
    }

    try {
      final children = source.tracks.asMap().entries.map((entry) {
        final index = entry.key;
        final track = entry.value;

        return _createAudioSource(
          Uri.parse(track.url),
          MediaItem(
            id: '${_currentShow!.name}_${source.id}_$index',
            album: _currentShow!.venue,
            title: track.title,
            artist: _currentShow!.artist,
            duration: Duration(seconds: track.duration),
            artUri: artUri,
            extras: {'source_id': source.id, 'track_index': index},
          ),
        );
      }).toList();

      if (requestId != _playbackRequestSerial) {
        logger.i(
          'Skipping superseded playback request before setAudioSources '
          '(source: ${source.id}, index: $initialIndex)',
        );
        return;
      }

      await _audioPlayer.setAudioSources(
        children,
        initialIndex: initialIndex,
        initialPosition: initialPosition ?? Duration.zero,
        preload: _settingsProvider?.offlineBuffering ?? false,
      );

      if (requestId != _playbackRequestSerial) {
        logger.i(
          'Skipping play() for superseded playback request '
          '(source: ${source.id}, index: $initialIndex)',
        );
        return;
      }

      unawaited(
        _audioPlayer.play().catchError((e, stack) {
          logger.w('AudioProvider: play() deferred execution failed: $e');
        }),
      );
    } catch (e, stackTrace) {
      if (requestId == _playbackRequestSerial &&
          _currentSource?.id == source.id) {
        logger.e('Error playing source', error: e, stackTrace: stackTrace);
        _error = 'Error playing source: ${e.toString()}';
        _errorController.add(_error!);
        notifyListeners();
        unawaited(stopAndClear());
      } else {
        logger.w(
          'Ignoring error from superseded playback request '
          '(source: ${source.id}, index: $initialIndex): $e',
        );
      }
    }
  }

  Future<void> stopAndClear() async {
    logger.i('Stopping and cleaning up...');
    await _audioPlayer.stop();
    _currentShow = null;
    _showListProvider?.setPlayingShow(null, null);
    _currentSource = null;
    _error = null;
    _pendingRandomShowRequest = null;
    _hasPrequeuedNextShow = false;
    _isTransitioning = false;
    _hasMarkedAsPlayed = false;
    notifyListeners();
  }

  AudioSource _createAudioSource(Uri uri, MediaItem tag) {
    return _audioCacheService.createAudioSource(
      uri: uri,
      tag: tag,
      useCache: _settingsProvider?.offlineBuffering ?? false,
    );
  }
}
