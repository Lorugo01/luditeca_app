import 'package:flutter/material.dart';

import '../theme/app_theme_palette.dart';

/// Tokens visuais que refletem a paleta de tema atual (ver `AppThemeRegistry`).
/// Os valores são getters dinâmicos para que a troca de tema afete toda a app.
abstract final class AppLayoutTokens {
  static Color get scaffoldBackground => AppThemeRegistry.current.background;
  static Color get cardBackground => AppThemeRegistry.current.cardBg;
  static Color get primary => AppThemeRegistry.current.primary;
  static Color get textPrimary => AppThemeRegistry.current.text;
  static Color get accent => AppThemeRegistry.current.accent;
  static Color get highlight => AppThemeRegistry.current.highlight;
  static Color get secondary => AppThemeRegistry.current.secondary;

  /// Indica se o tema atual é escuro (útil para ícones/sombreados).
  static bool get isDark => AppThemeRegistry.current.isDark;

  /// Cartão elevado (estatísticas, chips) — adapta ao tema claro/escuro.
  static Color get elevatedSurface => isDark
      ? Color.lerp(scaffoldBackground, cardBackground, 0.55)!
      : const Color(0xFFFFFFFF);

  /// Texto secundário sobre superfície elevada.
  static Color get elevatedSurfaceMuted =>
      textPrimary.withAlpha(isDark ? 200 : 140);

  /// Borda subtil em cartões internos.
  static Color get subtleBorder => primary.withAlpha(isDark ? 50 : 36);

  /// Fundo da barra de navegação (equivalente a `cardBg` no BottomNav do Play).
  static Color get navSurface => AppThemeRegistry.current.navSurface;
  static Color get navBorder => AppThemeRegistry.current.navBorder;

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
