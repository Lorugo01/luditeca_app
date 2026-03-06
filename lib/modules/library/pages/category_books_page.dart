import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/models/category_model.dart';
import '../../../widgets/responsive_navigation.dart';
import '../../../widgets/book_card.dart';
import '../controllers/category_books_controller.dart';

class CategoryBooksPage extends StatelessWidget {
  final CategoryModel category;

  const CategoryBooksPage({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final controller = Get.put(CategoryBooksController(category: category));

    return Scaffold(
      appBar: AppBar(
        title: Text(category.name),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Row(
        children: [
          if (orientation == Orientation.landscape)
            const ResponsiveNavigation(),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (controller.error.isNotEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        controller.error.value,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: controller.loadBooks,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                );
              }

              if (controller.books.isEmpty) {
                return const Center(
                  child: Text('Nenhum livro encontrado nesta categoria'),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 280,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: controller.books.length,
                        itemBuilder: (context, index) {
                          final book = controller.books[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 16),
                            child: BookCard(
                              book: book.toJson(),
                              width: 160,
                              showDescription: false,
                              actionButton: IconButton(
                                onPressed:
                                    () => controller.toggleFavorite(book),
                                icon: Icon(
                                  book.isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color:
                                      book.isFavorite
                                          ? Colors.red
                                          : Colors.white,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black.withAlpha(200),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
      bottomNavigationBar:
          orientation == Orientation.portrait
              ? const ResponsiveNavigation()
              : null,
    );
  }
}
