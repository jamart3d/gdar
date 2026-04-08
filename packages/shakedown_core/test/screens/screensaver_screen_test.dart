import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/song_structure_hints.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/models/track.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/services/wakelock_service.dart';
import 'package:shakedown_core/steal_screensaver/steal_visualizer.dart';
import 'package:shakedown_core/ui/screens/screensaver_screen.dart';
import 'package:shakedown_core/visualizer/visualizer_audio_reactor.dart';
import '../helpers/fake_settings_provider.dart';

class FakeScreensaverSettingsProvider extends FakeSettingsProvider {
  @override
  bool get oilEnableAudioReactivity => false;
}

class FakeStereoScreensaverSettingsProvider extends FakeSettingsProvider {
  FakeStereoScreensaverSettingsProvider({required this.graphMode});

  final String graphMode;

  @override
  bool get oilEnableAudioReactivity => true;

  @override
  String get oilAudioGraphMode => graphMode;

  @override
  String get oilBeatDetectorMode => 'pcm';
}

class FakeReactiveScreensaverSettingsProvider extends FakeSettingsProvider {
  @override
  bool get oilEnableAudioReactivity => true;

  @override
  String get oilBeatDetectorMode => 'pcm';
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
  bool get isLowEndTvDevice => false;

  @override
  Future<void> refresh() async {}
}

class FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  FakeAudioProvider({this.trackTitle = 'Track'});

  final String trackTitle;
  final _audioPlayer = FakeScreensaverAudioPlayer();

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
    title: trackTitle,
    duration: 60,
    url: 'url',
    setName: 'Set 1',
  );

  @override
  bool get isPlaying => false;

  @override
  GaplessPlayer get audioPlayer => _audioPlayer;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeScreensaverAudioPlayer extends Fake implements GaplessPlayer {
  @override
  int? get androidAudioSessionId => 1;
}

