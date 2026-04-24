part of 'gapless_player_web.dart';

mixin _GaplessPlayerWebAccessors
    on _GaplessPlayerBase, _GaplessPlayerWebEngine {
  bool get playing => _useJsEngine ? _playing : _fallbackPlayer!.playing;

  Duration get position {
    if (!_useJsEngine) return _fallbackPlayer!.position;

    double displaySec = _positionSec;
    if (_playing && _lastTickAt != null && _durationSec > 0) {
      final now = DateTime.now();
      final elapsedSec = now.difference(_lastTickAt!).inMicroseconds / 1e6;
      displaySec = (_positionSec + elapsedSec).clamp(0.0, _durationSec);
    }

    return Duration(milliseconds: (displaySec * 1000).round());
  }

  Duration get bufferedPosition => _useJsEngine
      ? Duration(milliseconds: (_currentTrackBufferedSec * 1000).round())
      : _fallbackPlayer!.bufferedPosition;

  Duration? get duration => _useJsEngine
      ? (_durationSec > 0
            ? Duration(milliseconds: (_durationSec * 1000).round())
            : null)
      : _fallbackPlayer!.duration;

  Duration? get nextTrackBuffered => _useJsEngine
      ? (_nextTrackBufferedSec > 0
            ? Duration(milliseconds: (_nextTrackBufferedSec * 1000).round())
            : null)
      : null;

  Duration? get nextTrackTotal => _useJsEngine
      ? (_nextTrackTotalSec > 0
            ? Duration(milliseconds: (_nextTrackTotalSec * 1000).round())
            : null)
      : null;

  int? get currentIndex =>
      _useJsEngine ? _currentIndex : _fallbackPlayer!.currentIndex;

  List<IndexedAudioSource> get sequence =>
      _useJsEngine ? _sequence : _fallbackPlayer!.sequence;

  ProcessingState get processingState =>
      _useJsEngine ? _processingState : _fallbackPlayer!.processingState;

  PlayerState get playerState => _useJsEngine
      ? PlayerState(_playing, _processingState)
      : _fallbackPlayer!.playerState;

  double get drift => _useJsEngine ? _lastDrift : 0.0;

  String get visibility => _useJsEngine ? _visibilityStatus : 'VIS';

  String get engineStateString =>
      _useJsEngine ? (_lastJsState ?? 'idle') : 'native';

  String get engineContextState =>
      _useJsEngine ? (_lastContextState ?? 'none') : 'native';

  bool get heartbeatActive => _useJsEngine ? _heartbeatActive : false;

  bool get heartbeatNeeded => _useJsEngine ? _heartbeatNeeded : false;

  double? get fetchTtfbMs => _useJsEngine ? _lastFetchTtfbMs : null;

  bool get fetchInFlight => _useJsEngine ? _fetchInFlight : false;

  double? get lastGapMs => _useJsEngine ? _lastGapMs : null;

  int? get scheduledIndex => _useJsEngine ? _scheduledIndex : null;

  double? get scheduledStartContextTime =>
      _useJsEngine ? _scheduledStartContextTime : null;

  double? get ctxCurrentTime => _useJsEngine ? _ctxCurrentTime : null;

  double? get outputLatencyMs => _useJsEngine ? _outputLatencyMs : null;

  double? get lastDecodeMs => _useJsEngine ? _lastDecodeMs : null;

  double? get lastConcatMs => _useJsEngine ? _lastConcatMs : null;

  int? get failedTrackCount => _useJsEngine ? _failedTrackCount : null;

  int? get workerTickCount => _useJsEngine ? _workerTickCount : null;

  int? get sampleRate => _useJsEngine ? _sampleRate : null;

  int? get decodedCacheSize => _useJsEngine ? _decodedCacheSize : null;

  String? get handoffState => _useJsEngine ? _handoffState : null;

  int? get handoffAttemptCount => _useJsEngine ? _handoffAttemptCount : null;

  int? get lastHandoffPollCount => _useJsEngine ? _lastHandoffPollCount : null;

  ({int count, String lastReason}) get heartbeatBlockedDiagnostics {
    if (!_useJsEngine) return (count: 0, lastReason: '');

    try {
      final diagnostics = _heartbeat?.getBlockedDiagnostics();
      return (
        count:
            diagnostics?.blockedCount ??
            _heartbeat?.blockedCount().toDartInt ??
            0,
        lastReason: diagnostics?.lastReason ?? '',
      );
    } catch (_) {
      return (count: 0, lastReason: '');
    }
  }

  int get heartbeatBlockedCount {
    return heartbeatBlockedDiagnostics.count;
  }

  String get heartbeatLastBlockedReason {
    return heartbeatBlockedDiagnostics.lastReason;
  }

  String get engineName {
    if (!_useJsEngine) {
      return 'Standard Engine (just_audio)';
    }
    final strategy = _strategy;
    if (strategy == 'html5') {
      return 'Mobile Gapless Engine (HTML5)';
    }
    if (strategy == 'passive') {
      return 'Passive engine (Mobile Fallback)';
    }
    if (strategy == 'hybrid') {
      return 'Hybrid Audio Engine (Gapless + Background)';
    }
    if (strategy == 'webaudio' || strategy == 'webAudio') {
      return 'Desktop Gapless Engine (Web Audio API)';
    }

    return _engine == null ? 'MISSING JS ENGINE' : 'Web Audio (Gapless)';
  }

  String get selectionReason {
    if (!_useJsEngine) {
      return 'User disabled Web Gapless Engine in settings.';
    }
    return _reason ?? 'No reason provided by hybrid_init.js';
  }

  AudioEngineMode get activeMode {
    if (!_useJsEngine) {
      return AudioEngineMode.standard;
    }
    final strategy = _strategy;
    if (strategy == 'html5') {
      return AudioEngineMode.html5;
    }
    if (strategy == 'webaudio' || strategy == 'webAudio') {
      return AudioEngineMode.webAudio;
    }
    if (strategy == 'hybrid') {
      return AudioEngineMode.hybrid;
    }
    if (strategy == 'passive') {
      return AudioEngineMode.passive;
    }
    return AudioEngineMode.standard;
  }

  int? get androidAudioSessionId => null;

  Stream<PlayerState> get playerStateStream => _useJsEngine
      ? _playerStateController.stream
      : _fallbackPlayer!.playerStateStream;

  Stream<PlaybackEvent> get playbackEventStream => _useJsEngine
      ? _playbackEventController.stream
      : _fallbackPlayer!.playbackEventStream;

  Stream<void> get playBlockedStream =>
      _useJsEngine ? _playBlockedController.stream : const Stream.empty();

  Stream<bool> get playingStream =>
      _useJsEngine ? _playingController.stream : _fallbackPlayer!.playingStream;

  Stream<ProcessingState> get processingStateStream => _useJsEngine
      ? _processingStateController.stream
      : _fallbackPlayer!.processingStateStream;

  Stream<Duration> get bufferedPositionStream => _useJsEngine
      ? _bufferedPositionController.stream
      : _fallbackPlayer!.bufferedPositionStream;

  Stream<Duration> get positionStream => _useJsEngine
      ? _positionController.stream
      : _fallbackPlayer!.positionStream;

  Stream<Duration?> get durationStream => _useJsEngine
      ? _durationController.stream
      : _fallbackPlayer!.durationStream;

  Stream<int?> get currentIndexStream => _useJsEngine
      ? _indexController.stream
      : _fallbackPlayer!.currentIndexStream;

  Stream<Duration?> get nextTrackBufferedStream =>
      _useJsEngine ? _nextTrackBufferedController.stream : const Stream.empty();

  Stream<Duration?> get nextTrackTotalStream =>
      _useJsEngine ? _nextTrackTotalController.stream : const Stream.empty();

  Stream<bool> get heartbeatActiveStream =>
      _useJsEngine ? _heartbeatActiveController.stream : Stream.value(false);

  Stream<bool> get heartbeatNeededStream =>
      _useJsEngine ? _heartbeatNeededController.stream : Stream.value(true);

  Stream<double> get driftStream =>
      _useJsEngine ? _driftController.stream : const Stream.empty();

  Stream<String> get visibilityStream =>
      _useJsEngine ? _visibilityController.stream : const Stream.empty();

  Stream<String> get engineStateStringStream =>
      _useJsEngine ? _engineStateStringController.stream : const Stream.empty();

  Stream<String> get engineContextStateStream => _useJsEngine
      ? _engineContextStateController.stream
      : const Stream.empty();

  Stream<SequenceState?> get sequenceStateStream => _useJsEngine
      ? _sequenceStateController.stream
      : _fallbackPlayer!.sequenceStateStream;

  Stream<double?> get scheduledStartContextTimeStream => _useJsEngine
      ? _scheduledStartContextTimeController.stream
      : const Stream.empty();

  Stream<double?> get outputLatencyMsStream =>
      _useJsEngine ? _outputLatencyMsController.stream : const Stream.empty();

  Stream<double?> get lastDecodeMsStream =>
      _useJsEngine ? _lastDecodeMsController.stream : const Stream.empty();

  Stream<double?> get lastConcatMsStream =>
      _useJsEngine ? _lastConcatMsController.stream : const Stream.empty();

  Stream<int?> get failedTrackCountStream =>
      _useJsEngine ? _failedTrackCountController.stream : const Stream.empty();

  Stream<int?> get workerTickCountStream =>
      _useJsEngine ? _workerTickCountController.stream : const Stream.empty();

  Stream<int?> get sampleRateStream =>
      _useJsEngine ? _sampleRateController.stream : const Stream.empty();

  Stream<int?> get decodedCacheSizeStream =>
      _useJsEngine ? _decodedCacheSizeController.stream : const Stream.empty();

  Stream<String?> get handoffStateStream =>
      _useJsEngine ? _handoffStateController.stream : const Stream.empty();

  Stream<int?> get handoffAttemptCountStream => _useJsEngine
      ? _handoffAttemptCountController.stream
      : const Stream.empty();

  Stream<int?> get lastHandoffPollCountStream => _useJsEngine
      ? _lastHandoffPollCountController.stream
      : const Stream.empty();
}
