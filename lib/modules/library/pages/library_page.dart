import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/layout/app_layout_tokens.dart';
import '../../../widgets/app_shell_layout.dart';
import '../controllers/library_controller.dart';
import '../widgets/library_header.dart';
import '../widgets/library_pattern_background.dart';
import '../widgets/library_books_body.dart';

/// Biblioteca em estilo prateleira (paridade com `cheerful-mundo-ludico-play`).
class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(LibraryController());

    return AppShellLayout(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LibraryHeader(controller: controller),
          Expanded(
            child: LibraryPatternBackground(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (controller.error.isNotEmpty) {
                  return _ErrorState(
                    message: controller.error.value,
                    onRetry: controller.loadBooks,
                  );
                }

                final books = controller.filteredBooks;
                if (books.isEmpty) {
                  return _EmptyState(
                    hasSearch: controller.searchQuery.value.trim().isNotEmpty,
                  );
                }

                return LibraryBooksBody(
                  controller: controller,
                  books: books,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch});

  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('📖', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(
              hasSearch ? 'Nenhum livro encontrado' : 'Nenhum livro na biblioteca',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppLayoutTokens.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasSearch
                  ? 'Tente outro termo ou altere o filtro.'
                  : 'Quando houver livros publicados, eles aparecem aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppLayoutTokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
