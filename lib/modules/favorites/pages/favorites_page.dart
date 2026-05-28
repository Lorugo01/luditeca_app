import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/models/book_model.dart';
import '../../../core/navigation/app_shell_navigator.dart';
import '../../../widgets/app_shell_layout.dart';
import '../../book/pages/book_details_page.dart';
import '../controllers/favorites_controller.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FavoritesController());

    return AppShellLayout(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0x33FF6B8A),
              Color(0x2938BDF8),
              AppLayoutTokens.scaffoldBackground,
            ],
            stops: [0.0, 0.45, 0.72],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FavoritesHeader(onBack: AppShellNavigator.goToHome),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.error.isNotEmpty) {
                    return _FavoritesErrorState(
                      message: controller.error.value,
                      onRetry: controller.loadFavorites,
                    );
                  }

                  if (controller.favoriteBooks.isEmpty) {
                    return const _FavoritesEmptyState();
                  }

                  return RefreshIndicator(
                    onRefresh: controller.loadFavorites,
                    color: AppLayoutTokens.primary,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 14,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: controller.favoriteBooks.length,
                      itemBuilder: (context, index) {
                        final book = controller.favoriteBooks[index];
                        return _FavoriteBookCard(
                          book: book,
                          onTap: () =>
                              Get.to(() => BookDetailsPage(book: book.toJson())),
                          onRemoveFavorite: () => controller.toggleFavorite(book),
                        );
                      },
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 8),
      child: Row(
        children: [
          Material(
            color: AppLayoutTokens.cardBackground,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black.withAlpha(25),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.arrow_back, color: AppLayoutTokens.textPrimary),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            '❤️ Minha Lista',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: AppLayoutTokens.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoritesEmptyState extends StatelessWidget {
  const _FavoritesEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('💔', style: TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            const Text(
              'Nenhum favorito ainda',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppLayoutTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Toque no ❤️ em qualquer livro na Biblioteca!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppLayoutTokens.textPrimary.withAlpha(153),
              ),
            ),
            const SizedBox(height: 28),
            Material(
              elevation: 6,
              shadowColor: AppLayoutTokens.primary.withAlpha(80),
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: AppShellNavigator.goToLibrary,
                child: Ink(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      colors: [AppLayoutTokens.primary, AppLayoutTokens.accent],
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  child: const Text(
                    '📚 Ir para a Biblioteca',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoritesErrorState extends StatelessWidget {
  const _FavoritesErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Tentar novamente')),
          ],
        ),
      ),
    );
  }
}

class _FavoriteBookCard extends StatelessWidget {
  const _FavoriteBookCard({
    required this.book,
    required this.onTap,
    required this.onRemoveFavorite,
  });

  final BookModel book;
  final VoidCallback onTap;
  final VoidCallback onRemoveFavorite;

  @override
  Widget build(BuildContext context) {
    final cover = book.coverImage ?? '';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppLayoutTokens.cardBackground,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B8A).withAlpha(51),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF6B8A), Color(0xFFFF4499)],
                    ),
                  ),
                  child: SizedBox(height: 4),
                ),
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (cover.isNotEmpty)
                        Image.network(
                          cover,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _coverPlaceholder(),
                        )
                      else
                        _coverPlaceholder(),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: const Color(0xFFFF6B8A),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onRemoveFavorite,
                            child: const SizedBox(
                              width: 32,
                              height: 32,
                              child: Icon(Icons.favorite, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: AppLayoutTokens.textPrimary,
                        ),
                      ),
                      Text(
                        '${book.pages.length} págs',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppLayoutTokens.primary.withAlpha(204),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder() {
    return Container(
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppLayoutTokens.primary, AppLayoutTokens.accent],
        ),
      ),
      child: const Icon(Icons.menu_book_rounded, color: Colors.white, size: 40),
    );
  }
}
