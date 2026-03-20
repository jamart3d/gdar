import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/utils.dart';

// ─── Fakes ───────────────────────────────────────────────────────────────────

class _FakeDeviceService extends ChangeNotifier implements DeviceService {
  _FakeDeviceService({required this.isTv});

  @override
  final bool isTv;
  @override
  bool get isMobile => !isTv;
  @override
  bool get isDesktop => false;
  @override
  bool get isSafari => false;
  @override
  bool get isPwa => false;
  @override
  String? get deviceName => 'Test';
  @override
  Future<void> refresh() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAudioProvider extends ChangeNotifier implements AudioProvider {
  final List<String> notifications = [];

  final _notificationStreamController = StreamController<String>.broadcast();

  @override
  void showNotification(String message) {
    notifications.add(message);
    _notificationStreamController.add(message);
  }

  @override
  Stream<String> get notificationStream => _notificationStreamController.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  @override
  bool get uiScale => false;
  @override
  String get appFont => 'default';
  @override
  bool get showPlaybackMessages => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeThemeProvider extends ChangeNotifier implements ThemeProvider {
  @override
  ThemeStyle get themeStyle => ThemeStyle.android;
  @override
  bool get isDarkMode => false;
  @override
  bool get isFruitAllowed => false;
  @override
  Future<void> get initializationComplete => Future.value();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ─── Helper ──────────────────────────────────────────────────────────────────

Widget _buildTestApp({
  required bool isTv,
  required _FakeAudioProvider audio,
  required VoidCallback onTrigger,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<DeviceService>.value(
        value: _FakeDeviceService(isTv: isTv),
      ),
      ChangeNotifierProvider<AudioProvider>.value(value: audio),
      ChangeNotifierProvider<SettingsProvider>.value(
        value: _FakeSettingsProvider(),
      ),
      ChangeNotifierProvider<ThemeProvider>.value(value: _FakeThemeProvider()),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onTrigger(),
            child: const Text('trigger'),
          ),
        ),
      ),
    ),
  );
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  group('showMessage routing contract', () {
    testWidgets('TV: routes to AudioProvider.showNotification', (tester) async {
      final audio = _FakeAudioProvider();
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DeviceService>.value(
              value: _FakeDeviceService(isTv: true),
            ),
            ChangeNotifierProvider<AudioProvider>.value(value: audio),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: _FakeSettingsProvider(),
            ),
            ChangeNotifierProvider<ThemeProvider>.value(
              value: _FakeThemeProvider(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  capturedContext = ctx;
                  return TextButton(
                    onPressed: () => showMessage(capturedContext, 'hello TV'),
                    child: const Text('tap'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap'));
      await tester.pump();

      expect(audio.notifications, contains('hello TV'));
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('phone: shows SnackBar, does NOT call showNotification', (
      tester,
    ) async {
      final audio = _FakeAudioProvider();
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DeviceService>.value(
              value: _FakeDeviceService(isTv: false),
            ),
            ChangeNotifierProvider<AudioProvider>.value(value: audio),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: _FakeSettingsProvider(),
            ),
            ChangeNotifierProvider<ThemeProvider>.value(
              value: _FakeThemeProvider(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  capturedContext = ctx;
                  return TextButton(
                    onPressed: () =>
                        showMessage(capturedContext, 'hello phone'),
                    child: const Text('tap'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap'));
      await tester.pump();

      expect(audio.notifications, isEmpty);
      expect(find.byType(SnackBar), findsOneWidget);
    });

    testWidgets('TV error variant: routes to showNotification', (tester) async {
      final audio = _FakeAudioProvider();
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<DeviceService>.value(
              value: _FakeDeviceService(isTv: true),
            ),
            ChangeNotifierProvider<AudioProvider>.value(value: audio),
            ChangeNotifierProvider<SettingsProvider>.value(
              value: _FakeSettingsProvider(),
            ),
            ChangeNotifierProvider<ThemeProvider>.value(
              value: _FakeThemeProvider(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) {
                  capturedContext = ctx;
                  return TextButton(
                    onPressed: () =>
                        showRestartMessage(capturedContext, 'restart needed'),
                    child: const Text('tap'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('tap'));
      await tester.pump();

      expect(audio.notifications, contains('restart needed'));
    });
  });
}
