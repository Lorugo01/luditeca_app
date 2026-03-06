import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../widgets/responsive_navigation.dart';
import '../../../widgets/book_card.dart';
import '../controllers/favorites_controller.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    final controller = Get.put(FavoritesController());

    return Scaffold(
      body: Row(
        children: [
          if (orientation == Orientation.landscape)
            const ResponsiveNavigation(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Favoritos',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
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
                              onPressed: controller.loadFavorites,
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (controller.favoriteBooks.isEmpty) {
                      return const Center(
                        child: Text('Nenhum livro favorito encontrado'),
                      );
                    }

                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 280,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              scrollDirection: Axis.horizontal,
                              itemCount: controller.favoriteBooks.length,
                              itemBuilder: (context, index) {
                                final book = controller.favoriteBooks[index];
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: BookCard(
                                    book: book.toJson(),
                                    width: 160,
                                    showDescription: false,
                                    actionButton: IconButton(
                                      onPressed:
                                          () => controller.toggleFavorite(book),
                                      icon: const Icon(
                                        Icons.favorite,
                                        color: Colors.red,
                                      ),
                                      style: IconButton.styleFrom(
                                        backgroundColor: Colors.black.withAlpha(
                                          200,
                                        ),
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
