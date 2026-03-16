import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:mockito/mockito.dart';

class MockSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  double get rgbAnimationSpeed => 1.0;
  @override
  bool get oilTvPremiumHighlight => false;
  @override
  int get glowMode => 0;
  @override
  bool get isTv => true;
  @override
  bool get highlightPlayingWithRgb => false;
  @override
  bool get highlightCurrentShowCard => false;
  @override
  bool get performanceMode => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockDeviceService extends Mock implements DeviceService {
  @override
  bool get isTv => true;
  @override
  bool get isPwa => false;
}

class MockAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  bool get isPlaying => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  Provider.debugCheckInvalidValueType = null;
  testWidgets(
    'TvFocusWrapper should NOT trigger onTap on KeyUp if KeyDown was not received',
    (WidgetTester tester) async {
      int tapCount = 0;

      final tvFocusNode = FocusNode();
      addTearDown(tvFocusNode.dispose);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsProvider>.value(value: MockSettingsProvider()),
            Provider<DeviceService>.value(value: MockDeviceService()),
            Provider<AudioProvider>.value(value: MockAudioProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  const Focus(autofocus: true, child: Text('Other Widget')),
                  TvFocusWrapper(
                    focusNode: tvFocusNode,
                    onTap: () => tapCount++,
                    child: const Text('Focus Me'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // 1. Press key while "Other Widget" is focused
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();

      // 2. Shift focus to TvFocusWrapper without tapping it
      tvFocusNode.requestFocus();
      await tester.pump();

      // 3. Release key while TvFocusWrapper is focused
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pump();

      // The tapCount should still be 0
      expect(
        tapCount,
        0,
        reason: 'onTap should not be called without a preceding KeyDown event',
      );
    },
  );

  testWidgets(
    'TvFocusWrapper SHOULD trigger onTap on KeyUp if KeyDown WAS received',
    (WidgetTester tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<SettingsProvider>.value(value: MockSettingsProvider()),
            Provider<DeviceService>.value(value: MockDeviceService()),
            Provider<AudioProvider>.value(value: MockAudioProvider()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: TvFocusWrapper(
                onTap: () => tapCount++,
                child: const Text('Focus Me'),
              ),
            ),
          ),
        ),
      );

      // Give focus to the widget
      await tester.tap(find.text('Focus Me'));
      await tester.pump();

      // Simulate a full KeyDown -> KeyUp sequence
      await tester.sendKeyDownEvent(LogicalKeyboardKey.select);
      await tester.pump();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.select);
      await tester.pump();

      // The tapCount should be 1
      expect(tapCount, 1);
    },
  );
}
