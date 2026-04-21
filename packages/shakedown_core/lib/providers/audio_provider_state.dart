part of 'audio_provider.dart';

mixin _AudioProviderState {
  late final GaplessPlayer _audioPlayer;
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  StreamSubscription<int?>? _indexSubscription;
  final _errorController = StreamController<String>.broadcast();
  final _randomShowRequestController =
      StreamController<({Show show, Source source})>.broadcast();
  final _bufferAgentNotificationController =
      StreamController<
        ({String message, VoidCallback? retryAction})
      >.broadcast();
  final _notificationController = StreamController<String>.broadcast();
  final _playbackFocusRequestController = StreamController<void>.broadcast();

  ShowListProvider? _showListProvider;
  SettingsProvider? _settingsProvider;
  bool? _lastPreventSleep;
  String? _lastTrackTransitionMode;
  int? _lastHandoffCrossfadeMs;
  bool? _lastOfflineBuffering;
  bool? _lastEnableBufferAgent;
  BufferAgent? _bufferAgent;

  Show? _currentShow;
  Source? _currentSource;
  ({Show show, Source source})? _pendingRandomShowRequest;

  bool _hasMarkedAsPlayed = false;

  AppLifecycleListener? _appLifecycleListener;
  UndoCheckpoint? _undoCheckpoint;
  UndoCheckpoint? _lastCapturedUndoCheckpoint;
  Timer? _undoCheckpointTimer;
  bool _isRestoringUndo = false;

  String? _lastAgentMessage;
  String? _lastNotificationMessage;
  String? _lastIssueMessage;
  String? _playbackResumePromptMessage;
  DateTime? _lastIssueAt;
  Timer? _notificationTimeoutTimer;
  Timer? _issueTimeoutTimer;
  StreamController<DngSnapshot>? _diagnosticsController;
  Timer? _diagnosticsTimer;
  StreamController<HudSnapshot>? _hudSnapshotController;
  double? _lastKnownGapMs;

  bool _isTransitioning = false;
  bool _hasPrequeuedNextShow = false;
  bool _isSwitchingSource = false;
  int _playbackRequestSerial = 0;

  late final CatalogService _catalogService;
  late AudioCacheService _audioCacheService;
  late final WakelockService _wakelockService;
  StreamSubscription<Duration>? _bufferedPositionSubscription;
  DateTime _lastBufferedNotify = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastPositionNotify = DateTime.fromMillisecondsSinceEpoch(0);

  String? _error;
  DateTime _lastErrorNotifyAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _fadeId = 0;
  late final bool _isWeb;

  GaplessPlayer get audioPlayer => _audioPlayer;
  bool get isPlaying => _audioPlayer.playing;
  Show? get currentShow => _currentShow;
  Source? get currentSource => _currentSource;
  ({Show show, Source source})? get pendingRandomShowRequest =>
      _pendingRandomShowRequest;
  String? get error => _error;

  Track? get currentTrack {
    if (_currentSource == null) return null;
    final index = _audioPlayer.currentIndex;
    final sequence = _audioPlayer.sequence;
    if (index == null || index < 0 || index >= sequence.length) return null;

    final sourceItem = sequence[index];
    if (sourceItem.tag is! MediaItem) return null;
    final item = sourceItem.tag as MediaItem;

    final itemSourceId = item.extras?['source_id'] as String?;
    if (itemSourceId != null && itemSourceId != _currentSource!.id) {
      return null;
    }

    final localIndex = currentLocalTrackIndex;
    if (localIndex >= 0 && localIndex < _currentSource!.tracks.length) {
      return _currentSource!.tracks[localIndex];
    }

    return null;
  }

  Duration? get nextTrackBuffered => _audioPlayer.nextTrackBuffered;
  String get engineState => _audioPlayer.engineStateString;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration> get bufferedPositionStream =>
      _audioPlayer.bufferedPositionStream;
  Stream<Duration?> get nextTrackBufferedStream =>
      _audioPlayer.nextTrackBufferedStream;
  Stream<Duration?> get nextTrackTotalStream =>
      _audioPlayer.nextTrackTotalStream;
  Stream<bool> get heartbeatActiveStream => _audioPlayer.heartbeatActiveStream;
  Stream<bool> get heartbeatNeededStream => _audioPlayer.heartbeatNeededStream;
  Stream<String> get engineStateStringStream =>
      _audioPlayer.engineStateStringStream;
  Stream<String> get engineContextStateStream =>
      _audioPlayer.engineContextStateStream;
  Stream<double> get driftStream => _audioPlayer.driftStream;
  Stream<String> get visibilityStream => _audioPlayer.visibilityStream;
  Stream<String> get playbackErrorStream => _errorController.stream;
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      _randomShowRequestController.stream;
  Stream<({String message, VoidCallback? retryAction})>
  get bufferAgentNotificationStream =>
      _bufferAgentNotificationController.stream;
  Stream<String> get notificationStream => _notificationController.stream;
  Stream<void> get playbackFocusRequestStream =>
      _playbackFocusRequestController.stream;

  int get currentLocalTrackIndex {
    final index = _audioPlayer.currentIndex;
    if (index == null) return 0;
    final sequence = _audioPlayer.sequence;
    if (sequence.isEmpty || index >= sequence.length) return index;

    final sourceItem = sequence[index];
    if (sourceItem.tag is! MediaItem) return index;
    final item = sourceItem.tag as MediaItem;
    return item.extras?['track_index'] as int? ?? index;
  }

  void captureUndoCheckpoint() {
    if (_currentShow == null || _currentSource == null || _isRestoringUndo) {
      _lastCapturedUndoCheckpoint = null;
      return;
    }

    final checkpoint = UndoCheckpoint(
      sourceId: _currentSource!.id,
      showDate: _currentShow!.date,
      trackIndex: currentLocalTrackIndex,
      position: _audioPlayer.position,
      title: _currentShow!.name,
      createdAt: DateTime.now(),
    );
    _replaceUndoCheckpoint(checkpoint);
    _lastCapturedUndoCheckpoint = checkpoint;
  }

  void _replaceUndoCheckpoint(UndoCheckpoint checkpoint) {
    _undoCheckpointTimer?.cancel();
    _undoCheckpoint = checkpoint;
    _undoCheckpointTimer = Timer(
      const Duration(seconds: 10),
      _clearUndoCheckpoint,
    );
  }

  void _clearUndoCheckpoint() {
    _undoCheckpointTimer?.cancel();
    _undoCheckpointTimer = null;
    _undoCheckpoint = null;
    _lastCapturedUndoCheckpoint = null;
  }

  void _clearUndoCheckpointIfCurrent(UndoCheckpoint? checkpoint) {
    if (checkpoint == null || !identical(_undoCheckpoint, checkpoint)) {
      return;
    }

    _clearUndoCheckpoint();
  }

  @visibleForTesting
  UndoCheckpoint? get undoCheckpointForTest => _undoCheckpoint;

  int get cachedTrackCount => _audioCacheService.cachedTrackCount;
}
