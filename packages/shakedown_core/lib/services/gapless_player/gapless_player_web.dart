import 'dart:async';
import 'dart:js_interop';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/utils/logger.dart';

part 'gapless_player_web_engine.dart';
part 'gapless_player_web_accessors.dart';
part 'gapless_player_web_api.dart';

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
  external void setPrefetchSeconds(JSNumber seconds);
  external _GdarState getState();
  external void onStateChange(JSFunction callback);
  external void onTrackChange(JSFunction callback);
  external void onError(JSFunction callback);
  external void setHybridBackgroundMode(JSString mode);
  external void setHybridHandoffMode(JSString mode);
  external void setHybridAllowHiddenWebAudio(JSBoolean enabled);
  external void setVolume(JSNumber volume);
}

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

class _GaplessPlayerBase {
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

  _GaplessPlayerBase({
    AudioPlayer? audioPlayer,
    bool? useWebGaplessEngine,
    String? trackTransitionMode,
    double? crossfadeDurationSeconds,
    AudioEngineMode? audioEngineMode,
    String? hybridHandoffMode,
  }) : _useJsEngine = useWebGaplessEngine ?? (_strategy != 'standard'),
       _fallbackPlayer = (useWebGaplessEngine ?? (_strategy != 'standard'))
           ? null
           : (audioPlayer ?? AudioPlayer());
}

class GaplessPlayer extends _GaplessPlayerBase
    with
        _GaplessPlayerWebEngine,
        _GaplessPlayerWebAccessors,
        _GaplessPlayerWebApi {
  GaplessPlayer({
    super.audioPlayer,
    super.useWebGaplessEngine,
    super.trackTransitionMode,
    super.crossfadeDurationSeconds,
    super.audioEngineMode,
    String? hybridHandoffMode,
  }) : super(hybridHandoffMode: hybridHandoffMode) {
    logger.i('GaplessPlayer: Detected Engine: $engineName');
    logger.i('GaplessPlayer: Selection Reason: $selectionReason');

    if (_useJsEngine) {
      _initJsEngine();
      _setupVisibilityListener();
      if (hybridHandoffMode != null) {
        setHybridHandoffMode(hybridHandoffMode);
      }
    }
  }
}

@JS('window.location.reload')
external void _reloadPage();
