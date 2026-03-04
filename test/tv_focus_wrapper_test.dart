import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:mockito/mockito.dart';

import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'helpers/test_helpers.dart';
import 'screens/splash_screen_test.mocks.dart';

void main() {
  late MockSettingsProvider mockSettings;
  late MockAudioProvider mockAudio;
  late MockDeviceService mockDevice;

  setUp(() {
    mockSettings = MockSettingsProvider();
    mockAudio = MockAudioProvider();
    mockDevice = MockDeviceService();

    when(mockSettings.rgbAnimationSpeed).thenReturn(1.0);
    when(mockSettings.performanceMode).thenReturn(false);
    when(mockSettings.useNeumorphism).thenReturn(false);
    when(mockAudio.isPlaying).thenReturn(false);
  });

  Widget createTestableWidget(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: mockSettings),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudio),
        ChangeNotifierProvider<DeviceService>.value(value: mockDevice),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('TvFocusWrapper does NOT trigger onTap on focus gain',
      (WidgetTester tester) async {
    bool tapped = false;
    final focusNode = FocusNode();

    await tester.pumpWidget(
      createTestableWidget(
        TvFocusWrapper(
          focusNode: focusNode,
          onTap: () {
            tapped = true;
          },
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );

    expect(tapped, isFalse);

    // Focus the widget
    focusNode.requestFocus();
    await tester.pump();

    expect(focusNode.hasFocus, isTrue);
    expect(tapped, isFalse,
        reason: 'onTap should not be called when focus is gained');
  });

  testWidgets('TvFocusWrapper triggers onTap on Select key up',
      (WidgetTester tester) async {
    bool tapped = false;
    final focusNode = FocusNode();

    await tester.pumpWidget(
      createTestableWidget(
        TvFocusWrapper(
          focusNode: focusNode,
          onTap: () {
            tapped = true;
          },
          child: const SizedBox(width: 100, height: 100),
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();

    // Send Select Key Down
    await simulateKeyDownEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(tapped, isFalse);

    // Send Select Key Up
    await simulateKeyUpEvent(LogicalKeyboardKey.select);
    await tester.pump();

    expect(tapped, isTrue);
  });
}
