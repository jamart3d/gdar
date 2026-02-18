import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shakedown/visualizer/audio_reactor.dart';

/// Android Visualizer API-based audio reactor.
///
/// Uses the Android Visualizer API for real-time FFT analysis.
/// Tuning knobs (peakDecay, bassBoost, reactivityStrength) can be
/// updated live via [updateConfig] without restarting the visualizer.
class VisualizerAudioReactor implements AudioReactor {
  static const MethodChannel _methodChannel =
      MethodChannel('shakedown/visualizer');
  static const EventChannel _eventChannel =
      EventChannel('shakedown/visualizer_events');

  final StreamController<AudioEnergy> _energyController =
      StreamController<AudioEnergy>.broadcast();

  final int? audioSessionId;
  bool _isRunning = false;
  StreamSubscription<dynamic>? _eventSubscription;

  VisualizerAudioReactor({this.audioSessionId});

  @override
  Stream<AudioEnergy> get energyStream => _energyController.stream;

  @override
  void start() async {
    if (_isRunning) return;

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
      _energyController.add(const AudioEnergy.zero());
    }
  }

  /// Push updated tuning knobs to the native side in real time.
  /// Call this whenever settings change — no restart needed.
  @override
  void updateConfig({
    double? peakDecay,
    double? bassBoost,
    double? reactivityStrength,
  }) {
    if (!_isRunning) return;
    _methodChannel.invokeMethod('updateConfig', {
      if (peakDecay != null) 'peakDecay': peakDecay,
      if (bassBoost != null) 'bassBoost': bassBoost,
      if (reactivityStrength != null) 'reactivityStrength': reactivityStrength,
    });
  }

  @override
  void stop() async {
    if (!_isRunning) return;
    _isRunning = false;
    _eventSubscription?.cancel();
    _eventSubscription = null;
    try {
      await _methodChannel.invokeMethod('stop');
      await _methodChannel.invokeMethod('release');
    } catch (e) {
      // Ignore errors during cleanup
    }
  }

  @override
  void dispose() {
    stop();
    _energyController.close();
  }

  void _handleVisualizerData(dynamic data) {
    if (data is Map) {
      final bass = (data['bass'] as num?)?.toDouble() ?? 0.0;
      final mid = (data['mid'] as num?)?.toDouble() ?? 0.0;
      final treble = (data['treble'] as num?)?.toDouble() ?? 0.0;
      final overall = (data['overall'] as num?)?.toDouble() ?? 0.0;

      _energyController.add(AudioEnergy(
        bass: bass.clamp(0.0, 1.0),
        mid: mid.clamp(0.0, 1.0),
        treble: treble.clamp(0.0, 1.0),
        overall: overall.clamp(0.0, 1.0),
      ));
    }
  }

  void _handleError(dynamic error) {
    _energyController.add(const AudioEnergy.zero());
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
