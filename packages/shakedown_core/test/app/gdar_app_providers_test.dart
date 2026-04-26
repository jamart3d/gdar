import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/app/gdar_app_provider_overrides.dart';
import 'package:shakedown_core/app/gdar_app_providers.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('buildGdarAppProviders wires shared dependencies', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final prefs = await SharedPreferences.getInstance();
    final settingsProvider = SettingsProvider(prefs, isTv: true);
    final showListProvider = ShowListProvider();
    final audioCacheService = AudioCacheService();
    final deviceService = DeviceService(initialIsTv: true, lockIsTv: true);
    const screensaverDelegate = ScreensaverLaunchDelegate(_noopLaunch);

    await tester.pumpWidget(
      MultiProvider(
        providers: buildGdarAppProviders(
          prefs: prefs,
          isTv: true,
          overrides: GdarAppProviderOverrides(
            settingsProvider: settingsProvider,
            showListProvider: showListProvider,
            audioCacheService: audioCacheService,
            deviceService: deviceService,
            screensaverLaunchDelegate: screensaverDelegate,
          ),
        ),
        child: Builder(
          builder: (context) {
            expect(context.read<SettingsProvider>(), same(settingsProvider));
            expect(context.read<ShowListProvider>(), same(showListProvider));
            expect(context.read<AudioCacheService>(), same(audioCacheService));
            expect(context.read<DeviceService>(), same(deviceService));
            expect(
              context.read<ScreensaverLaunchDelegate>(),
              screensaverDelegate,
            );
            expect(context.read<ThemeProvider>().isTv, isTrue);
            expect(context.read<AudioProvider>(), isNotNull);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}

Future<void> _noopLaunch({bool allowPermissionPrompts = true}) async {}
