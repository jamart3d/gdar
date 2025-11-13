// lib/utils/app_themes.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppThemes {
  static ThemeData lightTheme(bool useHandwritingFont) {
    final textTheme = useHandwritingFont
        ? GoogleFonts.caveatTextTheme(ThemeData.light().textTheme)
        : null; // Use default M3 typography

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // A cool white
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: Colors.white,
      textTheme: textTheme,
    );
  }

  static ThemeData darkTheme(bool useHandwritingFont) {
    final textTheme = useHandwritingFont
        ? GoogleFonts.caveatTextTheme(ThemeData.dark().textTheme)
        : null; // Use default M3 typography

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.black, // True black for OLED
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF121212),
        elevation: 0,
      ),
      cardColor: const Color(0xFF1E1E1E),
      textTheme: textTheme,
    );
  }
}
