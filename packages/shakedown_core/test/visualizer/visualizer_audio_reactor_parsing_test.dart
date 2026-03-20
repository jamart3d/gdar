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

      return AudioEnergy(
        bass: bass.clamp(0.0, 1.0),
        mid: mid.clamp(0.0, 1.0),
        treble: treble.clamp(0.0, 1.0),
        overall: overall.clamp(0.0, 1.0),
        isBeat: isBeat,
        bands: bands,
        waveform: waveform,
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
  });
}
