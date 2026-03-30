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
import 'package:shakedown_core/services/screensaver_launch_delegate.dart';
import 'package:shakedown_core/ui/screens/splash_screen.dart';
import 'package:shakedown_core/ui/screens/screensaver_screen.dart';
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

class _GdarMobileAppState extends State<GdarMobileApp> {
  late final ShowListProvider _showListProvider;
  late final SettingsProvider _settingsProvider;
  InactivityService? _inactivityService;
  DeepLinkService? _deepLinkService;
  StreamSubscription? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  bool _isScreensaverActive = false;

  void _setScreensaverActive(bool active) {
    if (!mounted) {
      _isScreensaverActive = active;
      return;
    }
    setState(() {
      _isScreensaverActive = active;
    });
  }

  @override
  void initState() {
    super.initState();
    _settingsProvider =
        widget.settingsProvider ??
        SettingsProvider(widget.prefs, isTv: widget.isTv);
    _showListProvider = widget.showListProvider ?? ShowListProvider();
    if (widget.isTv) {
      _inactivityService = InactivityService(
        onInactivityTimeout: _handleInactivityTimeout,
        initialDuration: Duration(
          minutes: _settingsProvider.oilScreensaverInactivityMinutes,
        ),
      );
    }

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
    _inactivityService?.dispose();
    _linkSubscription?.cancel();
    _deepLinkService?.dispose();
    super.dispose();
  }

  Future<void> _launchScreensaver({
    required bool allowPermissionPrompts,
    required String source,
  }) async {
    final navigator = _navigatorKey.currentState;
    if (navigator == null) {
      return;
    }

    logger.i('Launching screensaver from mobile/$source');
    _inactivityService?.stop();
    _setScreensaverActive(true);
    try {
      await navigator.push(
        ScreensaverScreen.route(allowPermissionPrompts: allowPermissionPrompts),
      );
    } on Exception catch (e) {
      logger.e('Screensaver launch failed', error: e);
    } catch (e) {
      logger.e('Screensaver launch failed', error: e);
    } finally {
      _setScreensaverActive(false);
      _inactivityService?.onUserActivity('screensaver_exit:mobile_$source');
      if (widget.isTv && _settingsProvider.useOilScreensaver) {
        _inactivityService?.start();
      }
    }
  }

  Future<void> _handleInactivityTimeout() {
    return _launchScreensaver(allowPermissionPrompts: false, source: 'timeout');
  }

  void _syncInactivityService(SettingsProvider settingsProvider) {
    final inactivityService = _inactivityService;
    if (!widget.isTv || inactivityService == null) {
      return;
    }

    inactivityService.updateDuration(
      Duration(minutes: settingsProvider.oilScreensaverInactivityMinutes),
    );

    if (settingsProvider.useOilScreensaver && !_isScreensaverActive) {
      inactivityService.start();
    } else {
      inactivityService.stop();
    }
  }

  void _initDeepLinks() {
    _deepLinkService = widget.deepLinkService ?? DeepLinkService();
    _deepLinkService!.init();

    _linkSubscription = _deepLinkService!.uriStream.listen((Uri? uri) async {
      if (uri == null) return;

      if (uri.scheme == 'shakedown') {
        if (uri.path == 'automate' || uri.host == 'automate') {
          final steps = uri.queryParameters['steps']?.split(',') ?? [];
          await _handleAutomation(steps);
        } else if (uri.host == 'settings') {
          final key = uri.queryParameters['key'];
          final value = uri.queryParameters['value'];

          if (key != null && value != null) {
            if (value == 'true' || value == 'false') {
              await widget.prefs.setBool(key, value == 'true');
              if (key == 'force_tv') {
                if (mounted) {
                  // We need to refresh the device service to reflect the change
                  // But we usually do this via a broadcast or provider update
                }
              }
            }
          }
        }
      }
    });
  }

  Future<void> _handleAutomation(List<String> steps) async {
    // Wait for navigator to be ready
    final state = _navigatorKey.currentState;
    if (state == null) {
      Future.delayed(
        const Duration(milliseconds: 500),
        () => _handleAutomation(steps),
      );
      return;
    }

    final context = state.context;
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
        if (widget.isTv) {
          await _launchScreensaver(
            allowPermissionPrompts: true,
            source: 'automation',
          );
        } else if (context.mounted) {
          await ScreensaverScreen.show(context);
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
              widget.deviceService ?? DeviceService(initialIsTv: widget.isTv),
        ),
        if (widget.isTv)
          Provider<ScreensaverLaunchDelegate>.value(
            value: ScreensaverLaunchDelegate(({
              bool allowPermissionPrompts = true,
            }) {
              return _launchScreensaver(
                allowPermissionPrompts: allowPermissionPrompts,
                source: 'manual',
              );
            }),
          ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          _syncInactivityService(settingsProvider);
          return RgbClockWrapper(
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'GDAR',
              debugShowCheckedModeBanner: false,
              theme: settingsProvider.useTrueBlack && widget.isTv
                  ? AppThemes.applyTrueBlack(
                      AppThemes.lightTheme(
                        settingsProvider.activeAppFont,
                        useMaterial3: settingsProvider.useMaterial3,
                        uiScale: settingsProvider.uiScale,
                        style: ThemeStyle.android,
                      ),
                    )
                  : AppThemes.lightTheme(
                      settingsProvider.activeAppFont,
                      useMaterial3: settingsProvider.useMaterial3,
                      uiScale: settingsProvider.uiScale,
                      style: ThemeStyle.android,
                    ),
              darkTheme: settingsProvider.useTrueBlack && widget.isTv
                  ? AppThemes.applyTrueBlack(
                      AppThemes.darkTheme(
                        settingsProvider.activeAppFont,
                        useMaterial3: settingsProvider.useMaterial3,
                        uiScale: settingsProvider.uiScale,
                        style: ThemeStyle.android,
                      ),
                    )
                  : AppThemes.darkTheme(
                      settingsProvider.activeAppFont,
                      useMaterial3: settingsProvider.useMaterial3,
                      uiScale: settingsProvider.uiScale,
                      style: ThemeStyle.android,
                    ),
              themeMode: themeProvider.currentThemeMode,
              builder: (context, child) {
                if (!widget.isTv || _inactivityService == null) {
                  return child ?? const SizedBox.shrink();
                }

                return InactivityDetector(
                  inactivityService: _inactivityService,
                  isScreensaverActive: _isScreensaverActive,
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
