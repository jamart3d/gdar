import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/settings/tv_screensaver_section.dart';
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
  _FakeSettings(this._graphMode, {this.beatDetectorMode = 'auto'}) {
    isTv = true;
  }

  final String _graphMode;
  final String beatDetectorMode;

  @override
  String get oilAudioGraphMode => _graphMode;

  @override
  String get oilBeatDetectorMode => beatDetectorMode;
}

Widget _buildSection(String graphMode, {String beatDetectorMode = 'auto'}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SettingsProvider>.value(
        value: _FakeSettings(graphMode, beatDetectorMode: beatDetectorMode),
      ),
      ChangeNotifierProvider<ThemeProvider>.value(value: _FakeThemeProvider()),
      ChangeNotifierProvider<DeviceService>.value(value: _FakeDeviceService()),
      ChangeNotifierProvider<AudioProvider>.value(value: _FakeAudioProvider()),
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
  });
}
