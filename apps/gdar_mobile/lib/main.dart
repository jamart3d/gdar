import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar_android/android_theme.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/app/gdar_app_provider_overrides.dart';
import 'package:shakedown_core/app/gdar_app_providers.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/deep_link_service.dart';
import 'package:shakedown_core/services/inactivity_service.dart';
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';
import 'package:shakedown_core/ui/screens/splash_screen.dart';
import 'package:shakedown_core/app/gdar_app_lifecycle_mixin.dart';
import 'package:shakedown_core/ui/navigation/app_route_observer.dart';
import 'package:shakedown_core/ui/widgets/rgb_clock_wrapper.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/utils/asset_constants.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      initLogger();

      final prefs = await SharedPreferences.getInstance();

      bool isTv = false;
      try {
        if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
          const deviceChannel = MethodChannel('com.jamart3d.shakedown/device');
          final bool? result = await deviceChannel.invokeMethod<bool>('isTv');
          isTv = result ?? false;
        }
      } catch (e) {
        debugPrint('Error detecting TV in main: $e');
      }

      if (prefs.getBool('force_tv') == true ||
          const bool.fromEnvironment('FORCE_TV', defaultValue: false)) {
        isTv = true;
      }

      if (!kIsWeb) {
        if (!isTv) {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        } else {
          await SystemChrome.setPreferredOrientations([
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }

        await JustAudioBackground.init(
          androidNotificationChannelId: 'com.jamart3d.shakedown.channel.audio',
          androidNotificationChannelName: 'Audio Playback',
          androidNotificationOngoing: true,
          androidNotificationIcon:
              AssetConstants.defaultAndroidNotificationIcon,
        );
      }

      runApp(GdarMobileApp(prefs: prefs, isTv: isTv));
    },
    (error, stack) {
      debugPrint('Fatal error: $error\n$stack');
    },
  );
}

class GdarMobileApp extends StatefulWidget {
  final SharedPreferences prefs;
  final bool isTv;
  final ShowListProvider? showListProvider;
  final AudioProvider? audioProvider;
  final AudioCacheService? audioCacheService;
  final SettingsProvider? settingsProvider;
  final DeviceService? deviceService;
  final DeepLinkService? deepLinkService;
  final bool enableDeepLinks;

  const GdarMobileApp({
    super.key,
    required this.prefs,
    required this.isTv,
    this.showListProvider,
    this.audioProvider,
    this.audioCacheService,
    this.settingsProvider,
    this.deviceService,
    this.deepLinkService,
    this.enableDeepLinks = true,
  });

  @override
  State<GdarMobileApp> createState() => _GdarMobileAppState();
}

class _GdarMobileAppState extends State<GdarMobileApp>
    with GdarAppLifecycleMixin<GdarMobileApp> {
  late final ShowListProvider _showListProvider;
  late final SettingsProvider _settingsProvider;

  @override
  bool get isTv => widget.isTv;

  @override
  SettingsProvider get settingsProvider => _settingsProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider =
        widget.settingsProvider ??
        SettingsProvider(widget.prefs, isTv: widget.isTv);
    _showListProvider = widget.showListProvider ?? ShowListProvider();

    ThemeProvider.getInstance?.setSettingsProvider(_settingsProvider);

    if (widget.showListProvider == null) {
      _showListProvider.init(widget.prefs);
    }

    initLifecycle(enableDeepLinks: widget.enableDeepLinks);
  }

  @override
  void dispose() {
    disposeLifecycle();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: buildGdarAppProviders(
        prefs: widget.prefs,
        isTv: widget.isTv,
        overrides: GdarAppProviderOverrides(
          settingsProvider: _settingsProvider,
          showListProvider: _showListProvider,
          audioProvider: widget.audioProvider,
          audioCacheService: widget.audioCacheService,
          deviceService: widget.deviceService,
          screensaverLaunchDelegate: widget.isTv
              ? ScreensaverLaunchDelegate(({
                  bool allowPermissionPrompts = true,
                }) {
                  return launchScreensaver(
                    allowPermissionPrompts: allowPermissionPrompts,
                    source: 'manual',
                  );
                })
              : null,
        ),
      ),
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          syncInactivityService(settingsProvider);
          return RgbClockWrapper(
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: MaterialApp(
              navigatorKey: navigatorKey,
              navigatorObservers: [shakedownRouteObserver],
              title: 'GDAR',
              debugShowCheckedModeBanner: false,
              theme: GDARAndroidTheme.light(
                appFont: settingsProvider.activeAppFont,
                uiScale: settingsProvider.uiScale,
              ),
              darkTheme: GDARAndroidTheme.dark(
                appFont: settingsProvider.activeAppFont,
                uiScale: settingsProvider.uiScale,
                useTrueBlack: settingsProvider.useTrueBlack && widget.isTv,
              ),
              themeMode: themeProvider.currentThemeMode,
              builder: (context, child) {
                if (!widget.isTv || inactivityService == null) {
                  return child ?? const SizedBox.shrink();
                }

                return InactivityDetector(
                  inactivityService: inactivityService,
                  isScreensaverActive: isScreensaverActive,
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: child ?? const SizedBox.shrink(),
                  ),
                );
              },
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
