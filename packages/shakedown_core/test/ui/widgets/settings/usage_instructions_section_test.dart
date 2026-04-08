import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/settings/usage_instructions_section.dart';

import '../../../helpers/test_helpers.dart';

class _FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  @override
  bool get isPlaying => false;

  @override
  Source? get currentSource => null;

  @override
  Show? get currentShow => null;

  @override
  int get cachedTrackCount => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the navigation undo help text', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
          ChangeNotifierProvider<DeviceService>(
            create: (_) => MockDeviceService(),
          ),
          ChangeNotifierProvider<SettingsProvider>.value(
            value: settingsProvider,
          ),
          ChangeNotifierProvider<AudioProvider>(
            create: (_) => _FakeAudioProvider(),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: UsageInstructionsSection(
                scaleFactor: 1.0,
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(
      find.textContaining('Press Previous within the first 5 seconds to undo'),
      findsOneWidget,
    );
    expect(
      find.textContaining(
        'This undo is temporary and expires after 10 seconds',
      ),
      findsOneWidget,
    );
  });
}
