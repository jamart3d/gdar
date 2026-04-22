import 'dart:async';
import 'dart:js_interop';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/services/gapless_player/web_tick_stall_policy.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/utils/utils.dart';

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
  external void onPlayBlocked(JSFunction callback);
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

  @JS('scheduledIndex')
  external JSNumber? get scheduledIndexJS;
  int? get scheduledIndex => scheduledIndexJS?.toDartInt;

  @JS('scheduledStartContextTime')
  external JSNumber? get scheduledStartContextTimeJS;
  double? get scheduledStartContextTime =>
      scheduledStartContextTimeJS?.toDartDouble;

  @JS('ctxCurrentTime')
  external JSNumber? get ctxCurrentTimeJS;
  double? get ctxCurrentTime => ctxCurrentTimeJS?.toDartDouble;

  @JS('outputLatencyMs')
  external JSNumber? get outputLatencyMsJS;
  double? get outputLatencyMs => outputLatencyMsJS?.toDartDouble;

  @JS('lastDecodeMs')
  external JSNumber? get lastDecodeMsJS;
  double? get lastDecodeMs => lastDecodeMsJS?.toDartDouble;

  @JS('lastConcatMs')
  external JSNumber? get lastConcatMsJS;
  double? get lastConcatMs => lastConcatMsJS?.toDartDouble;

  @JS('failedTrackCount')
  external JSNumber? get failedTrackCountJS;
  int? get failedTrackCount => failedTrackCountJS?.toDartInt;

  @JS('workerTickCount')
  external JSNumber? get workerTickCountJS;
  int? get workerTickCount => workerTickCountJS?.toDartInt;

  @JS('sampleRate')
  external JSNumber? get sampleRateJS;
  int? get sampleRate => sampleRateJS?.toDartInt;

  @JS('decodedCacheSize')
  external JSNumber? get decodedCacheSizeJS;
  int? get decodedCacheSize => decodedCacheSizeJS?.toDartInt;

  @JS('hs')
  external JSString? get handoffStateJS;
  String? get handoffState => handoffStateJS?.toDart;

  @JS('hat')
  external JSNumber? get handoffAttemptCountJS;
  int? get handoffAttemptCount => handoffAttemptCountJS?.toDartInt;

  @JS('hpd')
  external JSNumber? get lastHandoffPollCountJS;
  int? get lastHandoffPollCount => lastHandoffPollCountJS?.toDartInt;
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
  final _playBlockedController = StreamController<void>.broadcast();
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
  final _scheduledStartContextTimeController =
      StreamController<double?>.broadcast();
  final _outputLatencyMsController = StreamController<double?>.broadcast();
  final _lastDecodeMsController = StreamController<double?>.broadcast();
  final _lastConcatMsController = StreamController<double?>.broadcast();
  final _failedTrackCountController = StreamController<int?>.broadcast();
  final _workerTickCountController = StreamController<int?>.broadcast();
  final _sampleRateController = StreamController<int?>.broadcast();
  final _decodedCacheSizeController = StreamController<int?>.broadcast();
  final _handoffStateController = StreamController<String?>.broadcast();
  final _handoffAttemptCountController = StreamController<int?>.broadcast();
  final _lastHandoffPollCountController = StreamController<int?>.broadcast();

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
  int? _scheduledIndex;
  double? _scheduledStartContextTime;
  double? _ctxCurrentTime;
  double? _outputLatencyMs;
  double? _lastDecodeMs;
  double? _lastConcatMs;
  int? _failedTrackCount;
  int? _workerTickCount;
  int? _sampleRate;
  int? _decodedCacheSize;
  String? _handoffState;
  int? _handoffAttemptCount;
  int? _lastHandoffPollCount;
  DateTime? _syncDebugProbeUntil;
  String? _syncDebugProbeTag;
  Timer? _staleTickTimer;
  Timer? _interpolationTimer;
  int _postPlayResyncGeneration = 0;

  static const _staleTickThreshold = Duration(seconds: 2);
  static const _staleTickPollInterval = Duration(seconds: 1);
  static const _interpolationInterval = Duration(milliseconds: 250);
  static const _interpolationMinGap = Duration(milliseconds: 250);

  final bool _useJsEngine;
  final AudioPlayer? _fallbackPlayer;

  void _emitPlayBlocked() {
    if (_playBlockedController.isClosed) {
      return;
    }
    _playBlockedController.add(null);
  }

  void startSyncDebugProbe(
    String tag, {
    Duration window = const Duration(seconds: 6),
  }) {
    _syncDebugProbeTag = tag;
    _syncDebugProbeUntil = DateTime.now().add(window);
  }

  bool get syncDebugProbeActive {
    final until = _syncDebugProbeUntil;
    if (until == null) {
      return false;
    }
    if (DateTime.now().isAfter(until)) {
      _syncDebugProbeUntil = null;
      _syncDebugProbeTag = null;
      return false;
    }
    return true;
  }

  String? get syncDebugProbeTag =>
      syncDebugProbeActive ? _syncDebugProbeTag : null;

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
      _startStaleTickWatchdog();
      if (hybridHandoffMode != null) {
        setHybridHandoffMode(hybridHandoffMode);
      }
    }
  }
}

@JS('window.location.reload')
external void _reloadPage();
