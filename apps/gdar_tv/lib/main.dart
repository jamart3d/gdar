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
  bool _isScreensaverActive = false;

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

  Future<void> _handleInactivityTimeout() async {
    if (!mounted ||
        _isScreensaverActive ||
        !_settingsProvider.useOilScreensaver) {
      return;
    }

    final navigator = _navigatorKey.currentState;
    final navContext = _navigatorKey.currentContext;
    if (navigator == null || navContext == null) return;

    _isScreensaverActive = true;
    try {
      await ScreensaverScreen.show(navContext);
    } finally {
      _isScreensaverActive = false;
      _inactivityService.onUserActivity();
    }
  }

  void _syncInactivityService(SettingsProvider settingsProvider) {
    _inactivityService.updateDuration(
      Duration(minutes: settingsProvider.oilScreensaverInactivityMinutes),
    );

    if (settingsProvider.useOilScreensaver) {
      _inactivityService.start();
    } else {
      _inactivityService.stop();
    }
  }

  void _initDeepLinks() {
    _deepLinkService = widget.deepLinkService ?? DeepLinkService();
    _deepLinkService!.init();

    _linkSubscription = _deepLinkService!.uriStream.listen((uri) {
      // Deep link handling
    });
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
            child: InactivityDetector(
              inactivityService: _inactivityService,
              isScreensaverActive: _isScreensaverActive,
              child: Material(
                color: finalTheme.scaffoldBackgroundColor,
                child: MaterialApp(
                  navigatorKey: _navigatorKey,
                  title: 'GDAR TV',
                  debugShowCheckedModeBanner: false,
                  theme: finalTheme,
                  themeMode: ThemeMode.dark,
                  home: const SplashScreen(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
