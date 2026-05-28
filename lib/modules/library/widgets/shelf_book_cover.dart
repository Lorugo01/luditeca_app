import 'package:flutter/material.dart';
import '../../../core/models/book_model.dart';

/// Capa de livro na prateleira (inspirado em ShelfBookCover.jsx).
class ShelfBookCover extends StatelessWidget {
  const ShelfBookCover({
    super.key,
    required this.book,
    required this.spineColor,
    required this.onTap,
    this.tiltRadians = 0,
    this.coverSize = const Size(118, 168),
  });

  final BookModel book;
  final Color spineColor;
  final VoidCallback onTap;
  final double tiltRadians;
  final Size coverSize;

  static const List<Color> _spinePalette = [
    Color(0xFFE8A87C),
    Color(0xFF7EC8E3),
    Color(0xFFC8E6C9),
    Color(0xFFF48FB1),
    Color(0xFFCE93D8),
    Color(0xFF80CBC4),
    Color(0xFFFFCC80),
    Color(0xFFEF9A9A),
    Color(0xFF80DEEA),
  ];

  static Color spineColorAt(int index) => _spinePalette[index % _spinePalette.length];

  @override
  Widget build(BuildContext context) {
    final coverUrl = book.coverImage;
    final w = coverSize.width;
    final h = coverSize.height;

    return Transform.rotate(
      angle: tiltRadians,
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: coverUrl != null ? Colors.white : spineColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black.withAlpha(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(56),
                blurRadius: 12,
                offset: const Offset(4, 4),
              ),
            ],
          ),
          padding: coverUrl != null ? EdgeInsets.all(w * 0.05) : EdgeInsets.zero,
          child: coverUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    coverUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => _spineFallback(w),
                  ),
                )
              : _spineFallback(w),
        ),
      ),
    );
  }

  Widget _spineFallback(double width) {
    final maxChars = width < 95 ? 14 : 22;
    final title = book.title.length > maxChars
        ? '${book.title.substring(0, maxChars)}…'
        : book.title;

    return Center(
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: width < 95 ? 9 : 10,
            fontWeight: FontWeight.w900,
            color: Colors.black.withAlpha(179),
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
