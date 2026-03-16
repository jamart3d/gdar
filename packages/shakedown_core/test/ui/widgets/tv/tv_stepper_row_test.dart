import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_stepper_row.dart';
import '../../../helpers/test_helpers.dart';
import '../../../screens/splash_screen_test.mocks.dart';

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

  group('TvStepperRow', () {
    testWidgets('renders label and formatted value', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          TvStepperRow(
            label: 'Test Speed',
            value: 1.5,
            min: 0.0,
            max: 3.0,
            step: 0.1,
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('Test Speed'), findsOneWidget);
      expect(find.text('1.50'), findsOneWidget);
    });

    testWidgets('captures DPAD Right key to increment value', (tester) async {
      double? updatedValue;

      await tester.pumpWidget(
        createTestableWidget(
          TvStepperRow(
            label: 'Test Speed',
            value: 1.5,
            min: 0.0,
            max: 3.0,
            step: 0.1,
            onChanged: (v) => updatedValue = v,
          ),
        ),
      );

      // Focus the stepper
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Press Right Arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(updatedValue, closeTo(1.6, 0.001));
    });

    testWidgets('captures DPAD Left key to decrement value', (tester) async {
      double? updatedValue;

      await tester.pumpWidget(
        createTestableWidget(
          TvStepperRow(
            label: 'Test Speed',
            value: 1.5,
            min: 0.0,
            max: 3.0,
            step: 0.1,
            onChanged: (v) => updatedValue = v,
          ),
        ),
      );

      // Focus the stepper
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Press Left Arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();

      expect(updatedValue, closeTo(1.4, 0.001));
    });

    testWidgets('respects min/max bounds', (tester) async {
      double? updatedValue;

      await tester.pumpWidget(
        createTestableWidget(
          TvStepperRow(
            label: 'Test Speed',
            value: 3.0, // Already at max
            min: 0.0,
            max: 3.0,
            step: 0.1,
            onChanged: (v) => updatedValue = v,
          ),
        ),
      );

      // Focus the stepper
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      // Press Right Arrow (should not exceed max)
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(
        updatedValue,
        isNull,
      ); // onChanged shouldn't be called if value doesn't change
    });

    testWidgets('uses custom valueFormatter if provided', (tester) async {
      await tester.pumpWidget(
        createTestableWidget(
          TvStepperRow(
            label: 'Test Speed',
            value: 0.995,
            min: 0.0,
            max: 1.0,
            step: 0.001,
            valueFormatter: (v) => 'VAL: ${v.toStringAsFixed(3)}',
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('VAL: 0.995'), findsOneWidget);
    });
  });
}
