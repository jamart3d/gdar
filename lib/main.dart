import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/providers/theme_provider.dart';
import 'package:gdar/ui/screens/splash_screen.dart';
import 'package:gdar/utils/app_themes.dart';
import 'package:gdar/utils/logger.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

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
    androidNotificationChannelId: 'com.jamart3d.gdar.channel.audio',
    androidNotificationChannelName: 'Audio Playback',
    androidNotificationOngoing: true,
    androidNotificationIcon: 'mipmap/ic_launcher',
  );

  runApp(const GdarApp());
}

class GdarApp extends StatefulWidget {
  const GdarApp({super.key});

  @override
  State<GdarApp> createState() => _GdarAppState();
}

class _GdarAppState extends State<GdarApp> {
  late final ShowListProvider _showListProvider;
  late final Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _showListProvider = ShowListProvider();
    _initFuture = _showListProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        return MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: _showListProvider),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
              return DynamicColorBuilder(
                builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
                  ThemeData lightTheme;
                  ThemeData darkTheme;

                  if (settingsProvider.useDynamicColor &&
                      lightDynamic != null &&
                      darkDynamic != null) {
                    // Use dynamic colors if the setting is on and they are available
                    lightTheme = ThemeData(
                      useMaterial3: settingsProvider.useMaterial3,
                      colorScheme: lightDynamic,
                      textTheme: settingsProvider.useHandwritingFont
                          ? GoogleFonts.caveatTextTheme(
                              ThemeData(colorScheme: lightDynamic).textTheme)
                          : null,
                    );
                    darkTheme = ThemeData(
                      useMaterial3: settingsProvider.useMaterial3,
                      colorScheme: darkDynamic,
                      textTheme: settingsProvider.useHandwritingFont
                          ? GoogleFonts.caveatTextTheme(
                              ThemeData(colorScheme: darkDynamic).textTheme)
                          : null,
                    );

                    if (settingsProvider.halfGlowDynamic) {
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
                        settingsProvider.useHandwritingFont,
                        useMaterial3: settingsProvider.useMaterial3);
                    darkTheme = AppThemes.darkTheme(
                        settingsProvider.useHandwritingFont,
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

                      darkTheme =
                          darkTheme.copyWith(colorScheme: baseDarkScheme);
                    }

                    // Override surfaces to be "True Black" / Neutral (no tint)
                    // This keeps the primary/secondary colors from the seed (or default) but removes the tint from the background/surfaces.
                    // We do this AFTER potentially setting the seed color, so it applies to both seeded and default themes.
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

                  return MaterialApp(
                    title: 'gdar',
                    debugShowCheckedModeBanner: false,
                    theme: lightTheme,
                    darkTheme: darkTheme,
                    themeMode: themeProvider.isDarkMode
                        ? ThemeMode.dark
                        : ThemeMode.light,
                    home: const SplashScreen(),
                    builder: (context, child) {
                      final isTrueBlack = themeProvider.isDarkMode &&
                          (!settingsProvider.useDynamicColor ||
                              settingsProvider.halfGlowDynamic);

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
              );
            },
          ),
        );
      },
    );
  }
}
