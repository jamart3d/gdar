import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/screensaver_screen.dart';
import 'package:shakedown/steal_screensaver/steal_visualizer.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/services/wakelock_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'screensaver_exit_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SettingsProvider>(),
  MockSpec<AudioProvider>(),
])
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
    when(mockSettingsProvider.oilFlowSpeed).thenReturn(0.5);
    when(mockSettingsProvider.oilPalette).thenReturn('acid_green');

    when(mockSettingsProvider.oilPulseIntensity).thenReturn(0.8);
    when(mockSettingsProvider.oilHeatDrift).thenReturn(0.3);
    when(mockSettingsProvider.oilScreensaverMode).thenReturn('standard');
    when(mockSettingsProvider.oilPerformanceMode).thenReturn(false);
    when(mockSettingsProvider.oilShowInfoBanner).thenReturn(true);
    when(mockSettingsProvider.oilFilmGrain).thenReturn(0.15);
    when(mockSettingsProvider.oilInnerRingScale).thenReturn(1.0);
    when(mockSettingsProvider.oilInnerToMiddleGap).thenReturn(0.3);
    when(mockSettingsProvider.oilMiddleToOuterGap).thenReturn(0.3);
    when(mockSettingsProvider.oilOrbitDrift).thenReturn(1.0);
    when(mockSettingsProvider.oilPaletteCycle).thenReturn(false);
    when(mockSettingsProvider.oilPaletteTransitionSpeed).thenReturn(5.0);
    when(mockSettingsProvider.oilBlurAmount).thenReturn(0.0);
    when(mockSettingsProvider.oilFlatColor).thenReturn(false);
    when(mockSettingsProvider.oilBannerGlow).thenReturn(false);
    when(mockSettingsProvider.oilBannerFlicker).thenReturn(0.0);
    when(mockSettingsProvider.oilAudioPeakDecay).thenReturn(0.998);
    when(mockSettingsProvider.oilAudioBassBoost).thenReturn(1.0);
    when(mockSettingsProvider.oilAudioReactivityStrength).thenReturn(1.0);
    when(mockSettingsProvider.oilTranslationSmoothing).thenReturn(0.1);
    when(mockSettingsProvider.oilBannerDisplayMode).thenReturn('ring');
    when(mockSettingsProvider.oilLogoScale).thenReturn(0.5);
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
    await tester.tap(find.byType(StealVisualizer));
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
