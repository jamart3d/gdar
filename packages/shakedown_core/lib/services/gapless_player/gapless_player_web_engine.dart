part of 'gapless_player_web.dart';

mixin _GaplessPlayerWebEngine on _GaplessPlayerBase {
  void _setupVisibilityListener() {
    _visibilityStartTime = DateTime.now();
    try {
      _addEventListener(
        'visibilitychange'.toJS,
        ((JSAny? event) {
          final state = _visibilityState.toDart;
          _isVisible = state == 'visible';
          _visibilityStartTime = DateTime.now();
          _visibilityController.add(_visibilityStatus);
          if (_isVisible) {
            _resyncFromJsState(reason: 'visibility_visible');
          }
        }).toJS,
      );
    } catch (error) {
      logger.w('GaplessPlayerWeb: Failed to setup visibility listener: $error');
    }
  }

  String get _visibilityStatus {
    final now = DateTime.now();
    final difference = now.difference(_visibilityStartTime);
    final minutes = difference.inMinutes;
    final status = _isVisible ? 'VIS' : 'HID';
    return '$status(${minutes}m)';
  }

  void _initJsEngine() {
    final engine = _engine;
    if (engine == null) {
      logger.e(
        'FATAL: Gapless Audio Engine (window._gdarAudio) not found. Web Audio initialization aborted.',
      );
      return;
    }

    final gdar = _GdarAudioEngine(engine);
    gdar.init();
    gdar.onStateChange(
      ((JSAny? raw) {
        if (raw != null && raw.isA<JSObject>()) {
          _onJsStateChange(raw as _GdarState);
        }
      }).toJS,
    );
    gdar.onTrackChange(
      ((JSAny? raw) {
        if (raw == null || !raw.isA<JSObject>()) {
          return;
        }
        final event = raw as _JsTrackChangeEvent;
        final to = event.to;
        _currentIndex = to >= 0 ? to : null;
        _indexController.add(_currentIndex);
        _emitSequenceState();
        _emitPlayerState();
      }).toJS,
    );
    gdar.onError(
      ((JSAny? raw) {
        if (raw == null) {
          return;
        }
        _processingState = ProcessingState.idle;
        _processingStateController.add(_processingState);

        var message = 'Unknown error';
        if (raw.isA<JSString>()) {
          message = (raw as JSString).toDart;
        } else if (raw.isA<JSObject>()) {
          final object = _JSObject(raw as JSObject);
          final errorMessage = object.message;
          if (errorMessage != null) {
            message = errorMessage.toDart;
          } else {
            message = raw.toString();
          }
        }

        _onJsError(message);
      }).toJS,
    );
    if (_JSObject(engine).hasOwnProperty('onPlayBlocked'.toJS)) {
      gdar.onPlayBlocked(
        ((JSAny? raw) {
          _emitPlayBlocked();
        }).toJS,
      );
    } else {
      logger.w(
        'GaplessPlayerWeb: JS engine missing onPlayBlocked(). '
        'Likely stale deployed web bundle; continuing without play-blocked '
        'callback.',
      );
    }
  }

  void _onJsError(String message) {
    if (message == 'Relisten engine error') return;
    _playbackEventController.addError(
      Exception('WebAudio: $message'),
      StackTrace.current,
    );
  }

  void _callEngine(void Function(_GdarAudioEngine) action) {
    if (!_useJsEngine) {
      return;
    }
    final engine = _engine;
    if (engine != null) {
      action(_GdarAudioEngine(engine));
    }
  }

  void _resyncFromJsState({String reason = 'manual'}) {
    if (!_useJsEngine) {
      return;
    }

    _callEngine((engine) {
      try {
        final state = engine.getState();
        logger.i('GaplessPlayerWeb: resyncFromJsState reason=$reason');
        _onJsStateChange(state);
      } catch (error, stackTrace) {
        logger.w('GaplessPlayerWeb: resync failed: $error\n$stackTrace');
      }
    });
  }

  void _startStaleTickWatchdog() {
    _staleTickTimer ??= Timer.periodic(
      _GaplessPlayerBase._staleTickPollInterval,
      (_) {
        if (WebTickStallPolicy.shouldResync(
          playing: _playing,
          visible: _isVisible,
          lastTickAt: _lastTickAt,
          stallThreshold: _GaplessPlayerBase._staleTickThreshold,
          now: DateTime.now(),
        )) {
          _resyncFromJsState(reason: 'stale_tick');
        }
      },
    );
  }

  ProcessingState _mapProcessingState(String jsState) {
    switch (jsState) {
      case 'loading':
        return ProcessingState.loading;
      case 'buffering':
        return ProcessingState.buffering;
      case 'ready':
        return ProcessingState.ready;
      case 'ended':
      case 'completed':
        return ProcessingState.completed;
      case 'handoff_countdown':
        return ProcessingState.ready;
      case 'suspended_by_os':
        return ProcessingState.idle;
      case 'idle':
      default:
        return ProcessingState.idle;
    }
  }

  void _onJsStateChange(_GdarState state) {
    final now = DateTime.now();
    if (_lastTickAt != null) {
      final diff = now.difference(_lastTickAt!).inMilliseconds / 1000.0;
      _lastDrift = diff;
      _driftController.add(diff);
    }
    _lastTickAt = now;

    _visibilityController.add(_visibilityStatus);

    final wasPlaying = _playing;
    final wasDuration = _durationSec;
    final wasIndex = _currentIndex;

    try {
      final position = state.position;
      _positionSec = (position != null && position.isFinite) ? position : 0.0;
      final duration = state.duration;
      _durationSec = (duration != null && duration.isFinite) ? duration : 0.0;

      final currentBuffered = state.currentTrackBuffered;
      _currentTrackBufferedSec =
          (currentBuffered != null && currentBuffered.isFinite)
          ? currentBuffered
          : 0.0;
      final nextBuffered = state.nextTrackBuffered;
      _nextTrackBufferedSec = (nextBuffered != null && nextBuffered.isFinite)
          ? nextBuffered
          : 0.0;
      final nextTotal = state.nextTrackTotal;
      _nextTrackTotalSec = (nextTotal != null && nextTotal.isFinite)
          ? nextTotal
          : 0.0;

      final index = state.index;
      _currentIndex = (index != null && index >= 0) ? index : null;

      final processingState = state.processingState;
      _lastJsState = processingState;
      _processingState = _mapProcessingState(processingState ?? 'idle');
      _engineStateStringController.add(processingState ?? 'idle');

      if (wasIndex != _currentIndex || wasDuration != _durationSec) {
        _indexController.add(_currentIndex);
        _durationController.add(
          Duration(milliseconds: (_durationSec * 1000).round()),
        );
      }

      _playing = state.playing ?? false;
      if (wasPlaying != _playing) {
        _playingController.add(_playing);
      }

      final heartbeatActive = state.heartbeatActive ?? false;
      if (_heartbeatActive != heartbeatActive) {
        _heartbeatActive = heartbeatActive;
        _heartbeatActiveController.add(_heartbeatActive);
      }

      final heartbeatNeeded = state.heartbeatNeeded ?? true;
      if (_heartbeatNeeded != heartbeatNeeded) {
        _heartbeatNeeded = heartbeatNeeded;
        _heartbeatNeededController.add(_heartbeatNeeded);
      }

      final ttfb = state.fetchTtfbMs;
      if (ttfb != null && ttfb.isFinite) {
        _lastFetchTtfbMs = ttfb;
      }
      _fetchInFlight = state.fetchInFlight ?? false;
      final gap = state.lastGapMs;
      if (gap != null && gap.isFinite) {
        _lastGapMs = gap;
      }

      _scheduledIndex = state.scheduledIndex;
      _scheduledStartContextTime = state.scheduledStartContextTime;
      _scheduledStartContextTimeController.add(_scheduledStartContextTime);

      _ctxCurrentTime = state.ctxCurrentTime;
      _outputLatencyMs = state.outputLatencyMs;
      _outputLatencyMsController.add(_outputLatencyMs);

      _lastDecodeMs = state.lastDecodeMs;
      _lastDecodeMsController.add(_lastDecodeMs);

      _lastConcatMs = state.lastConcatMs;
      _lastConcatMsController.add(_lastConcatMs);

      _failedTrackCount = state.failedTrackCount;
      _failedTrackCountController.add(_failedTrackCount);

      _workerTickCount = state.workerTickCount;
      _workerTickCountController.add(_workerTickCount);

      _sampleRate = state.sampleRate;
      _sampleRateController.add(_sampleRate);

      _decodedCacheSize = state.decodedCacheSize;
      _decodedCacheSizeController.add(_decodedCacheSize);

      _handoffState = state.handoffState;
      _handoffStateController.add(_handoffState);

      _handoffAttemptCount = state.handoffAttemptCount;
      _handoffAttemptCountController.add(_handoffAttemptCount);

      _lastHandoffPollCount = state.lastHandoffPollCount;
      _lastHandoffPollCountController.add(_lastHandoffPollCount);
    } catch (error, stackTrace) {
      logger.w(
        'GaplessPlayerWeb: Error unboxing engine state: $error\n$stackTrace',
      );
      return;
    }

    _positionController.add(
      Duration(milliseconds: (_positionSec * 1000).round()),
    );

    _bufferedPositionController.add(
      Duration(milliseconds: (_currentTrackBufferedSec * 1000).round()),
    );

    if (_durationSec != wasDuration) {
      final durationMilliseconds = (_durationSec * 1000).round();
      _durationController.add(
        durationMilliseconds > 0
            ? Duration(milliseconds: durationMilliseconds)
            : null,
      );
    }

    final nextBufferedMilliseconds = (_nextTrackBufferedSec * 1000).round();
    _nextTrackBufferedController.add(
      nextBufferedMilliseconds > 0
          ? Duration(milliseconds: nextBufferedMilliseconds)
          : null,
    );

    final nextTotalMilliseconds = (_nextTrackTotalSec * 1000).round();
    _nextTrackTotalController.add(
      nextTotalMilliseconds > 0
          ? Duration(milliseconds: nextTotalMilliseconds)
          : null,
    );

    final currentContext = state.contextState;
    final contextChanged = _lastContextState != currentContext;
    _lastContextState = currentContext;
    if (currentContext != null && currentContext.isNotEmpty) {
      _engineContextStateController.add(currentContext);
    }

    if (_currentIndex != wasIndex || contextChanged) {
      _indexController.add(_currentIndex);
      _emitSequenceState();
    }
    _processingStateController.add(_processingState);
    _emitPlayerState();

    _playbackEventController.add(
      PlaybackEvent(
        processingState: _processingState,
        updatePosition: Duration(milliseconds: (_positionSec * 1000).round()),
        duration: _durationSec > 0
            ? Duration(milliseconds: (_durationSec * 1000).round())
            : null,
        currentIndex: _currentIndex,
      ),
    );
  }

  void _emitPlayerState() {
    _playerStateController.add(PlayerState(_playing, _processingState));
    if (_playing) {
      _startInterpolationTimer();
    } else {
      _stopInterpolationTimer();
    }
  }

  void _emitInterpolatedPosition() {
    if (!_playing || _lastTickAt == null || _durationSec <= 0) {
      return;
    }
    if (_processingState == ProcessingState.buffering ||
        _processingState == ProcessingState.loading) {
      return;
    }
    final now = DateTime.now();
    if (!WebTickStallPolicy.shouldInterpolate(
      playing: _playing,
      lastTickAt: _lastTickAt,
      minGapBeforeInterpolate: _GaplessPlayerBase._interpolationMinGap,
      now: now,
    )) {
      return;
    }
    final elapsedSec = now.difference(_lastTickAt!).inMicroseconds / 1e6;
    final interpolated = (_positionSec + elapsedSec).clamp(0.0, _durationSec);
    _positionController.add(
      Duration(milliseconds: (interpolated * 1000).round()),
    );
  }

  void _startInterpolationTimer() {
    if (_interpolationTimer != null) {
      return;
    }
    _interpolationTimer = Timer.periodic(
      _GaplessPlayerBase._interpolationInterval,
      (_) => _emitInterpolatedPosition(),
    );
  }

  void _stopInterpolationTimer() {
    _interpolationTimer?.cancel();
    _interpolationTimer = null;
  }

  void _emitSequenceState() {
    if (_sequence.isEmpty) {
      return;
    }
    final index = (_currentIndex ?? 0).clamp(0, _sequence.length - 1);
    _sequenceStateController.add(
      SequenceState(
        sequence: _sequence,
        currentIndex: index,
        shuffleIndices: List.generate(_sequence.length, (i) => i),
        shuffleModeEnabled: false,
        loopMode: LoopMode.off,
      ),
    );
  }
}
