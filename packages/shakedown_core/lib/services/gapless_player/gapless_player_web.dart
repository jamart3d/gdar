import 'dart:async';
import 'dart:js_interop';
// ignore: avoid_web_libraries_in_flutter
import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown_core/utils/logger.dart';

// ─── JS interop bindings ─────────────────────────────────────────────────────

/// Binds to the JavaScript object at [window._gdarAudio].
@JS('_gdarAudio')
external JSObject? get _engine;

@JS('_shakedownAudioStrategy')
external JSString? get _strategyVal;

@JS('_shakedownAudioReason')
external JSString? get _reasonVal;

String? get _strategy => _strategyVal?.toDart;
String? get _reason => _reasonVal?.toDart;

@JS('document.visibilityState')
external JSString get _visibilityState;

@JS('document.addEventListener')
external void _addEventListener(JSString type, JSFunction listener);

/// JavaScript engine API surface.
@JS()
@anonymous
extension type _GdarAudioEngine(JSObject _) {
  external void init();
  external void setPlaylist(JSArray<JSObject> tracks, JSNumber startIndex);
  external void appendTracks(JSArray<JSObject> tracks);
  external void play();
  external void pause();
  external void stop();
  external void seek(JSNumber seconds);
  external void prepareToPlay(JSString url);
  external void setTrackTransitionMode(JSString mode);
  external void setCrossfadeDurationSeconds(JSNumber seconds);
  external void setHandoffCrossfadeMs(JSNumber ms);
  external void seekToIndex(JSNumber index);
  external void setPrefetchSeconds(JSNumber s);
  external _GdarState getState();
  external void onStateChange(JSFunction cb);
  external void onTrackChange(JSFunction cb);
  external void onError(JSFunction cb);
  external void setHybridBackgroundMode(JSString mode);
  external void setHybridHandoffMode(JSString mode);
  external void setHybridAllowHiddenWebAudio(JSBoolean enabled);
  external void setVolume(JSNumber volume);
}

/// Snapshot of engine state returned by [_GdarAudioEngine.getState].
@JS()
@anonymous
extension type _GdarState(JSObject _) implements JSObject {
  @JS('playing')
  external JSBoolean? get playingJS;
  bool? get playing => playingJS?.toDart;

  @JS('index')
  external JSNumber? get indexJS;
  int? get index => indexJS?.toDartInt;

  @JS('position')
  external JSNumber? get positionJS;
  double? get position => positionJS?.toDartDouble;

  @JS('duration')
  external JSNumber? get durationJS;
  double? get duration => durationJS?.toDartDouble;

  @JS('currentTrackBuffered')
  external JSNumber? get currentTrackBufferedJS;
  double? get currentTrackBuffered => currentTrackBufferedJS?.toDartDouble;

  @JS('nextTrackBuffered')
  external JSNumber? get nextTrackBufferedJS;
  double? get nextTrackBuffered => nextTrackBufferedJS?.toDartDouble;

  @JS('nextTrackTotal')
  external JSNumber? get nextTrackTotalJS;
  double? get nextTrackTotal => nextTrackTotalJS?.toDartDouble;

  @JS('playlistLength')
  external JSNumber? get playlistLengthJS;
  int? get playlistLength => playlistLengthJS?.toDartInt;

  @JS('contextState')
  external JSString? get contextStateJS;
  String? get contextState => contextStateJS?.toDart;

  @JS('processingState')
  external JSString? get processingStateJS;
  String? get processingState => processingStateJS?.toDart;

  @JS('heartbeatActive')
  external JSBoolean? get heartbeatActiveJS;
  bool? get heartbeatActive => heartbeatActiveJS?.toDart;

  @JS('heartbeatNeeded')
  external JSBoolean? get heartbeatNeededJS;
  bool? get heartbeatNeeded => heartbeatNeededJS?.toDart;

  @JS('fetchTtfbMs')
  external JSNumber? get fetchTtfbMsJS;
  double? get fetchTtfbMs => fetchTtfbMsJS?.toDartDouble;

  @JS('fetchInFlight')
  external JSBoolean? get fetchInFlightJS;
  bool? get fetchInFlight => fetchInFlightJS?.toDart;

  @JS('lastGapMs')
  external JSNumber? get lastGapMsJS;
  double? get lastGapMs => lastGapMsJS?.toDartDouble;
}

