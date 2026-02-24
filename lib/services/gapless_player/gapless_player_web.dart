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
  external int get playlistLength;
  external String get contextState;
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

  bool _playing = false;
  int? _currentIndex;
  double _positionSec = 0;
  double _durationSec = 0;
  ProcessingState _processingState = ProcessingState.idle;
  List<IndexedAudioSource> _sequence = [];

  /// Creates a [GaplessPlayer] (web implementation).
  ///
  /// [audioPlayer] is intentionally ignored on web — provided only to satisfy
  /// the same constructor signature as the native wrapper.
  GaplessPlayer({AudioPlayer? audioPlayer}) {
    _engine.init();
    _engine.onStateChange(
      ((JSObject raw) {
        _onJsStateChange(raw as _GdarState);
      }).toJS,
    );
    _engine.onTrackChange(
      ((JSObject raw) {
        final s = raw as _GdarState;
        final to = s.index;
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

  void _onJsStateChange(_GdarState s) {
    final wasPlaying = _playing;
    final wasDuration = _durationSec;

    _playing = s.playing;
    _positionSec = s.position;
    _durationSec = s.duration;
    _currentIndex = s.index >= 0 ? s.index : null;

    _processingState = _playing
        ? ProcessingState.ready
        : (_currentIndex == null
            ? ProcessingState.idle
            : ProcessingState.ready);

    _positionController
        .add(Duration(milliseconds: (_positionSec * 1000).round()));

    if (_durationSec != wasDuration) {
      _durationController.add(_durationSec > 0
          ? Duration(milliseconds: (_durationSec * 1000).round())
          : null);
    }
    if (_playing != wasPlaying) {
      _playingController.add(_playing);
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

  /// Whether the engine is playing.
  bool get playing => _playing;

  /// Current playback position.
  Duration get position =>
      Duration(milliseconds: (_positionSec * 1000).round());

  /// Web has no separate buffered position concept; mirrors [position].
  Duration get bufferedPosition => position;

  /// Current track duration, or null if not yet known.
  Duration? get duration => _durationSec > 0
      ? Duration(milliseconds: (_durationSec * 1000).round())
      : null;

  /// Index of the current track in [sequence].
  int? get currentIndex => _currentIndex;

  /// The loaded [IndexedAudioSource] sequence.
  List<IndexedAudioSource> get sequence => _sequence;

  /// Current [ProcessingState].
  ProcessingState get processingState => _processingState;

  /// Synchronous [PlayerState] snapshot.
  PlayerState get playerState => PlayerState(_playing, _processingState);

  /// Not applicable on web — always null.
  int? get androidAudioSessionId => null;

  // ─── Streams ──────────────────────────────────────────────────────────────

  Stream<PlayerState> get playerStateStream => _playerStateController.stream;
  Stream<PlaybackEvent> get playbackEventStream =>
      _playbackEventController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<ProcessingState> get processingStateStream =>
      _processingStateController.stream;
  Stream<Duration> get bufferedPositionStream => _positionController.stream;
  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<int?> get currentIndexStream => _indexController.stream;
  Stream<SequenceState?> get sequenceStateStream =>
      _sequenceStateController.stream;

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
      );
    }
    return _JsTrack(url: '', title: '', artist: '', album: '', id: '');
  }

  /// Loads a playlist of audio sources into the JS engine.
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

  /// Appends additional audio sources to the JS playlist.
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

  /// Releases all resources.
  Future<void> dispose() async {
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