void main() {
  late FakeScreensaverSettingsProvider settingsProvider;
  late FakeAudioProvider audioProvider;
  late FakeDeviceService deviceService;
  late FakeWakelockService wakelockService;
  const visualizerChannel = MethodChannel('shakedown/visualizer');
  const visualizerEventsChannel = MethodChannel('shakedown/visualizer_events');
  const stereoChannel = MethodChannel('shakedown/stereo');
  const permissionChannel = MethodChannel(
    'flutter.baseflow.com/permissions/methods',
  );

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    VisualizerAudioReactor.debugResetEventChannelLifecycleQueue();
    settingsProvider = FakeScreensaverSettingsProvider()..isTv = true;
    settingsProvider.setOilBannerFont('Roboto');
    audioProvider = FakeAudioProvider();
    deviceService = FakeDeviceService();
    wakelockService = FakeWakelockService();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(visualizerEventsChannel, (call) async {
          switch (call.method) {
            case 'listen':
            case 'cancel':
              return null;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(visualizerChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(visualizerEventsChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(stereoChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(permissionChannel, null);
  });

  Widget createTestableWidget({
    required Widget child,
    AudioProvider? audioOverride,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
        ChangeNotifierProvider<AudioProvider>.value(
          value: audioOverride ?? audioProvider,
        ),
        ChangeNotifierProvider<DeviceService>.value(value: deviceService),
        Provider<WakelockService>.value(value: wakelockService),
      ],
      child: MaterialApp(home: child),
    );
  }

  SongStructureHintCatalog createHintCatalog() {
    return const SongStructureHintCatalog(
      version: 1,
      kind: 'song_structure_hints',
      entries: [
        SongStructureHintEntry(
          id: 'eyes_main',
          title: 'Eyes of the World',
          canonicalTitle: 'Eyes of the World',
          variant: 'main',
          aliases: ['Eyes'],
          matchKeys: ['eyes', 'eyes_of_the_world'],
          confidence: 0.9,
          tempo: SongTempoHint(
            bpmMin: 108,
            bpmMax: 124,
            feel: 'steady',
            swing: 0.2,
          ),
          pulse: SongPulseHint(
            beatsPerBar: 4,
            subdivision: '8th',
            beatStrength: 'medium',
          ),
          rhythm: SongRhythmHint(
            density: 'medium',
            transientProfile: 'mid_onsets',
            notes: 'Test entry',
          ),
          sections: [],
          detectorHints: SongDetectorHint(
            preferPcm: true,
            preferLowOnsets: false,
            preferMidOnsets: true,
            phaseLockStrength: 0.4,
            refractoryBias: 'normal',
          ),
        ),
      ],
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

    testWidgets('passes matched song hint metadata into StealVisualizer', (
      WidgetTester tester,
    ) async {
      final hintAudioProvider = FakeAudioProvider(trackTitle: 'Eyes');

      await tester.pumpWidget(
        createTestableWidget(
          child: ScreensaverScreen(
            songHintCatalogOverride: createHintCatalog(),
          ),
          audioOverride: hintAudioProvider,
        ),
      );
      await tester.pump();

      final visualizer = tester.widget<StealVisualizer>(
        find.byType(StealVisualizer),
      );
      expect(visualizer.config.trackHintId, isNotEmpty);
      expect(visualizer.config.trackHintTitle, 'Eyes of the World');
      expect(visualizer.config.trackHintSeedSource, 'title');

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

    testWidgets(
      'requests stereo capture for reactive screensaver sessions and keeps it alive across dispose',
      (WidgetTester tester) async {
        final stereoSettings = FakeStereoScreensaverSettingsProvider(
          graphMode: 'beat_debug',
        )..isTv = true;
        var stereoRequestCount = 0;
        var stereoStopCount = 0;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(permissionChannel, (call) async {
              switch (call.method) {
                case 'checkPermissionStatus':
                  return 1; // granted
                case 'requestPermissions':
                  return <int, int>{7: 1}; // microphone granted
              }
              return null;
            });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(visualizerChannel, (call) async {
              switch (call.method) {
                case 'isAvailable':
                case 'initialize':
                case 'start':
                case 'stop':
                case 'release':
                case 'updateConfig':
                  return true;
              }
              return null;
            });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(stereoChannel, (call) async {
              switch (call.method) {
                case 'requestCapture':
                  stereoRequestCount++;
                  return true;
                case 'stopCapture':
                  stereoStopCount++;
                  return true;
              }
              return null;
            });

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsProvider>.value(
                value: stereoSettings,
              ),
              ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
              ChangeNotifierProvider<DeviceService>.value(value: deviceService),
              Provider<WakelockService>.value(value: wakelockService),
            ],
            child: const MaterialApp(home: ScreensaverScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
        await tester.pump();

        expect(stereoRequestCount, 1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();

        expect(stereoStopCount, 0);
      },
    );

    testWidgets('retries stereo capture request after a failed attempt', (
      WidgetTester tester,
    ) async {
      final stereoSettings = FakeStereoScreensaverSettingsProvider(
        graphMode: 'beat_debug',
      )..isTv = true;
      var stereoRequestCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(permissionChannel, (call) async {
            switch (call.method) {
              case 'checkPermissionStatus':
                return 1; // granted
              case 'requestPermissions':
                return <int, int>{7: 1};
            }
            return null;
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(visualizerChannel, (call) async {
            switch (call.method) {
              case 'isAvailable':
              case 'initialize':
              case 'start':
              case 'stop':
              case 'release':
              case 'updateConfig':
                return true;
            }
            return null;
          });
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(stereoChannel, (call) async {
            if (call.method == 'requestCapture') {
              stereoRequestCount++;
              return false; // simulate denial / system unavailability
            }
            return true;
          });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsProvider>.value(
              value: stereoSettings,
            ),
            ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
            ChangeNotifierProvider<DeviceService>.value(value: deviceService),
            Provider<WakelockService>.value(value: wakelockService),
          ],
          child: const MaterialApp(home: ScreensaverScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      });
      await tester.pump();

      // A failed attempt resets _hasAttemptedStereoCapture, so subsequent
      // builds re-request rather than being gated out permanently.
      // The retry fires within the same pump cycle (build() calls
      // _syncStereoCapture unawaited after each rebuild), so by the time
      // the initial pumps settle we already have more than one attempt.
      expect(stereoRequestCount, greaterThan(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    });

    testWidgets(
      'interactive pcm mode can skip microphone prompt when visualizer starts without it',
      (WidgetTester tester) async {
        final reactiveSettings = FakeReactiveScreensaverSettingsProvider()
          ..isTv = true;
        var permissionRequestCount = 0;
        var visualizerInitializeCount = 0;
        var stereoRequestCount = 0;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(permissionChannel, (call) async {
              switch (call.method) {
                case 'checkPermissionStatus':
                  return 0; // denied
                case 'requestPermissions':
                  permissionRequestCount++;
                  return <int, int>{7: 0};
              }
              return null;
            });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(visualizerChannel, (call) async {
              switch (call.method) {
                case 'isAvailable':
                case 'initialize':
                case 'start':
                case 'stop':
                case 'release':
                case 'updateConfig':
                  if (call.method == 'initialize') {
                    visualizerInitializeCount++;
                  }
                  return true;
              }
              return null;
            });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(stereoChannel, (call) async {
              if (call.method == 'requestCapture') {
                stereoRequestCount++;
              }
              return true;
            });

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsProvider>.value(
                value: reactiveSettings,
              ),
              ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
              ChangeNotifierProvider<DeviceService>.value(value: deviceService),
              Provider<WakelockService>.value(value: wakelockService),
            ],
            child: const MaterialApp(home: ScreensaverScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pump(const Duration(milliseconds: 600));
        await tester.runAsync(() async {
          await Future<void>.delayed(const Duration(milliseconds: 10));
        });
        await tester.pump();

        expect(find.byType(StealVisualizer), findsOneWidget);
        expect(permissionRequestCount, 0);
        expect(visualizerInitializeCount, greaterThanOrEqualTo(1));
        expect(stereoRequestCount, 1);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'non-interactive launch skips permission and enhanced capture prompts',
      (WidgetTester tester) async {
        final reactiveSettings = FakeReactiveScreensaverSettingsProvider()
          ..isTv = true;
        var permissionRequestCount = 0;
        var stereoRequestCount = 0;
        var visualizerInitializeCount = 0;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(permissionChannel, (call) async {
              switch (call.method) {
                case 'checkPermissionStatus':
                  return 0; // denied
                case 'requestPermissions':
                  permissionRequestCount++;
                  return <int, int>{7: 0};
              }
              return null;
            });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(visualizerChannel, (call) async {
              if (call.method == 'initialize') {
                visualizerInitializeCount++;
              }
              return true;
            });
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(stereoChannel, (call) async {
              if (call.method == 'requestCapture') {
                stereoRequestCount++;
              }
              return true;
            });

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<SettingsProvider>.value(
                value: reactiveSettings,
              ),
              ChangeNotifierProvider<AudioProvider>.value(value: audioProvider),
              ChangeNotifierProvider<DeviceService>.value(value: deviceService),
              Provider<WakelockService>.value(value: wakelockService),
            ],
            child: const MaterialApp(
              home: ScreensaverScreen(allowPermissionPrompts: false),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        expect(find.byType(StealVisualizer), findsOneWidget);
        expect(permissionRequestCount, 0);
        expect(stereoRequestCount, 0);
        expect(visualizerInitializeCount, 0);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      },
    );
  });
}