/// Track change event sent from the JS engine.
@JS()
@anonymous
extension type _JsTrackChangeEvent(JSObject _) implements JSObject {
  @JS('from')
  external JSNumber? get fromJS;
  int get from => fromJS?.toDartInt ?? -1;

  @JS('to')
  external JSNumber? get toJS;
  int get to => toJS?.toDartInt ?? -1;
}

/// A JS track object passed to [_GdarAudioEngine.setPlaylist].
@JS()
@anonymous
extension type _JsTrack._(JSObject _) implements JSObject {
  external factory _JsTrack({
    required JSString url,
    required JSString title,
    required JSString artist,
    required JSString album,
    required JSString id,
    required JSNumber duration,
  });
}

@JS()
extension type _JSObject(JSObject _) implements JSObject {
  @JS('message')
  external JSString? get message;

  @JS('hasOwnProperty')
  external bool hasOwnProperty(JSString property);
}

// ─── Web GaplessPlayer ───────────────────────────────────────────────────────

/// Web implementation of [GaplessPlayer].
///
/// Bridges Dart → JavaScript [gapless_audio_engine.js] for true 0ms gapless
/// playback via [AudioBufferSourceNode] scheduling. The public API surface is
/// identical to the native wrapper so [AudioProvider] and [BufferAgent] need
/// no changes at the call sites.
class GaplessPlayer {
  // ─── Synthesised state ────────────────────────────────────────────────────

  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _playbackEventController = StreamController<PlaybackEvent>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _processingStateController =
      StreamController<ProcessingState>.broadcast();
  final _engineStateStringController = StreamController<String>.broadcast();
  final _engineContextStateController = StreamController<String>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedPositionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _indexController = StreamController<int?>.broadcast();
  final _sequenceStateController = StreamController<SequenceState?>.broadcast();
  final _nextTrackBufferedController = StreamController<Duration?>.broadcast();
  final _nextTrackTotalController = StreamController<Duration?>.broadcast();
  final _heartbeatActiveController = StreamController<bool>.broadcast();
  final _heartbeatNeededController = StreamController<bool>.broadcast();
  final _driftController = StreamController<double>.broadcast();
  final _visibilityController = StreamController<String>.broadcast();

  bool _playing = false;
  int? _currentIndex;
  double _positionSec = 0;
  double _durationSec = 0;
  double _currentTrackBufferedSec = 0;
  double _nextTrackBufferedSec = 0;
  double _nextTrackTotalSec = 0;
  bool _heartbeatActive = false;
  bool _heartbeatNeeded = true;
  DateTime? _lastTickAt;
  double _lastDrift = 0;
  DateTime _visibilityStartTime = DateTime.now();
  bool _isVisible = true;
  ProcessingState _processingState = ProcessingState.idle;
  List<IndexedAudioSource> _sequence = [];
  String? _lastContextState;
  String? _lastJsState;
  double? _lastFetchTtfbMs;
  bool _fetchInFlight = false;
  double? _lastGapMs;

  final bool _useJsEngine;
  final AudioPlayer? _fallbackPlayer;

