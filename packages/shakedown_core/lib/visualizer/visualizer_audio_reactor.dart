import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';

/// Android Visualizer API-based audio reactor.
///
/// Uses the Android Visualizer API for real-time FFT analysis.
/// Tuning knobs (peakDecay, bassBoost, reactivityStrength, beatSensitivity)
/// can be updated live via [updateConfig] without restarting the visualizer.
class VisualizerAudioReactor implements AudioReactor {
  static const MethodChannel _methodChannel =
      MethodChannel('shakedown/visualizer');
  static const EventChannel _eventChannel =
      EventChannel('shakedown/visualizer_events');

  final StreamController<AudioEnergy> _energyController =
      StreamController<AudioEnergy>.broadcast();

  final int? audioSessionId;
  bool _isRunning = false;
  bool _isDisposed = false;
  StreamSubscription<dynamic>? _eventSubscription;

  VisualizerAudioReactor({this.audioSessionId});

  @override
  Stream<AudioEnergy> get energyStream => _energyController.stream;

  @override
  void start() async {
    if (_isRunning || _isDisposed) return;

    try {
      final result = await _methodChannel.invokeMethod('initialize', {
        'audioSessionId': audioSessionId ?? 0,
      });

      if (result == true) {
        _isRunning = true;

        _eventSubscription = _eventChannel
            .receiveBroadcastStream()
            .listen(_handleVisualizerData, onError: _handleError);

        await _methodChannel.invokeMethod('start');
      }
    } catch (e) {
      _safeAdd(const AudioEnergy.zero());
    }
  }

  /// Push updated tuning knobs to the native side in real time.
  /// Call this whenever settings change - no restart needed.
  @override
  void updateConfig({
    double? peakDecay,
    double? bassBoost,
    double? reactivityStrength,
    double? beatSensitivity,
  }) {
    if (!_isRunning || _isDisposed) return;
    unawaited(_methodChannel.invokeMethod('updateConfig', {
      if (peakDecay != null) 'peakDecay': peakDecay,
      if (bassBoost != null) 'bassBoost': bassBoost,
      if (reactivityStrength != null) 'reactivityStrength': reactivityStrength,
      if (beatSensitivity != null) 'beatSensitivity': beatSensitivity,
    }));
  }

  @override
  Future<void> stop() async {
    if (!_isRunning && _eventSubscription == null) return;
    _isRunning = false;
    final subscription = _eventSubscription;
    _eventSubscription = null;
    try {
      await subscription?.cancel();
    } catch (e) {
      // Ignore stream cancellation errors during cleanup.
    }
    try {
      await _methodChannel.invokeMethod('stop');
      await _methodChannel.invokeMethod('release');
    } catch (e) {
      // Ignore errors during cleanup
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    unawaited(stop().whenComplete(() {
      if (!_energyController.isClosed) {
        unawaited(_energyController.close());
      }
    }));
  }

  void _safeAdd(AudioEnergy energy) {
    if (_isDisposed || _energyController.isClosed) return;
    _energyController.add(energy);
  }

  void _handleVisualizerData(dynamic data) {
    if (data is Map) {
      final bass = (data['bass'] as num?)?.toDouble() ?? 0.0;
      final mid = (data['mid'] as num?)?.toDouble() ?? 0.0;
      final treble = (data['treble'] as num?)?.toDouble() ?? 0.0;
      final overall = (data['overall'] as num?)?.toDouble() ?? 0.0;
      final isBeat = (data['isBeat'] as bool?) ?? false;

      // Parse 8-band data if available, otherwise synthesise from 3-band
      List<double> bands;
      final rawBands = data['bands'];
      if (rawBands is List && rawBands.length >= 8) {
        bands = rawBands
            .take(8)
            .map((e) => (e as num).toDouble().clamp(0.0, 1.0))
            .toList();
      } else {
        bands = [
          bass,
          bass,
          mid * 0.8,
          mid,
          mid * 0.6,
          treble * 0.8,
          treble,
          treble * 0.5,
        ];
      }

      _safeAdd(AudioEnergy(
        bass: bass.clamp(0.0, 1.0),
        mid: mid.clamp(0.0, 1.0),
        treble: treble.clamp(0.0, 1.0),
        overall: overall.clamp(0.0, 1.0),
        isBeat: isBeat,
        bands: bands,
      ));
    }
  }

  void _handleError(dynamic error) {
    _safeAdd(const AudioEnergy.zero());
  }

  static Future<bool> isAvailable() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
