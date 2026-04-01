import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'helpers/fake_settings_provider.dart';

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
  bool get isLowEndTvDevice => false;

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSettingsProvider settingsProvider;
  late FakeAudioProvider audioProvider;
  late FakeWakelockService wakelockService;
  late FakeDeviceService deviceService;

  setUp(() {
    settingsProvider = FakeSettingsProvider()..isTv = true;
    audioProvider = FakeAudioProvider();
    wakelockService = FakeWakelockService();
    deviceService = FakeDeviceService();
  });

  Widget createWidgetUnderTest() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
        Provider<WakelockService>.value(value: wakelockService),
        ChangeNotifierProvider<DeviceService>.value(value: deviceService),
      ],
      child: const MaterialApp(home: ScreensaverScreen()),
    );
  }

  testWidgets('Screensaver exits on Tap', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 3000));

    expect(find.byType(ScreensaverScreen), findsOneWidget);

    await tester.tap(find.byType(StealVisualizer));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScreensaverScreen), findsNothing);
  });

  testWidgets('Screensaver exits on Key Event (D-pad Center)', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 3000));

    expect(find.byType(ScreensaverScreen), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScreensaverScreen), findsNothing);
  });

  testWidgets('Screensaver exits on Back button', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pump(const Duration(milliseconds: 3000));

    expect(find.byType(ScreensaverScreen), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(ScreensaverScreen), findsNothing);
  });
}
