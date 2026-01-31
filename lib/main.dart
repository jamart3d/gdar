import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/screens/onboarding_screen.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/screens/show_list_screen.dart';
import 'package:shakedown/ui/screens/splash_screen.dart';
import 'package:shakedown/ui/screens/track_list_screen.dart';
import 'package:shakedown/utils/app_themes.dart';
import 'package:shakedown/utils/logger.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:app_links/app_links.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/ui/widgets/rgb_clock_wrapper.dart';
import 'package:shakedown/services/audio_cache_service.dart';
import 'package:shakedown/providers/update_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  initLogger();

  await AudioProvider.clearAudioCache();

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

    if (widget.showListProvider == null) {
      _showListProvider.init(widget.prefs);
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
          final animationOnly =
              uri.queryParameters['animation_only']?.toLowerCase() == 'true';
          audioProvider.playRandomShow(
              filterBySearch: true, animationOnly: animationOnly);
        } else if (uri.host == 'ui-scale') {
          // SAFETY: Disable debug tools in Release Mode
          if (kReleaseMode) {
            logger.w(
                'Main: [Session #$_sessionId] Ignoring debug deep link (ui-scale) in Release Mode');
            return;
          }
          final enabled =
              uri.queryParameters['enabled']?.toLowerCase() == 'true';
          final settingsProvider =
              Provider.of<SettingsProvider>(context, listen: false);

          logger
              .i('Main: [Session #$_sessionId] Setting UI scale to: $enabled');

          if (enabled != settingsProvider.uiScale) {
            settingsProvider.toggleUiScale();
          }
        } else if (uri.host == 'font') {
          // SAFETY: Disable debug tools in Release Mode
          if (kReleaseMode) {
            logger.w(
                'Main: [Session #$_sessionId] Ignoring debug deep link (font) in Release Mode');
            return;
          }
          final fontName =
              uri.queryParameters['name']?.toLowerCase() ?? 'default';
          final settingsProvider =
              Provider.of<SettingsProvider>(context, listen: false);

          final validFonts = [
            'default',
            'caveat',
            'permanent_marker',
            'rock_salt'
          ];

          if (validFonts.contains(fontName)) {
            logger.i('Main: [Session #$_sessionId] Setting font to: $fontName');
            settingsProvider.setAppFont(fontName);
          } else {
            logger.w(
                'Main: [Session #$_sessionId] Invalid font name: $fontName (valid: ${validFonts.join(", ")})');
          }
        } else if (uri.host == 'open') {
          final feature = uri.queryParameters['feature']?.toLowerCase() ?? '';
          logger.i(
              'Main: [Session #$_sessionId] Deep link matches "open" with feature: "$feature"');

          if (feature.contains('play') || feature.contains('random')) {
            logger.i(
                'Main: [Session #$_sessionId] Triggering playRandomShow based on feature: "$feature"');
            final animationOnly =
                uri.queryParameters['animation_only']?.toLowerCase() == 'true';
            audioProvider.playRandomShow(
                filterBySearch: true, animationOnly: animationOnly);
          } else {
            logger.i(
                'Main: [Session #$_sessionId] Feature "$feature" does not require playback');
          }
        } else if (uri.host == 'navigate') {
          final screen = uri.queryParameters['screen']?.toLowerCase();
          logger.i('Main: [Session #$_sessionId] Navigating to: $screen');

          if (screen == 'settings') {
            final highlight = uri.queryParameters['highlight'];
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => SettingsScreen(highlightSetting: highlight)),
            );
          } else if (screen == 'splash') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SplashScreen()),
              (route) => false,
            );
          } else if (screen == 'onboarding') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              (route) => false,
            );
          } else if (screen == 'home') {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const ShowListScreen()),
              (route) => false,
            );

            final action = uri.queryParameters['action']?.toLowerCase();
            if (action == 'search') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<ShowListProvider>(context, listen: false)
                    .setSearchVisible(true);
              });
            } else if (action == 'close_search') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Provider.of<ShowListProvider>(context, listen: false)
                    .setSearchVisible(false);
              });
            }
          } else if (screen == 'player') {
            final openPanel = uri.queryParameters['panel'] == 'open';
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => PlaybackScreen(initiallyOpen: openPanel)),
            );
          } else if (screen == 'track_list') {
            final indexStr = uri.queryParameters['index'];
            final showListProvider =
                Provider.of<ShowListProvider>(context, listen: false);
            final allShows = showListProvider.allShows;

            if (indexStr != null && allShows.isNotEmpty) {
              final index = int.tryParse(indexStr) ?? 0;
              final safeIndex = index.clamp(0, allShows.length - 1);
              final show = allShows[safeIndex];

              if (show.sources.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        TrackListScreen(show: show, source: show.sources.first),
                  ),
                );
              }
            }
          }
        } else if (uri.host == 'debug') {
          // SAFETY: Disable debug tools in Release Mode
          if (kReleaseMode) {
            logger.w(
                'Main: [Session #$_sessionId] Ignoring debug deep link (debug) in Release Mode');
            return;
          }
          final action = uri.queryParameters['action']?.toLowerCase();
          if (action == 'reset_prefs') {
            logger.w(
                'Main: [Session #$_sessionId] RESETTING ALL PREFERENCES via Deep Link');
            final settingsProvider =
                Provider.of<SettingsProvider>(context, listen: false);
            settingsProvider.resetToDefaults();
          } else if (action == 'complete_onboarding') {
            logger.i(
                'Main: [Session #$_sessionId] Completing Onboarding via Deep Link');
            final settingsProvider =
                Provider.of<SettingsProvider>(context, listen: false);
            settingsProvider.completeOnboarding();
          } else if (action == 'show_font_dialog') {
            logger.i(
                'Main: [Session #$_sessionId] Showing Font Dialog via Deep Link');
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) =>
                      const SettingsScreen(showFontSelection: true)),
            );
          } else if (action == 'simulate_update') {
            logger.i(
                'Main: [Session #$_sessionId] Simulating Update via Deep Link');
            Provider.of<UpdateProvider>(context, listen: false)
                .simulateUpdate();

            // Navigate to onboarding to see the banner
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
              (route) => false,
            );
          }
        } else if (uri.host == 'settings') {
          final key = uri.queryParameters['key'];
          final value = uri.queryParameters['value'];
          logger.i('Main: [Session #$_sessionId] Setting $key to $value');
          final settingsProvider =
              Provider.of<SettingsProvider>(context, listen: false);

          if (key == 'show_playback_messages') {
            if (value == 'true' && !settingsProvider.showPlaybackMessages) {
              settingsProvider.toggleShowPlaybackMessages();
            } else if (value == 'false' &&
                settingsProvider.showPlaybackMessages) {
              settingsProvider.toggleShowPlaybackMessages();
            }
          } else if (key == 'show_splash_screen') {
            if (value == 'true' && !settingsProvider.showSplashScreen) {
              settingsProvider.toggleShowSplashScreen();
            } else if (value == 'false' && settingsProvider.showSplashScreen) {
              settingsProvider.toggleShowSplashScreen();
            }
          }
        } else if (uri.host == 'player') {
          final action = uri.queryParameters['action']?.toLowerCase();
          logger.i('Main: [Session #$_sessionId] Player Action: $action');
          final audioProvider =
              Provider.of<AudioProvider>(context, listen: false);

          if (action == 'pause') {
            audioProvider.pause();
          } else if (action == 'resume' || action == 'play') {
            audioProvider.resume();
          } else if (action == 'stop') {
            logger.i(
                'Main: [Session #$_sessionId] Stopping and clearing playback via deep link');
            audioProvider.stopAndClear();
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlaybackScreen()),
            );
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
        ChangeNotifierProvider(create: (_) => AudioCacheService()),
        ChangeNotifierProxyProvider<SettingsProvider, ShowListProvider>(
          create: (_) => _showListProvider,
          update: (_, settingsProvider, showListProvider) =>
              showListProvider!..update(settingsProvider),
        ),
        ChangeNotifierProxyProvider2<ShowListProvider, SettingsProvider,
            AudioProvider>(
          create: (context) => AudioProvider(
            audioCacheService:
                Provider.of<AudioCacheService>(context, listen: false),
          ),
          update: (_, showListProvider, settingsProvider, audioProvider) =>
              audioProvider!
                ..update(
                  showListProvider,
                  settingsProvider,
                ),
        ),
        ChangeNotifierProvider(create: (_) => UpdateProvider()),
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
                  final baseLight = ThemeData(
                    useMaterial3: settingsProvider.useMaterial3,
                    colorScheme: lightDynamic,
                  );
                  final baseDark = ThemeData(
                    useMaterial3: settingsProvider.useMaterial3,
                    colorScheme: darkDynamic,
                  );

                  lightTheme = baseLight.copyWith(
                    textTheme: AppThemes.buildTextTheme(
                      settingsProvider.appFont,
                      baseLight.textTheme,
                      uiScale: settingsProvider.uiScale,
                    ),
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: baseLight.colorScheme.primary,
                      selectionColor:
                          baseLight.colorScheme.primary.withValues(alpha: 0.3),
                      selectionHandleColor: baseLight.colorScheme.primary,
                    ),
                  );
                  darkTheme = baseDark.copyWith(
                    textTheme: AppThemes.buildTextTheme(
                      settingsProvider.appFont,
                      baseDark.textTheme,
                      uiScale: settingsProvider.uiScale,
                    ),
                    textSelectionTheme: TextSelectionThemeData(
                      cursorColor: baseDark.colorScheme.primary,
                      selectionColor:
                          baseDark.colorScheme.primary.withValues(alpha: 0.3),
                      selectionHandleColor: baseDark.colorScheme.primary,
                    ),
                  );

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
                  lightTheme = AppThemes.lightTheme(
                    settingsProvider.appFont,
                    useMaterial3: settingsProvider.useMaterial3,
                    uiScale: settingsProvider.uiScale,
                  );
                  darkTheme = AppThemes.darkTheme(
                    settingsProvider.appFont,
                    useMaterial3: settingsProvider.useMaterial3,
                    uiScale: settingsProvider.uiScale,
                  );

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
                  themeAnimationDuration: Duration.zero, // Instant font changes
                  themeAnimationCurve:
                      Curves.linear, // Not used with zero duration
                  home: settingsProvider.showOnboarding
                      ? const OnboardingScreen()
                      : (settingsProvider.showSplashScreen
                          ? const SplashScreen()
                          : const ShowListScreen()),
                  builder: (context, child) {
                    final isTrueBlack = themeProvider.isDarkMode &&
                        settingsProvider.useTrueBlack;

                    if (isTrueBlack) {
                      child = AnnotatedRegion<SystemUiOverlayStyle>(
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
