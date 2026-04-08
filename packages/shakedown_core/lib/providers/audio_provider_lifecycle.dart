part of 'audio_provider.dart';

mixin _AudioProviderLifecycle
    on
        ChangeNotifier,
        WidgetsBindingObserver,
        _AudioProviderState,
        _AudioProviderPlayback,
        _AudioProviderDiagnostics {
  void _listenForProcessingState() {
    _processingStateSubscription = _audioPlayer.processingStateStream.listen((
      state,
    ) {
      _updateWakeLockState();

      if (state == ProcessingState.completed) {
        final shouldPlay = _settingsProvider?.playRandomOnCompletion ?? false;
        final sequence = _audioPlayer.sequence;
        final currentIndex = _audioPlayer.currentIndex;
        final looksTerminal =
            sequence.isEmpty ||
            currentIndex == null ||
            currentIndex >= sequence.length - 1;
        logger.i(
          'AudioProvider: ProcessingState.completed received. AutoPlay: '
          '$shouldPlay, Transitioning: $_isTransitioning, Prequeued: '
          '$_hasPrequeuedNextShow, LooksTerminal: $looksTerminal',
        );
        if (!looksTerminal) {
          logger.w(
            'Ignoring ProcessingState.completed because player is not at the '
            'terminal index.',
          );
          return;
        }
        if (_isTransitioning || _hasPrequeuedNextShow) {
          logger.i(
            'Skipping fallback random show because a transition/prequeued '
            'show is already in flight.',
          );
          return;
        }
        if (shouldPlay) {
          logger.i('Playback completed. Triggering fallback random show...');
          playRandomShow();
        }
      }
    });

    _audioPlayer.playingStream.listen((isPlaying) {
      _updateWakeLockState();
      if (isPlaying) {
        _clearPlaybackResumePrompt();
      }
    });
  }

  Future<void> _updateWakeLockState() async {
    final shouldPreventScreensaver = _settingsProvider?.preventSleep ?? true;
    final isPlaying = _audioPlayer.playing;

    if (shouldPreventScreensaver && isPlaying) {
      try {
        if (!(await _wakelockService.enabled)) {
          await _wakelockService.enable();
          logger.d('AudioProvider: Wake Lock ENABLED (Prevent Sleep)');
        }
      } catch (e) {
        logger.w('Failed to enable Wake Lock: $e');
      }
    } else {
      try {
        if (await _wakelockService.enabled) {
          await _wakelockService.disable();
          logger.d('AudioProvider: Wake Lock DISABLED');
        }
      } catch (e) {
        logger.w('Failed to disable Wake Lock: $e');
      }
    }
  }

  void update(
    ShowListProvider showListProvider,
    SettingsProvider settingsProvider,
    AudioCacheService audioCacheService,
  ) {
    _showListProvider = showListProvider;
    _audioCacheService = audioCacheService;

    if (_settingsProvider != null &&
        settingsProvider.webPrefetchSeconds !=
            _settingsProvider!.webPrefetchSeconds) {
      _audioPlayer.setWebPrefetchSeconds(settingsProvider.webPrefetchSeconds);
    }

    if (_settingsProvider != null &&
        settingsProvider.hybridHandoffMode !=
            _settingsProvider!.hybridHandoffMode) {
      _audioPlayer.setHybridHandoffMode(
        settingsProvider.hybridHandoffMode.name,
      );
    }

    if (_settingsProvider != null &&
        settingsProvider.hybridBackgroundMode !=
            _settingsProvider!.hybridBackgroundMode) {
      _audioPlayer.setHybridBackgroundMode(
        settingsProvider.hybridBackgroundMode.name,
      );
    }

    if (_settingsProvider == null ||
        settingsProvider.allowHiddenWebAudio !=
            _settingsProvider!.allowHiddenWebAudio) {
      _audioPlayer.setHybridAllowHiddenWebAudio(
        settingsProvider.allowHiddenWebAudio,
      );
    }

    if (_lastHandoffCrossfadeMs == null ||
        settingsProvider.handoffCrossfadeMs != _lastHandoffCrossfadeMs) {
      _audioPlayer.setHandoffCrossfadeMs(settingsProvider.handoffCrossfadeMs);
      _lastHandoffCrossfadeMs = settingsProvider.handoffCrossfadeMs;
    }

    if (_lastTrackTransitionMode == null ||
        settingsProvider.trackTransitionMode != _lastTrackTransitionMode) {
      _audioPlayer.setTrackTransitionMode(settingsProvider.trackTransitionMode);
      _lastTrackTransitionMode = settingsProvider.trackTransitionMode;
    }

    if (_lastPreventSleep == null ||
        settingsProvider.preventSleep != _lastPreventSleep) {
      _lastPreventSleep = settingsProvider.preventSleep;
      _updateWakeLockState();
    }

    _settingsProvider = settingsProvider;
    _updateBufferAgent();

    if (_lastOfflineBuffering == null ||
        _settingsProvider?.offlineBuffering != _lastOfflineBuffering) {
      _lastOfflineBuffering = _settingsProvider?.offlineBuffering;
      _audioCacheService.monitorCache(_lastOfflineBuffering ?? false);
    }
  }

  void _updateBufferAgent() {
    final shouldEnable = _settingsProvider?.enableBufferAgent ?? false;

    if (_lastEnableBufferAgent == shouldEnable) return;
    _lastEnableBufferAgent = shouldEnable;

    if (shouldEnable && _bufferAgent == null) {
      _bufferAgent = BufferAgent(
        _audioPlayer,
        onRecoveryNotification: (message, retryAction) {
          _bufferAgentNotificationController.add((
            message: message,
            retryAction: retryAction,
          ));
        },
      );
      logger.i('AudioProvider: Buffer Agent enabled');
    } else if (!shouldEnable && _bufferAgent != null) {
      _bufferAgent?.dispose();
      _bufferAgent = null;
      logger.i('AudioProvider: Buffer Agent disabled');
    }
  }

  void _listenForPlaybackProgress() {
    _indexSubscription = _audioPlayer.currentIndexStream.listen((index) async {
      final sequence = _audioPlayer.sequence;
      if (index == null || sequence.isEmpty) return;

      if (index == sequence.length - 1) {
        final shouldPlay = _settingsProvider?.playRandomOnCompletion ?? false;
        if (!_isTransitioning && shouldPlay) {
          logger.i(
            'Started last track (Index $index, Length ${sequence.length}). '
            'Pre-queueing next random show...',
          );
          _isTransitioning = true;
          await queueRandomShow();
        } else {
          logger.d(
            'Last track reached (Index $index, Length ${sequence.length}), '
            'but skipping queue. Transitioning: $_isTransitioning, '
            'AutoPlay: $shouldPlay',
          );
        }
      }

      final currentSource = sequence[index];
      if (currentSource.tag is MediaItem) {
        final item = currentSource.tag as MediaItem;
        final sourceId = item.extras?['source_id'] as String?;

        if (sourceId != null &&
            _pendingRandomShowRequest != null &&
            _pendingRandomShowRequest!.source.id == sourceId) {
          _pendingRandomShowRequest = null;
        }

        if (sourceId != null && _currentSource?.id != sourceId) {
          if (_isSwitchingSource) {
            logger.d(
              'Ignoring source mismatch during manual switch (Player: '
              '$sourceId, App: ${_currentSource?.id})',
            );
          } else {
            _updateCurrentShowFromSourceId(sourceId);
          }
        }
      }

      notifyListeners();
    });
  }

  void _listenForErrors() {
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        logger.e('Playback error', error: error, stackTrace: stackTrace);
        _errorController.add('Playback error: $error');
      },
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _clearUndoCheckpoint();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _audioCacheService.removeListener(notifyListeners);
    _processingStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    _indexSubscription?.cancel();
    _bufferedPositionSubscription?.cancel();
    _errorController.close();
    _randomShowRequestController.close();
    _bufferAgentNotificationController.close();
    _notificationController.close();
    _playbackFocusRequestController.close();
    _diagnosticsTimer?.cancel();
    _diagnosticsController?.close();
    _hudSnapshotController?.close();
    _notificationTimeoutTimer?.cancel();
    _issueTimeoutTimer?.cancel();
    _undoCheckpointTimer?.cancel();
    _audioPlayer.dispose();
    _wakelockService.disable();
    super.dispose();
  }
}
