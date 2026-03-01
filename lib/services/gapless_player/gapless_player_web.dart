import 'dart:async';
import 'dart:js_interop';
// ignore: avoid_web_libraries_in_flutter
import 'package:just_audio/just_audio.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown/utils/logger.dart';

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

/// JavaScript engine API surface.
@JS()
@anonymous
extension type _GdarAudioEngine(JSObject _) {
  external void init();
  external void setPlaylist(JSArray<JSObject> tracks, int startIndex);
  external void appendTracks(JSArray<JSObject> tracks);
  external void play();
  external void pause();
  external void stop();
  external void seek(double seconds);
  external void prepareToPlay(JSString url);
  external void setCrossfadeDurationSeconds(JSNumber seconds);
  external void seekToIndex(int index);
  external void setPrefetchSeconds(int s);
  external _GdarState getState();
  external void onStateChange(JSFunction cb);
  external void onTrackChange(JSFunction cb);
  external void onError(JSFunction cb);
  external void setHybridBackgroundMode(JSString mode);
  external void setHybridHandoffMode(JSString mode);
}

/// Snapshot of engine state returned by [_GdarAudioEngine.getState].
@JS()
@anonymous
extension type _GdarState(JSObject _) implements JSObject {
  @JS('playing')
  external bool? get playing;
  @JS('index')
  external int? get index;
  @JS('position')
  external double? get position;
  @JS('duration')
  external double? get duration;
  @JS('currentTrackBuffered')
  external double? get currentTrackBuffered;
  @JS('nextTrackBuffered')
  external double? get nextTrackBuffered;
  @JS('nextTrackTotal')
  external double? get nextTrackTotal;
  @JS('playlistLength')
  external int? get playlistLength;
  @JS('contextState')
  external String? get contextState;
  @JS('processingState')
  external String? get processingState;
}

/// Track change event sent from the JS engine.
@JS()
@anonymous
extension type _JsTrackChangeEvent(JSObject _) {
  external int get from;
  external int get to;
}

/// A JS track object passed to [_GdarAudioEngine.setPlaylist].
@JS()
@anonymous
extension type _JsTrack._(JSObject _) implements JSObject {
  external factory _JsTrack({
    required String url,
    required String title,
    required String artist,
    required String album,
    required String id,
    required double duration,
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
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedPositionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _indexController = StreamController<int?>.broadcast();
  final _sequenceStateController = StreamController<SequenceState?>.broadcast();
  final _nextTrackBufferedController = StreamController<Duration?>.broadcast();
  final _nextTrackTotalController = StreamController<Duration?>.broadcast();

  bool _playing = false;
  int? _currentIndex;
  double _positionSec = 0;
  double _durationSec = 0;
  double _currentTrackBufferedSec = 0;
  double _nextTrackBufferedSec = 0;
  double _nextTrackTotalSec = 0;
  ProcessingState _processingState = ProcessingState.idle;
  List<IndexedAudioSource> _sequence = [];
  String? _lastContextState;

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
  })  : _useJsEngine = useWebGaplessEngine ?? (_strategy != 'standard'),
        _fallbackPlayer = (useWebGaplessEngine ?? (_strategy != 'standard'))
            ? null
            : (audioPlayer ?? AudioPlayer()) {
    logger.i('GaplessPlayer: Detected Engine: $engineName');
    logger.i('GaplessPlayer: Selection Reason: $selectionReason');

    if (_useJsEngine) {
      _initJsEngine();
      if (hybridHandoffMode != null) {
        setHybridHandoffMode(hybridHandoffMode);
      }
      // Note: background mode is typically set later via settings provider
    }
  }

