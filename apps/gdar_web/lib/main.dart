import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
import 'package:shakedown_core/ui/screens/fruit_tab_host_screen.dart';
import 'package:shakedown_core/ui/screens/show_list_screen.dart';
import 'package:shakedown_core/ui/screens/splash_screen.dart';
import 'package:shakedown_core/ui/widgets/rgb_clock_wrapper.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/utils/web_error_logger.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gdar_android/android_theme.dart';
import 'package:gdar_fruit/fruit_theme.dart';

Future<void> main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Web-specific initialization
      initLogger();
      if (kIsWeb) {
        initWebErrorLogger();
      }

      final prefs = await SharedPreferences.getInstance();

      runApp(GdarWebApp(prefs: prefs));
    },
    (error, stack) {
      if (kIsWeb) {
        recordWebError(error, stack, context: 'Zone');
      }
    },
  );
}

class GdarWebApp extends StatefulWidget {
  final SharedPreferences prefs;

  const GdarWebApp({super.key, required this.prefs});

  @override
  State<GdarWebApp> createState() => _GdarWebAppState();
}

class _GdarWebAppState extends State<GdarWebApp> {
  late final ShowListProvider _showListProvider;
  late final SettingsProvider _settingsProvider;
  late final DeepLinkService _deepLinkService;
  StreamSubscription? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  bool get _isAndroidStyle =>
      Uri.base.queryParameters['ui']?.toLowerCase() == 'android';

  bool get _isTv =>
      Uri.base.queryParameters['force_tv']?.toLowerCase() == 'true';

  @override
  void initState() {
    super.initState();
    final bool isTv = _isTv;
    _settingsProvider = SettingsProvider(widget.prefs, isTv: isTv);
    _showListProvider = ShowListProvider();

    // Link providers for theme-specific settings resets
    ThemeProvider.getInstance?.setSettingsProvider(_settingsProvider);

    // Set theme style based on URL parameter or default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = _navigatorKey.currentContext?.read<ThemeProvider>();
      if (themeProvider != null) {
        final targetStyle = _isAndroidStyle
            ? ThemeStyle.android
            : ThemeStyle.fruit;
        if (themeProvider.themeStyle != targetStyle) {
          themeProvider.setThemeStyle(targetStyle);
        }
      }
    });

    _showListProvider.init(widget.prefs);
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _deepLinkService.dispose();
    super.dispose();
  }

  void _initDeepLinks() {
    _deepLinkService = DeepLinkService();
    _deepLinkService.init();

    _linkSubscription = _deepLinkService.uriStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    // Basic implementation for now
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider(isTv: _isTv)),
        Provider<CatalogService>(create: (_) => CatalogService()),
        Provider<WakelockService>(create: (_) => WakelockService()),
        ChangeNotifierProvider.value(value: _settingsProvider),
        ChangeNotifierProvider(create: (_) => AudioCacheService()..init()),
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
          create: (_) => AudioProvider(),
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
          create: (_) => DeviceService(initialIsTv: _isTv),
        ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          final isAndroid = themeProvider.themeStyle == ThemeStyle.android;

          final lightTheme = isAndroid
              ? GDARAndroidTheme.light(
                  appFont: settingsProvider.activeAppFont,
                  uiScale: settingsProvider.uiScale,
                )
              : GDARFruitTheme.light(
                  uiScale: settingsProvider.uiScale,
                  colorOption: themeProvider.fruitColorOption,
                );

          final darkTheme = isAndroid
              ? GDARAndroidTheme.dark(
                  appFont: settingsProvider.activeAppFont,
                  uiScale: settingsProvider.uiScale,
                )
              : GDARFruitTheme.dark(
                  uiScale: settingsProvider.uiScale,
                  colorOption: themeProvider.fruitColorOption,
                );

          return RgbClockWrapper(
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: MaterialApp(
              navigatorKey: _navigatorKey,
              title: 'Shakedown.',
              debugShowCheckedModeBanner: false,
              theme: lightTheme,
              darkTheme: darkTheme,
              themeMode: themeProvider.currentThemeMode,
              home: settingsProvider.showSplashScreen
                  ? const SplashScreen()
                  : (isAndroid
                        ? const ShowListScreen()
                        : const FruitTabHostScreen()),
            ),
          );
        },
      ),
    );
  }
}

