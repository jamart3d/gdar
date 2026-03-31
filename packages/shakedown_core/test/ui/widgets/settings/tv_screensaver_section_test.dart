import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';
import 'package:shakedown_core/ui/widgets/settings/tv_screensaver_section.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import '../../../helpers/fake_settings_provider.dart';

class _FakeThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => ThemeStyle.android;
  @override
  bool get isDarkMode => true;
  @override
  bool get isFruitAllowed => false;
  @override
  Future<void> get initializationComplete => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  bool get isPlaying => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeviceService extends ChangeNotifier implements DeviceService {
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

class _FakeSettings extends FakeSettingsProvider {
  _FakeSettings(
    this._graphMode, {
    String beatDetectorMode = 'auto',
    bool enableAudioReactivity = true,
    this.scaleSineEnabled = false,
  }) : _beatDetectorMode = beatDetectorMode,
       _enableAudioReactivity = enableAudioReactivity {
    isTv = true;
  }

  final String _graphMode;
  final bool scaleSineEnabled;
  String _beatDetectorMode;
  bool _enableAudioReactivity;

  @override
  String get oilAudioGraphMode => _graphMode;

  @override
  String get oilBeatDetectorMode => _beatDetectorMode;

  @override
  bool get oilEnableAudioReactivity => _enableAudioReactivity;

  @override
  bool get oilScaleSineEnabled => scaleSineEnabled;

  @override
  Future<void> setOilBeatDetectorMode(String mode) async {
    _beatDetectorMode = mode;
    notifyListeners();
  }

  @override
  Future<void> toggleOilEnableAudioReactivity() async {
    _enableAudioReactivity = !_enableAudioReactivity;
    notifyListeners();
  }
}

Widget _buildSection(
  String graphMode, {
  String beatDetectorMode = 'auto',
  bool enableAudioReactivity = true,
  bool scaleSineEnabled = false,
  ScreensaverLaunchDelegate? launchDelegate,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(
        value: _FakeSettings(
          graphMode,
          beatDetectorMode: beatDetectorMode,
          enableAudioReactivity: enableAudioReactivity,
          scaleSineEnabled: scaleSineEnabled,
        ),
      ),
      ChangeNotifierProvider<ThemeProvider>.value(value: _FakeThemeProvider()),
      ChangeNotifierProvider<DeviceService>.value(value: _FakeDeviceService()),
      ChangeNotifierProvider<AudioProvider>.value(value: _FakeAudioProvider()),
      Provider<ScreensaverLaunchDelegate?>.value(value: launchDelegate),
    ],
    child: const MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TvScreensaverSection(
            scaleFactor: 1.0,
            initiallyExpanded: true,
          ),
        ),
      ),
    ),
  );
}

