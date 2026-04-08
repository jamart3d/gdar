import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shakedown_core/visualizer/visualizer_audio_reactor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const visualizerChannel = MethodChannel('shakedown/visualizer');
  const visualizerEventsChannel = MethodChannel('shakedown/visualizer_events');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(visualizerChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(visualizerEventsChannel, null);
  });

  test(
    'serializes shared visualizer event-channel teardown before a new reactor starts',
    () async {
      final flutterErrors = <FlutterErrorDetails>[];
      final previousOnError = FlutterError.onError;
      FlutterError.onError = flutterErrors.add;
      addTearDown(() => FlutterError.onError = previousOnError);

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(visualizerChannel, (call) async {
            switch (call.method) {
              case 'initialize':
              case 'start':
              case 'stop':
              case 'release':
              case 'isAvailable':
                return true;
            }
            return null;
          });

      var activeStreamGeneration = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(visualizerEventsChannel, (call) async {
            switch (call.method) {
              case 'listen':
                activeStreamGeneration++;
                return null;
              case 'cancel':
                final cancelGeneration = activeStreamGeneration;
                await Future<void>.delayed(const Duration(milliseconds: 10));
                if (cancelGeneration != activeStreamGeneration) {
                  throw PlatformException(
                    code: 'error',
                    message: 'No active stream to cancel',
                  );
                }
                activeStreamGeneration = 0;
                return null;
            }
            return null;
          });

      final firstReactor = VisualizerAudioReactor(audioSessionId: 1);
      expect(await firstReactor.start(), isTrue);

      firstReactor.dispose();

      final secondReactor = VisualizerAudioReactor(audioSessionId: 1);
      expect(await secondReactor.start(), isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(flutterErrors, isEmpty);

      await secondReactor.stop();
      secondReactor.dispose();
    },
  );
}
