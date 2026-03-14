import 'dart:async';
import 'dart:js_interop';

import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:just_audio_background/just_audio_background.dart';

// ─── JS interop bindings ─────────────────────────────────────────────────────

@JS('_hybridAudio')
external _HybridAudioEngine get _engine;

/// JavaScript engine API surface.
@JS()
@anonymous
extension type _HybridAudioEngine(JSObject _) {
  external void init();
  external void setPlaylist(JSArray<JSObject> tracks, int startIndex);
  external void appendTracks(JSArray<JSObject> tracks);
  external void play();
  external void pause();
  external void stop();
  external void seek(double seconds);
  external void seekToIndex(int index);
  external void setPrefetchSeconds(int s);
  external void setTrackTransitionMode(String s);
  external void setCrossfadeDuration(double s);
  external _HybridState getState();
  external void onStateChange(JSFunction cb);
  external void onTrackChange(JSFunction cb);
  external void onError(JSFunction cb);
}

/// Snapshot of engine state returned by [_HybridAudioEngine.getState].
@JS()
@anonymous
extension type _HybridState(JSObject _) {
  external bool get playing;
  external int get index;
  external double get position;
  external double get duration;
  external double get currentTrackBuffered;
  external double get nextTrackBuffered;
  external double get nextTrackTotal;
  external int get playlistLength;
  external String get contextState;
  external String get processingState;
}

/// Track change event sent from the JS engine.
@JS()
@anonymous
extension type _JsTrackChangeEvent(JSObject _) {
  external int get from;
  external int get to;
}

/// A JS track object.
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
extension type _JSObject(JSObject _) {
  @JS('message')
  external JSString? get message;
}

// ─── Web Hybrid Audio Engine ─────────────────────────────────────────────────

/// Brings the window._hybridAudio API into Dart.
class HybridAudioEngine {
  // ─── Synthesised state ────────────────────────────────────────────────────

  final _playerStateController = StreamController<PlayerState>.broadcast();
  final _playbackEventController = StreamController<PlaybackEvent>.broadcast();
  final _playingController = StreamController<bool>.broadcast();
  final _processingStateController =
      StreamController<ProcessingState>.broadcast();
  final _positionController = StreamController<Duration>.broadcast();
  final _bufferedPositionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _indexController = StreamController<int?>.broadcast();
  final _sequenceStateController = StreamController<SequenceState?>.broadcast();
  final _nextTrackBufferedController = StreamController<Duration?>.broadcast();
  final _nextTrackTotalController = StreamController<Duration?>.broadcast();
  final _contextStateController = StreamController<String>.broadcast();

  bool _playing = false;
  int? _currentIndex;
  double _positionSec = 0;
  double _durationSec = 0;
  double _currentTrackBufferedSec = 0;
  double _nextTrackBufferedSec = 0;
  double _nextTrackTotalSec = 0;
  String _contextState = 'hybrid_foreground';
  ProcessingState _processingState = ProcessingState.idle;
  List<IndexedAudioSource> _sequence = [];

  HybridAudioEngine() {
    _initJsEngine();
  }

  void _initJsEngine() {
    _engine.init();
    _engine.onStateChange(
      ((JSObject raw) {
        _onJsStateChange(raw as _HybridState);
      }).toJS,
    );
    _engine.onTrackChange(
      ((JSObject raw) {
        final e = raw as _JsTrackChangeEvent;
        final to = e.to;
        _currentIndex = to >= 0 ? to : null;
        _indexController.add(_currentIndex);
        _emitSequenceState();
        _emitPlayerState();
      }).toJS,
    );
    _engine.onError(
      ((JSAny raw) {
        _processingState = ProcessingState.idle;
        _processingStateController.add(_processingState);

        String message = 'Unknown hybrid engine error';
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

        _playbackEventController.addError(
          Exception('HybridEngine: $message'),
          StackTrace.current,
        );
      }).toJS,
    );
  }

  /// Maps a JS processingState string to the [ProcessingState] enum.
  ProcessingState _mapProcessingState(String jsState) {
    switch (jsState) {
      case 'loading':
        return ProcessingState.loading;
      case 'buffering':
        return ProcessingState.buffering;
      case 'ready':
        return ProcessingState.ready;
      case 'completed':
        return ProcessingState.completed;
      case 'idle':
      default:
        return ProcessingState.idle;
    }
  }

