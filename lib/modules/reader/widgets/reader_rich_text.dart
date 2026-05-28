import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import '../models/book_element.dart';

Color _parseBookColor(String? hex, Color fallback) {
  if (hex == null || hex.isEmpty) return fallback;
  try {
    final normalized = hex.replaceAll('#', '0xFF');
    return Color(int.parse(normalized));
  } catch (_) {
    return fallback;
  }
}

TextAlign _toTextAlign(String? align) {
  switch (align) {
    case 'center':
      return TextAlign.center;
    case 'right':
      return TextAlign.right;
    default:
      return TextAlign.left;
  }
}

TextDecoration _toTextDecoration(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'underline':
      return TextDecoration.underline;
    case 'line-through':
      return TextDecoration.lineThrough;
    case 'underline line-through':
      return TextDecoration.combine([
        TextDecoration.underline,
        TextDecoration.lineThrough,
      ]);
    default:
      return TextDecoration.none;
  }
}

Color _withOpacity(Color color, double? opacity) {
  final v = opacity ?? 1.0;
  final clamped = v < 0 ? 0.0 : (v > 1 ? 1.0 : v);
  return color.withAlpha((255 * clamped).round());
}

List<Shadow>? _buildShadows(BookElement element) {
  final blur = element.shadowBlur ?? 0;
  final op = element.shadowOpacity ?? 0;
  final hasShadow = blur > 0 || op > 0;
  if (!hasShadow) return null;
  final base = _parseBookColor(element.shadowColor, Colors.black);
  final c = _withOpacity(base, op <= 0 ? 0.5 : op);
  return [
    Shadow(
      color: c,
      blurRadius: blur,
      offset: Offset(element.shadowOffsetX ?? 0, element.shadowOffsetY ?? 0),
    ),
  ];
}

/// `height` no Flutter é multiplicador (ex. 1.2), não px; valores absurdos partem o layout.
double? _safeTextHeightMultiplier(double? raw) {
  if (raw == null) return null;
  if (raw >= 0.85 && raw <= 3.0) return raw;
  return null;
}

double? _safeLetterSpacing(double? raw) {
  if (raw == null) return null;
  return raw.clamp(-1.5, 8.0);
}

TextStyle _buildBaseTextStyle(BookElement element) {
  final baseColor = _parseBookColor(element.color, Colors.black);
  final effectiveColor = _withOpacity(baseColor, element.opacity);
  final strokeW = element.strokeWidth ?? 0;
  final strokeC = _parseBookColor(element.strokeColor, Colors.black);
  final hasStroke = strokeW > 0;
  return TextStyle(
    fontFamily: element.fontFamily ?? 'Roboto',
    fontSize: element.fontSize?.toDouble() ?? 16,
    fontWeight:
        element.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal,
    fontStyle:
        element.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal,
    color: effectiveColor,
    decoration: _toTextDecoration(element.textDecoration),
    height: _safeTextHeightMultiplier(element.lineHeight),
    letterSpacing: _safeLetterSpacing(element.letterSpacing),
    shadows: _buildShadows(element),
    foreground:
        hasStroke
            ? (Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = strokeW
              ..color = _withOpacity(strokeC, element.opacity))
            : null,
  );
}

/// Texto do leitor: suporta `contentSpans` (PPTX com negrito por trecho).
Widget buildReaderAutoSizeText(
  BookElement element, {
  int? maxLines,
  double minFontSize = 8,
  TextOverflow overflow = TextOverflow.visible,
}) {
  final spans = element.contentSpans;
  final baseStyle = _buildBaseTextStyle(element);
  final fallbackColor = _parseBookColor(element.color, Colors.black);
  final effectiveColor = _withOpacity(fallbackColor, element.opacity);

  if (spans != null && spans.length > 1) {
    final children = spans.map((s) {
      final fs = s.fontSize?.toDouble() ?? (element.fontSize?.toDouble() ?? 16);
      final fw = s.fontWeight == 'bold' ? FontWeight.bold : FontWeight.normal;
      final ft = s.fontStyle == 'italic' ? FontStyle.italic : FontStyle.normal;
      final col = _withOpacity(
        _parseBookColor(s.color ?? element.color, fallbackColor),
        element.opacity,
      );
      return TextSpan(
        text: s.text,
        style: baseStyle.copyWith(
          fontSize: fs,
          fontWeight: fw,
          fontStyle: ft,
          color: col,
        ),
      );
    }).toList();

    return AutoSizeText.rich(
      TextSpan(children: children),
      textAlign: _toTextAlign(element.textAlign),
      minFontSize: minFontSize,
      maxLines: maxLines,
      overflow: overflow,
      style: baseStyle,
    );
  }

  return AutoSizeText(
    element.content ?? '',
    style: baseStyle.copyWith(color: effectiveColor),
    textAlign: _toTextAlign(element.textAlign),
    minFontSize: minFontSize,
    maxLines: maxLines,
    overflow: overflow,
  );
}
