import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:shakedown_core/app/gdar_app_provider_overrides.dart';
import 'package:shakedown_core/app/gdar_app_providers.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/screens/fruit_tab_host_screen.dart';
import 'package:shakedown_core/ui/screens/show_list_screen.dart';
import 'package:shakedown_core/app/gdar_app_lifecycle_mixin.dart';
import 'package:shakedown_core/ui/screens/splash_screen.dart';
import 'package:shakedown_core/ui/navigation/app_route_observer.dart';
import 'package:shakedown_core/ui/widgets/rgb_clock_wrapper.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/utils/web_error_logger.dart';
import 'package:shakedown_core/utils/web_perf_hint.dart';
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

class _GdarWebAppState extends State<GdarWebApp>
    with GdarAppLifecycleMixin<GdarWebApp> {
  late final ShowListProvider _showListProvider;
  late final SettingsProvider _settingsProvider;

  bool get _isAndroidStyle =>
      Uri.base.queryParameters['ui']?.toLowerCase() == 'android';

  bool get _isTv =>
      Uri.base.queryParameters['force_tv']?.toLowerCase() == 'true';

  @override
  bool get isTv => _isTv;

  @override
  SettingsProvider get settingsProvider => _settingsProvider;

  @override
  void initState() {
    super.initState();
    final bool isTv = _isTv;
    _settingsProvider = SettingsProvider(widget.prefs, isTv: isTv);
    _showListProvider = ShowListProvider();

    // Targeted debug boxes for show list cards
    _settingsProvider.setShowDebugLayout(true);
    if (kIsWeb) {
      debugPaintSizeEnabled = false;
    }

    // Link providers for theme-specific settings resets
    ThemeProvider.getInstance?.setSettingsProvider(_settingsProvider);

    // Apply URL-based theme override, or set first-time default.
    // IMPORTANT: do NOT override the user's persisted preference on every
    // reload — only force a style when an explicit URL param is present or
    // on first launch (no saved preference yet).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = navigatorKey.currentContext?.read<ThemeProvider>();
      if (themeProvider == null) return;

      if (_isAndroidStyle) {
        // Explicit URL override → always honour
        if (themeProvider.themeStyle != ThemeStyle.android) {
          themeProvider.setThemeStyle(ThemeStyle.android);
        }
      } else if (!widget.prefs.containsKey('theme_style_preference')) {
        // First launch — no saved preference yet → default to Fruit
        // (or Android on low-power devices).
        final targetStyle = isLikelyLowPowerWebDevice()
            ? ThemeStyle.android
            : ThemeStyle.fruit;
        if (themeProvider.themeStyle != targetStyle) {
          themeProvider.setThemeStyle(targetStyle);
        }
      }
    });

    _showListProvider.init(widget.prefs);

    initLifecycle();
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
        isTv: _isTv,
        overrides: GdarAppProviderOverrides(
          settingsProvider: _settingsProvider,
          showListProvider: _showListProvider,
        ),
      ),
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
                  useTrueBlack: settingsProvider.useTrueBlack,
                )
              : GDARFruitTheme.dark(
                  uiScale: settingsProvider.uiScale,
                  colorOption: themeProvider.fruitColorOption,
                );

          return RgbClockWrapper(
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: MaterialApp(
              navigatorKey: navigatorKey,
              navigatorObservers: [shakedownRouteObserver],
              title: 'Shakedown.',
              color: themeProvider.currentThemeMode == ThemeMode.light
                  ? lightTheme.scaffoldBackgroundColor
                  : darkTheme.scaffoldBackgroundColor,
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
