import 'package:flutter/material.dart';

import 'theme/app_theme_palette.dart';

class AppTheme {
  static ThemeData get lightTheme => forId(AppThemeRegistry.defaultId);

  /// Constrói o `ThemeData` a partir do id de uma paleta.
  static ThemeData forId(String id) {
    final palette = AppThemeRegistry.palette(id);
    final brightness = palette.isDark ? Brightness.dark : Brightness.light;
    final onPalette = palette.isDark ? Colors.white : palette.text;

    return ThemeData(
      fontFamily: 'Poppins',
      brightness: brightness,
      primaryColor: palette.primary,
      scaffoldBackgroundColor: palette.background,
      textTheme: TextTheme(
        displayLarge: TextStyle(fontWeight: FontWeight.bold, color: palette.text),
        displayMedium: TextStyle(fontWeight: FontWeight.bold, color: palette.text),
        bodyLarge: TextStyle(fontSize: 16, color: palette.text),
        bodyMedium: TextStyle(fontSize: 14, color: palette.text.withAlpha(220)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: palette.primary,
        onPrimary: palette.isDark ? Colors.black : Colors.white,
        secondary: palette.accent,
        onSecondary: palette.isDark ? Colors.black : Colors.white,
        surface: palette.background,
        onSurface: onPalette,
        error: const Color(0xFFC53030),
        onError: Colors.white,
      ),
    );
  }

  static double getResponsiveSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return baseSize * 0.8;
    } else if (width < 1200) {
      return baseSize * 0.9;
    }
    return baseSize;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return const EdgeInsets.all(8.0);
    } else if (width < 1200) {
      return const EdgeInsets.all(16.0);
    }
    return const EdgeInsets.all(24.0);
  }
}
