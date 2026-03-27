import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/providers/update_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/wakelock_service.dart';
import 'package:shakedown_core/services/deep_link_service.dart';
import 'package:shakedown_core/services/inactivity_service.dart';
import 'package:shakedown_core/ui/screens/screensaver_screen.dart';
import 'package:shakedown_core/ui/screens/splash_screen.dart';
import 'package:shakedown_core/ui/widgets/rgb_clock_wrapper.dart';
import 'package:shakedown_core/utils/app_themes.dart';
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

class _GdarTvAppState extends State<GdarTvApp> {
  late final ShowListProvider _showListProvider;
  late final SettingsProvider _settingsProvider;
  late final InactivityService _inactivityService;
  DeepLinkService? _deepLinkService;
  StreamSubscription? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final _TvNavigationObserver _navigationObserver;
  bool _isScreensaverActive = false;
  final ValueNotifier<String?> _launchError = ValueNotifier(null);

  void _setScreensaverActive(bool active) {
    if (!mounted) {
      _isScreensaverActive = active;
      return;
    }
    setState(() {
      _isScreensaverActive = active;
    });
  }

  void _handleRouteChanged(Route<dynamic>? route) {
    // Route tracking kept for diagnostics only — no longer gates the timer.
    final name = route?.settings.name;
    if (name != null) {
      debugPrint('GdarTvApp: route changed name=$name');
    }
  }

  Future<void> _showScreensaver(
    NavigatorState navigator, {
    bool allowPermissionPrompts = true,
  }) async {
    _setScreensaverActive(true);
    try {
      await navigator.push(
        ScreensaverScreen.route(allowPermissionPrompts: allowPermissionPrompts),
      );
    } finally {
      _setScreensaverActive(false);
      _inactivityService.onUserActivity();
    }
  }

  @override
  void initState() {
    super.initState();
    _settingsProvider =
        widget.settingsProvider ??
        SettingsProvider(widget.prefs, isTv: widget.isTv);
    _showListProvider = widget.showListProvider ?? ShowListProvider();
    _inactivityService = InactivityService(
      onInactivityTimeout: _handleInactivityTimeout,
      initialDuration: Duration(
        minutes: _settingsProvider.oilScreensaverInactivityMinutes,
      ),
    );
    _navigationObserver = _TvNavigationObserver(_handleRouteChanged);

    ThemeProvider.getInstance?.setSettingsProvider(_settingsProvider);

    if (widget.showListProvider == null) {
      _showListProvider.init(widget.prefs);
    }
    if (widget.enableDeepLinks) {
      _initDeepLinks();
    }
  }

  @override
  void dispose() {
    _inactivityService.dispose();
    _launchError.dispose();
    _linkSubscription?.cancel();
    _deepLinkService?.dispose();
    super.dispose();
  }

  Future<void> _handleInactivityTimeout() async {
    if (!mounted) {
      _launchError.value = 'widget not mounted';
      return;
    }

    // Guard: don't double-launch if screensaver is already active.
    if (_isScreensaverActive) {
      _launchError.value = 'already active';
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      _launchError.value = 'navigator null';
      return;
    }

    logger.i('TV inactivity timeout — launching screensaver');
    _inactivityService.stop();
    _setScreensaverActive(true);
    _launchError.value = null;
    try {
      await navigator.push(
        ScreensaverScreen.route(allowPermissionPrompts: false),
      );
    } on Exception catch (e) {
      _launchError.value = e.toString().replaceFirst('Exception: ', '');
      logger.e('Screensaver launch failed', error: e);
    } catch (e) {
      _launchError.value = e.runtimeType.toString();
      logger.e('Screensaver launch failed', error: e);
    } finally {
      _setScreensaverActive(false);
      // Restart monitoring after screensaver exits.
      if (_settingsProvider.useOilScreensaver) {
        _inactivityService.start();
      }
    }
  }

  void _syncInactivityService(SettingsProvider settingsProvider) {
    _inactivityService.updateDuration(
      Duration(minutes: settingsProvider.oilScreensaverInactivityMinutes),
    );

    // Match v1.1.69: run whenever enabled and screensaver isn't active.
    // No route-eligibility gate — the timeout handler checks what it needs.
    if (settingsProvider.useOilScreensaver && !_isScreensaverActive) {
      _inactivityService.start();
    } else {
      _inactivityService.stop();
    }
  }

  void _initDeepLinks() {
    _deepLinkService = widget.deepLinkService ?? DeepLinkService();
    _deepLinkService!.init();

    _linkSubscription = _deepLinkService!.uriStream.listen((Uri? uri) {
      if (uri == null) return;

      if (uri.scheme == 'shakedown') {
        if (uri.path == 'automate') {
          final steps = uri.queryParameters['steps']?.split(',') ?? [];
          _handleAutomation(steps);
        } else if (uri.host == 'automate') {
          // Handle shakedown://automate?steps=...
          final steps = uri.queryParameters['steps']?.split(',') ?? [];
          _handleAutomation(steps);
        }
      }
    });
  }

