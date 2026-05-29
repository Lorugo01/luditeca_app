import 'package:flutter/material.dart';
import '../../../core/layout/app_layout_tokens.dart';

/// Fundo com padrão de semicírculos (paridade com Library.jsx do Play).
class LibraryPatternBackground extends StatelessWidget {
  const LibraryPatternBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipBehavior: Clip.hardEdge,
      child: CustomPaint(
        painter: _SemicirclePatternPainter(
          baseColor: AppLayoutTokens.scaffoldBackground,
          dotColor: Colors.white.withAlpha(140),
        ),
        child: child,
      ),
    );
  }
}

class _SemicirclePatternPainter extends CustomPainter {
  _SemicirclePatternPainter({
    required this.baseColor,
    required this.dotColor,
  });

  final Color baseColor;
  final Color dotColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = baseColor);

    const stepX = 56.0;
    const stepY = 48.0;
    const radius = 18.0;

    final paint = Paint()..color = dotColor;

    for (var y = -radius; y < size.height + stepY; y += stepY) {
      for (var x = -radius; x < size.width + stepX; x += stepX) {
        final offsetY = ((x / stepX).floor().isEven) ? y : y + stepY / 2;
        canvas.drawArc(
          Rect.fromCircle(
            center: Offset(x + radius, offsetY + radius),
            radius: radius,
          ),
          0,
          3.14159,
          false,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
