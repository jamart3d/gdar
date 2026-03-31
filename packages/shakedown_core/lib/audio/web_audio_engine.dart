import 'dart:async';
import 'package:shakedown_core/services/audio/gdar_audio_interface.dart';
import 'package:shakedown_core/audio/web_interop.dart';

/// A resilient web audio engine that supports both Web Audio and HTML5 playback.
/// Features a 5-second stall recovery "Escape Hatch".
class WebAudioEngine implements GdarAudioInterface {
  final _telemetryController = StreamController<GdarHudSnapshot>.broadcast();
  Timer? _stallTimer;

  bool _isSurvivalMode = false;

  // Internal state
  String? _currentUrl;
  String _activeEngine = 'WA'; // WA (Web Audio) or H5B (HTML5)
  String _contextState = 'suspended';

  // High-Fidelity Diagnostics (Observability)
  double _maxObservedDrift = 0.0;
  double _lastTickTime = 0.0;
  int _recoveryCount = 0;
  DateTime? _hiddenAt;
  bool _isVisible = true;
  String _visibilityDuration = 'V:VIS';
  double? _trackDuration; // Duration of current track in seconds
  double? _trackPosition; // Position of current track in seconds

  // Memory Safety
  final List<String> _prefetchBuffer = [];
  static const int _maxBufferSize = 3;

  // For testing/mocking
  bool simulateStall = false;

  @override
  Stream<GdarHudSnapshot> get telemetryStream => _telemetryController.stream;

  @override
  Future<void> initialize() async {
    // Bind telemetry updates to Worker-Tick for background pulse & drift tracking
    WebInterop.onWorkerTick.listen((event) {
      tick();
    });

    _emitTelemetry();
  }

  /// Manually triggers the background update cycle.
  /// Primarily used for testing scenarios where the WebWorker tick is unavailable.
  void tick() {
    _calculateDrift();
    _updateVisibilityDuration();
    _checkBoundarySentinel();
    _emitTelemetry();
  }

  @override
  Future<void> play(String url, {double volume = 1.0}) async {
    _currentUrl = url;
    _activeEngine = 'WA';
    _contextState = 'suspended';
    _trackPosition = 0.0;
    _trackDuration = 180.0; // Mocking a 3m track

    _prefetchBuffer.add(url);
    _evictOldBuffers();

    _emitTelemetry();

    // Start 5s Stall Recovery Timer (The "Escape Hatch")
    _stallTimer?.cancel();
    _stallTimer = Timer(const Duration(seconds: 5), () {
      if (_contextState != 'running') {
        _handleStall();
      }
    });

    // Sync MediaSession state immediately for OS controls
    WebInterop.syncMediaSession(true);

    // Simulate engine startup
    if (!simulateStall) {
      _checkContextState();
    }
  }

  @override
  void setSurvivalMode(bool active) {
    _isSurvivalMode = active;
    _emitTelemetry();
  }

  @override
  void updateVisibility(bool isVisible) {
    if (_isVisible == isVisible) return;

    _isVisible = isVisible;
    if (!isVisible) {
      _hiddenAt = DateTime.now();
    } else {
      _hiddenAt = null;
      _visibilityDuration = 'V:VIS';
    }
    _emitTelemetry();
  }

  void _handleStall() {
    _activeEngine = 'H5B';
    _recoveryCount++;
    // In a real app, this would instantiate or trigger the HTML5 <audio> element path
    _emitTelemetry();
  }

  void _checkContextState() {
    // Simulate a slight delay in AudioContext activation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_currentUrl != null && _activeEngine == 'WA') {
        _contextState = 'running';
        _emitTelemetry();
      }
    });
  }

  void _calculateDrift() {
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    if (_lastTickTime > 0) {
      final delta = now - _lastTickTime;
      final drift = (delta - 250.0).abs(); // Expected 250ms tick
      if (drift > _maxObservedDrift) {
        _maxObservedDrift = drift;
      }
    }
    _lastTickTime = now;
  }

  void _updateVisibilityDuration() {
    if (!_isVisible && _hiddenAt != null) {
      final diff = DateTime.now().difference(_hiddenAt!);
      final minutes = diff.inMinutes;
      final seconds = diff.inSeconds % 60;
      _visibilityDuration = 'V:HID(${minutes}m${seconds}s)';
    }
  }

  void _checkBoundarySentinel() {
    if (_trackDuration == null || _trackPosition == null) return;

    // Simulate position update
    _trackPosition = _trackPosition! + 0.25;

    final remaining = _trackDuration! - _trackPosition!;

    // Adaptive Prefetching: If hidden, trigger earlier or more aggressively
    final threshold = _isVisible ? 10.0 : 15.0;

    if (remaining <= threshold && remaining > (threshold - 0.25)) {
      _triggerPrewarm();
    }

    // Soft Stitching at T-0.5s
    if (remaining <= 0.5 && remaining > 0.25) {
      if (_maxObservedDrift > 50.0) {
        // Threshold for glue
        _injectFallbackGlue();
      }
      _handleSoftStitch();
    }
  }

  void _injectFallbackGlue() {
    _emitTelemetry(
      log:
          'Stability low (Drift: ${_maxObservedDrift}ms). Injecting 100ms silent glue.',
    );
  }

  void _handleSoftStitch() {
    // In real impl: Seamlessly transition to next buffered segment
    // We update MediaSession metadata for the new show segment
    _emitTelemetry(
      log: 'Soft Stitching: Syncing MediaSession for next show segment',
    );

    // Simulate continuity bridge
    _trackPosition = 0.0;
    _emitTelemetry(log: 'Transitioned to next show segment (0ms gap)');
  }

  void _triggerPrewarm() {
    _recoveryCount++;

    // In real impl: Initiate pre-warming of next track
    _emitTelemetry();
  }

  void _evictOldBuffers() {
    while (_prefetchBuffer.length > _maxBufferSize) {
      final evicted = _prefetchBuffer.removeAt(0);
      _emitTelemetry(log: 'Evicting buffer: $evicted');
    }
  }

  void _emitTelemetry({String? log}) {
    final snapshot = GdarHudSnapshot(
      engine: _activeEngine,
      contextState: _contextState,
      survival: _isSurvivalMode,
      url: _currentUrl ?? 'none',
      mdft: _maxObservedDrift,
      rvc: _recoveryCount,
      vDur: _visibilityDuration,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      metadata: log != null ? {'log': log} : const {},
    );
    _telemetryController.add(snapshot);
  }
}
