import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shakedown/visualizer/audio_reactor.dart';

/// Android Visualizer API-based audio reactor.
///
/// This reactor uses the Android Visualizer API to perform real-time FFT
/// analysis on the audio output, providing accurate frequency-based energy data.
///
/// Requires Android platform and an active audio session.
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
      // Initialize the visualizer on the native side
      final result = await _methodChannel.invokeMethod('initialize', {
        'audioSessionId': audioSessionId ?? 0,
      });

      if (result == true) {
        _isRunning = true;

        // Listen to FFT data from native side via EventChannel
        _eventSubscription = _eventChannel
            .receiveBroadcastStream()
            .listen(_handleVisualizerData, onError: _handleError);

        // Start capturing
        await _methodChannel.invokeMethod('start');
      }
    } catch (e) {
      // If initialization fails, emit zero energy
      _energyController.add(const AudioEnergy.zero());
    }
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

  /// Handle FFT data from the native visualizer.
  ///
  /// The data is expected to be a map with frequency band magnitudes:
  /// {
  ///   'bass': double (0.0-1.0),
  ///   'mid': double (0.0-1.0),
  ///   'treble': double (0.0-1.0),
  ///   'overall': double (0.0-1.0)
  /// }
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
    // On error, emit zero energy
    _energyController.add(const AudioEnergy.zero());
  }

  /// Check if the Android Visualizer API is available on this device.
  static Future<bool> isAvailable() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } catch (e) {
      return false;
    }
  }
}
