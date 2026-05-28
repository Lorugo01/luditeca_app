import 'package:get/get.dart';
import '../../../core/models/book_model.dart';
import '../../../core/services/luditeca_api_service.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../book/pages/book_details_page.dart';

enum LibraryBookFilter { all, animated, interactive, digital }

class LibraryController extends GetxController {
  final LuditecaApiService _api = LuditecaApiService();
  final favoritesController = Get.find<FavoritesController>();

  final RxList<BookModel> allBooks = <BookModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final RxString searchQuery = ''.obs;
  final Rx<LibraryBookFilter> activeFilter = LibraryBookFilter.all.obs;

  static const int booksPerShelf = 6;

  @override
  void onInit() {
    super.onInit();
    loadBooks();
  }

  Future<void> loadBooks() async {
    try {
      isLoading.value = true;
      error.value = '';
      final response = await _api.getBooks();
      allBooks.value = response
          .map((json) => BookModel.fromJson(json))
          .where((b) => b.title.trim().isNotEmpty)
          .toList();
    } catch (e) {
      error.value = 'Erro ao carregar livros: $e';
    } finally {
      isLoading.value = false;
    }
  }

  List<BookModel> get filteredBooks {
    final q = searchQuery.value.trim().toLowerCase();
    return allBooks.where((book) {
      if (!_matchesFilter(book)) return false;
      if (q.isEmpty) return true;
      final title = book.title.toLowerCase();
      final author = (book.author ?? '').toLowerCase();
      final desc = (book.description ?? '').toLowerCase();
      return title.contains(q) || author.contains(q) || desc.contains(q);
    }).toList();
  }

  List<List<BookModel>> get bookShelves {
    final books = filteredBooks;
    final shelves = <List<BookModel>>[];
    for (var i = 0; i < books.length; i += booksPerShelf) {
      final end = (i + booksPerShelf > books.length) ? books.length : i + booksPerShelf;
      shelves.add(books.sublist(i, end));
    }
    return shelves;
  }

  bool _matchesFilter(BookModel book) {
    switch (activeFilter.value) {
      case LibraryBookFilter.animated:
        return book.kind == BookKind.animated || book.kind == BookKind.legacy;
      case LibraryBookFilter.interactive:
        return book.kind == BookKind.interactive;
      case LibraryBookFilter.digital:
        return book.kind == BookKind.digital;
      case LibraryBookFilter.all:
        return true;
    }
  }

  void setFilter(LibraryBookFilter filter) {
    activeFilter.value = filter;
  }

  void setSearch(String value) {
    searchQuery.value = value;
  }

  void openBook(BookModel book) {
    Get.to(() => BookDetailsPage(book: book.toJson()));
  }

  void toggleFavorite(BookModel book) {
    favoritesController.toggleFavorite(book);
  }

  bool isFavorite(BookModel book) {
    return favoritesController.isFavorite(book);
  }
}