  void _initJsEngine() {
    final engine = _engine;
    if (engine == null) {
      logger.e(
          'FATAL: Gapless Audio Engine (window._gdarAudio) not found. Web Audio initialization aborted.');
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
      ((JSObject raw) {
        final e = raw as _JsTrackChangeEvent;
        final to = e.to;
        _currentIndex = to >= 0 ? to : null;
        _indexController.add(_currentIndex);
        _emitSequenceState();
        _emitPlayerState();
      }).toJS,
    );
    gdar.onError(
      ((JSAny raw) {
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
    final wasPlaying = _playing;
    final wasDuration = _durationSec;
    final wasIndex = _currentIndex;

    // Use tentative check for properties to avoid crashes if engine is partially initialized
    try {
      _playing = s.playing ?? false;
      _positionSec = s.position ?? 0;
      _durationSec = s.duration ?? 0;
      _currentTrackBufferedSec = s.currentTrackBuffered ?? 0;
      _nextTrackBufferedSec = s.nextTrackBuffered ?? 0;
      _nextTrackTotalSec = s.nextTrackTotal ?? 0;
      final idx = s.index;
      _currentIndex = (idx != null && idx >= 0) ? idx : null;
      final ps = s.processingState;
      _processingState = _mapProcessingState(ps ?? 'idle');
      _processingStateController.add(_processingState);
      _engineStateStringController.add(ps ?? 'idle');

      // Explicitly notify on duration or index changes to keep sliding panel in sync
      if (wasIndex != _currentIndex || wasDuration != _durationSec) {
        _indexController.add(_currentIndex);
        _durationController
            .add(Duration(milliseconds: (_durationSec * 1000).round()));
      }

      if (wasPlaying != _playing) {
        _playingController.add(_playing);
      }
    } catch (e) {
      // ignore partially initialized state
      return;
    }

    _positionController
        .add(Duration(milliseconds: (_positionSec * 1000).round()));
    _bufferedPositionController
        .add(Duration(milliseconds: (_currentTrackBufferedSec * 1000).round()));

    if (_durationSec != wasDuration) {
      _durationController.add(_durationSec > 0
          ? Duration(milliseconds: (_durationSec * 1000).round())
          : null);
    }
    _nextTrackBufferedController.add(_nextTrackBufferedSec > 0
        ? Duration(milliseconds: (_nextTrackBufferedSec * 1000).round())
        : null);
    _nextTrackTotalController.add(_nextTrackTotalSec > 0
        ? Duration(milliseconds: (_nextTrackTotalSec * 1000).round())
        : null);
    if (_playing != wasPlaying) {
      _playingController.add(_playing);
    }

    final currentContext = s.contextState;
    final contextChanged = _lastContextState != currentContext;
    _lastContextState = currentContext;

    if (_currentIndex != wasIndex || contextChanged) {
      _indexController.add(_currentIndex);
      _emitSequenceState();
    }
    _processingStateController.add(_processingState);
    _emitPlayerState();

    // Emit a synthetic PlaybackEvent so widgets listening to
    // playbackEventStream (progress bars, track metadata, etc.)
    // receive updates on the Web platform.
    _playbackEventController.add(PlaybackEvent(
      processingState: _processingState,
      updatePosition: Duration(milliseconds: (_positionSec * 1000).round()),
      duration: _durationSec > 0
          ? Duration(milliseconds: (_durationSec * 1000).round())
          : null,
      currentIndex: _currentIndex,
    ));
  }

  void _emitPlayerState() {
    _playerStateController.add(PlayerState(_playing, _processingState));
  }

  void _emitSequenceState() {
    if (_sequence.isEmpty) return;
    final idx = (_currentIndex ?? 0).clamp(0, _sequence.length - 1);
    _sequenceStateController.add(SequenceState(
      sequence: _sequence,
      currentIndex: idx,
      shuffleIndices: List.generate(_sequence.length, (i) => i),
      shuffleModeEnabled: false,
      loopMode: LoopMode.off,
    ));
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

  /// Emits the raw string processing state from the JS engine (e.g. 'handoff_countdown')
  Stream<String> get engineStateStringStream =>
      _useJsEngine ? _engineStateStringController.stream : const Stream.empty();

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
        url: src.uri.toString(),
        title: item?.title ?? '',
        artist: item?.artist ?? '',
        album: item?.album ?? '',
        id: item?.id ?? '',
        duration: item?.duration?.inSeconds.toDouble() ?? 0,
      );
    }
    return _JsTrack(
      url: '',
      title: '',
      artist: '',
      album: '',
      id: '',
      duration: 0,
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
        initialIndex,
      );
      if (initialPosition != Duration.zero) {
        e.seek(initialPosition.inMilliseconds / 1000.0);
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
      await _fallbackPlayer!.play();
    } else {
      _callEngine((e) => e.play());
    }
  }

  /// Pauses playback.
  Future<void> pause() async {
    if (!_useJsEngine) {
      await _fallbackPlayer!.pause();
    } else {
      _callEngine((e) => e.pause());
    }
  }

  /// Stops playback.
  Future<void> stop() async {
    if (!_useJsEngine) {
      await _fallbackPlayer!.stop();
    } else {
      _callEngine((e) => e.stop());
    }
  }

  /// Seeks to [position] within the current track, or to [index] if provided.
  Future<void> seek(Duration? position, {int? index}) async {
    if (!_useJsEngine) return _fallbackPlayer!.seek(position, index: index);
    _callEngine((e) {
      if (index != null) {
        e.seekToIndex(index);
      } else if (position != null) {
        e.seek(position.inMilliseconds / 1000.0);
      }
    });
  }

  /// Seeks to the next track.
  Future<void> seekToNext() async {
    if (!_useJsEngine) return _fallbackPlayer!.seekToNext();
    final next = (_currentIndex ?? 0) + 1;
    if (next < _sequence.length) {
      _callEngine((e) => e.seekToIndex(next));
    }
  }

  /// Seeks to the previous track.
  Future<void> seekToPrevious() async {
    if (!_useJsEngine) return _fallbackPlayer!.seekToPrevious();
    final prev = (_currentIndex ?? 1) - 1;
    if (prev >= 0) {
      _callEngine((e) => e.seekToIndex(prev));
    }
  }

  /// Updates the web prefetch window (seconds).
  void setCrossfadeDurationSeconds(double seconds) {
    if (_useJsEngine && _engine != null) {
      final gdar = _GdarAudioEngine(_engine!);
      gdar.setCrossfadeDurationSeconds(seconds.toJS);
    }
  }

  /// Updates the web prefetch window (seconds).
  void setWebPrefetchSeconds(int seconds) {
    if (_useJsEngine) {
      _callEngine((e) => e.setPrefetchSeconds(seconds));
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

  /// Releases all resources.
  Future<void> dispose() async {
    if (!_useJsEngine) {
      return _fallbackPlayer!.dispose();
    }
    _callEngine((e) => e.stop());
    await _playerStateController.close();
    await _playbackEventController.close();
    await _playingController.close();
    await _processingStateController.close();
    await _positionController.close();
    await _bufferedPositionController.close();
    await _durationController.close();
    await _indexController.close();
    await _sequenceStateController.close();
  }

  /// Reloads the web page.
  void reload() {
    _reloadPage();
  }
}

@JS('window.location.reload')
external void _reloadPage();
