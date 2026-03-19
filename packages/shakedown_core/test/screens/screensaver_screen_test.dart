import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/wakelock_service.dart';
import 'package:shakedown_core/steal_screensaver/steal_visualizer.dart';
import 'package:shakedown_core/ui/screens/screensaver_screen.dart';
import '../helpers/fake_settings_provider.dart';

class FakeScreensaverSettingsProvider extends FakeSettingsProvider {
  @override
  bool get oilEnableAudioReactivity => false;
}

class FakeWakelockService extends Fake implements WakelockService {
  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}

  @override
  Future<void> toggle({required bool enable}) async {}
}

class FakeDeviceService extends ChangeNotifier implements DeviceService {
  @override
  bool get isTv => true;

  @override
  bool get isMobile => false;

  @override
  bool get isDesktop => false;

  @override
  bool get isSafari => false;

  @override
  bool get isPwa => false;

  @override
  String? get deviceName => 'Android TV';

  @override
  Future<void> refresh() async {}
}

class FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  Show? get currentShow => Show(
    name: 'Show',
    artist: 'Artist',
    date: '2025-01-01',
    venue: 'Venue',
    sources: const <Source>[],
  );

  @override
  Track? get currentTrack => Track(
    trackNumber: 1,
    title: 'Track',
    duration: 60,
    url: 'url',
    setName: 'Set 1',
  );

  @override
  bool get isPlaying => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeScreensaverSettingsProvider settingsProvider;
  late FakeAudioProvider audioProvider;
  late FakeDeviceService deviceService;
  late FakeWakelockService wakelockService;

  setUp(() {
    settingsProvider = FakeScreensaverSettingsProvider()..isTv = true;
    settingsProvider.setOilBannerFont('Roboto');
    audioProvider = FakeAudioProvider();
    deviceService = FakeDeviceService();
    wakelockService = FakeWakelockService();
  });

  Widget createTestableWidget({required Widget child}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
        ChangeNotifierProvider<DeviceService>.value(value: deviceService),
        Provider<WakelockService>.value(value: wakelockService),
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
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('passes correct configuration to StealVisualizer', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        createTestableWidget(child: const ScreensaverScreen()),
      );

      final visualizer = tester.widget<StealVisualizer>(
        find.byType(StealVisualizer),
      );
      expect(visualizer.config.palette, 'psychedelic');
      expect(visualizer.config.flowSpeed, 1.0);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('exits when onExit is called', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestableWidget(child: const ScreensaverScreen()),
      );

      final visualizer = tester.widget<StealVisualizer>(
        find.byType(StealVisualizer),
      );
      visualizer.onExit!();
      await tester.pumpAndSettle();

      expect(find.byType(ScreensaverScreen), findsNothing);
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