  void _onJsStateChange(_HybridState s) {
    final wasPlaying = _playing;
    final wasDuration = _durationSec;
    final wasIndex = _currentIndex;
    final wasContext = _contextState;

    _playing = s.playing;
    _positionSec = s.position;
    _durationSec = s.duration;
    _currentTrackBufferedSec = s.currentTrackBuffered;
    _nextTrackBufferedSec = s.nextTrackBuffered;
    _nextTrackTotalSec = s.nextTrackTotal;
    _currentIndex = s.index >= 0 ? s.index : null;
    _contextState = s.contextState;

    _processingState = _mapProcessingState(s.processingState);

    _positionController
        .add(Duration(milliseconds: (s.position * 1000).round()));
    _bufferedPositionController
        .add(Duration(milliseconds: (_currentTrackBufferedSec * 1000).round()));

    if (_contextState != wasContext) {
      _contextStateController.add(_contextState);
    }
    if ((_durationSec - wasDuration).abs() > 0.1) {
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
    if (_currentIndex != wasIndex) {
      _indexController.add(_currentIndex);
      _emitSequenceState();
    }

    _processingStateController.add(_processingState);
    _emitPlayerState();

    _playbackEventController.add(PlaybackEvent(
      processingState: _processingState,
      updatePosition: Duration(milliseconds: (s.position * 1000).round()),
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

  bool get playing => _playing;

  Duration get position =>
      Duration(milliseconds: (_positionSec * 1000).round());

  Duration get bufferedPosition =>
      Duration(milliseconds: (_currentTrackBufferedSec * 1000).round());

  Duration? get duration => (_durationSec > 0
      ? Duration(milliseconds: (_durationSec * 1000).round())
      : null);

  Duration? get nextTrackBuffered => (_nextTrackBufferedSec > 0
      ? Duration(milliseconds: (_nextTrackBufferedSec * 1000).round())
      : null);

  Duration? get nextTrackTotal => (_nextTrackTotalSec > 0
      ? Duration(milliseconds: (_nextTrackTotalSec * 1000).round())
      : null);

  int? get currentIndex => _currentIndex;

  List<IndexedAudioSource> get sequence => _sequence;

  ProcessingState get processingState => _processingState;

  PlayerState get playerState => PlayerState(_playing, _processingState);

  String get engineName => 'Hybrid Web Audio Engine ($_contextState)';

  String get selectionReason => 'User Override: Hybrid';

  AudioEngineMode get activeMode => AudioEngineMode.hybrid;

  int? get androidAudioSessionId => null;

  // ─── Streams ──────────────────────────────────────────────────────────────

  Stream<PlayerState> get playerStateStream => _playerStateController.stream;

  Stream<PlaybackEvent> get playbackEventStream =>
      _playbackEventController.stream;

  Stream<bool> get playingStream => _playingController.stream;

  Stream<ProcessingState> get processingStateStream =>
      _processingStateController.stream;

  Stream<Duration> get bufferedPositionStream =>
      _bufferedPositionController.stream;

  Stream<Duration> get positionStream => _positionController.stream;

  Stream<Duration?> get durationStream => _durationController.stream;

  Stream<int?> get currentIndexStream => _indexController.stream;

  Stream<Duration?> get nextTrackBufferedStream =>
      _nextTrackBufferedController.stream;

  Stream<Duration?> get nextTrackTotalStream =>
      _nextTrackTotalController.stream;

  Stream<SequenceState?> get sequenceStateStream =>
      _sequenceStateController.stream;

  Stream<String> get contextStateStream => _contextStateController.stream;

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
    _sequence = children.whereType<IndexedAudioSource>().toList();
    _engine.setPlaylist(
      children.map(_sourceToJsTrack).toList().toJS,
      initialIndex,
    );
    if (initialPosition != Duration.zero) {
      _engine.seek(initialPosition.inMilliseconds / 1000.0);
    }
    _emitSequenceState();
    return null; // Duration only known post-decode on web
  }

  /// Appends additional audio sources to the playlist.
  Future<void> addAudioSources(List<AudioSource> sources) async {
    _sequence = [..._sequence, ...sources.whereType<IndexedAudioSource>()];
    _engine.appendTracks(sources.map(_sourceToJsTrack).toList().toJS);
  }

  /// Begins or resumes playback.
  Future<void> play() async => _engine.play();

  /// Pauses playback.
  Future<void> pause() async => _engine.pause();

  /// Stops playback.
  Future<void> stop() async => _engine.stop();

  /// Seeks to [position] within the current track, or to [index] if provided.
  Future<void> seek(Duration? position, {int? index}) async {
    if (index != null) {
      _engine.seekToIndex(index);
    } else if (position != null) {
      _engine.seek(position.inMilliseconds / 1000.0);
    }
  }

  /// Seeks to the next track.
  Future<void> seekToNext() async {
    final next = (_currentIndex ?? 0) + 1;
    if (next < _sequence.length) _engine.seekToIndex(next);
  }

  /// Seeks to the previous track.
  Future<void> seekToPrevious() async {
    final prev = (_currentIndex ?? 1) - 1;
    if (prev >= 0) _engine.seekToIndex(prev);
  }

  /// Updates the web prefetch window (seconds).
  void setWebPrefetchSeconds(int seconds) {
    _engine.setPrefetchSeconds(seconds);
  }

  void setTrackTransitionMode(String mode) {
    _engine.setTrackTransitionMode(mode);
  }

  void setCrossfadeDuration(double seconds) {
    _engine.setCrossfadeDuration(seconds);
  }

  /// Releases all resources.
  Future<void> dispose() async {
    _engine.stop();
    await _playerStateController.close();
    await _playbackEventController.close();
    await _playingController.close();
    await _processingStateController.close();
    await _positionController.close();
    await _bufferedPositionController.close();
    await _durationController.close();
    await _indexController.close();
    await _sequenceStateController.close();
    await _nextTrackBufferedController.close();
    await _nextTrackTotalController.close();
    await _contextStateController.close();
  }

  /// Reloads the web page.
  void reload() {
    _reloadPage();
  }
}

@JS('window.location.reload')
external void _reloadPage();
