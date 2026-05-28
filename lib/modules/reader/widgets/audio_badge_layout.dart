import 'package:flutter/material.dart';

import '../models/book_element.dart';

/// Posição do botão de áudio **fora** da caixa do elemento (igual ao editor Konva).
class AudioBadgeLayout {
  AudioBadgeLayout._();

  /// Deve coincidir com o tamanho do widget [AudioButtonWidget] (36×36).
  static const double badgeDiameter = 36;

  /// Espaço entre a caixa do elemento e o badge (px) — igual a `AUDIO_BADGE_OUTSET` no JS.
  static const double outset = 4;

  static String _normalizePlacement(String? raw) {
    final s = (raw ?? '').trim().toLowerCase();
    const ok = {'nw', 'ne', 'sw', 'se', 'n', 's', 'e', 'w'};
    if (ok.contains(s)) return s;
    return 'se';
  }

  static double _clampPct(double v) => v.clamp(0.0, 100.0);

  /// Percentuais legados → preset outside mais próximo (mesmos limiares que o JS).
  static String nearestOutsidePlacement(double xPct, double yPct) {
    final x = _clampPct(xPct) / 100.0;
    final y = _clampPct(yPct) / 100.0;
    final left = x < 0.35;
    final right = x > 0.65;
    final top = y < 0.35;
    final bottom = y > 0.65;
    if (top && left) return 'nw';
    if (top && right) return 'ne';
    if (bottom && left) return 'sw';
    if (bottom && right) return 'se';
    if (top) return 'n';
    if (bottom) return 's';
    if (left) return 'w';
    if (right) return 'e';
    return x < 0.5 ? 'w' : 'e';
  }

  static String _placementForElement(BookElement e) {
    if (e.audioBadgeXPct != null && e.audioBadgeYPct != null) {
      return nearestOutsidePlacement(e.audioBadgeXPct!, e.audioBadgeYPct!);
    }
    return _normalizePlacement(e.audioBadgePlacement);
  }

  /// Canto sup. esq. do badge, totalmente fora do retângulo [0,0]×[boxW,boxH].
  static Offset outsideTopLeftForPlacement(
    String placement,
    double boxW,
    double boxH,
  ) {
    final d = badgeDiameter;
    final playR = d / 2;
    final o = outset;
    switch (_normalizePlacement(placement)) {
      case 'n':
        return Offset(boxW / 2 - playR, -d - o);
      case 's':
        return Offset(boxW / 2 - playR, boxH + o);
      case 'e':
        return Offset(boxW + o, boxH / 2 - playR);
      case 'w':
        return Offset(-d - o, boxH / 2 - playR);
      case 'nw':
        return Offset(-d - o, -d - o);
      case 'ne':
        return Offset(boxW + o, -d - o);
      case 'sw':
        return Offset(-d - o, boxH + o);
      case 'se':
      default:
        return Offset(boxW + o, boxH + o);
    }
  }

  /// Resolve [BookElement] (placement ou XPct/YPct) para offset outside.
  static Offset outsideTopLeftFromElement(
    BookElement e,
    double boxW,
    double boxH,
  ) {
    final p = _placementForElement(e);
    return outsideTopLeftForPlacement(p, boxW, boxH);
  }
}
