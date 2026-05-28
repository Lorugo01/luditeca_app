import 'package:flutter/material.dart';

enum ReaderColorMode { normal, night, sepia, contrast }

/// Cores do painel de texto conforme o modo de leitura.
class ReaderPageTheme {
  const ReaderPageTheme({
    required this.panelBackground,
    required this.panelText,
    required this.pageBackdrop,
  });

  final Color panelBackground;
  final Color panelText;
  final Color pageBackdrop;

  static ReaderPageTheme forMode(ReaderColorMode mode) {
    switch (mode) {
      case ReaderColorMode.night:
        return const ReaderPageTheme(
          panelBackground: Color(0xFF1A202C),
          panelText: Color(0xFFF7FAFC),
          pageBackdrop: Color(0xFF000000),
        );
      case ReaderColorMode.sepia:
        return const ReaderPageTheme(
          panelBackground: Color(0xFFF4E8D0),
          panelText: Color(0xFF5D4037),
          pageBackdrop: Color(0xFF3D3228),
        );
      case ReaderColorMode.contrast:
        return const ReaderPageTheme(
          panelBackground: Color(0xFFFFFFFF),
          panelText: Color(0xFF000000),
          pageBackdrop: Color(0xFF000000),
        );
      case ReaderColorMode.normal:
        return const ReaderPageTheme(
          panelBackground: Color(0xFFFFF8E1),
          panelText: Color(0xFF2D3748),
          pageBackdrop: Color(0xFF000000),
        );
    }
  }
}

ColorFilter colorFilterForMode(ReaderColorMode mode) {
  switch (mode) {
    case ReaderColorMode.night:
      return const ColorFilter.matrix([
        0.6, 0, 0, 0, 0,
        0, 0.55, 0, 0, 0,
        0, 0, 0.5, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    case ReaderColorMode.sepia:
      return const ColorFilter.matrix([
        0.9, 0.1, 0, 0, 20,
        0.05, 0.85, 0.05, 0, 10,
        0, 0.1, 0.75, 0, 5,
        0, 0, 0, 1, 0,
      ]);
    case ReaderColorMode.contrast:
      return const ColorFilter.matrix([
        1.4, 0, 0, 0, -20,
        0, 1.4, 0, 0, -20,
        0, 0, 1.4, 0, -20,
        0, 0, 0, 1, 0,
      ]);
    case ReaderColorMode.normal:
      return const ColorFilter.matrix([
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
      ]);
  }
}

/// Painel de acessibilidade (paridade com `AccessibilityBar.jsx` do Play).
class AnimatedReaderAccessibilityPanel extends StatelessWidget {
  const AnimatedReaderAccessibilityPanel({
    super.key,
    required this.fontSize,
    required this.colorMode,
    required this.isSpeaking,
    required this.onFontSizeChanged,
    required this.onColorModeChanged,
    required this.onSpeakToggle,
  });

  final double fontSize;
  final ReaderColorMode colorMode;
  final bool isSpeaking;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<ReaderColorMode> onColorModeChanged;
  final VoidCallback onSpeakToggle;

  static const _modes = [
    (ReaderColorMode.normal, 'Normal', Icons.wb_sunny_outlined),
    (ReaderColorMode.night, 'Noturno', Icons.nightlight_round),
    (ReaderColorMode.sepia, 'Sépia', Icons.visibility_outlined),
    (ReaderColorMode.contrast, 'Contraste', Icons.contrast),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 12,
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: Container(
        width: 260,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFF9F7AEA).withAlpha(51)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'TAMANHO DO TEXTO',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _roundBtn(
                  icon: Icons.remove,
                  onTap: () => onFontSizeChanged((fontSize - 2).clamp(12, 40)),
                ),
                Expanded(
                  child: Text(
                    '${fontSize.toInt()}px',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _roundBtn(
                  icon: Icons.add,
                  onTap: () => onFontSizeChanged((fontSize + 2).clamp(12, 40)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'MODO DE COR',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes.map((m) {
                final selected = colorMode == m.$1;
                return InkWell(
                  onTap: () => onColorModeChanged(m.$1),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF9F7AEA)
                          : const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          m.$3,
                          size: 16,
                          color: selected ? Colors.white : Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          m.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: selected ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text(
              'NARRAÇÃO DE VOZ',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Colors.grey,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: onSpeakToggle,
              style: FilledButton.styleFrom(
                backgroundColor:
                    isSpeaking ? const Color(0xFFFC8181) : const Color(0xFF48BB78),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: Icon(isSpeaking ? Icons.volume_off : Icons.volume_up),
              label: Text(
                isSpeaking ? 'Parar Narração' : 'Ler em Voz Alta',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _roundBtn({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: const Color(0xFFF0F4FF),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, color: const Color(0xFF4299E1), size: 20),
        ),
      ),
    );
  }
}
