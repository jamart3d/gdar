import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar_android/android_theme.dart';
import 'package:shakedown_core/app/gdar_app_provider_overrides.dart';
import 'package:shakedown_core/app/gdar_app_providers.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/audio_cache_service.dart';
import 'package:shakedown_core/services/automation/automation_executor.dart';
import 'package:shakedown_core/services/automation/automation_step_parser.dart';
import 'package:shakedown_core/services/deep_link_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/services/inactivity_service.dart';
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';
import 'package:shakedown_core/ui/navigation/app_route_observer.dart';
import 'package:shakedown_core/ui/navigation/route_names.dart';
import 'package:shakedown_core/ui/screens/screensaver_screen.dart';
import 'package:shakedown_core/ui/screens/splash_screen.dart';
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

class _GdarTvAppState extends State<GdarTvApp> {
  late final ShowListProvider _showListProvider;
  late final SettingsProvider _settingsProvider;
  late final InactivityService _inactivityService;
  DeepLinkService? _deepLinkService;
  StreamSubscription? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final _TvNavigationObserver _navigationObserver;
  bool _isScreensaverActive = false;
  String? _currentRouteName;

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
    final name = route?.settings.name;
    // Preserve the last known name so anonymous routes (popups, dialogs)
    // don't accidentally clear the current screen context.
    if (name != null && name != _currentRouteName) {
      debugPrint('GdarTvApp: route changed name=$name');
      _currentRouteName = name;
      // Defer setState — NavigatorObserver callbacks fire during the navigation
      // frame and calling setState directly here triggers a framework assertion.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
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
    _linkSubscription?.cancel();
    _deepLinkService?.dispose();
    super.dispose();
  }

  Future<void> _launchScreensaver({
    required bool allowPermissionPrompts,
    required String source,
  }) async {
    if (!mounted) {
      return;
    }

    // Guard: don't double-launch if screensaver is already active.
    if (_isScreensaverActive) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    final settings = _settingsProvider;
    final enhancedEligible =
        settings.oilEnableAudioReactivity &&
        settings.oilBeatDetectorMode == 'pcm';
    logger.i(
      'Launching screensaver from $source '
      '(allowPermissionPrompts=$allowPermissionPrompts, '
      'audioReactivity=${settings.oilEnableAudioReactivity}, '
      'beatDetectorMode=${settings.oilBeatDetectorMode}, '
      'audioGraphMode=${settings.oilAudioGraphMode}, '
      'enhancedEligible=$enhancedEligible, '
      'useOilScreensaver=${settings.useOilScreensaver})',
    );
    _inactivityService.stop();
    _setScreensaverActive(true);
    try {
      // Yield to the event loop before pushing so we don't hit the navigator
      // lock assertion when the inactivity timer fires during a route animation.
      await Future.delayed(Duration.zero);
      if (!mounted || !_isScreensaverActive) return;
      await navigator.push(
        ScreensaverScreen.route(allowPermissionPrompts: allowPermissionPrompts),
      );
    } on Exception catch (e) {
      logger.e('Screensaver launch failed', error: e);
    } catch (e) {
      logger.e('Screensaver launch failed', error: e);
    } finally {
      _setScreensaverActive(false);
      // Restart monitoring after screensaver exits.
      if (_settingsProvider.useOilScreensaver) {
        _inactivityService.start();
      }
    }
  }

  Future<void> _handleInactivityTimeout() {
    return _launchScreensaver(allowPermissionPrompts: false, source: 'timeout');
  }

  void _syncInactivityService(SettingsProvider settingsProvider) {
    _inactivityService.updateDuration(
      Duration(minutes: settingsProvider.oilScreensaverInactivityMinutes),
    );

    final isOnBlockedRoute =
        _currentRouteName == ShakedownRouteNames.tvSettings;

    if (settingsProvider.useOilScreensaver &&
        !_isScreensaverActive &&
        !isOnBlockedRoute) {
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

  Future<void> _handleAutomation(List<String> rawSteps) async {
    final context = _navigatorKey.currentState?.context;
    if (context == null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleAutomation(rawSteps);
      });
      return;
    }

    final audioProvider = Provider.of<AudioProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(
      context,
      listen: false,
    );

    final executor = AutomationExecutor(
      playRandomShow: audioProvider.playRandomShow,
      delay: (duration) => Future.delayed(duration),
      applySetting: (key, value) async {
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
      },
      launchScreensaver: () => _launchScreensaver(
        allowPermissionPrompts: true,
        source: 'automation',
      ),
    );

    final steps = parseAutomationSteps(rawSteps);
    await executor.execute(steps);
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
            return _launchScreensaver(
              allowPermissionPrompts: allowPermissionPrompts,
              source: 'manual',
            );
          }),
        ),
      ),
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          _syncInactivityService(settingsProvider);
          final theme = GDARAndroidTheme.dark(
            appFont: settingsProvider.activeAppFont,
            uiScale: settingsProvider.uiScale,
            // TV root surfaces are always OLED black by product spec.
            useTrueBlack: true,
          );

          return RgbClockWrapper(
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              navigatorObservers: [_navigationObserver, shakedownRouteObserver],
              title: 'GDAR TV',
              debugShowCheckedModeBanner: false,
              theme: theme,
              themeMode: ThemeMode.dark,
              builder: (context, child) => InactivityDetector(
                inactivityService: _inactivityService,
                isScreensaverActive: _isScreensaverActive,
                child: ColoredBox(
                  color: theme.scaffoldBackgroundColor,
                  child: child ?? const SizedBox.shrink(),
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
