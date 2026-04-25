import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/app/gdar_app_provider_overrides.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/update_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';
import 'package:shakedown_core/services/wakelock_service.dart';

List<SingleChildWidget> buildGdarAppProviders({
  required SharedPreferences prefs,
  required bool isTv,
  required GdarAppProviderOverrides overrides,
}) {
  final settingsProvider =
      overrides.settingsProvider ?? SettingsProvider(prefs, isTv: isTv);
  final showListProvider = overrides.showListProvider ?? ShowListProvider();

  return <SingleChildWidget>[
    ChangeNotifierProvider(create: (_) => ThemeProvider(isTv: isTv)),
    Provider<CatalogService>(create: (_) => CatalogService()),
    Provider<WakelockService>(create: (_) => WakelockService()),
    ChangeNotifierProvider<SettingsProvider>.value(value: settingsProvider),
    ChangeNotifierProvider<AudioCacheService>(
      create: (_) => overrides.audioCacheService ?? (AudioCacheService()..init()),
    ),
    ChangeNotifierProxyProvider<SettingsProvider, ShowListProvider>(
      create: (_) => showListProvider,
      update: (_, settings, current) => current!..update(settings),
    ),
    ChangeNotifierProxyProvider3<
      ShowListProvider,
      SettingsProvider,
      AudioCacheService,
      AudioProvider
    >(
      create: (_) => overrides.audioProvider ?? AudioProvider(),
      update: (_, shows, settings, cache, current) {
        return current!..update(shows, settings, cache);
      },
    ),
    ChangeNotifierProvider(create: (_) => UpdateProvider()),
    ChangeNotifierProvider<DeviceService>(
      create: (_) => overrides.deviceService ?? DeviceService(initialIsTv: isTv),
    ),
    if (overrides.screensaverLaunchDelegate != null)
      Provider<ScreensaverLaunchDelegate>.value(
        value: overrides.screensaverLaunchDelegate!,
      ),
  ];
}
