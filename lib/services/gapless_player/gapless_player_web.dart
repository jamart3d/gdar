import 'dart:async';
import 'dart:js_interop';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

// ─── JS interop bindings ─────────────────────────────────────────────────────

/// Binds to the JavaScript object at [window._gdarAudio].
@JS('_gdarAudio')
external _GdarAudioEngine get _engine;

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
  external void seekToIndex(int index);
  external void setPrefetchSeconds(int s);
  external _GdarState getState();
  external void onStateChange(JSFunction cb);
  external void onTrackChange(JSFunction cb);
  external void onError(JSFunction cb);
}

/// Snapshot of engine state returned by [_GdarAudioEngine.getState].
@JS()
@anonymous
extension type _GdarState(JSObject _) {
  external bool get playing;
  external int get index;
  external double get position;
  external double get duration;
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
  final _positionController = StreamController<Duration>.broadcast();
  final _durationController = StreamController<Duration?>.broadcast();
  final _indexController = StreamController<int?>.broadcast();
  final _sequenceStateController = StreamController<SequenceState?>.broadcast();
  final _nextTrackBufferedController = StreamController<Duration?>.broadcast();
  final _nextTrackTotalController = StreamController<Duration?>.broadcast();

  bool _playing = false;
  int? _currentIndex;
  double _positionSec = 0;
  double _durationSec = 0;
  double _nextTrackBufferedSec = 0;
  double _nextTrackTotalSec = 0;
  ProcessingState _processingState = ProcessingState.idle;
  List<IndexedAudioSource> _sequence = [];

  final bool _useJsEngine;
  final AudioPlayer? _fallbackPlayer;

  /// Creates a [GaplessPlayer] (web implementation).
  ///
  /// If [useWebGaplessEngine] is true, it bridges to the custom JS engine
  /// for perfect gapless playback. If false, it acts as a transparent proxy
  /// to a standard `just_audio` [AudioPlayer].
  GaplessPlayer({
    AudioPlayer? audioPlayer,
    bool useWebGaplessEngine = true,
  })  : _useJsEngine = useWebGaplessEngine,
        _fallbackPlayer =
            useWebGaplessEngine ? null : (audioPlayer ?? AudioPlayer()) {
    if (_useJsEngine) {
      _initJsEngine();
    }
  }

  void _initJsEngine() {
    _engine.init();
    _engine.onStateChange(
      ((JSObject raw) {
        _onJsStateChange(raw as _GdarState);
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
      ((JSObject raw) {
        _processingState = ProcessingState.idle;
        _processingStateController.add(_processingState);
        _playbackEventController.addError(
          Exception('gdar audio engine error'),
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

  void _onJsStateChange(_GdarState s) {
    final wasPlaying = _playing;
    final wasDuration = _durationSec;
    final wasIndex = _currentIndex;

    _playing = s.playing;
    _positionSec = s.position;
    _durationSec = s.duration;
    _nextTrackBufferedSec = s.nextTrackBuffered;
    _nextTrackTotalSec = s.nextTrackTotal;
    _currentIndex = s.index >= 0 ? s.index : null;

    _processingState = _mapProcessingState(s.processingState);

    _positionController
        .add(Duration(milliseconds: (_positionSec * 1000).round()));

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
    if (_currentIndex != wasIndex) {
      _indexController.add(_currentIndex);
      _emitSequenceState();
    }
    _processingStateController.add(_processingState);
    _emitPlayerState();
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

  Duration get bufferedPosition =>
      _useJsEngine ? position : _fallbackPlayer!.bufferedPosition;

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
      ? _positionController.stream
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
    if (!_useJsEngine) return _fallbackPlayer!.addAudioSources(sources);
    _sequence = [..._sequence, ...sources.whereType<IndexedAudioSource>()];
    _engine.appendTracks(sources.map(_sourceToJsTrack).toList().toJS);
  }

  /// Begins or resumes playback.
  Future<void> play() async =>
      _useJsEngine ? _engine.play() : _fallbackPlayer!.play();

  /// Pauses playback.
  Future<void> pause() async =>
      _useJsEngine ? _engine.pause() : _fallbackPlayer!.pause();

  /// Stops playback.
  Future<void> stop() async =>
      _useJsEngine ? _engine.stop() : _fallbackPlayer!.stop();

  /// Seeks to [position] within the current track, or to [index] if provided.
  Future<void> seek(Duration? position, {int? index}) async {
    if (!_useJsEngine) return _fallbackPlayer!.seek(position, index: index);
    if (index != null) {
      _engine.seekToIndex(index);
    } else if (position != null) {
      _engine.seek(position.inMilliseconds / 1000.0);
    }
  }

  /// Seeks to the next track.
  Future<void> seekToNext() async {
    if (!_useJsEngine) return _fallbackPlayer!.seekToNext();
    final next = (_currentIndex ?? 0) + 1;
    if (next < _sequence.length) _engine.seekToIndex(next);
  }

  /// Seeks to the previous track.
  Future<void> seekToPrevious() async {
    if (!_useJsEngine) return _fallbackPlayer!.seekToPrevious();
    final prev = (_currentIndex ?? 1) - 1;
    if (prev >= 0) _engine.seekToIndex(prev);
  }

  /// Updates the web prefetch window (seconds).
  void setWebPrefetchSeconds(int seconds) {
    if (_useJsEngine) _engine.setPrefetchSeconds(seconds);
  }

  /// Releases all resources.
  Future<void> dispose() async {
    if (!_useJsEngine) {
      return _fallbackPlayer!.dispose();
    }
    _engine.stop();
    await _playerStateController.close();
    await _playbackEventController.close();
    await _playingController.close();
    await _processingStateController.close();
    await _positionController.close();
    await _durationController.close();
    await _indexController.close();
    await _sequenceStateController.close();
  }
}
