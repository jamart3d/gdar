import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/screensaver_screen.dart';
import 'package:shakedown/oil_slide/oil_slide_visualizer.dart';
import 'package:flutter/services.dart';

import 'screensaver_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SettingsProvider>(),
  MockSpec<AudioProvider>(),
])
void main() {
  late MockSettingsProvider mockSettingsProvider;
  late MockAudioProvider mockAudioProvider;

  setUp(() {
    mockSettingsProvider = MockSettingsProvider();
    mockAudioProvider = MockAudioProvider();

    // Default mock behavior
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

    // Mock AudioProvider
    // Using a fake AudioPlayer or mocking the property
    // For now, just ensuring it doesn't crash on sessionId access
    // Note: in a real test we might need more exhaustive mocks for AudioPlayer
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
            value: mockSettingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
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
