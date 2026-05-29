import 'package:flutter/material.dart';

/// Paleta de cores de um tema (paridade com `THEMES` em
/// `cheerful-mundo-ludico-play/src/lib/themes.js`).
class AppThemePalette {
  const AppThemePalette({
    required this.id,
    required this.familyEmoji,
    required this.familyLabel,
    required this.variantLabel,
    required this.isDark,
    required this.background,
    required this.cardBg,
    required this.primary,
    required this.text,
    required this.accent,
    required this.highlight,
    required this.secondary,
  });

  final String id;
  final String familyEmoji;

  /// Nome da família (ex.: «Azul»).
  final String familyLabel;

  /// Nome da variante (ex.: «Azul» ou «Azul Escuro»).
  final String variantLabel;
  final bool isDark;

  final Color background;
  final Color cardBg;
  final Color primary;
  final Color text;
  final Color accent;
  final Color highlight;
  final Color secondary;

  /// Fundo da barra de navegação (Play usa `cardBg`).
  Color get navSurface => cardBg;
  Color get navBorder => primary.withAlpha(0x33);
}

/// Grupo de tema (uma cor com variante clara e escura) para o seletor.
class AppThemeFamily {
  const AppThemeFamily({
    required this.emoji,
    required this.label,
    required this.lightId,
    required this.darkId,
  });

  final String emoji;
  final String label;
  final String lightId;
  final String darkId;
}

/// Registo central de temas. Mantém a paleta atual aplicada em toda a app.
abstract final class AppThemeRegistry {
  static const String defaultId = 'blue-light';

  static final Map<String, AppThemePalette> _palettes = {
    for (final p in _all) p.id: p,
  };

  static AppThemePalette _current = _palettes[defaultId]!;

  static AppThemePalette get current => _current;

  /// Normaliza ids antigos guardados em `SharedPreferences`.
  static String normalizeId(String id) {
    switch (id) {
      case 'ocean':
        return 'blue-light';
      case 'rose':
        return 'pink-light';
      case 'forest':
        return 'green-light';
      default:
        return _palettes.containsKey(id) ? id : defaultId;
    }
  }

  static AppThemePalette palette(String id) =>
      _palettes[normalizeId(id)] ?? _palettes[defaultId]!;

  static void setCurrent(String id) {
    _current = palette(id);
  }

  static List<AppThemeFamily> get families => _families;

  static const List<AppThemeFamily> _families = [
    AppThemeFamily(emoji: '💙', label: 'Azul', lightId: 'blue-light', darkId: 'blue-dark'),
    AppThemeFamily(emoji: '🌸', label: 'Rosa', lightId: 'pink-light', darkId: 'pink-dark'),
    AppThemeFamily(emoji: '🤩', label: 'Amarelo', lightId: 'yellow-light', darkId: 'yellow-dark'),
    AppThemeFamily(emoji: '❤️', label: 'Vermelho', lightId: 'red-light', darkId: 'red-dark'),
    AppThemeFamily(emoji: '🌿', label: 'Verde', lightId: 'green-light', darkId: 'green-dark'),
    AppThemeFamily(emoji: '💜', label: 'Roxo', lightId: 'purple-light', darkId: 'purple-dark'),
    AppThemeFamily(emoji: '🐚', label: 'Turquesa', lightId: 'teal-light', darkId: 'teal-dark'),
    AppThemeFamily(emoji: '🌅', label: 'Laranja', lightId: 'orange-light', darkId: 'orange-dark'),
    AppThemeFamily(emoji: '🔷', label: 'Índigo', lightId: 'indigo-light', darkId: 'indigo-dark'),
    AppThemeFamily(emoji: '🌈', label: 'Arco-Íris', lightId: 'rainbow-light', darkId: 'rainbow-dark'),
  ];