  Future<void> _handleAutomation(List<String> steps) async {
    final context = _navigatorKey.currentState?.context;
    if (context == null) {
      // Wait a bit and try again if the navigator isn't ready
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleAutomation(steps);
      });
      return;
    }

    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    for (final step in steps) {
      final trimmedStep = step.trim();
      if (trimmedStep == 'dice') {
        await audioProvider.playRandomShow();
      } else if (trimmedStep.startsWith('sleep:')) {
        final seconds = int.tryParse(trimmedStep.split(':')[1]) ?? 0;
        await Future.delayed(Duration(seconds: seconds));
      } else if (trimmedStep.startsWith('settings:')) {
        final parts = trimmedStep.split(':');
        if (parts.length < 2) continue;
        final keyValue = parts[1].split('=');
        if (keyValue.length < 2) continue;
        final key = keyValue[0];
        final value = keyValue[1];

        if (key == 'oil_enable_audio_reactivity') {
          final target = value == 'true';
          if (settingsProvider.oilEnableAudioReactivity != target) {
            await settingsProvider.toggleOilEnableAudioReactivity();
          }
        } else if (key == 'oil_audio_graph_mode') {
          await settingsProvider.setOilAudioGraphMode(value);
        } else if (key == 'force_tv') {
          await settingsProvider.setForceTv(value == 'true');
        } else if (key == 'oil_screensaver_mode') {
          await settingsProvider.setOilScreensaverMode(value);
        }
      } else if (trimmedStep == 'screensaver') {
        final navigator = _navigatorKey.currentState;
        if (navigator != null) {
          await _showScreensaver(navigator);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(isTv: widget.isTv)),
        Provider<CatalogService>(create: (_) => CatalogService()),
        Provider<WakelockService>(create: (_) => WakelockService()),
        ChangeNotifierProvider.value(value: _settingsProvider),
        ChangeNotifierProvider(
          create: (_) =>
              widget.audioCacheService ?? (AudioCacheService()..init()),
        ),
        ChangeNotifierProxyProvider<SettingsProvider, ShowListProvider>(
          create: (_) => _showListProvider,
          update: (_, settingsProvider, showListProvider) =>
              showListProvider!..update(settingsProvider),
        ),
        ChangeNotifierProxyProvider3<
          ShowListProvider,
          SettingsProvider,
          AudioCacheService,
          AudioProvider
        >(
          create: (_) => widget.audioProvider ?? AudioProvider(),
          update:
              (
                _,
                showListProvider,
                settingsProvider,
                audioCacheService,
                audioProvider,
              ) => audioProvider!
                ..update(showListProvider, settingsProvider, audioCacheService),
        ),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
        ChangeNotifierProvider(
          create: (_) =>
              widget.deviceService ??
              DeviceService(initialIsTv: widget.isTv, lockIsTv: widget.isTv),
        ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          _syncInactivityService(settingsProvider);
          final theme = AppThemes.darkTheme(
            settingsProvider.activeAppFont,
            useMaterial3: settingsProvider.useMaterial3,
            uiScale: settingsProvider.uiScale,
            style: ThemeStyle.android,
          );

          final finalTheme = settingsProvider.useTrueBlack
              ? AppThemes.applyTrueBlack(theme)
              : theme;

          return RgbClockWrapper(
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              navigatorObservers: [_navigationObserver],
              title: 'GDAR TV',
              debugShowCheckedModeBanner: false,
              theme: finalTheme,
              themeMode: ThemeMode.dark,
              builder: (context, child) => InactivityDetector(
                inactivityService: _inactivityService,
                isScreensaverActive: _isScreensaverActive,
                child: Stack(
                  children: [
                    ColoredBox(
                      color: finalTheme.scaffoldBackgroundColor,
                      child: child ?? const SizedBox.shrink(),
                    ),
                    // DIAGNOSIS: Force overlay visibility and center it to rule out overscan.
                    // Also removed the !_isScreensaverActive gate to see if it's "stuck" active.
                    if (settingsProvider.useOilScreensaver)
                      Center(
                        child: _InactivityCountdownOverlay(
                          countdown: _inactivityService.debugCountdown,
                          launchError: _launchError,
                        ),
                      ),
                  ],
                ),
              ),
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

/// Small semi-transparent countdown overlay in the top-left corner.
/// Shows the inactivity timer state so you can confirm it's alive on hardware
/// without needing logcat. Turns red with a specific message if launch fails.
class _InactivityCountdownOverlay extends StatelessWidget {
  const _InactivityCountdownOverlay({
    required this.countdown,
    required this.launchError,
  });

  final ValueNotifier<String> countdown;
  final ValueNotifier<String?> launchError;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ValueListenableBuilder<String?>(
        valueListenable: launchError,
        builder: (context, error, _) {
          if (error != null) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xCC990000),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'SS ERR: $error',
                style: const TextStyle(
                  color: Color(0xFFFFAAAA),
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
              ),
            );
          }
          return ValueListenableBuilder<String>(
            valueListenable: countdown,
            builder: (context, value, _) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xCCFF0000), // Bright red
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  'SS: $value (TV: ${ThemeProvider.getInstance?.isTv})',
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
