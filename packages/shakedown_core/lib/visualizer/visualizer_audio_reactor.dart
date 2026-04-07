import 'dart:async';
import 'package:flutter/services.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';
import 'package:shakedown_core/utils/logger.dart';

/// Android Visualizer API-based audio reactor.
///
/// Uses the Android Visualizer API for real-time FFT analysis.
/// Tuning knobs (peakDecay, bassBoost, reactivityStrength, beatSensitivity)
/// can be updated live via [updateConfig] without restarting the visualizer.
class VisualizerAudioReactor implements AudioReactor {
  static const MethodChannel _methodChannel = MethodChannel(
    'shakedown/visualizer',
  );
  static const EventChannel _eventChannel = EventChannel(
    'shakedown/visualizer_events',
  );
  static const MethodChannel _stereoChannel = MethodChannel('shakedown/stereo');

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
  Future<bool> start() async {
    if (_isRunning || _isDisposed) return _isRunning;

    try {
      logger.i(
        'VisualizerAudioReactor: start() begin '
        '(audioSessionId=${audioSessionId ?? 0})',
      );
      final result = await _methodChannel.invokeMethod('initialize', {
        'audioSessionId': audioSessionId ?? 0,
      });
      logger.i('VisualizerAudioReactor: initialize returned $result');

      if (result == true) {
        _isRunning = true;

        logger.i('VisualizerAudioReactor: subscribing to event channel');
        _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
          _handleVisualizerData,
          onError: _handleError,
        );

        logger.i('VisualizerAudioReactor: invoking native start()');
        await _methodChannel.invokeMethod('start');
        logger.i('VisualizerAudioReactor: native start() returned');
        return true;
      }
    } catch (e) {
      logger.w('VisualizerAudioReactor: start() threw $e');
      _safeAdd(const AudioEnergy.zero());
    }
    return false;
  }

  /// Push updated tuning knobs to the native side in real time.
  /// Call this whenever settings change - no restart needed.
  @override
  void updateConfig({
    double? peakDecay,
    double? bassBoost,
    double? reactivityStrength,
    String? beatDetectorMode,
    String? autocorrBeatVariant,
    String? autocorrLogoVariant,
    double? beatSensitivity,
    bool? autocorrSecondPass,
    bool? autocorrSecondPassHq,
  }) {
    if (!_isRunning || _isDisposed) return;
    unawaited(
      _methodChannel.invokeMethod('updateConfig', {
        'peakDecay': ?peakDecay,
        'bassBoost': ?bassBoost,
        'reactivityStrength': ?reactivityStrength,
        'beatDetectorMode': ?beatDetectorMode,
        'autocorrBeatVariant': ?autocorrBeatVariant,
        'autocorrLogoVariant': ?autocorrLogoVariant,
        'beatSensitivity': ?beatSensitivity,
        'autocorrSecondPass': ?autocorrSecondPass,
        'autocorrSecondPassHq': ?autocorrSecondPassHq,
      }),
    );
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
    unawaited(
      stop().whenComplete(() {
        if (!_energyController.isClosed) {
          unawaited(_energyController.close());
        }
      }),
    );
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
      final beatScore = (data['beatScore'] as num?)?.toDouble() ?? 0.0;
      final beatThreshold = (data['beatThreshold'] as num?)?.toDouble() ?? 0.0;
      final beatConfidence =
          (data['beatConfidence'] as num?)?.toDouble() ?? 0.0;
      final rawBeatSource = data['beatSource'];
      final beatSource = rawBeatSource is String && rawBeatSource.isNotEmpty
          ? rawBeatSource
          : null;
      final beatBpm = _parseOptionalDouble(
        data['beatBpm'],
        min: 0.0,
        max: 400.0,
      );
      final beatIbiMs = _parseOptionalDouble(
        data['beatIbiMs'],
        min: 0.0,
        max: 5000.0,
      );
      final beatPhase = _parseOptionalDouble(
        data['beatPhase'],
        min: 0.0,
        max: 1.0,
      );
      final nextBeatMs = _parseOptionalDouble(
        data['nextBeatMs'],
        min: 0.0,
        max: 5000.0,
      );
      final beatGridConfidence = _parseOptionalDouble(
        data['beatGridConfidence'],
        min: 0.0,
        max: 1.0,
      );

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

      List<double> waveform = const [];
      final rawWaveform = data['waveform'];
      if (rawWaveform is List && rawWaveform.isNotEmpty) {
        waveform = rawWaveform
            .map((e) => (e as num).toDouble().clamp(-1.0, 1.0))
            .toList();
      }

      List<double> waveformL = const [];
      final rawWaveformL = data['waveformL'];
      if (rawWaveformL is List && rawWaveformL.isNotEmpty) {
        waveformL = rawWaveformL
            .map((e) => (e as num).toDouble().clamp(-1.0, 1.0))
            .toList();
      }

      List<double> waveformR = const [];
      final rawWaveformR = data['waveformR'];
      if (rawWaveformR is List && rawWaveformR.isNotEmpty) {
        waveformR = rawWaveformR
            .map((e) => (e as num).toDouble().clamp(-1.0, 1.0))
            .toList();
      }

      List<bool> beatAlgos = const [];
      final rawBeatAlgos = data['beatAlgos'];
      if (rawBeatAlgos is List && rawBeatAlgos.isNotEmpty) {
        beatAlgos = rawBeatAlgos.map((e) => e == true).toList();
      }

      List<double> parseDoubleList(
        Object? raw, {
        double min = 0.0,
        double max = 1.0,
      }) {
        if (raw is List && raw.isNotEmpty) {
          return raw.map((e) => (e as num).toDouble().clamp(min, max)).toList();
        }
        return const [];
      }

      final algoLevels = parseDoubleList(data['algoLevels'], max: 3.0);
      final algoSignals = parseDoubleList(data['algoSignals']);
      final algoBaselines = parseDoubleList(data['algoBaselines']);
      final algoThresholds = parseDoubleList(data['algoThresholds'], max: 3.0);
      final rawWinningAlgoId = data['winningAlgoId'];
      final winningAlgoId = rawWinningAlgoId is num && rawWinningAlgoId >= 0
          ? rawWinningAlgoId.toInt()
          : null;
      final rawDebugAudioSessionId = data['debugAudioSessionId'];
      final debugAudioSessionId =
          rawDebugAudioSessionId is num && rawDebugAudioSessionId >= 0
          ? rawDebugAudioSessionId.toInt()
          : null;
      final debugPcmActive = data['debugPcmActive'] == true;
      final debugPcmFresh = data['debugPcmFresh'] == true;
      final rawDebugPcmAnalysisFrames = data['debugPcmAnalysisFrames'];
      final debugPcmAnalysisFrames =
          rawDebugPcmAnalysisFrames is num && rawDebugPcmAnalysisFrames >= 0
          ? rawDebugPcmAnalysisFrames.toInt()
          : null;
      final debugPcmAgeMs = _parseOptionalDouble(
        data['debugPcmAgeMs'],
        min: 0.0,
        max: 600000.0,
      );

      _safeAdd(
        AudioEnergy(
          bass: bass.clamp(0.0, 1.0),
          mid: mid.clamp(0.0, 1.0),
          treble: treble.clamp(0.0, 1.0),
          overall: overall.clamp(0.0, 1.0),
          isBeat: isBeat,
          beatScore: beatScore.clamp(0.0, 3.0),
          beatThreshold: beatThreshold.clamp(0.0, 3.0),
          beatConfidence: beatConfidence.clamp(0.0, 1.0),
          beatSource: beatSource,
          beatBpm: beatBpm,
          beatIbiMs: beatIbiMs,
          beatPhase: beatPhase,
          nextBeatMs: nextBeatMs,
          beatGridConfidence: beatGridConfidence,
          bands: bands,
          waveform: waveform,
          waveformL: waveformL,
          waveformR: waveformR,
          beatAlgos: beatAlgos,
          algoLevels: algoLevels,
          algoSignals: algoSignals,
          algoBaselines: algoBaselines,
          algoThresholds: algoThresholds,
          winningAlgoId: winningAlgoId,
          debugAudioSessionId: debugAudioSessionId,
          debugPcmActive: debugPcmActive,
          debugPcmFresh: debugPcmFresh,
          debugPcmAnalysisFrames: debugPcmAnalysisFrames,
          debugPcmAgeMs: debugPcmAgeMs,
        ),
      );
    }
  }

  void _handleError(dynamic error) {
    _safeAdd(const AudioEnergy.zero());
  }

  double? _parseOptionalDouble(
    Object? raw, {
    required double min,
    required double max,
  }) {
    if (raw is! num) return null;
    return raw.toDouble().clamp(min, max);
  }

  /// Request AudioPlaybackCapture permission (shows system dialog on TV).
  /// Returns true if capture started, false if denied or unavailable.
  /// Falls back gracefully: waveformL/R stay empty and VU uses FFT bands.
  static Future<bool> requestStereoCapture() async {
    try {
      logger.i('VisualizerAudioReactor: invoking stereo requestCapture');
      final result = await _stereoChannel.invokeMethod<bool>('requestCapture');
      logger.i(
        'VisualizerAudioReactor: stereo requestCapture returned '
        '${result ?? false}',
      );
      return result ?? false;
    } catch (error) {
      logger.w('VisualizerAudioReactor: stereo requestCapture threw $error');
      return false;
    }
  }

  static Future<StereoCaptureStatus> getStereoCaptureStatus() async {
    try {
      final result = await _stereoChannel.invokeMethod<Object?>(
        'getCaptureStatus',
      );
      if (result is Map) {
        final active = result['active'] == true;
        final pending = result['pending'] == true;
        return StereoCaptureStatus(isActive: active, isPending: pending);
      }
    } catch (_) {}
    return const StereoCaptureStatus();
  }

  /// Stop AudioPlaybackCapture. Waveform L/R return to empty.
  static Future<void> stopStereoCapture() async {
    try {
      await _stereoChannel.invokeMethod<bool>('stopCapture');
    } catch (_) {}
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

class StereoCaptureStatus {
  final bool isActive;
  final bool isPending;

  const StereoCaptureStatus({this.isActive = false, this.isPending = false});

  bool get isInactive => !isActive && !isPending;
}
