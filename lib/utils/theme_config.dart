import 'package:flutter/material.dart';

class ThemeConfig {
  static const Color backgroundColor = Color(0xFF0F0F13);
  static const Color surfaceColor = Color(0xFF1A1A24);
  static const Color accentColor = Colors.deepPurpleAccent;
  static const String fontFamily = 'Poppins';

  static ThemeData get theme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: accentColor,
      scaffoldBackgroundColor: backgroundColor,
      fontFamily: fontFamily,
      useMaterial3: true,
      
      // Horizontal tab theme
      tabBarTheme: const TabBarThemeData(
        labelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, fontFamily: fontFamily),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontFamily: fontFamily),
        indicatorColor: accentColor,
      ),

      // Global text theme with smaller sizes
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 12),
        bodyMedium: TextStyle(fontSize: 11),
        bodySmall: TextStyle(fontSize: 10, color: Colors.white38),
        labelLarge: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
      ),

      sliderTheme: const SliderThemeData(
        trackHeight: 2,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 4),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 8),
        activeTrackColor: accentColor,
        thumbColor: accentColor,
      ),

      dropdownMenuTheme: DropdownMenuThemeData(
        textStyle: const TextStyle(fontSize: 11),
        menuStyle: MenuStyle(
          backgroundColor: WidgetStateProperty.all(surfaceColor),
        ),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        hintStyle: const TextStyle(fontSize: 11, color: Colors.white24),
      ),
    );
  }
}
