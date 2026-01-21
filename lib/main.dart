import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';
import 'package:shakedown/ui/screens/splash_screen.dart';
import 'package:shakedown/utils/app_themes.dart';
import 'package:shakedown/utils/logger.dart';
// import 'package:google_fonts/google_fonts.dart'; // Removed
import 'package:just_audio_background/just_audio_background.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/ui/widgets/rgb_clock_wrapper.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Lock device orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize your logger
  initLogger();

  // Initialize background audio service with your app-specific channel
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.jamart3d.shakedown.channel.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(GdarApp(prefs: prefs));
}

class GdarApp extends StatefulWidget {
  final SharedPreferences prefs;
  final ShowListProvider? showListProvider;
  final SettingsProvider? settingsProvider;

  const GdarApp({
    super.key,
    required this.prefs,
    this.showListProvider,
    this.settingsProvider,
  });

  @override
  State<GdarApp> createState() => _GdarAppState();
}

class _GdarAppState extends State<GdarApp> {
  late final ShowListProvider _showListProvider;
  late final SettingsProvider _settingsProvider;
  late final AppLinks _appLinks;
  StreamSubscription? _linkSubscription;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final String _sessionId =
      DateTime.now().millisecondsSinceEpoch.toString().substring(7);

  @override
  void initState() {
    super.initState();
    _settingsProvider =
        widget.settingsProvider ?? SettingsProvider(widget.prefs);
    _showListProvider = widget.showListProvider ?? ShowListProvider();

    // Start initialization but don't block the UI
    // Only init if it's the internal one (or if we want to force it, but for tests we might want to skip)
    if (widget.showListProvider == null) {
      _showListProvider.init();
    }

    _initDeepLinks();
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Handle initial link if app was closed
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        logger
            .i('Main: [Session #$_sessionId] Handling INITIAL deep link: $uri');
        _handleDeepLink(uri);
      }
    });

    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      logger.i('Main: [Session #$_sessionId] Handling STREAM deep link: $uri');
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri uri) {
    logger.i(
        'Main: [Session #$_sessionId] Handling deep link: $uri (scheme: ${uri.scheme}, host: ${uri.host}, query: ${uri.queryParameters})');

    if (uri.scheme == 'shakedown' || uri.scheme == 'gdar') {
      _triggerDeepLinkAction(uri);
    } else {
      logger.w('Main: Unhandled deep link scheme: ${uri.scheme}');
    }
  }

  void _triggerDeepLinkAction(Uri uri, {int retryCount = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final context = _navigatorKey.currentContext;
      if (context != null) {
        final audioProvider =
            Provider.of<AudioProvider>(context, listen: false);

        if (uri.host == 'play-random') {
          logger.i(
              'Main: [Session #$_sessionId] Triggering playRandomShow from host: "play-random"');
          audioProvider.playRandomShow(filterBySearch: true);
        } else if (uri.host == 'open') {
          final feature = uri.queryParameters['feature']?.toLowerCase() ?? '';
          logger.i(
              'Main: [Session #$_sessionId] Deep link matches "open" with feature: "$feature"');

          if (feature.contains('play') || feature.contains('random')) {
            logger.i(
                'Main: [Session #$_sessionId] Triggering playRandomShow based on feature: "$feature"');
            audioProvider.playRandomShow(filterBySearch: true);
          } else {
            logger.i(
                'Main: [Session #$_sessionId] Feature "$feature" does not require playback');
          }
        } else {
          logger.w(
              'Main: [Session #$_sessionId] Unhandled deep link host: ${uri.host}');
        }
      } else {
        if (retryCount < 10) {
          logger.w(
              'Main: [Session #$_sessionId] Navigator context is null, retrying (${retryCount + 1})...');
          Future.delayed(const Duration(milliseconds: 200), () {
            _triggerDeepLinkAction(uri, retryCount: retryCount + 1);
          });
        } else {
          logger.e(
              'Main: Navigator context is null after multiple retries. Deep link failed.');
        }
      }
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: _settingsProvider),
        ChangeNotifierProxyProvider<SettingsProvider, ShowListProvider>(
          create: (_) => _showListProvider,
          update: (_, settingsProvider, showListProvider) =>
              showListProvider!..update(settingsProvider),
        ),
        ChangeNotifierProxyProvider2<ShowListProvider, SettingsProvider,
            AudioProvider>(
          create: (_) => AudioProvider(),
          update: (_, showListProvider, settingsProvider, audioProvider) =>
              audioProvider!
                ..update(
                  showListProvider,
                  settingsProvider,
                ),
        ),
      ],
      child: Consumer2<ThemeProvider, SettingsProvider>(
        builder: (context, themeProvider, settingsProvider, child) {
          return RgbClockWrapper(
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: DynamicColorBuilder(
              builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
                ThemeData lightTheme;
                ThemeData darkTheme;

                if (settingsProvider.useDynamicColor &&
                    lightDynamic != null &&
                    darkDynamic != null) {
                  // Use dynamic colors if the setting is on and they are available
                  // Use dynamic colors if the setting is on and they are available
                  final baseLight = ThemeData(
                    useMaterial3: settingsProvider.useMaterial3,
                    colorScheme: lightDynamic,
                  );
                  final baseDark = ThemeData(
                    useMaterial3: settingsProvider.useMaterial3,
                    colorScheme: darkDynamic,
                  );

                  lightTheme = baseLight.copyWith(
                    textTheme: AppThemes.getTextTheme(
                        settingsProvider.appFont, baseLight.textTheme),
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: baseLight.colorScheme.primary,
                      selectionColor:
                          baseLight.colorScheme.primary.withValues(alpha: 0.3),
                      selectionHandleColor: baseLight.colorScheme.primary,
                    ),
                  );
                  darkTheme = baseDark.copyWith(
                    textTheme: AppThemes.getTextTheme(
                        settingsProvider.appFont, baseDark.textTheme),
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: baseDark.colorScheme.primary,
                      selectionColor:
                          baseDark.colorScheme.primary.withValues(alpha: 0.3),
                      selectionHandleColor: baseDark.colorScheme.primary,
                    ),
                  );

                  // Apply True Black if enabled
                  if (settingsProvider.useTrueBlack) {
                    final trueBlackDynamic = darkDynamic.copyWith(
                      surface: Colors.black,
                      onSurface: Colors.white,
                      surfaceContainerLowest: Colors.black,
                      surfaceContainerLow: Colors.black,
                      surfaceContainer: Colors.black,
                      surfaceContainerHigh: Colors.black,
                      surfaceContainerHighest: Colors.black,
                    );

                    darkTheme = darkTheme.copyWith(
                      colorScheme: trueBlackDynamic,
                      scaffoldBackgroundColor: Colors.black,
                      appBarTheme: const AppBarTheme(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        systemOverlayStyle: SystemUiOverlayStyle.light,
                      ),
                    );
                  }
                } else {
                  // If dynamic color is off, first get the base static themes.
                  lightTheme = AppThemes.lightTheme(settingsProvider.appFont,
                      useMaterial3: settingsProvider.useMaterial3);
                  darkTheme = AppThemes.darkTheme(settingsProvider.appFont,
                      useMaterial3: settingsProvider.useMaterial3);

                  // Then, check for a user-defined seed color to override the color scheme.
                  final seedColor = settingsProvider.seedColor;
                  if (seedColor != null) {
                    lightTheme = lightTheme.copyWith(
                      colorScheme: ColorScheme.fromSeed(
                        seedColor: seedColor,
                        brightness: Brightness.light,
                      ),
                    );

                    // Generate base dark scheme from seed
                    final baseDarkScheme = ColorScheme.fromSeed(
                      seedColor: seedColor,
                      brightness: Brightness.dark,
                    );

                    darkTheme = darkTheme.copyWith(colorScheme: baseDarkScheme);

                    // Apply seed-based selection theme
                    lightTheme = lightTheme.copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: lightTheme.colorScheme.primary,
                        selectionColor: lightTheme.colorScheme.primary
                            .withValues(alpha: 0.3),
                        selectionHandleColor: lightTheme.colorScheme.primary,
                      ),
                    );
                    darkTheme = darkTheme.copyWith(
                      textSelectionTheme: TextSelectionThemeData(
                        cursorColor: darkTheme.colorScheme.primary,
                        selectionColor: darkTheme.colorScheme.primary
                            .withValues(alpha: 0.3),
                        selectionHandleColor: darkTheme.colorScheme.primary,
                      ),
                    );
                  }

                  // Override surfaces to be "True Black" if enabled
                  if (settingsProvider.useTrueBlack) {
                    final baseDarkScheme = darkTheme.colorScheme;
                    final trueBlackDarkScheme = baseDarkScheme.copyWith(
                      surface: Colors.black,
                      onSurface: Colors.white,
                      surfaceContainerLowest: Colors.black,
                      surfaceContainerLow: Colors.black,
                      surfaceContainer: Colors.black,
                      surfaceContainerHigh: Colors.black,
                      surfaceContainerHighest: Colors.black,
                    );

                    darkTheme = darkTheme.copyWith(
                      colorScheme: trueBlackDarkScheme,
                      scaffoldBackgroundColor: Colors.black,
                      appBarTheme: const AppBarTheme(
                        backgroundColor: Colors.black,
                        elevation: 0,
                        scrolledUnderElevation: 0,
                        systemOverlayStyle: SystemUiOverlayStyle.light,
                      ),
                    );
                  }
                }

                return MaterialApp(
                  navigatorKey: _navigatorKey,
                  title: 'Shakedown',
                  debugShowCheckedModeBanner: false,
                  theme: lightTheme,
                  darkTheme: darkTheme,
                  themeMode: themeProvider.isDarkMode
                      ? ThemeMode.dark
                      : ThemeMode.light,
                  themeAnimationDuration: const Duration(milliseconds: 400),
                  themeAnimationCurve: Curves.easeInOutCubicEmphasized,
                  home: settingsProvider.showSplashScreen
                      ? const SplashScreen()
                      : const ShowListScreen(),
                  builder: (context, child) {
                    final isTrueBlack = themeProvider.isDarkMode &&
                        settingsProvider.useTrueBlack;

                    if (isTrueBlack) {
                      return AnnotatedRegion<SystemUiOverlayStyle>(
                        value: const SystemUiOverlayStyle(
                          systemNavigationBarColor: Colors.black,
                          systemNavigationBarIconBrightness: Brightness.light,
                        ),
                        child: child!,
                      );
                    }
                    return child!;
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}
