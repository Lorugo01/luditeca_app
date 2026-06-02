import 'package:flutter/material.dart';

/// Grelhas de capas de livro com limite de largura por célula (desktop / ecrãs largos).
abstract final class BookCoverGridDelegate {
  static const double _spacing = 14;

  static double _tileWidth(
    BuildContext context, {
    required double phone,
    required double tablet,
    required double desktop,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (w >= 1200) return desktop;
    if (w >= 600) return tablet;
    return phone;
  }

  static SliverGridDelegate _responsive({
    required double maxTileWidth,
    required double childAspectRatio,
    double spacing = _spacing,
  }) {
    return SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: maxTileWidth,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      childAspectRatio: childAspectRatio,
    );
  }

  /// Favoritos («Minha Lista»).
  static SliverGridDelegate favorites(BuildContext context) {
    return _responsive(
      maxTileWidth: _tileWidth(
        context,
        phone: 158,
        tablet: 168,
        desktop: 188,
      ),
      childAspectRatio: 0.62,
    );
  }

  /// Biblioteca — modo grelha densa.
  static SliverGridDelegate libraryDense(BuildContext context) {
    return _responsive(
      maxTileWidth: _tileWidth(
        context,
        phone: 118,
        tablet: 136,
        desktop: 156,
      ),
      childAspectRatio: 0.55,
      spacing: 12,
    );
  }

  /// Biblioteca — modo capas grandes.
  static SliverGridDelegate libraryCovers(BuildContext context) {
    return _responsive(
      maxTileWidth: _tileWidth(
        context,
        phone: 158,
        tablet: 176,
        desktop: 196,
      ),
      childAspectRatio: 0.72,
      spacing: 12,
    );
  }
}
