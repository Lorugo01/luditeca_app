import 'package:flutter/material.dart';

/// Breakpoints da biblioteca (alinhados ao Play, adaptados a janelas estreitas).
abstract final class LibraryLayout {
  static const double compactWidth = 420;
  static const double mediumWidth = 720;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compactWidth;

  static bool isMedium(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mediumWidth;

  /// Tamanho da capa na prateleira conforme largura útil.
  static Size shelfCoverSize(double contentWidth) {
    final w = (contentWidth * 0.30).clamp(80.0, 125.0);
    return Size(w, w * 1.42);
  }

  static double shelfRowHeight(Size coverSize) => coverSize.height + 52;

  static double titleWidthForCover(Size coverSize) => coverSize.width + 12;
}
