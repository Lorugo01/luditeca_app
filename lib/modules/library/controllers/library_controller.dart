import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/models/book_model.dart';
import '../../../core/models/category_model.dart';
import '../pages/category_books_page.dart';
import '../controllers/category_books_controller.dart';
import '../../favorites/controllers/favorites_controller.dart';

class LibraryController extends GetxController {
  final supabase = Supabase.instance.client;
  final RxList<CategoryModel> categories = <CategoryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;
  final favoritesController = Get.find<FavoritesController>();

  @override
  void onInit() {
    super.onInit();
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      error.value = '';

      final response = await supabase.from('categories').select().order('name');

      categories.value =
          (response as List)
              .map((json) => CategoryModel.fromJson(json))
              .toList();
    } catch (e) {
      error.value = 'Erro ao carregar categorias: $e';
    } finally {
      isLoading.value = false;
    }
  }

  void navigateToCategoryBooks(CategoryModel category) {
    if (Get.isRegistered<CategoryBooksController>(
      tag: category.id.toString(),
    )) {
      Get.delete<CategoryBooksController>(tag: category.id.toString());
    }
    Get.to(
      () => CategoryBooksPage(category: category),
      transition: Transition.rightToLeft,
    );
  }

  void toggleFavorite(BookModel book) {
    favoritesController.toggleFavorite(book);
  }

  bool isFavorite(BookModel book) {
    return favoritesController.isFavorite(book);
  }
}
