import 'package:get/get.dart';
import '../../../core/models/book_model.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/luditeca_api_service.dart';

class FavoritesController extends GetxController {
  final LuditecaApiService _service = LuditecaApiService();
  final RxList<BookModel> favoriteBooks = <BookModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    try {
      isLoading.value = true;
      error.value = '';

      final userId = _service.currentUser?['id']?.toString();
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return;
      }

      final booksResponse = await _service.getFavoriteBooks();
      if (booksResponse.isEmpty) {
        favoriteBooks.clear();
        return;
      }

      final List<BookModel> loadedBooks = [];
      for (final bookData in booksResponse) {
        try {
          final book = BookModel.fromJson(bookData);
          book.isFavorite = true;
          loadedBooks.add(book);
        } catch (e) {
          continue;
        }
      }

      favoriteBooks.value = loadedBooks;
    } catch (e) {
      error.value = 'Erro ao carregar favoritos: $e';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(BookModel book) async {
    try {
      final userId = _service.currentUser?['id']?.toString();
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return;
      }
      final isCurrentlyFavorite = isFavorite(book);
      final profile = await _service.getUserProfile(userId);
      List<int> favoriteIds =
          (profile?['favorites'] as List<dynamic>? ?? [])
              .map((e) => int.tryParse(e.toString()) ?? 0)
              .where((e) => e > 0)
              .toList();

      if (isCurrentlyFavorite) {
        // Remove o ID do livro da lista de favoritos
        favoriteIds.remove(book.id);
        favoriteBooks.removeWhere((b) => b.id == book.id);
        book.isFavorite = false;
      } else {
        // Adiciona o ID do livro à lista de favoritos
        favoriteIds.add(book.id);
        book.isFavorite = true;
        favoriteBooks.add(book);
      }

      await _service.setFavorites(favoriteIds);

      debugPrint(
        'FavoritesController: Total de favoritos após operação: ${favoriteBooks.length}',
      );
    } catch (e) {
      error.value = 'Erro ao atualizar favoritos: $e';
      rethrow;
    }
  }

  bool isFavorite(BookModel book) {
    return favoriteBooks.any((b) => b.id == book.id);
  }
}
