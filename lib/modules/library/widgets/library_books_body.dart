import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/layout/book_cover_grid.dart';
import '../../../core/models/book_model.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../controllers/library_controller.dart';
import 'library_layout.dart';
import 'library_shelf.dart';
import 'adaptive_cover_tile.dart';

enum _GridLayout { dense, covers }

/// Corpo da biblioteca conforme layout escolhido nas configurações.
class LibraryBooksBody extends StatelessWidget {
  const LibraryBooksBody({
    super.key,
    required this.controller,
    required this.books,
  });

  final LibraryController controller;
  final List<BookModel> books;

  @override
  Widget build(BuildContext context) {
    final prefs = Get.find<AppPreferencesController>();
    final compact = MediaQuery.sizeOf(context).width < LibraryLayout.compactWidth;

    return Obx(() {
      final layoutId = prefs.libraryLayoutId.value;

      return RefreshIndicator(
        onRefresh: controller.loadBooks,
        color: AppLayoutTokens.primary,
        child: switch (layoutId) {
          'grid' => _buildGrid(context, books, layout: _GridLayout.dense),
          'covers' => _buildGrid(context, books, layout: _GridLayout.covers),
          'list' => _buildList(context, books),
          _ => _buildShelf(context, books, compact),
        },
      );
    });
  }

  Widget _buildShelf(BuildContext context, List<BookModel> books, bool compact) {
    final shelves = <List<BookModel>>[];
    for (var i = 0; i < books.length; i += LibraryController.booksPerShelf) {
      final end = (i + LibraryController.booksPerShelf > books.length)
          ? books.length
          : i + LibraryController.booksPerShelf;
      shelves.add(books.sublist(i, end));
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(compact ? 4 : 8, compact ? 12 : 16, compact ? 4 : 8, 32),
      children: [
        Center(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 16,
              vertical: compact ? 6 : 8,
            ),
            decoration: BoxDecoration(
              color: AppLayoutTokens.elevatedSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppLayoutTokens.subtleBorder),
            ),
            child: Text(
              compact
                  ? 'Toque para abrir • Deslize'
                  : 'Toque para abrir • Deslize para ver mais',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w800,
                color: AppLayoutTokens.textPrimary,
                height: 1.25,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (var si = 0; si < shelves.length; si++)
          LibraryShelf(
            books: shelves[si],
            startIndex: si * LibraryController.booksPerShelf,
            onBookTap: controller.openBook,
          ),
      ],
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<BookModel> books, {
    required _GridLayout layout,
  }) {
    final gridDelegate = switch (layout) {
      _GridLayout.dense => BookCoverGridDelegate.libraryDense(context),
      _GridLayout.covers => BookCoverGridDelegate.libraryCovers(context),
    };
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      gridDelegate: gridDelegate,
      itemCount: books.length,
      itemBuilder: (context, index) => AdaptiveCoverTile(
        book: books[index],
        onTap: () => controller.openBook(books[index]),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<BookModel> books) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 32),
      itemCount: books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final book = books[index];
        final cover = book.coverImage ?? '';
        return Material(
          color: AppLayoutTokens.cardBackground,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => controller.openBook(book),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: cover.isNotEmpty
                        ? CachedNetworkImage(imageUrl: cover, width: 56, height: 72, fit: BoxFit.cover)
                        : Container(
                            width: 56,
                            height: 72,
                            color: AppLayoutTokens.primary.withAlpha(51),
                            child: Icon(Icons.menu_book, color: AppLayoutTokens.primary),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppLayoutTokens.textPrimary,
                          ),
                        ),
                        if (book.author != null && book.author!.isNotEmpty)
                          Text(
                            book.author!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppLayoutTokens.textPrimary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: AppLayoutTokens.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
