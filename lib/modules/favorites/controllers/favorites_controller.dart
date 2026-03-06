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
        debugPrint('FavoritesController: Usuário não autenticado');
        return;
      }

      debugPrint(
        'FavoritesController: Carregando favoritos para usuário: $userId',
      );

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
      debugPrint('FavoritesController: IDs dos favoritos: $favoriteIds');

      if (favoriteIds.isEmpty) {
        debugPrint('FavoritesController: Nenhum favorito encontrado');
        favoriteBooks.clear();
        return;
      }

      // Busca os livros favoritos
      final booksResponse = await supabase
          .from('books')
          .select('*')
          .inFilter('id', favoriteIds);

      debugPrint('FavoritesController: Resposta dos livros: $booksResponse');

      final List<BookModel> loadedBooks = [];
      for (final bookData in booksResponse) {
        try {
          final book = BookModel.fromJson(bookData);
          book.isFavorite = true;
          loadedBooks.add(book);
          debugPrint('FavoritesController: Livro carregado: ${book.title}');
        } catch (e) {
          debugPrint('FavoritesController: Erro ao processar livro: $e');
        }
      }

      favoriteBooks.value = loadedBooks;
      debugPrint(
        'FavoritesController: Total de favoritos carregados: ${favoriteBooks.length}',
      );
    } catch (e) {
      error.value = 'Erro ao carregar favoritos: $e';
      debugPrint('FavoritesController: Erro ao carregar favoritos: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFavorite(BookModel book) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        error.value = 'Usuário não autenticado';
        debugPrint(
          'FavoritesController: Usuário não autenticado ao tentar favoritar',
        );
        return;
      }

      debugPrint(
        'FavoritesController: Verificando se livro ${book.id} já é favorito',
      );
      final isCurrentlyFavorite = isFavorite(book);
      debugPrint('FavoritesController: Livro é favorito? $isCurrentlyFavorite');

      // Busca os favoritos atuais do usuário
      final userResponse =
          await supabase
              .from('profiles')
              .select('favorites')
              .eq('id', userId)
              .single();

      List<int> favoriteIds = List<int>.from(userResponse['favorites'] ?? []);

      if (isCurrentlyFavorite) {
        debugPrint('FavoritesController: Removendo livro dos favoritos');
        // Remove o ID do livro da lista de favoritos
        favoriteIds.remove(book.id);
        favoriteBooks.removeWhere((b) => b.id == book.id);
        book.isFavorite = false;
      } else {
        debugPrint('FavoritesController: Adicionando livro aos favoritos');
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
      debugPrint('FavoritesController: Erro ao atualizar favoritos: $e');
      rethrow;
    }
  }

  bool isFavorite(BookModel book) {
    final result = favoriteBooks.any((b) => b.id == book.id);
    debugPrint(
      'FavoritesController: Verificando se livro ${book.id} é favorito: $result',
    );
    return result;
  }
}
