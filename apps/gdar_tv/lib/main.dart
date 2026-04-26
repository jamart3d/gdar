import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar_android/android_theme.dart';
import 'package:shakedown_core/shakedown_core.dart';
import 'package:shakedown_core/app/gdar_app_provider_overrides.dart';
import 'package:shakedown_core/app/gdar_app_providers.dart';
import 'package:shakedown_core/services/inactivity_service.dart';
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';
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

      const bool isTv = true;

      if (!kIsWeb) {
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);

        await JustAudioBackground.init(
          androidNotificationChannelId: 'com.jamart3d.shakedown.channel.audio',
          androidNotificationChannelName: 'Audio Playback',
          androidNotificationOngoing: true,
          androidNotificationIcon:
              AssetConstants.defaultAndroidNotificationIcon,
        );
      }

      runApp(GdarTvApp(prefs: prefs, isTv: isTv));
    },
    (error, stack) {
      debugPrint('Fatal error: $error\n$stack');
    },
  );
}

class GdarTvApp extends StatefulWidget {
  final SharedPreferences prefs;
  final bool isTv;
  final ShowListProvider? showListProvider;
  final AudioProvider? audioProvider;
  final AudioCacheService? audioCacheService;
  final SettingsProvider? settingsProvider;
  final DeviceService? deviceService;
  final DeepLinkService? deepLinkService;
  final bool enableDeepLinks;

  const GdarTvApp({
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
  State<GdarTvApp> createState() => _GdarTvAppState();
}

class _GdarTvAppState extends State<GdarTvApp>
    with GdarAppLifecycleMixin<GdarTvApp> {
  late final ShowListProvider _showListProvider;
  late final SettingsProvider _settingsProvider;

  @override
  bool get isTv => widget.isTv;

  @override
  SettingsProvider get settingsProvider => _settingsProvider;

  late final _TvNavigationObserver _navigationObserver;

  @override
  void initState() {
    super.initState();
    _settingsProvider =
        widget.settingsProvider ??
        SettingsProvider(widget.prefs, isTv: widget.isTv);
    _showListProvider = widget.showListProvider ?? ShowListProvider();
    if (widget.showListProvider == null) {
      _showListProvider.init(widget.prefs);
    }

    _navigationObserver = _TvNavigationObserver(handleRouteChanged);

    ThemeProvider.getInstance?.setSettingsProvider(_settingsProvider);

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
          screensaverLaunchDelegate: ScreensaverLaunchDelegate(({
            bool allowPermissionPrompts = true,
          }) {
            return launchScreensaver(
              allowPermissionPrompts: allowPermissionPrompts,
              source: 'manual',
            );
          }),
        ),
      ),
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          syncInactivityService(settingsProvider);
          final theme = GDARAndroidTheme.dark(
            appFont: settingsProvider.activeAppFont,
            uiScale: settingsProvider.uiScale,
            // TV root surfaces are always OLED black by product spec.
            useTrueBlack: true,
          );

          return RgbClockWrapper(
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: MaterialApp(
              navigatorKey: navigatorKey,
              navigatorObservers: [_navigationObserver, shakedownRouteObserver],
              title: 'GDAR TV',
              debugShowCheckedModeBanner: false,
              theme: theme,
              themeMode: ThemeMode.dark,
              builder: (context, child) {
                return InactivityDetector(
                  inactivityService: inactivityService,
                  isScreensaverActive: isScreensaverActive,
                  child: ColoredBox(
                    color: theme.scaffoldBackgroundColor,
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

class _TvNavigationObserver extends NavigatorObserver {
  _TvNavigationObserver(this.onRouteChanged);

  final ValueChanged<Route<dynamic>?> onRouteChanged;

  void _notify(Route<dynamic>? route) => onRouteChanged(route);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _notify(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _notify(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _notify(newRoute ?? oldRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _notify(previousRoute);
  }
}
