part of 'audio_provider.dart';

mixin _AudioProviderDiagnostics on ChangeNotifier, _AudioProviderState {
  Stream<DngSnapshot> get diagnosticsStream {
    _diagnosticsController ??= StreamController<DngSnapshot>.broadcast(
      onListen: _startDiagnosticsTimer,
      onCancel: _stopDiagnosticsTimer,
    );
    return _diagnosticsController!.stream;
  }

  Stream<HudSnapshot> get hudSnapshotStream {
    _hudSnapshotController ??= StreamController<HudSnapshot>.broadcast(
      onListen: _startDiagnosticsTimer,
      onCancel: _stopDiagnosticsTimer,
    );
    return _hudSnapshotController!.stream;
  }

  HudSnapshot get currentHudSnapshot => createHudSnapshot();

  void clearLastIssue() {
    _issueTimeoutTimer?.cancel();
    _lastIssueMessage = null;
    _lastIssueAt = null;
    notifyListeners();
  }

  void _setAgentMessage(String message) {
    _lastAgentMessage = message;
    _startIssueClearTimer(message);
    notifyListeners();
  }

  void _setPlaybackResumePrompt(String message) {
    _playbackResumePromptMessage = message;
    _startIssueClearTimer(message);
    notifyListeners();
  }

  void _setNotificationMessage(String message) {
    _lastNotificationMessage = message;
    _startIssueClearTimer(message);
    _notificationTimeoutTimer?.cancel();
    _notificationTimeoutTimer = Timer(const Duration(seconds: 4), () {
      _lastNotificationMessage = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void _startIssueClearTimer(String message) {
    _issueTimeoutTimer?.cancel();
    _lastIssueMessage = message;
    _lastIssueAt = DateTime.now();
    _issueTimeoutTimer = Timer(const Duration(seconds: 8), () {
      if (_playbackResumePromptMessage == message) {
        _playbackResumePromptMessage = null;
      }
      _lastIssueMessage = null;
      _lastIssueAt = null;
      notifyListeners();
    });
  }

  void _clearPlaybackResumePrompt() {
    final prompt = _playbackResumePromptMessage;
    if (prompt == null) return;

    _playbackResumePromptMessage = null;
    if (_lastIssueMessage == prompt) {
      _issueTimeoutTimer?.cancel();
      _lastIssueMessage = null;
      _lastIssueAt = null;
    }
    notifyListeners();
  }

  void _startDiagnosticsTimer() {
    _diagnosticsTimer?.cancel();
    _diagnosticsTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (_diagnosticsController != null &&
          _diagnosticsController!.hasListener) {
        _diagnosticsController!.add(createSnapshot());
      }
      if (_hudSnapshotController != null &&
          _hudSnapshotController!.hasListener) {
        _hudSnapshotController!.add(createHudSnapshot());
      }
    });
  }

  void _stopDiagnosticsTimer() {
    final diagHasListeners = _diagnosticsController?.hasListener ?? false;
    final hudHasListeners = _hudSnapshotController?.hasListener ?? false;
    if (!diagHasListeners && !hudHasListeners) {
      _diagnosticsTimer?.cancel();
      _diagnosticsTimer = null;
    }
  }

  DngSnapshot createSnapshot() {
    final snapshot = DngSnapshot(
      position: _audioPlayer.position,
      buffered: _audioPlayer.bufferedPosition,
      nextBuffered: _audioPlayer.nextTrackBuffered ?? Duration.zero,
      drift: _audioPlayer.drift,
      visibility: _audioPlayer.visibility,
      playerState: _audioPlayer.playerState,
      engineState: _audioPlayer.engineStateString,
      engineContextState: _audioPlayer.engineContextState,
      hbActive: _audioPlayer.heartbeatActive,
      hbNeeded: _audioPlayer.heartbeatNeeded,
      agentMessage: _lastAgentMessage,
      notificationMessage: _lastNotificationMessage,
      lastIssueMessage: _lastIssueMessage,
      lastIssueAt: _lastIssueAt,
      error: (_error != null && _error!.isNotEmpty) ? 'ERR' : 'OK',
      fetchTtfbMs: _audioPlayer.fetchTtfbMs,
      fetchInFlight: _audioPlayer.fetchInFlight,
      lastGapMs: _audioPlayer.lastGapMs,
      scheduledIndex: _audioPlayer.scheduledIndex,
      scheduledStartContextTime: _audioPlayer.scheduledStartContextTime,
      ctxCurrentTime: _audioPlayer.ctxCurrentTime,
      outputLatencyMs: _audioPlayer.outputLatencyMs,
      lastDecodeMs: _audioPlayer.lastDecodeMs,
      lastConcatMs: _audioPlayer.lastConcatMs,
      failedTrackCount: _audioPlayer.failedTrackCount,
      workerTickCount: _audioPlayer.workerTickCount,
      sampleRate: _audioPlayer.sampleRate,
      decodedCacheSize: _audioPlayer.decodedCacheSize,
      handoffState: _audioPlayer.handoffState,
      handoffAttemptCount: _audioPlayer.handoffAttemptCount,
      lastHandoffPollCount: _audioPlayer.lastHandoffPollCount,
    );

    if (_audioPlayer.syncDebugProbeActive) {
      final playerState = snapshot.playerState;
      logger.i(
        'AudioProviderSync[${_audioPlayer.syncDebugProbeTag ?? 'unknown'}]: '
        'snapshotPos=${formatDuration(snapshot.position)} '
        'snapshotBuf=${formatDuration(snapshot.buffered)} '
        'snapshotNext=${formatDuration(snapshot.nextBuffered)} '
        'snapshotPlaying=${playerState?.playing ?? false} '
        'snapshotProcessing=${playerState?.processingState.name ?? 'unknown'} '
        'engineState=${snapshot.engineState ?? 'null'}',
      );
    }

    return snapshot;
  }

  HudSnapshot createHudSnapshot() {
    final dng = createSnapshot();
    final settings = _settingsProvider;
    if (settings == null) return HudSnapshot.empty();

    final isPlaying = dng.playerState?.playing ?? false;
    final headroom = dng.buffered - dng.position;
    final headroomSec = headroom.inSeconds;
    final headroomText = '${headroomSec >= 0 ? '+' : ''}${headroomSec}s';

    final signal =
        (dng.lastIssueMessage != null && dng.lastIssueMessage!.isNotEmpty)
        ? 'ISS'
        : (dng.notificationMessage != null &&
              dng.notificationMessage!.trim().isNotEmpty)
        ? 'NTF'
        : (dng.agentMessage != null && dng.agentMessage!.trim().isNotEmpty)
        ? 'AGT'
        : '--';

    var rawMessage = '--';
    if (dng.lastIssueMessage != null && dng.lastIssueMessage!.isNotEmpty) {
      rawMessage = dng.lastIssueMessage!.trim();
    } else if (dng.notificationMessage != null &&
        dng.notificationMessage!.trim().isNotEmpty) {
      rawMessage = dng.notificationMessage!.trim();
    } else if (dng.agentMessage != null &&
        dng.agentMessage!.trim().isNotEmpty) {
      rawMessage = dng.agentMessage!.trim();
    } else if (dng.engineState == 'handoff_countdown') {
      final diff = (dng.buffered - dng.position).inSeconds;
      final countdown = diff - 5;
      rawMessage = countdown > 0
          ? 'Handoff in ${countdown}s...'
          : 'Handing off to WebAudio...';
    }

    final message = rawMessage == '--'
        ? rawMessage
        : _compactMessage(rawMessage);
    final effectiveMode = settings.audioEngineMode == AudioEngineMode.auto
        ? _audioPlayer.activeMode
        : settings.audioEngineMode;
    final detectedProfile = kIsWeb ? _shortDetectedProfile() : '--';

    return HudSnapshot(
      engine: _shortMode(effectiveMode),
      detectedProfile: detectedProfile,
      transition: _shortTransition(settings.trackTransitionMode),
      handoff: _shortHandoff(settings.hybridHandoffMode),
      background: _shortBackground(settings.hybridBackgroundMode),
      preset: settings.hiddenSessionPreset == HiddenSessionPreset.stability
          ? 'STB'
          : settings.hiddenSessionPreset == HiddenSessionPreset.balanced
          ? 'BAL'
          : 'MAX',
      activeEngine: _shortActiveEngine(
        dng.engineContextState,
        effectiveMode,
        dng.hbActive,
      ),
      heartbeat: dng.hbActive ? 'ON' : (dng.hbNeeded ? 'ND' : 'OFF'),
      visibility: dng.visibility,
      drift: dng.drift == 0.0 ? '--' : '${(dng.drift * 1000).round()}ms',
      prefetch: settings.webPrefetchSeconds < 0
          ? 'G'
          : '${settings.webPrefetchSeconds}s',
      processing: _shortProcessing(dng.playerState?.processingState),
      buffered: formatDuration(dng.buffered),
      headroom: headroomText,
      nextBuffered: formatDuration(dng.nextBuffered),
      error: dng.error ?? '--',
      engineState: _shortEngineState(dng.engineState),
      signal: signal,
      message: message,
      hbActive: dng.hbActive,
      hbNeeded: dng.hbNeeded,
      heartbeatEnabledBySettings:
          settings.hybridBackgroundMode == HybridBackgroundMode.heartbeat,
      isPlaying: isPlaying,
      isHandoffCountdown: dng.engineState == 'handoff_countdown',
      fetchTtfbMs: dng.fetchTtfbMs,
      fetchInFlight: dng.fetchInFlight,
      lastGapMs: () {
        final gap = dng.lastGapMs;
        if (gap != null) _lastKnownGapMs = gap;
        return _lastKnownGapMs;
      }(),
      scheduledIndex: dng.scheduledIndex,
      scheduledStartContextTime: dng.scheduledStartContextTime,
      ctxCurrentTime: dng.ctxCurrentTime,
      outputLatencyMs: dng.outputLatencyMs,
      lastDecodeMs: dng.lastDecodeMs,
      lastConcatMs: dng.lastConcatMs,
      failedTrackCount: dng.failedTrackCount,
      workerTickCount: dng.workerTickCount,
      sampleRate: dng.sampleRate,
      decodedCacheSize: dng.decodedCacheSize,
      handoffState: dng.handoffState,
      handoffAttemptCount: dng.handoffAttemptCount,
      lastHandoffPollCount: dng.lastHandoffPollCount,
    );
  }

  String _compactMessage(String value) {
    final cleaned = value
        .replaceAll('\n', ' ')
        .replaceAll('\u2022', '-')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.length <= 100) return cleaned;
    return '${cleaned.substring(0, 97)}...';
  }

  String _shortMode(AudioEngineMode mode) {
    switch (mode) {
      case AudioEngineMode.webAudio:
        return 'WBA';
      case AudioEngineMode.html5:
        return 'H5';
      case AudioEngineMode.standard:
        return 'STD';
      case AudioEngineMode.passive:
        return 'PAS';
      case AudioEngineMode.hybrid:
        return 'HYB';
      case AudioEngineMode.auto:
        return 'AUT';
    }
  }

  String _shortDetectedProfile() {
    switch (detectWebRuntimeProfile()) {
      case WebRuntimeProfile.low:
        return 'L';
      case WebRuntimeProfile.pwa:
        return 'P';
      case WebRuntimeProfile.desk:
        return 'D';
      case WebRuntimeProfile.web:
        return 'W';
    }
  }

  String _shortTransition(String mode) {
    if (mode == 'crossfade') return 'XFD';
    if (mode == 'gapless') return 'GLS';
    return 'GAP';
  }

  String _shortHandoff(HybridHandoffMode mode) {
    switch (mode) {
      case HybridHandoffMode.immediate:
        return 'IMM';
      case HybridHandoffMode.boundary:
        return 'BND';
      case HybridHandoffMode.none:
        return 'OFF';
      case HybridHandoffMode.buffered:
        return 'BUF';
    }
  }

  String _shortBackground(HybridBackgroundMode mode) {
    switch (mode) {
      case HybridBackgroundMode.video:
        return 'VID';
      case HybridBackgroundMode.heartbeat:
        return 'HRT';
      case HybridBackgroundMode.html5:
        return 'H5';
      case HybridBackgroundMode.none:
        return 'OFF';
    }
  }

  String _shortActiveEngine(
    String? engineContextState,
    AudioEngineMode effectiveMode,
    bool heartbeatActive,
  ) {
    final state = engineContextState ?? '';
    // The hybrid JS engine emits contextState as 'hybrid (WA) ...' or
    // 'hybrid (H5B) ...', NOT the bare keywords 'webaudio'/'html5'.
    // Non-hybrid engines emit 'html5 (H5) ...' or 'standard'. Check both forms.
    final isWA = state.contains('webaudio') || state.contains('(WA)');
    final isH5B = state.contains('(H5B)');
    final isH5 = state.contains('html5') || state.contains('(H5)');
    final isSTD = state.contains('standard');

    if (isWA) return heartbeatActive ? 'WA+' : 'WA';
    if (isH5B) return heartbeatActive ? 'H5B+' : 'H5B';
    if (isH5) return heartbeatActive ? 'H5+' : 'H5';
    if (isSTD) return 'STD';
    // Context not yet populated — show unknown rather than mirroring ENG.
    return '--';
  }

  String _shortProcessing(ProcessingState? processing) {
    switch (processing) {
      case ProcessingState.idle:
        return 'IDL';
      case ProcessingState.loading:
        return 'LOD';
      case ProcessingState.buffering:
        return 'BUF';
      case ProcessingState.ready:
        return 'RDY';
      case ProcessingState.completed:
        return 'END';
      case null:
        return '--';
    }
  }

  String _shortEngineState(String? state) {
    switch (state) {
      case 'handoff_countdown':
        return 'CNT';
      case 'suspended_by_os':
        return 'SUS';
      case 'waiting_for_visibility':
        return 'VIS';
      case 'heartbeat_active':
        return 'HBA';
      case 'active':
        return 'ACT';
      case 'ready':
        return 'RDY';
      case 'idle':
        return 'IDL';
      case null:
        return '--';
      default:
        return state.length <= 3 ? state.toUpperCase() : state.substring(0, 3);
    }
  }
}
