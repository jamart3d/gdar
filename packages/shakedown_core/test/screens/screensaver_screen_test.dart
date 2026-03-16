import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/wakelock_service.dart';
import 'package:shakedown_core/ui/screens/screensaver_screen.dart';
import 'package:shakedown_core/steal_screensaver/steal_visualizer.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';

import 'screensaver_screen_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<SettingsProvider>(),
  MockSpec<AudioProvider>(),
  MockSpec<DeviceService>(),
  MockSpec<WakelockService>(),
  MockSpec<GaplessPlayer>(as: #MockAudioPlayerRelaxed),
])
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

    reset(mockSettingsProvider);
    reset(mockAudioProvider);

    // Default mock behavior for SettingsProvider
    when(mockSettingsProvider.oilEnableAudioReactivity).thenReturn(true);
    when(mockSettingsProvider.oilFlowSpeed).thenReturn(0.5);
    when(mockSettingsProvider.oilPalette).thenReturn('acid_green');
    when(mockSettingsProvider.oilPulseIntensity).thenReturn(0.8);
    when(mockSettingsProvider.oilHeatDrift).thenReturn(0.3);
    when(mockSettingsProvider.oilScreensaverMode).thenReturn('standard');
    when(mockSettingsProvider.oilPerformanceLevel).thenReturn(0);
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
    when(mockSettingsProvider.oilBannerDisplayMode).thenReturn('ring');
    when(mockSettingsProvider.oilLogoScale).thenReturn(0.5);
    when(mockSettingsProvider.oilLogoTrailIntensity).thenReturn(0.0);
    when(mockSettingsProvider.oilLogoTrailSlices).thenReturn(6);
    when(mockSettingsProvider.oilLogoTrailLength).thenReturn(0.5);
    when(mockSettingsProvider.oilLogoTrailScale).thenReturn(0.1);
    when(mockSettingsProvider.enableSwipeToBlock).thenReturn(false);
    when(mockSettingsProvider.oilBannerFont).thenReturn('Roboto');
    when(mockSettingsProvider.oilAudioGraphMode).thenReturn('off');
    when(mockSettingsProvider.oilBeatSensitivity).thenReturn(0.5);
    when(mockSettingsProvider.oilInnerRingFontScale).thenReturn(0.75);
    when(mockSettingsProvider.oilInnerRingSpacingMultiplier).thenReturn(0.7);
    when(mockSettingsProvider.oilTrackLetterSpacing).thenReturn(1.0);
    when(mockSettingsProvider.oilTrackWordSpacing).thenReturn(0.2);
    when(mockSettingsProvider.oilLogoAntiAlias).thenReturn(false);
    when(mockSettingsProvider.oilBannerResolution).thenReturn(2.0);
    when(mockSettingsProvider.oilLogoTrailDynamic).thenReturn(false);
    when(mockSettingsProvider.oilTranslationSmoothing).thenReturn(0.5);
    when(mockSettingsProvider.oilFlatTextProximity).thenReturn(0.5);
    when(mockSettingsProvider.oilFlatTextPlacement).thenReturn('center');
    when(mockSettingsProvider.oilScreensaver4kSupport).thenReturn(false);
    when(mockSettingsProvider.oilBannerPixelSnap).thenReturn(true);
    when(mockSettingsProvider.oilBeatImpact).thenReturn(0.25);
    when(mockSettingsProvider.oilScaleSource).thenReturn(-1);
    when(mockSettingsProvider.oilScaleMultiplier).thenReturn(1.0);
    when(mockSettingsProvider.oilColorSource).thenReturn(6);
    when(mockSettingsProvider.oilColorMultiplier).thenReturn(1.0);
    when(mockSettingsProvider.oilWoodstockEveryHour).thenReturn(true);

    // Mock AudioProvider's audioPlayer for ScreensaverScreen
    final mockAudioPlayer = MockAudioPlayerRelaxed();
    when(mockAudioProvider.audioPlayer).thenReturn(mockAudioPlayer);
    when(mockAudioProvider.isPlaying).thenReturn(false);
    when(mockAudioPlayer.androidAudioSessionId).thenReturn(0);

    // Mock DeviceService
    when(mockDeviceService.isTv).thenReturn(true);
    when(mockDeviceService.isMobile).thenReturn(false);
  });

  Widget createTestableWidget({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(
          value: mockSettingsProvider,
        ),
        ChangeNotifierProvider<AudioProvider>.value(value: mockAudioProvider),
        ChangeNotifierProvider<DeviceService>.value(value: mockDeviceService),
        Provider<WakelockService>.value(value: mockWakelockService),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('ScreensaverScreen', () {
    testWidgets('renders StealVisualizer', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(child: const ScreensaverScreen()),
      );
      expect(find.byType(StealVisualizer), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('passes correct configuration to StealVisualizer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(child: const ScreensaverScreen()),
      );

      final StealVisualizer visualizer = tester.widget(
        find.byType(StealVisualizer),
      );
      expect(visualizer.config.palette, 'acid_green');
      expect(visualizer.config.flowSpeed, 0.5);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('exits when onExit is called', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(child: const ScreensaverScreen()),
      );

      final StealVisualizer visualizer = tester.widget(
        find.byType(StealVisualizer),
      );
      visualizer.onExit!();
      await tester.pumpAndSettle();

      expect(find.byType(ScreensaverScreen), findsNothing);
      await tester.pumpWidget(Container());
      await tester.pump(
        const Duration(milliseconds: 600),
      ); // Clear initState Future.delayed
    });
  });
}
