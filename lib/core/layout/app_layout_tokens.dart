import 'package:flutter/material.dart';

/// Tokens visuais alinhados ao tema **blue-light** («Oceano») do Luditeca Play
/// (`cheerful-mundo-ludico-play` — `src/lib/themes.js`).
abstract final class AppLayoutTokens {
  static const Color scaffoldBackground = Color(0xFFEBF8FF);
  static const Color cardBackground = Color(0xFFBAE6FD);
  static const Color primary = Color(0xFF0EA5E9);
  static const Color textPrimary = Color(0xFF0C2A5E);
  static const Color accent = Color(0xFF38BDF8);

  /// Fundo da barra de navegação (equivalente a `cardBg` no BottomNav do Play).
  static const Color navSurface = Color(0xFFE0F2FE);
  static const Color navBorder = Color(0x330EA5E9);

  static BorderRadius get barTopRadius =>
      const BorderRadius.vertical(top: Radius.circular(24));

  static List<BoxShadow> get navTopShadow => [
        BoxShadow(
          color: Colors.black.withAlpha(31),
          blurRadius: 24,
          offset: const Offset(0, -4),
        ),
      ];
}
