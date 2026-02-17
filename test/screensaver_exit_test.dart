import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/screensaver_screen.dart';
import 'package:shakedown/oil_slide/oil_slide_visualizer.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/services/wakelock_service.dart';
import 'package:mockito/mockito.dart';
import 'screensaver_exit_test.mocks.dart';

class MockWakelockService extends Fake implements WakelockService {
  @override
  Future<void> enable() async {}
  @override
  Future<void> disable() async {}
  @override
  Future<void> toggle({required bool enable}) async {}
}

class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => true;
  @override
  String? get deviceName => 'Mock TV';
  @override
  Future<void> refresh() async {}
}

void main() {
  late MockSettingsProvider mockSettingsProvider;
  late MockAudioProvider mockAudioProvider;
  late MockWakelockService mockWakelockService;
  late MockDeviceService mockDeviceService;

  setUp(() {
    mockSettingsProvider = MockSettingsProvider();
    mockAudioProvider = MockAudioProvider();
    mockWakelockService = MockWakelockService();
    mockDeviceService = MockDeviceService();

    when(mockSettingsProvider.oilEnableAudioReactivity).thenReturn(false);
    when(mockSettingsProvider.oilViscosity).thenReturn(0.5);
    when(mockSettingsProvider.oilFlowSpeed).thenReturn(1.0);
    when(mockSettingsProvider.oilPalette).thenReturn('psychedelic');
    when(mockSettingsProvider.oilFilmGrain).thenReturn(0.1);
    when(mockSettingsProvider.oilPulseIntensity).thenReturn(0.5);
    when(mockSettingsProvider.oilVisualMode).thenReturn('psychedelic');
    when(mockSettingsProvider.oilMetaballCount).thenReturn(6);
    when(mockSettingsProvider.oilHeatDrift).thenReturn(0.1);
    when(mockSettingsProvider.oilScreensaverMode).thenReturn('default');
    when(mockSettingsProvider.oilEasterEggsEnabled).thenReturn(false);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        Provider<WakelockService>.value(value: mockWakelockService),
        ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
      ],
      child: const MaterialApp(
        home: ScreensaverScreen(),
      ),
    );
  }

  testWidgets('Screensaver exits on Tap', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScreensaverScreen), findsOneWidget);

    // Tap the visualizer
    await tester.tap(find.byType(OilSlideVisualizer));
    await tester.pump(const Duration(milliseconds: 500));
    await tester
        .pump(const Duration(milliseconds: 500)); // Second pump for transition

    // Verify it popped
    expect(find.byType(ScreensaverScreen), findsNothing);
  });

  testWidgets('Screensaver exits on Key Event (D-pad Center)',
      (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScreensaverScreen), findsOneWidget);

    // Global key handler doesn't require focus on a specific widget
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify it popped
    expect(find.byType(ScreensaverScreen), findsNothing);
  });

  testWidgets('Screensaver exits on Back button', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScreensaverScreen), findsOneWidget);

    // Simulate Back button press
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // Verify it popped
    expect(find.byType(ScreensaverScreen), findsNothing);
  });
}
