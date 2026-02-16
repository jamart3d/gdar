import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/screensaver_screen.dart';
import 'package:shakedown/oil_slide/oil_slide_visualizer.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:flutter/services.dart';
import 'screensaver_screen_test.mocks.dart';

// Manual mock to avoid build_runner for this quick fix
class MockDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => false;
  @override
  String? get deviceName => 'Mock Device';
  @override
  Future<void> refresh() async {}
}

void main() {
  late MockSettingsProvider mockSettingsProvider;
  late MockAudioProvider mockAudioProvider;
  late MockDeviceService mockDeviceService;

  setUp(() {
    mockSettingsProvider = MockSettingsProvider();
    mockAudioProvider = MockAudioProvider();
    mockDeviceService = MockDeviceService();

    // Default mock behavior for SettingsProvider
    when(mockSettingsProvider.oilEnableAudioReactivity).thenReturn(true);
    when(mockSettingsProvider.oilViscosity).thenReturn(0.5);
    when(mockSettingsProvider.oilFlowSpeed).thenReturn(1.0);
    when(mockSettingsProvider.oilPalette).thenReturn('psychedelic');
    when(mockSettingsProvider.oilFilmGrain).thenReturn(0.1);
    when(mockSettingsProvider.oilPulseIntensity).thenReturn(0.5);
    when(mockSettingsProvider.oilVisualMode).thenReturn('psychedelic');
    when(mockSettingsProvider.oilMetaballCount).thenReturn(6);
    when(mockSettingsProvider.oilHeatDrift).thenReturn(0.1);
    when(mockSettingsProvider.oilScreensaverMode).thenReturn('default');
    when(mockSettingsProvider.oilEasterEggsEnabled).thenReturn(true);
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
      ],
      child: const MaterialApp(
        home: ScreensaverScreen(),
      ),
    );
  }

  testWidgets('ScreensaverScreen renders OilSlideVisualizer',
      (WidgetTester tester) async {
    // Mock MethodChannel for VisualizerAudioReactor.isAvailable
    const MethodChannel channel = MethodChannel('shakedown/visualizer');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (MethodCall methodCall) async {
      if (methodCall.method == 'isAvailable') {
        return false; // Force fallback to mock reactor
      }
      return null;
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(); // Allow initState async calls to proceed

    expect(find.byType(OilSlideVisualizer), findsOneWidget);
  });

  testWidgets(
      'ScreensaverScreen passes correct configuration to OilSlideVisualizer',
      (WidgetTester tester) async {
    // Setup specific mock values
    when(mockSettingsProvider.oilViscosity).thenReturn(0.8);
    when(mockSettingsProvider.oilVisualMode).thenReturn('lava_lamp');

    // Mock MethodChannel for VisualizerAudioReactor.isAvailable
    const MethodChannel channel = MethodChannel('shakedown/visualizer');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel,
        (MethodCall methodCall) async {
      if (methodCall.method == 'isAvailable') {
        return false;
      }
      return null;
    });

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump();

    // Verify
    final visualizerFinder = find.byType(OilSlideVisualizer);
    expect(visualizerFinder, findsOneWidget);

    final visualizer = tester.widget<OilSlideVisualizer>(visualizerFinder);
    expect(visualizer.config.viscosity, 0.8);
    expect(visualizer.config.visualMode, 'lava_lamp');
    expect(visualizer.config.palette, 'psychedelic'); // Default mock value
  });
}
