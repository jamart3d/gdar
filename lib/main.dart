// lib/main.dart

import 'package:flutter/material.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/theme_provider.dart';
import 'package:gdar/ui/screens/show_list_screen.dart';
import 'package:gdar/utils/app_themes.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

// The main entry point for the application.
Future<void> main() async {
  // Ensure that plugin services are initialized before running the app.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the background audio service.
  // This is required for displaying media notifications and lock screen controls.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  // Run the app, wrapped in providers for state management.
  runApp(const GdarApp());
}

class GdarApp extends StatelessWidget {
  const GdarApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider makes the ThemeProvider and AudioProvider available
    // to all descendant widgets in the app.
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AudioProvider()),
      ],
      // The Consumer widget listens to changes in the ThemeProvider.
      // When the theme changes, this part of the tree rebuilds.
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'gdar',
            debugShowCheckedModeBanner: false,

            // Set the theme properties based on the provider's state.
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: themeProvider.currentThemeMode,

            // The starting screen of the app.
            home: const ShowListScreen(),
          );
        },
      ),
    );
  }
}