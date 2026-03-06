import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      fontFamily: 'Poppins',
      primarySwatch: Colors.indigo,
      scaffoldBackgroundColor: Colors.white,
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
    );
  }

  // Método auxiliar para obter tamanhos responsivos
  static double getResponsiveSize(BuildContext context, double baseSize) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return baseSize * 0.8; // Mobile
    } else if (width < 1200) {
      return baseSize * 0.9; // Tablet
    } else {
      return baseSize; // Desktop
    }
  }

  // Método para obter padding responsivo
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 600) {
      return const EdgeInsets.all(8.0);
    } else if (width < 1200) {
      return const EdgeInsets.all(16.0);
    } else {
      return const EdgeInsets.all(24.0);
    }
  }
}
