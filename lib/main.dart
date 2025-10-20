import 'package:flutter/material.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/theme_provider.dart';
import 'package:gdar/ui/screens/show_list_screen.dart';
import 'package:gdar/ui/screens/show_list_screen_slivers.dart'; // Import the slivers screen
import 'package:gdar/utils/app_themes.dart';
import 'package:gdar/utils/logger.dart'; // Import the logger
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'gdar',
            debugShowCheckedModeBanner: false,
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            // Use a Consumer to dynamically switch the home screen based on settings
            home: Consumer<SettingsProvider>(
              builder: (context, settingsProvider, child) {
                if (settingsProvider.useSliverView) {
                  return const ShowListScreenSlivers();
                } else {
                  return const ShowListScreen();
                }
              },
            ),
          );
        },
      ),
    );
  }
}

