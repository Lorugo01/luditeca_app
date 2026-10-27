import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Pose do livro na prateleira conforme orientação da capa.
enum CoverShelfPose {
  /// Capa vertical — livro em pé (retrato).
  standing,

  /// Capa horizontal — livro deitado na prateleira.
  lying,

  /// Proporção ~1:1.
  square,
}

/// Calcula tamanho e pose das capas a partir da proporção largura/altura.
abstract final class CoverLayout {
  static const double _defaultAspectRatio = 0.71;

  static CoverShelfPose poseForRatio(double ratio) {
    if (ratio >= 1.12) return CoverShelfPose.lying;
    if (ratio <= 0.88) return CoverShelfPose.standing;
    return CoverShelfPose.square;
  }

  static double _maxHeight(double contentWidth) =>
      (contentWidth * 0.44).clamp(130.0, 182.0);

  static double _maxWidth(double contentWidth) =>
      (contentWidth * 0.40).clamp(110.0, 182.0);

  /// Altura útil da fila da prateleira (capa + rótulo).
  static double shelfRowHeight(double contentWidth) =>
      _maxHeight(contentWidth) + 52;

  static Size shelfSize({
    required double aspectRatio,
    required double contentWidth,
  }) {
    final maxH = _maxHeight(contentWidth);
    final maxW = _maxWidth(contentWidth);
    final ratio = aspectRatio > 0 ? aspectRatio : _defaultAspectRatio;
    final pose = poseForRatio(ratio);

    switch (pose) {
      case CoverShelfPose.standing:
        final h = maxH;
        final w = (h * ratio).clamp(68.0, maxW);
        return Size(w, h);
      case CoverShelfPose.lying:
        final w = maxW;
        final h = (w / ratio).clamp(72.0, maxH * 0.82);
        return Size(w, h);
      case CoverShelfPose.square:
        final side = math.min(maxW, maxH * 0.86).clamp(96.0, maxW);
        return Size(side, side);
    }
  }

  /// Inclinação natural na prateleira (rad), conforme pose e posição na fila.
  static double shelfTilt({
    required CoverShelfPose pose,
    required int index,
    required int count,
    bool compact = false,
  }) {
    final spread = compact ? 0.028 : 0.038;
    final center = (count - 1) / 2;
    final base = (index - center) * spread;

    return switch (pose) {
      CoverShelfPose.standing => base,
      CoverShelfPose.lying => base * 0.45 - 0.035,
      CoverShelfPose.square => base * 0.65,
    };
  }

  /// Padding interior do cartão (menor quando o tamanho já segue a capa).
  static double innerPadding(Size size, CoverShelfPose pose) {
    final minSide = math.min(size.width, size.height);
    return switch (pose) {
      CoverShelfPose.standing => minSide * 0.03,
      CoverShelfPose.lying => minSide * 0.025,
      CoverShelfPose.square => minSide * 0.035,
    };
  }

  static BoxFit coverFit(CoverShelfPose pose) {
    return switch (pose) {
      CoverShelfPose.standing => BoxFit.cover,
      CoverShelfPose.lying => BoxFit.contain,
      CoverShelfPose.square => BoxFit.cover,
    };
  }

  /// Tamanho da capa na página de detalhes (mesma lógica de orientação da biblioteca).
  static Size detailsCoverSize({
    required double aspectRatio,
    required double screenWidth,
  }) {
    final ratio = aspectRatio > 0 ? aspectRatio : _defaultAspectRatio;
    final pose = poseForRatio(ratio);
    final maxH = (screenWidth * 0.52).clamp(220.0, 340.0);
    final maxW = (screenWidth * 0.78).clamp(260.0, 520.0);

    return switch (pose) {
      CoverShelfPose.standing => () {
        final h = maxH;
        final w = (h * ratio).clamp(150.0, maxW * 0.58);
        return Size(w, h);
      }(),
      CoverShelfPose.lying => () {
        final w = maxW;
        final h = (w / ratio).clamp(140.0, maxH * 0.78);
        return Size(w, h);
      }(),
      CoverShelfPose.square => () {
        final side = math.min(maxW * 0.62, maxH * 0.88).clamp(200.0, 300.0);
        return Size(side, side);
      }(),
    };
  }

  /// Tamanho da capa no ecrã de preparação do livro (antes de abrir o leitor).
  static Size loadingCoverSize({required double aspectRatio}) {
    final ratio = aspectRatio > 0 ? aspectRatio : _defaultAspectRatio;
    final pose = poseForRatio(ratio);
    const maxH = 150.0;
    const maxW = 220.0;

    return switch (pose) {
      CoverShelfPose.standing => () {
        final h = maxH;
        final w = (h * ratio).clamp(88.0, maxW * 0.55);
        return Size(w, h);
      }(),
      CoverShelfPose.lying => () {
        final w = maxW;
        final h = (w / ratio).clamp(80.0, maxH * 0.85);
        return Size(w, h);
      }(),
      CoverShelfPose.square => () {
        final side = math.min(maxW * 0.55, maxH).clamp(110.0, 140.0);
        return Size(side, side);
      }(),
    };
  }

  static double labelWidthFor(Size coverSize) => coverSize.width + 14;
}
