import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown/utils/logger.dart';

/// Intelligent playback recovery agent that monitors buffering state and
/// automatically attempts recovery from network issues and buffering failures.
///
/// The agent adapts its behavior based on app visibility:
/// - **Background/Deep Sleep**: Silently attempts recovery after delay
/// - **Foreground/Visible**: Notifies user via callback for UI feedback
class BufferAgent with WidgetsBindingObserver {
  final AudioPlayer _audioPlayer;
  final void Function(String message, VoidCallback? retryAction)?
      _onRecoveryNotification;

  Timer? _bufferingTimer;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;

  bool _isBuffering = false;
  DateTime? _bufferingStartTime;
  bool _isRecovering = false;
  AppLifecycleState _appLifecycleState = AppLifecycleState.resumed;

  /// Creates a new Buffer Agent.
  ///
  /// [audioPlayer] - The audio player instance to monitor
  /// [onRecoveryNotification] - Optional callback for UI notifications when app is visible
  BufferAgent(
    this._audioPlayer, {
    void Function(String message, VoidCallback? retryAction)?
        onRecoveryNotification,
  }) : _onRecoveryNotification = onRecoveryNotification {
    _initialize();
  }

  void _initialize() {
    // Register as lifecycle observer
    WidgetsBinding.instance.addObserver(this);

    // Listen to player state changes
    _playerStateSubscription =
        _audioPlayer.playerStateStream.listen(_onPlayerStateChanged);

    // Listen to playback events for errors
    _playbackEventSubscription = _audioPlayer.playbackEventStream.listen(
      (_) {}, // Normal events
      onError: _onPlaybackError,
    );

    logger.i('BufferAgent: Initialized and monitoring playback');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appLifecycleState = state;
    logger.d('BufferAgent: App lifecycle changed to $state');
  }

  void _onPlayerStateChanged(PlayerState state) {
    final processingState = state.processingState;
    final isBuffering = processingState == ProcessingState.buffering;

    if (isBuffering && !_isBuffering) {
      // Started buffering
      _isBuffering = true;
      _bufferingStartTime = DateTime.now();
      _startBufferingTimer();
      logger.d('BufferAgent: Buffering started');
    } else if (!isBuffering && _isBuffering) {
      // Stopped buffering (playback resumed)
      _isBuffering = false;
      _bufferingStartTime = null;
      _cancelBufferingTimer();
      _isRecovering = false;
      logger.d('BufferAgent: Buffering ended (playback resumed)');
    }
  }

  void _startBufferingTimer() {
    _cancelBufferingTimer();

    // Check buffering duration every 5 seconds
    _bufferingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_bufferingStartTime == null || !_isBuffering) {
        timer.cancel();
        return;
      }

      final bufferingDuration = DateTime.now().difference(_bufferingStartTime!);

      // Threshold: 20 seconds (aligns with ExoPlayer min buffer)
      if (bufferingDuration.inSeconds >= 20 && !_isRecovering) {
        logger.w(
            'BufferAgent: Buffering stalled for ${bufferingDuration.inSeconds}s, attempting recovery');
        _attemptRecovery();
        timer.cancel();
      }
    });
  }

  void _cancelBufferingTimer() {
    _bufferingTimer?.cancel();
    _bufferingTimer = null;
  }

  void _onPlaybackError(Object error, StackTrace stackTrace) {
    logger.e('BufferAgent: Playback error detected',
        error: error, stackTrace: stackTrace);

    // If we're not already recovering, attempt recovery
    if (!_isRecovering) {
      logger.w('BufferAgent: Attempting recovery from playback error');
      _attemptRecovery();
    }
  }

  void _attemptRecovery() {
    if (_isRecovering) {
      logger.d('BufferAgent: Recovery already in progress, skipping');
      return;
    }

    _isRecovering = true;
    final isAppVisible = _appLifecycleState == AppLifecycleState.resumed;

    if (isAppVisible) {
      // App is visible: Notify user via callback
      logger.i('BufferAgent: App visible, showing recovery notification');
      _onRecoveryNotification?.call(
        'Network issue detected. Retrying playback...',
        _performRecovery,
      );

      // Also attempt automatic recovery after a short delay
      Future.delayed(const Duration(seconds: 2), _performRecovery);
    } else {
      // App is in background/deep sleep: Silent recovery after delay
      logger.i('BufferAgent: App in background, scheduling silent recovery');
      final delaySeconds =
          15 + (DateTime.now().millisecondsSinceEpoch % 16); // 15-30 seconds
      Future.delayed(Duration(seconds: delaySeconds), _performRecovery);
    }
  }

  void _performRecovery() {
    if (!_isRecovering) return;

    final currentPosition = _audioPlayer.position;
    logger.i(
        'BufferAgent: Performing recovery (position: ${currentPosition.inSeconds}s)');

    try {
      // Attempt recovery by seeking to current position (triggers rebuffering)
      _audioPlayer.seek(currentPosition).then((_) {
        logger.i('BufferAgent: Seek completed, attempting play');
        return _audioPlayer.play();
      }).then((_) {
        logger.i('BufferAgent: Recovery successful');
        _isRecovering = false;
      }).catchError((error) {
        logger.e('BufferAgent: Recovery failed', error: error);
        _isRecovering = false;
      });
    } catch (e) {
      logger.e('BufferAgent: Recovery attempt threw exception', error: e);
      _isRecovering = false;
    }
  }

  /// Disposes of the buffer agent and cleans up resources.
  void dispose() {
    logger.i('BufferAgent: Disposing');
    WidgetsBinding.instance.removeObserver(this);
    _cancelBufferingTimer();
    _playerStateSubscription?.cancel();
    _playbackEventSubscription?.cancel();
  }
}
