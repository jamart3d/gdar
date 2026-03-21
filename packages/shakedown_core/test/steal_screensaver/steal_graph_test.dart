import 'dart:async';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/steal_screensaver/steal_config.dart';
import 'package:shakedown_core/steal_screensaver/steal_game.dart';
import 'package:shakedown_core/steal_screensaver/steal_graph.dart';
import 'package:shakedown_core/visualizer/audio_reactor.dart';

import '../helpers/test_helpers.dart';

class FakeAudioReactor implements AudioReactor {
  final StreamController<AudioEnergy> _controller = StreamController<AudioEnergy>.broadcast();
  @override
  Stream<AudioEnergy> get energyStream => _controller.stream;
  @override
  Future<void> start() async {}
  @override
  void stop() {}
  @override
  void updateConfig({double? peakDecay, double? bassBoost, double? reactivityStrength, double? beatSensitivity}) {}
  @override
  void dispose() => _controller.close();
  
  void push(AudioEnergy e) => _controller.add(e);
}

void main() {
  group('StealGraph', () {
    final mockDevice = MockDeviceService();
    final fakeReactor = FakeAudioReactor();
    
    // We instantiate the graph inside StealGame because StealGraph
    // relies on HasGameReference<StealGame> for game.size, game.time, and game.config.
    final stealGraphTester = FlameTester<StealGame>(
      () => StealGame(
        config: StealConfig(audioGraphMode: 'corner'),
        deviceService: mockDevice,
        audioReactor: fakeReactor,
      ),
    );

    stealGraphTester.testGameWidget(
      'is visible when audioGraphMode is active',
      setUp: (game, tester) async {
        // game.onLoad() is automatically called by FlameTester
      },
      verify: (game, tester) async {
        final graph = game.children.whereType<StealGraph>().first;
        expect(graph.graphMode, 'corner');
        expect(graph.isVisible, isTrue);
      },
    );

    stealGraphTester.testGameWidget(
      'reacts to audio energy updates',
      setUp: (game, tester) async {
        // Push some fake audio energy containing a beat
        final energy = AudioEnergy(
          bands: [0.1, 0.2, 0.8, 0.4, 0.5, 0.6, 0.7, 0.8], // 8 bands
          bass: 0.5,
          mid: 0.5,
          treble: 0.5,
          overall: 0.6,
          isBeat: true,
          waveformL: [],
          waveformR: [],
          waveform: [],
          beatAlgos: [true, false, false, false, false, false],
          algoLevels: [0.8, 0.2, 0.2, 0.2, 0.2, 0.2],
        );
        
        // Push to the fake reactor so StealGame picks it up on loop
        fakeReactor.push(energy);
        
        // Allow the stream to dispatch
        await Future.delayed(Duration.zero);
        
        // Pump game loop forward by a small fraction (dt) to process the beat
        game.update(0.016); 
      },
      verify: (game, tester) async {
        final graph = game.children.whereType<StealGraph>().first;
        
        // The graph tracks beat state internally from the energy stream injected via StealGame
        expect(graph.energy.isBeat, isTrue);
      },
    );
  });
}
