import 'package:flutter_test/flutter_test.dart';
import 'package:gdar_fruit/audio/web_audio_engine.dart';
import 'dart:async';

void main() {
  group('WebAudioEngine - Stall Recovery', () {
    test('triggers H5 fallback after 5 seconds of non-running state', () async {
      final engine = WebAudioEngine();
      engine.simulateStall = true;
      await engine.initialize();
      
      final states = <String>[];
      final subscription = engine.telemetryStream.listen((data) {
        states.add(data.engine);
      });

      await engine.play('https://example.com/audio.mp3');
      
      // Wait for more than 5 seconds
      await Future.delayed(const Duration(seconds: 6));
      
      expect(states.contains('H5'), isTrue, reason: 'Engine should switch to H5 after 5s stall');
      
      await subscription.cancel();
    });

    test('stays on WA if context becomes running within 5 seconds', () async {
      final engine = WebAudioEngine();
      engine.simulateStall = false;
      await engine.initialize();
      
      final states = <String>[];
      final subscription = engine.telemetryStream.listen((data) {
        states.add(data.engine);
      });

      await engine.play('https://example.com/audio.mp3');
      
      // Wait for the simulated 500ms activation
      await Future.delayed(const Duration(seconds: 1));
      
      expect(states.contains('WA'), isTrue);
      expect(states.contains('H5'), isFalse);
      
      await subscription.cancel();
    });
  });
}