void main() {
  const stereoChannel = MethodChannel('shakedown/stereo');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(stereoChannel, null);
  });

  group('TvScreensaverSection audio graph mode — control visibility', () {
    testWidgets(
      'circular: shows Radius, hides Line Replication and Line Spread',
      (tester) async {
        await tester.pumpWidget(_buildSection('circular'));
        expect(find.text('Radius'), findsOneWidget);
        expect(find.text('Line Replication'), findsNothing);
        expect(find.text('Line Spread'), findsNothing);
      },
    );

    testWidgets(
      'circular_ekg: shows Radius, Line Replication, and Line Spread',
      (tester) async {
        await tester.pumpWidget(_buildSection('circular_ekg'));
        expect(find.text('Radius'), findsOneWidget);
        expect(find.text('Line Replication'), findsOneWidget);
        expect(find.text('Line Spread'), findsOneWidget);
      },
    );

    testWidgets('ekg: shows Line Replication and Line Spread, no Radius', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSection('ekg'));
      expect(find.text('Radius'), findsNothing);
      expect(find.text('Line Replication'), findsOneWidget);
      expect(find.text('Line Spread'), findsOneWidget);
    });

    testWidgets('corner: shows no EKG controls', (tester) async {
      await tester.pumpWidget(_buildSection('corner'));
      expect(find.text('Radius'), findsNothing);
      expect(find.text('Line Replication'), findsNothing);
      expect(find.text('Line Spread'), findsNothing);
    });

    testWidgets('off: shows no EKG controls', (tester) async {
      await tester.pumpWidget(_buildSection('off'));
      expect(find.text('Radius'), findsNothing);
      expect(find.text('Line Replication'), findsNothing);
      expect(find.text('Line Spread'), findsNothing);
      expect(find.text('NONE'), findsNWidgets(2));
      expect(find.text('DEF'), findsNWidgets(2));
    });

    testWidgets(
      'audio reactivity off hides frequency-isolation controls but keeps sine drive',
      (tester) async {
        await tester.pumpWidget(
          _buildSection(
            'corner',
            enableAudioReactivity: false,
            scaleSineEnabled: true,
          ),
        );

        expect(find.text('Frequency Isolation'), findsNothing);
        expect(find.text('Logo Scale Source'), findsNothing);
        expect(find.text('Scale Multiplier'), findsNothing);
        expect(find.text('Logo Color Source'), findsNothing);
        expect(find.text('Color Pulse Multiplier'), findsNothing);
        expect(find.text('Audio Graph'), findsNothing);
        expect(find.text('Reactivity Strength'), findsNothing);
        expect(find.text('Sine Wave Drive'), findsOneWidget);
        expect(find.text('Sine Frequency'), findsOneWidget);
        expect(find.text('Sine Amplitude'), findsOneWidget);
        expect(find.textContaining('Audio reactive:'), findsNothing);
      },
    );

    testWidgets('pcm mode shows enhanced audio capture hint', (tester) async {
      await tester.pumpWidget(_buildSection('off', beatDetectorMode: 'pcm'));
      expect(find.text('Enhanced'), findsOneWidget);
      expect(
        find.textContaining('Android system audio capture for cleaner onset'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Enhanced Audio Capture uses Android system audio'),
        findsOneWidget,
      );
    });

    testWidgets(
      'auto mode explains that it stays hybrid unless capture is already active',
      (tester) async {
        await tester.pumpWidget(_buildSection('off', beatDetectorMode: 'auto'));
        expect(
          find.textContaining('Auto stays on Hybrid by default'),
          findsOneWidget,
        );
        expect(
          find.textContaining('Auto will not start Android capture by itself'),
          findsOneWidget,
        );
      },
    );

    testWidgets('bass mode shows bass-specific detector description', (
      tester,
    ) async {
      await tester.pumpWidget(_buildSection('off', beatDetectorMode: 'bass'));
      expect(
        find.textContaining('Bass listens for kick and low-end thump'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'This stays reactive only and does not BPM-lock the screensaver.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'selecting enhanced requests audio capture immediately when reactivity is on',
      (tester) async {
        var requestCaptureCount = 0;
        var stopCaptureCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(stereoChannel, (call) async {
              switch (call.method) {
                case 'requestCapture':
                  requestCaptureCount++;
                  return true;
                case 'stopCapture':
                  stopCaptureCount++;
                  return true;
              }
              return null;
            });

        await tester.pumpWidget(_buildSection('off', beatDetectorMode: 'auto'));
        await tester.ensureVisible(find.text('Enhanced'));
        await tester.tap(find.text('Enhanced'));
        await tester.pump();

        expect(requestCaptureCount, 1);
        expect(stopCaptureCount, 0);
      },
    );

    testWidgets(
      'enabling audio reactivity requests audio capture when enhanced is already selected',
      (tester) async {
        var requestCaptureCount = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(stereoChannel, (call) async {
              if (call.method == 'requestCapture') {
                requestCaptureCount++;
                return true;
              }
              if (call.method == 'stopCapture') {
                return true;
              }
              return null;
            });

        await tester.pumpWidget(
          _buildSection(
            'off',
            beatDetectorMode: 'pcm',
            enableAudioReactivity: false,
          ),
        );

        final toggle = find.ancestor(
          of: find.text('Enable Audio Reactivity'),
          matching: find.byType(TvFocusWrapper),
        );
        await tester.ensureVisible(toggle);
        await tester.tap(toggle);
        await tester.pump();

        expect(requestCaptureCount, 1);
      },
    );

    testWidgets('leaving enhanced stops audio capture session', (tester) async {
      var stopCaptureCount = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(stereoChannel, (call) async {
            if (call.method == 'requestCapture') {
              return true;
            }
            if (call.method == 'stopCapture') {
              stopCaptureCount++;
              return true;
            }
            return null;
          });

      await tester.pumpWidget(_buildSection('off', beatDetectorMode: 'pcm'));
      await tester.ensureVisible(find.text('Auto'));
      await tester.tap(find.text('Auto'));
      await tester.pump();

      expect(stopCaptureCount, 1);
    });

    testWidgets('start button prefers shared launch delegate', (tester) async {
      var launchCount = 0;
      await tester.pumpWidget(
        _buildSection(
          'off',
          launchDelegate: ScreensaverLaunchDelegate(({
            bool allowPermissionPrompts = true,
          }) async {
            launchCount++;
          }),
        ),
      );

      final startTile = find.ancestor(
        of: find.text('Start Screen Saver'),
        matching: find.byType(TvFocusWrapper),
      );
      await tester.ensureVisible(startTile);
      await tester.tap(startTile);
      await tester.pump();

      expect(launchCount, 1);
    });
  });
}
