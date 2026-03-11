import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/book_model.dart';
import 'package:flutter/foundation.dart';

class FavoritesController extends GetxController {
  final supabase = Supabase.instance.client;
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

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return;
      }

      // Busca os favoritos do usuário
      final userResponse =
          await supabase
              .from('profiles')
              .select('favorites')
              .eq('id', userId)
              .single();

      final List<int> favoriteIds = List<int>.from(
        userResponse['favorites'] ?? [],
      );

      if (favoriteIds.isEmpty) {
        favoriteBooks.clear();
        return;
      }

      // Busca os livros favoritos
      final booksResponse = await supabase
          .from('books')
          .select('*')
          .inFilter('id', favoriteIds);

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
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        return;
      }
      final isCurrentlyFavorite = isFavorite(book);

      // Busca os favoritos atuais do usuário
      final userResponse =
          await supabase
              .from('profiles')
              .select('favorites')
              .eq('id', userId)
              .single();

      List<int> favoriteIds = List<int>.from(userResponse['favorites'] ?? []);

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

      // Atualiza os favoritos no perfil do usuário
      await supabase
          .from('profiles')
          .update({'favorites': favoriteIds})
          .eq('id', userId);

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
