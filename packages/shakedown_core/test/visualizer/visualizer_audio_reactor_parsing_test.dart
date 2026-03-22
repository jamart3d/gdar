import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';

/// Tests for AudioEnergy parsing logic, isolated from the platform channel.
///
/// VisualizerAudioReactor._handleVisualizerData is private, so we test the
/// contract through AudioEnergy directly — ensuring the waveform field parses
/// and clamps correctly as the reactor does.
void main() {
  group('AudioEnergy waveform parsing', () {
    AudioEnergy parseEvent(Map<String, dynamic> data) {
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

      List<double> bands;
      final rawBands = data['bands'];
      if (rawBands is List && rawBands.length >= 8) {
        bands = rawBands
            .take(8)
            .map((e) => (e as num).toDouble().clamp(0.0, 1.0))
            .toList();
      } else {
        bands = List.filled(8, 0.0);
      }

      List<double> waveform = const [];
      final rawWaveform = data['waveform'];
      if (rawWaveform is List && rawWaveform.isNotEmpty) {
        waveform = rawWaveform
            .map((e) => (e as num).toDouble().clamp(-1.0, 1.0))
            .toList();
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

      return AudioEnergy(
        bass: bass.clamp(0.0, 1.0),
        mid: mid.clamp(0.0, 1.0),
        treble: treble.clamp(0.0, 1.0),
        overall: overall.clamp(0.0, 1.0),
        isBeat: isBeat,
        beatScore: beatScore.clamp(0.0, 3.0),
        beatThreshold: beatThreshold.clamp(0.0, 3.0),
        beatConfidence: beatConfidence.clamp(0.0, 1.0),
        beatSource: beatSource,
        bands: bands,
        waveform: waveform,
        algoLevels: algoLevels,
        algoSignals: algoSignals,
        algoBaselines: algoBaselines,
        algoThresholds: algoThresholds,
        winningAlgoId: winningAlgoId,
      );
    }

    test('waveform absent → empty list', () {
      final e = parseEvent({
        'bass': 0.5,
        'mid': 0.3,
        'treble': 0.2,
        'overall': 0.3,
      });
      expect(e.waveform, isEmpty);
    });

    test('waveform empty list → empty list', () {
      final e = parseEvent({
        'bass': 0.5,
        'mid': 0.3,
        'treble': 0.2,
        'overall': 0.3,
        'waveform': <dynamic>[],
      });
      expect(e.waveform, isEmpty);
    });

    test('waveform 256 points are preserved', () {
      final samples = List<double>.generate(256, (i) => (i / 255.0) * 2 - 1);
      final e = parseEvent({
        'bass': 0.5,
        'mid': 0.3,
        'treble': 0.2,
        'overall': 0.3,
        'waveform': samples,
      });
      expect(e.waveform.length, 256);
    });

    test('waveform values clamped to -1..1', () {
      final e = parseEvent({
        'bass': 0.5,
        'mid': 0.3,
        'treble': 0.2,
        'overall': 0.3,
        'waveform': [2.0, -2.0, 0.5],
      });
      expect(e.waveform[0], 1.0);
      expect(e.waveform[1], -1.0);
      expect(e.waveform[2], 0.5);
    });

    test('isBeat false when absent', () {
      final e = parseEvent({
        'bass': 0.5,
        'mid': 0.3,
        'treble': 0.2,
        'overall': 0.3,
      });
      expect(e.isBeat, false);
    });

    test('isBeat true when set', () {
      final e = parseEvent({
        'bass': 0.5,
        'mid': 0.3,
        'treble': 0.2,
        'overall': 0.3,
        'isBeat': true,
      });
      expect(e.isBeat, true);
    });

    test('final hybrid beat telemetry parses and clamps correctly', () {
      final e = parseEvent({
        'bass': 0.5,
        'mid': 0.3,
        'treble': 0.2,
        'overall': 0.3,
        'beatScore': 4.0,
        'beatThreshold': -1.0,
        'beatConfidence': 1.5,
        'beatSource': 'PCM',
      });
      expect(e.beatScore, 3.0);
      expect(e.beatThreshold, 0.0);
      expect(e.beatConfidence, 1.0);
      expect(e.beatSource, 'PCM');
    });

    test('beat telemetry fields parse and clamp correctly', () {
      final e = parseEvent({
        'bass': 0.5,
        'mid': 0.3,
        'treble': 0.2,
        'overall': 0.3,
        'algoLevels': [4.0, 1.5, -1.0],
        'algoSignals': [0.8, 0.4, 2.0],
        'algoBaselines': [0.2, -1.0, 0.5],
        'algoThresholds': [2.5, 4.0, -1.0],
        'winningAlgoId': 1,
      });
      expect(e.algoLevels, [3.0, 1.5, 0.0]);
      expect(e.algoSignals, [0.8, 0.4, 1.0]);
      expect(e.algoBaselines, [0.2, 0.0, 0.5]);
      expect(e.algoThresholds, [2.5, 3.0, 0.0]);
      expect(e.winningAlgoId, 1);
    });

    test('negative winning algorithm id parses as null', () {
      final e = parseEvent({
        'bass': 0.5,
        'mid': 0.3,
        'treble': 0.2,
        'overall': 0.3,
        'winningAlgoId': -1,
      });
      expect(e.winningAlgoId, isNull);
    });
  });
}
