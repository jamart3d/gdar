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

    int? localIndex;
    if (item.extras?.containsKey('track_index') ?? false) {
      localIndex = item.extras!['track_index'] as int?;
    }
    if (localIndex == null) {
      try {
        final parts = item.id.split('_');
        localIndex = int.tryParse(parts.last);
      } catch (_) {}
    }

    if (localIndex != null &&
        localIndex >= 0 &&
        localIndex < _currentSource!.tracks.length) {
      return _currentSource!.tracks[localIndex];
    }

    if (index < _currentSource!.tracks.length) {
      return _currentSource!.tracks[index];
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

  int get cachedTrackCount => _audioCacheService.cachedTrackCount;
}
