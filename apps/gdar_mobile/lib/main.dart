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
  DeepLinkService? _deepLinkService;
  StreamSubscription? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

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
    if (widget.enableDeepLinks) {
      _initDeepLinks();
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkService?.dispose();
    super.dispose();
  }

  void _initDeepLinks() {
    _deepLinkService = widget.deepLinkService ?? DeepLinkService();
    _deepLinkService!.init();

    _linkSubscription = _deepLinkService!.uriStream.listen((uri) async {
      if (uri.scheme == 'shakedown' && uri.host == 'settings') {
        final key = uri.queryParameters['key'];
        final value = uri.queryParameters['value'];

        if (key != null && value != null) {
          if (value == 'true' || value == 'false') {
            await widget.prefs.setBool(key, value == 'true');
            if (key == 'force_tv') {
              if (mounted) {
                await Provider.of<DeviceService>(
                  context,
                  listen: false,
                ).refresh();
              }
            }
          }
        }
      }
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
              home: const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
