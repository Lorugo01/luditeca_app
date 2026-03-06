import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/book_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/services/supabase_service.dart';
import 'package:flutter/foundation.dart';
import '../../favorites/controllers/favorites_controller.dart';

class CategoryBooksController extends GetxController {
  final SupabaseService _supabaseService = Get.find<SupabaseService>();
  final CategoryModel category;
  final supabase = Supabase.instance.client;
  final favoritesController = Get.find<FavoritesController>();

  CategoryBooksController({required this.category});

  final RxList<BookModel> books = <BookModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      isLoading.value = true;
      error.value = '';

      debugPrint('=== Iniciando busca de livros ===');
      debugPrint('Categoria: ID=${category.id}, Nome=${category.name}');

      // Query modificada para garantir o filtro correto por categoria
      final response = await _supabaseService.client
          .from('books')
          .select('*, categories!inner(*)')
          .eq('categories.id', category.id)
          .order('title');

      debugPrint('Resposta bruta do Supabase: $response');

      if (response.isEmpty) {
        debugPrint('Lista vazia retornada do Supabase');
        books.value = [];
        return;
      }

      debugPrint('Número de registros retornados: ${response.length}');

      final List<BookModel> loadedBooks = [];
      for (final json in response) {
        try {
          debugPrint('Processando livro: $json');
          final book = BookModel.fromJson(json);
          loadedBooks.add(book);
          debugPrint('Livro adicionado: ${book.title}');
        } catch (e) {
          debugPrint('Erro ao processar livro: $e');
        }
      }

      books.value = loadedBooks;
      debugPrint('Total de livros carregados: ${books.length}');

      // Atualiza o estado de favorito para cada livro
      for (var book in books) {
        book.isFavorite = favoritesController.isFavorite(book);
      }
    } catch (e, stackTrace) {
      error.value = 'Erro ao carregar livros: $e';
      debugPrint('Erro ao carregar livros: $e');
      debugPrint('Stack trace: $stackTrace');
    } finally {
      isLoading.value = false;
      debugPrint('=== Fim da busca de livros ===');
    }
  }

  void toggleFavorite(BookModel book) {
    favoritesController.toggleFavorite(book);
    // Atualiza o estado de favorito do livro na lista
    final index = books.indexWhere((b) => b.id == book.id);
    if (index != -1) {
      books[index].isFavorite = favoritesController.isFavorite(book);
      books.refresh(); // Notifica os widgets que a lista foi atualizada
    }
  }
}
