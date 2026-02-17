import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/screensaver_screen.dart';
import 'package:shakedown/steal_screensaver/steal_visualizer.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/services/wakelock_service.dart';
import 'package:flutter/services.dart';
import 'package:mockito/annotations.dart';
import 'screensaver_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SettingsProvider>(),
  MockSpec<AudioProvider>(),
  MockSpec<WakelockService>(),
])

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
  late MockWakelockService mockWakelockService;

  setUp(() {
    mockSettingsProvider = MockSettingsProvider();
    mockAudioProvider = MockAudioProvider();
    mockDeviceService = MockDeviceService();
    mockWakelockService = MockWakelockService();

    // Default mock behavior for SettingsProvider
    when(mockSettingsProvider.oilEnableAudioReactivity).thenReturn(true);
    when(mockSettingsProvider.oilFlowSpeed).thenReturn(0.5);
    when(mockSettingsProvider.oilPalette).thenReturn('acid_green');
    when(mockSettingsProvider.oilFilmGrain).thenReturn(0.15);
    when(mockSettingsProvider.oilPulseIntensity).thenReturn(0.8);
    when(mockSettingsProvider.oilHeatDrift).thenReturn(0.3);
    when(mockSettingsProvider.oilScreensaverMode).thenReturn('standard');
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
        Provider<WakelockService>.value(value: mockWakelockService),
      ],
      child: const MaterialApp(
        home: ScreensaverScreen(),
      ),
    );
  }

  testWidgets('ScreensaverScreen renders StealVisualizer',
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

    expect(find.byType(StealVisualizer), findsOneWidget);
  });

  testWidgets(
      'ScreensaverScreen passes correct configuration to StealVisualizer',
      (WidgetTester tester) async {
    // Setup specific mock values
    when(mockSettingsProvider.oilFlowSpeed).thenReturn(0.8);

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
    final visualizerFinder = find.byType(StealVisualizer);
    expect(visualizerFinder, findsOneWidget);

    final visualizer = tester.widget<StealVisualizer>(visualizerFinder);
    expect(visualizer.config.flowSpeed, 0.8);
    expect(visualizer.config.palette, 'acid_green'); // Default mock value
  });
}
