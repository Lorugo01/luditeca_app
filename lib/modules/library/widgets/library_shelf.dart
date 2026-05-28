import 'package:flutter/material.dart';
import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/models/book_model.dart';
import 'library_layout.dart';
import 'shelf_book_cover.dart';

/// Uma prateleira de madeira com livros em fila horizontal.
class LibraryShelf extends StatelessWidget {
  const LibraryShelf({
    super.key,
    required this.books,
    required this.onBookTap,
    this.startIndex = 0,
  });

  final List<BookModel> books;
  final void Function(BookModel book) onBookTap;
  final int startIndex;

  @override
  Widget build(BuildContext context) {
    final contentWidth = MediaQuery.sizeOf(context).width;
    final coverSize = LibraryLayout.shelfCoverSize(contentWidth);
    final rowHeight = LibraryLayout.shelfRowHeight(coverSize);
    final labelWidth = LibraryLayout.titleWidthForCover(coverSize);
    final compact = LibraryLayout.isCompact(context);

    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 20 : 28),
      child: Column(
        children: [
          SizedBox(
            height: rowHeight,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
              itemCount: books.length,
              itemBuilder: (context, i) {
                final book = books[i];
                final globalIndex = startIndex + i;
                final tilt = (i - (books.length - 1) / 2) * (compact ? 0.03 : 0.04);

                return Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 2, right: compact ? 2 : 4),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ShelfBookCover(
                        book: book,
                        spineColor: ShelfBookCover.spineColorAt(globalIndex),
                        tiltRadians: tilt,
                        coverSize: coverSize,
                        onTap: () => onBookTap(book),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: labelWidth,
                        child: Text(
                          book.title,
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: compact ? 10 : 11,
                            fontWeight: FontWeight.w700,
                            color: AppLayoutTokens.textPrimary,
                            height: 1.15,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const _WoodenPlank(),
        ],
      ),
    );
  }
}

class _WoodenPlank extends StatelessWidget {
  const _WoodenPlank();

  @override
  Widget build(BuildContext context) {
    final compact = LibraryLayout.isCompact(context);

    return Column(
      children: [
        Container(
          height: compact ? 14 : 18,
          margin: EdgeInsets.symmetric(horizontal: compact ? 4 : 8),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF8B6914), Color(0xFF6B4F0F), Color(0xFF5A3E0A)],
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(89),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 24),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [_ShelfLeg(), _ShelfLeg()],
          ),
        ),
      ],
    );
  }
}

class _ShelfLeg extends StatelessWidget {
  const _ShelfLeg();

  @override
  Widget build(BuildContext context) {
    final compact = LibraryLayout.isCompact(context);

    return Container(
      width: compact ? 14 : 18,
      height: compact ? 16 : 20,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6B4F0F), Color(0xFF4A3208)],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
    );
  }
}