  /// Creates a [GaplessPlayer] (web implementation).
  ///
  /// If [useWebGaplessEngine] is true, it bridges to the custom JS engine
  /// for perfect gapless playback. If false, it acts as a transparent proxy
  /// to a standard `just_audio` [AudioPlayer].
  GaplessPlayer({
    AudioPlayer? audioPlayer,
    bool? useWebGaplessEngine,
    String? trackTransitionMode,
    double? crossfadeDurationSeconds,
    AudioEngineMode? audioEngineMode,
    String? hybridHandoffMode,
  }) : _useJsEngine = useWebGaplessEngine ?? (_strategy != 'standard'),
       _fallbackPlayer = (useWebGaplessEngine ?? (_strategy != 'standard'))
           ? null
           : (audioPlayer ?? AudioPlayer()) {
    logger.i('GaplessPlayer: Detected Engine: $engineName');
    logger.i('GaplessPlayer: Selection Reason: $selectionReason');

    if (_useJsEngine) {
      _initJsEngine();
      _setupVisibilityListener();
      if (hybridHandoffMode != null) {
        setHybridHandoffMode(hybridHandoffMode);
      }
      // Note: background mode is typically set later via settings provider
    }
  }

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
        }).toJS,
      );
    } catch (e) {
      logger.w('GaplessPlayerWeb: Failed to setup visibility listener: $e');
    }
  }

  String get _visibilityStatus {
    final now = DateTime.now();
    final diff = now.difference(_visibilityStartTime);
    final minutes = diff.inMinutes;
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
        if (raw == null || !raw.isA<JSObject>()) return;
        final e = raw as _JsTrackChangeEvent;
        final to = e.to;
        _currentIndex = to >= 0 ? to : null;
        _indexController.add(_currentIndex);
        _emitSequenceState();
        _emitPlayerState();
      }).toJS,
    );
    gdar.onError(
      ((JSAny? raw) {
        if (raw == null) return;
        _processingState = ProcessingState.idle;
        _processingStateController.add(_processingState);

        String message = 'Unknown error';
        if (raw.isA<JSString>()) {
          message = (raw as JSString).toDart;
        } else if (raw.isA<JSObject>()) {
          final obj = _JSObject(raw as JSObject);
          final m = obj.message;
          if (m != null) {
            message = m.toDart;
          } else {
            message = raw.toString();
          }
        }

        _onJsError(message);
      }).toJS,
    );
  }

  void _onJsError(String message) {
    _playbackEventController.addError(
      Exception('WebAudio: $message'),
      StackTrace.current,
    );
  }

  void _callEngine(void Function(_GdarAudioEngine) action) {
    if (!_useJsEngine) return;
    final engine = _engine;
    if (engine != null) {
      action(_GdarAudioEngine(engine));
    }
  }

  /// Maps a JS processingState string to the [ProcessingState] enum.
  ProcessingState _mapProcessingState(String jsState) {
    ProcessingState state;
    switch (jsState) {
      case 'loading':
        state = ProcessingState.loading;
        break;
      case 'buffering':
        state = ProcessingState.buffering;
        break;
      case 'ready':
        state = ProcessingState.ready;
        break;
      case 'ended':
      case 'completed': // Original 'completed' case
        state = ProcessingState.completed;
        break;
      case 'handoff_countdown':
        // Map to ready so the UI doesn't hide controls with a spinner during the background-to-foreground transition
        state = ProcessingState.ready;
        break;
      case 'suspended_by_os':
        state = ProcessingState.idle;
        break;
      case 'idle':
      default:
        state = ProcessingState.idle;
    }
    return state;
  }

  void _onJsStateChange(_GdarState s) {
    final now = DateTime.now();
    if (_lastTickAt != null) {
      final diff = now.difference(_lastTickAt!).inMilliseconds / 1000.0;
      _lastDrift = diff;
      _driftController.add(diff);
    }
    _lastTickAt = now;

    // Periodically update visibility status (on every state tick)
    _visibilityController.add(_visibilityStatus);

    final wasPlaying = _playing;
    final wasDuration = _durationSec;
    final wasIndex = _currentIndex;

    // Use tentative check for properties to avoid crashes if engine is partially initialized
    try {
      final p = s.position;
      _positionSec = (p != null && p.isFinite) ? p : 0.0;
      final d = s.duration;
      _durationSec = (d != null && d.isFinite) ? d : 0.0;

      final ctb = s.currentTrackBuffered;
      _currentTrackBufferedSec = (ctb != null && ctb.isFinite) ? ctb : 0.0;
      final ntb = s.nextTrackBuffered;
      _nextTrackBufferedSec = (ntb != null && ntb.isFinite) ? ntb : 0.0;
      final ntt = s.nextTrackTotal;
      _nextTrackTotalSec = (ntt != null && ntt.isFinite) ? ntt : 0.0;

      final idx = s.index;
      _currentIndex = (idx != null && idx >= 0) ? idx : null;

      final ps = s.processingState;
      _lastJsState = ps;
      _processingState = _mapProcessingState(ps ?? 'idle');
      _processingStateController.add(_processingState);
      _engineStateStringController.add(ps ?? 'idle');

      // Explicitly notify on duration or index changes to keep sliding panel in sync
      if (wasIndex != _currentIndex || wasDuration != _durationSec) {
        _indexController.add(_currentIndex);
        _durationController.add(
          Duration(milliseconds: (_durationSec * 1000).round()),
        );
      }

      _playing = s.playing ?? false;
      if (wasPlaying != _playing) {
        _playingController.add(_playing);
      }

      final hbActive = s.heartbeatActive ?? false;
      if (_heartbeatActive != hbActive) {
        _heartbeatActive = hbActive;
        _heartbeatActiveController.add(_heartbeatActive);
      }

      final hbNeeded = s.heartbeatNeeded ?? true;
      if (_heartbeatNeeded != hbNeeded) {
        _heartbeatNeeded = hbNeeded;
        _heartbeatNeededController.add(_heartbeatNeeded);
      }

      final ttfb = s.fetchTtfbMs;
      if (ttfb != null && ttfb.isFinite) _lastFetchTtfbMs = ttfb;
      _fetchInFlight = s.fetchInFlight ?? false;
      final gap = s.lastGapMs;
      if (gap != null && gap.isFinite) _lastGapMs = gap;
    } catch (e, st) {
      logger.w('GaplessPlayerWeb: Error unboxing engine state: $e\n$st');
      return;
    }

    // Safety check for timer-based updates before emitting streams
    final posMs = (_positionSec * 1000).round();
    _positionController.add(Duration(milliseconds: posMs));

    _bufferedPositionController.add(
      Duration(milliseconds: (_currentTrackBufferedSec * 1000).round()),
    );

    if (_durationSec != wasDuration) {
      final durMs = (_durationSec * 1000).round();
      _durationController.add(durMs > 0 ? Duration(milliseconds: durMs) : null);
    }

    final ntbMs = (_nextTrackBufferedSec * 1000).round();
    _nextTrackBufferedController.add(
      ntbMs > 0 ? Duration(milliseconds: ntbMs) : null,
    );

    final nttMs = (_nextTrackTotalSec * 1000).round();
    _nextTrackTotalController.add(
      nttMs > 0 ? Duration(milliseconds: nttMs) : null,
    );

    final currentContext = s.contextState;
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

    // Emit a synthetic PlaybackEvent so widgets listening to
    // playbackEventStream (progress bars, track metadata, etc.)
    // receive updates on the Web platform.
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
  }

  void _emitSequenceState() {
    if (_sequence.isEmpty) return;
    final idx = (_currentIndex ?? 0).clamp(0, _sequence.length - 1);
    _sequenceStateController.add(
      SequenceState(
        sequence: _sequence,
        currentIndex: idx,
        shuffleIndices: List.generate(_sequence.length, (i) => i),
        shuffleModeEnabled: false,
        loopMode: LoopMode.off,
      ),
    );
  }

  // ─── Getters ──────────────────────────────────────────────────────────────

  bool get playing => _useJsEngine ? _playing : _fallbackPlayer!.playing;

  Duration get position => _useJsEngine
      ? Duration(milliseconds: (_positionSec * 1000).round())
      : _fallbackPlayer!.position;

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

  /// Returns the name of the active audio engine.
  String get engineName {
    if (!_useJsEngine) return 'Standard Engine (just_audio)';
    final strategy = _strategy;
    if (strategy == 'html5') return 'Mobile Gapless Engine (HTML5)';
    if (strategy == 'passive') return 'Passive engine (Mobile Fallback)';
    if (strategy == 'hybrid') {
      return 'Hybrid Audio Engine (Gapless + Background)';
    }
    if (strategy == 'webaudio' || strategy == 'webAudio') {
      return 'Desktop Gapless Engine (Web Audio API)';
    }

    return _engine == null ? 'MISSING JS ENGINE' : 'Web Audio (Gapless)';
  }

  /// Returns the reason why the current engine was selected.
  String get selectionReason {
    if (!_useJsEngine) return 'User disabled Web Gapless Engine in settings.';
    return _reason ?? 'No reason provided by hybrid_init.js';
  }

  /// Returns the resolved [AudioEngineMode].
  AudioEngineMode get activeMode {
    if (!_useJsEngine) return AudioEngineMode.standard;
    final strategy = _strategy;
    if (strategy == 'html5') return AudioEngineMode.html5;
    if (strategy == 'webaudio' || strategy == 'webAudio') {
      return AudioEngineMode.webAudio;
    }
    if (strategy == 'hybrid') return AudioEngineMode.hybrid;
    if (strategy == 'passive') return AudioEngineMode.passive;
    return AudioEngineMode.standard;
  }

  int? get androidAudioSessionId => null;

  // ─── Streams ──────────────────────────────────────────────────────────────

  Stream<PlayerState> get playerStateStream => _useJsEngine
      ? _playerStateController.stream
      : _fallbackPlayer!.playerStateStream;

  Stream<PlaybackEvent> get playbackEventStream => _useJsEngine
      ? _playbackEventController.stream
      : _fallbackPlayer!.playbackEventStream;

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

  /// Stream of JS engine tick drift.
  Stream<double> get driftStream =>
      _useJsEngine ? _driftController.stream : const Stream.empty();

  /// Stream of JS engine visibility status.
  Stream<String> get visibilityStream =>
      _useJsEngine ? _visibilityController.stream : const Stream.empty();

  /// Emits the raw string processing state from the JS engine (e.g. 'handoff_countdown')
  Stream<String> get engineStateStringStream =>
      _useJsEngine ? _engineStateStringController.stream : const Stream.empty();

  /// Emits the raw JS contextState (e.g. 'hybrid_foreground').
  Stream<String> get engineContextStateStream => _useJsEngine
      ? _engineContextStateController.stream
      : const Stream.empty();

  Stream<SequenceState?> get sequenceStateStream => _useJsEngine
      ? _sequenceStateController.stream
      : _fallbackPlayer!.sequenceStateStream;

  // ─── Methods ──────────────────────────────────────────────────────────────

  /// Converts an [AudioSource] to a [_JsTrack] for the JS engine.
  _JsTrack _sourceToJsTrack(AudioSource src) {
    if (src is UriAudioSource) {
      final tag = src.tag;
      final item = tag is MediaItem ? tag : null;
      return _JsTrack(
        url: src.uri.toString().toJS,
        title: (item?.title ?? '').toJS,
        artist: (item?.artist ?? '').toJS,
        album: (item?.album ?? '').toJS,
        id: (item?.id ?? '').toJS,
        duration: (item?.duration?.inSeconds.toDouble() ?? 0.0).toJS,
      );
    }
    return _JsTrack(
      url: ''.toJS,
      title: ''.toJS,
      artist: ''.toJS,
      album: ''.toJS,
      id: ''.toJS,
      duration: 0.0.toJS,
    );
  }

  /// Loads a playlist of audio sources into the engine.
  Future<Duration?> setAudioSources(
    List<AudioSource> children, {
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
    bool preload = true,
  }) async {
    if (!_useJsEngine) {
      return _fallbackPlayer!.setAudioSources(
        children,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
        preload: preload,
      );
    }
    _sequence = children.whereType<IndexedAudioSource>().toList();

    _callEngine((e) {
      e.setPlaylist(
        children.map(_sourceToJsTrack).toList().toJS,
        initialIndex.toJS,
      );
      if (initialPosition != Duration.zero) {
        e.seek((initialPosition.inMilliseconds / 1000.0).toJS);
      }
    });

    _emitSequenceState();
    return null; // Duration only known post-decode on web
  }

  /// Appends additional audio sources to the playlist.
  Future<void> addAudioSources(List<AudioSource> sources) async {
    if (!_useJsEngine) return _fallbackPlayer!.addAudioSources(sources);
    _sequence = [..._sequence, ...sources.whereType<IndexedAudioSource>()];
    _callEngine((e) {
      e.appendTracks(sources.map(_sourceToJsTrack).toList().toJS);
    });
  }

  /// Begins or resumes playback.
  Future<void> play() async {
    if (!_useJsEngine) {
      await _fallbackPlayer?.play();
    } else {
      _callEngine((e) => e.play());
    }
  }

  /// Pauses playback.
  Future<void> pause() async {
    if (!_useJsEngine) {
      await _fallbackPlayer?.pause();
    } else {
      _callEngine((e) => e.pause());
    }
  }

  /// Stops playback.
  Future<void> stop() async {
    if (!_useJsEngine) {
      await _fallbackPlayer?.stop();
    } else {
      _callEngine((e) => e.stop());
    }
  }

  /// Seeks to [position] within the current track, or to [index] if provided.
  Future<void> seek(Duration? position, {int? index}) async {
    if (!_useJsEngine) return _fallbackPlayer?.seek(position, index: index);
    _callEngine((e) {
      if (index != null) {
        e.seekToIndex(index.toJS);
      } else if (position != null) {
        e.seek((position.inMilliseconds / 1000.0).toJS);
      }
    });
  }

  /// Sets the volume (0.0 to 1.0).
  Future<void> setVolume(double volume) async {
    if (!_useJsEngine) {
      await _fallbackPlayer?.setVolume(volume);
    } else {
      _callEngine((e) {
        final obj = _JSObject(e as JSObject);
        if (obj.hasOwnProperty('setVolume'.toJS)) {
          e.setVolume(volume.toJS);
        }
      });
    }
  }

  /// Seeks to the next track.
  Future<void> seekToNext() async {
    if (!_useJsEngine) return _fallbackPlayer?.seekToNext();
    final next = (_currentIndex ?? 0) + 1;
    if (next < _sequence.length) {
      _callEngine((e) => e.seekToIndex(next.toJS));
    }
  }

  /// Seeks to the previous track.
  Future<void> seekToPrevious() async {
    if (!_useJsEngine) return _fallbackPlayer?.seekToPrevious();
    final prev = (_currentIndex ?? 1) - 1;
    if (prev >= 0) {
      _callEngine((e) => e.seekToIndex(prev.toJS));
    }
  }

  /// Updates the web prefetch window (seconds).
  void setCrossfadeDurationSeconds(double seconds) {
    if (_useJsEngine && _engine != null) {
      final engine = _engine;
      if (engine == null) return;
      final gdar = _GdarAudioEngine(engine);
      gdar.setCrossfadeDurationSeconds(seconds.toJS);
    }
  }

  /// Updates the hybrid handoff crossfade window (ms).
  void setHandoffCrossfadeMs(int ms) {
    if (_useJsEngine) {
      _callEngine((e) {
        final obj = _JSObject(e as JSObject);
        if (obj.hasOwnProperty('setHandoffCrossfadeMs'.toJS)) {
          e.setHandoffCrossfadeMs(ms.toJS);
        }
      });
    }
  }

  /// Updates the web prefetch window (seconds).
  void setWebPrefetchSeconds(int seconds) {
    if (_useJsEngine) {
      _callEngine((e) => e.setPrefetchSeconds(seconds.toJS));
    }
  }

  void setHybridBackgroundMode(String mode) {
    if (_useJsEngine) {
      _callEngine((e) {
        final obj = _JSObject(e as JSObject);
        if (obj.hasOwnProperty('setHybridBackgroundMode'.toJS)) {
          e.setHybridBackgroundMode(mode.toJS);
        }
      });
    }
  }

  void setHybridHandoffMode(String mode) {
    if (_useJsEngine) {
      _callEngine((e) {
        final obj = _JSObject(e as JSObject);
        if (obj.hasOwnProperty('setHybridHandoffMode'.toJS)) {
          e.setHybridHandoffMode(mode.toJS);
        }
      });
    }
  }

  void setHybridAllowHiddenWebAudio(bool enabled) {
    if (_useJsEngine) {
      _callEngine((e) {
        final obj = _JSObject(e as JSObject);
        if (obj.hasOwnProperty('setHybridAllowHiddenWebAudio'.toJS)) {
          e.setHybridAllowHiddenWebAudio(enabled.toJS);
        }
      });
    }
  }

  void setTrackTransitionMode(String mode) {
    if (_useJsEngine) {
      final normalized = mode == 'gap' ? 'gap' : 'gapless';
      _callEngine((e) {
        final obj = _JSObject(e as JSObject);
        if (obj.hasOwnProperty('setTrackTransitionMode'.toJS)) {
          e.setTrackTransitionMode(normalized.toJS);
        }
      });
    }
  }

  /// Releases all resources.
  Future<void> dispose() async {
    if (!_useJsEngine) {
      return _fallbackPlayer?.dispose();
    }
    _callEngine((e) => e.stop());
    await _playerStateController.close();
    await _playbackEventController.close();
    await _playingController.close();
    await _processingStateController.close();
    await _engineStateStringController.close();
    await _engineContextStateController.close();
    await _positionController.close();
    await _bufferedPositionController.close();
    await _durationController.close();
    await _indexController.close();
    await _sequenceStateController.close();
    await _nextTrackBufferedController.close();
    await _nextTrackTotalController.close();
    await _heartbeatActiveController.close();
    await _heartbeatNeededController.close();
    await _driftController.close();
    await _visibilityController.close();
  }

  /// Reloads the web page.
  void reload() {
    _reloadPage();
  }
}

@JS('window.location.reload')
external void _reloadPage();