  static const List<AppThemePalette> _all = [
    // ---- AZUL ----
    AppThemePalette(
      id: 'blue-light', familyEmoji: '💙', familyLabel: 'Azul', variantLabel: 'Azul',
      isDark: false,
      background: Color(0xFFEBF8FF), cardBg: Color(0xFFBAE6FD), primary: Color(0xFF0EA5E9),
      text: Color(0xFF0C2A5E), accent: Color(0xFF38BDF8), highlight: Color(0xFF7DD3FC),
      secondary: Color(0xFF0284C7),
    ),
    AppThemePalette(
      id: 'blue-dark', familyEmoji: '💙', familyLabel: 'Azul', variantLabel: 'Azul Escuro',
      isDark: true,
      background: Color(0xFF00071A), cardBg: Color(0xFF001033), primary: Color(0xFF38BDF8),
      text: Color(0xFFBAE6FD), accent: Color(0xFF0EA5E9), highlight: Color(0xFF7DD3FC),
      secondary: Color(0xFF0284C7),
    ),
    // ---- ROSA ----
    AppThemePalette(
      id: 'pink-light', familyEmoji: '🌸', familyLabel: 'Rosa', variantLabel: 'Rosa',
      isDark: false,
      background: Color(0xFFFFF0F8), cardBg: Color(0xFFFFD6EE), primary: Color(0xFFE91E8C),
      text: Color(0xFF6B0047), accent: Color(0xFFFF6EC7), highlight: Color(0xFFFF9EDA),
      secondary: Color(0xFFB5179E),
    ),
    AppThemePalette(
      id: 'pink-dark', familyEmoji: '🌸', familyLabel: 'Rosa', variantLabel: 'Rosa Escuro',
      isDark: true,
      background: Color(0xFF1A0015), cardBg: Color(0xFF350030), primary: Color(0xFFFF4FBD),
      text: Color(0xFFFFBFEA), accent: Color(0xFFFF0090), highlight: Color(0xFFFF6EC7),
      secondary: Color(0xFFC2006E),
    ),
    // ---- AMARELO ----
    AppThemePalette(
      id: 'yellow-light', familyEmoji: '🤩', familyLabel: 'Amarelo', variantLabel: 'Amarelo',
      isDark: false,
      background: Color(0xFFFFFCEB), cardBg: Color(0xFFFFF3B0), primary: Color(0xFFF59E0B),
      text: Color(0xFF713F00), accent: Color(0xFFFB923C), highlight: Color(0xFFFDE68A),
      secondary: Color(0xFFD97706),
    ),
    AppThemePalette(
      id: 'yellow-dark', familyEmoji: '🤩', familyLabel: 'Amarelo', variantLabel: 'Amarelo Escuro',
      isDark: true,
      background: Color(0xFF180E00), cardBg: Color(0xFF2D1A00), primary: Color(0xFFFBBF24),
      text: Color(0xFFFDE68A), accent: Color(0xFFF97316), highlight: Color(0xFFFCD34D),
      secondary: Color(0xFFD97706),
    ),
    // ---- VERMELHO ----
    AppThemePalette(
      id: 'red-light', familyEmoji: '❤️', familyLabel: 'Vermelho', variantLabel: 'Vermelho',
      isDark: false,
      background: Color(0xFFFFF5F5), cardBg: Color(0xFFFFD6D6), primary: Color(0xFFE53E3E),
      text: Color(0xFF7A0000), accent: Color(0xFFFC4F4F), highlight: Color(0xFFFEB2B2),
      secondary: Color(0xFFC53030),
    ),
    AppThemePalette(
      id: 'red-dark', familyEmoji: '❤️', familyLabel: 'Vermelho', variantLabel: 'Vermelho Escuro',
      isDark: true,
      background: Color(0xFF120000), cardBg: Color(0xFF2D0000), primary: Color(0xFFFC4F4F),
      text: Color(0xFFFFB3B3), accent: Color(0xFFE53E3E), highlight: Color(0xFFFC8181),
      secondary: Color(0xFF9B2C2C),
    ),
    // ---- VERDE ----
    AppThemePalette(
      id: 'green-light', familyEmoji: '🌿', familyLabel: 'Verde', variantLabel: 'Verde',
      isDark: false,
      background: Color(0xFFEDFFF5), cardBg: Color(0xFFBBFBD0), primary: Color(0xFF22C55E),
      text: Color(0xFF064E1B), accent: Color(0xFF16A34A), highlight: Color(0xFF86EFAC),
      secondary: Color(0xFF15803D),
    ),
    AppThemePalette(
      id: 'green-dark', familyEmoji: '🌿', familyLabel: 'Verde', variantLabel: 'Verde Escuro',
      isDark: true,
      background: Color(0xFF001409), cardBg: Color(0xFF002B14), primary: Color(0xFF4ADE80),
      text: Color(0xFFA7F3D0), accent: Color(0xFF22C55E), highlight: Color(0xFF6EE7B7),
      secondary: Color(0xFF15803D),
    ),
    // ---- ROXO ----
    AppThemePalette(
      id: 'purple-light', familyEmoji: '💜', familyLabel: 'Roxo', variantLabel: 'Roxo',
      isDark: false,
      background: Color(0xFFF5F0FF), cardBg: Color(0xFFE9D8FD), primary: Color(0xFF9333EA),
      text: Color(0xFF3B0764), accent: Color(0xFFA855F7), highlight: Color(0xFFD8B4FE),
      secondary: Color(0xFF7C3AED),
    ),
    AppThemePalette(
      id: 'purple-dark', familyEmoji: '💜', familyLabel: 'Roxo', variantLabel: 'Roxo Escuro',
      isDark: true,
      background: Color(0xFF0A0015), cardBg: Color(0xFF1A0035), primary: Color(0xFFC084FC),
      text: Color(0xFFE9D8FD), accent: Color(0xFFA855F7), highlight: Color(0xFFD8B4FE),
      secondary: Color(0xFF7C3AED),
    ),
    // ---- TURQUESA ----
    AppThemePalette(
      id: 'teal-light', familyEmoji: '🐚', familyLabel: 'Turquesa', variantLabel: 'Turquesa',
      isDark: false,
      background: Color(0xFFEDFAFA), cardBg: Color(0xFFAFECEF), primary: Color(0xFF0694A2),
      text: Color(0xFF014451), accent: Color(0xFF16BDCA), highlight: Color(0xFF7EDCE2),
      secondary: Color(0xFF047481),
    ),
    AppThemePalette(
      id: 'teal-dark', familyEmoji: '🐚', familyLabel: 'Turquesa', variantLabel: 'Turquesa Escuro',
      isDark: true,
      background: Color(0xFF001215), cardBg: Color(0xFF00242A), primary: Color(0xFF22D3EE),
      text: Color(0xFFA5F3FC), accent: Color(0xFF06B6D4), highlight: Color(0xFF67E8F9),
      secondary: Color(0xFF0891B2),
    ),
    // ---- LARANJA ----
    AppThemePalette(
      id: 'orange-light', familyEmoji: '🌅', familyLabel: 'Laranja', variantLabel: 'Laranja',
      isDark: false,
      background: Color(0xFFFFF7F0), cardBg: Color(0xFFFDDCBF), primary: Color(0xFFF97316),
      text: Color(0xFF6A2000), accent: Color(0xFFFB923C), highlight: Color(0xFFFED7AA),
      secondary: Color(0xFFEA580C),
    ),
    AppThemePalette(
      id: 'orange-dark', familyEmoji: '🌅', familyLabel: 'Laranja', variantLabel: 'Laranja Escuro',
      isDark: true,
      background: Color(0xFF160800), cardBg: Color(0xFF2D1200), primary: Color(0xFFFB923C),
      text: Color(0xFFFED7AA), accent: Color(0xFFF97316), highlight: Color(0xFFFDBA74),
      secondary: Color(0xFFEA580C),
    ),
    // ---- ÍNDIGO ----
    AppThemePalette(
      id: 'indigo-light', familyEmoji: '🔷', familyLabel: 'Índigo', variantLabel: 'Índigo',
      isDark: false,
      background: Color(0xFFEEF2FF), cardBg: Color(0xFFC7D2FE), primary: Color(0xFF4F46E5),
      text: Color(0xFF1E1B4B), accent: Color(0xFF6366F1), highlight: Color(0xFFA5B4FC),
      secondary: Color(0xFF4338CA),
    ),
    AppThemePalette(
      id: 'indigo-dark', familyEmoji: '🔷', familyLabel: 'Índigo', variantLabel: 'Índigo Escuro',
      isDark: true,
      background: Color(0xFF05040F), cardBg: Color(0xFF0E0A2E), primary: Color(0xFF818CF8),
      text: Color(0xFFC7D2FE), accent: Color(0xFF6366F1), highlight: Color(0xFFA5B4FC),
      secondary: Color(0xFF4338CA),
    ),
    // ---- ARCO-ÍRIS ----
    AppThemePalette(
      id: 'rainbow-light', familyEmoji: '🌈', familyLabel: 'Arco-Íris', variantLabel: 'Arco-Íris',
      isDark: false,
      background: Color(0xFFFFFDF5), cardBg: Color(0xFFFFFFFF), primary: Color(0xFFFF6B6B),
      text: Color(0xFF2D2D2D), accent: Color(0xFF4ECDC4), highlight: Color(0xFFFFE66D),
      secondary: Color(0xFFA855F7),
    ),
    AppThemePalette(
      id: 'rainbow-dark', familyEmoji: '🌈', familyLabel: 'Arco-Íris', variantLabel: 'Festa Neon',
      isDark: true,
      background: Color(0xFF0A0A0A), cardBg: Color(0xFF1A1A2E), primary: Color(0xFFFF6B6B),
      text: Color(0xFFE0E0E0), accent: Color(0xFF4ECDC4), highlight: Color(0xFFFFE66D),
      secondary: Color(0xFFA855F7),
    ),
  ];
}
