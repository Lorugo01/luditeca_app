import 'package:flutter/material.dart';
import 'layout/app_layout_tokens.dart';

class AppTheme {
  static ThemeData get lightTheme => forId('ocean');

  static ThemeData forId(String id) {
    final colors = _paletteFor(id);
    return ThemeData(
      fontFamily: 'Poppins',
      primarySwatch: Colors.blue,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.scaffold,
      textTheme: TextTheme(
        displayLarge: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        displayMedium: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: Colors.grey[800]),
        bodyMedium: TextStyle(fontSize: 14, color: Colors.grey[700]),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: colors.primary,
        secondary: colors.accent,
        surface: colors.scaffold,
      ),
    );
  }

  static _ThemePalette _paletteFor(String id) {
    switch (id) {
      case 'rose':
        return const _ThemePalette(
          primary: Color(0xFFFF6B8A),
          accent: Color(0xFFFF4499),
          scaffold: Color(0xFFFFF1F5),
        );
      case 'forest':
        return const _ThemePalette(
          primary: Color(0xFF22C55E),
          accent: Color(0xFF14B8A6),
          scaffold: Color(0xFFF0FDF4),
        );
      case 'ocean':
      default:
        return const _ThemePalette(
          primary: AppLayoutTokens.primary,
          accent: AppLayoutTokens.accent,
          scaffold: AppLayoutTokens.scaffoldBackground,
        );
    }
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

class _ThemePalette {
  const _ThemePalette({
    required this.primary,
    required this.accent,
    required this.scaffold,
  });

  final Color primary;
  final Color accent;
  final Color scaffold;
}
