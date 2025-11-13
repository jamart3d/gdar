import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/providers/theme_provider.dart';
import 'package:gdar/ui/screens/show_list_screen.dart';
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
  );

  runApp(const GdarApp());
}

class GdarApp extends StatelessWidget {
  const GdarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ShowListProvider()),
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
                  useMaterial3: true,
                  colorScheme: lightDynamic,
                  textTheme: settingsProvider.useHandwritingFont
                      ? GoogleFonts.caveatTextTheme(
                      ThemeData(colorScheme: lightDynamic).textTheme)
                      : null,
                );
                darkTheme = ThemeData(
                  useMaterial3: true,
                  colorScheme: darkDynamic,
                  brightness: Brightness.dark,
                  textTheme: settingsProvider.useHandwritingFont
                      ? GoogleFonts.caveatTextTheme(
                      ThemeData(colorScheme: darkDynamic).textTheme)
                      : null,
                );
              } else {
                // Otherwise, use the predefined static themes
                lightTheme = AppThemes.lightTheme(settingsProvider.useHandwritingFont);
                darkTheme = AppThemes.darkTheme(settingsProvider.useHandwritingFont);
              }

              return MaterialApp(
                title: 'gdar',
                debugShowCheckedModeBanner: false,
                theme: lightTheme,
                darkTheme: darkTheme,
                themeMode:
                themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
                home: const ShowListScreen(),
              );
            },
          );
        },
      ),
    );
  }
}
