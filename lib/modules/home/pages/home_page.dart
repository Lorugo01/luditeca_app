import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/controllers/auth_controller.dart';
import '../../../widgets/responsive_navigation.dart';
import '../../../widgets/book_card.dart';
import '../controllers/home_controller.dart';
import '../../../modules/reader/pages/reader_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  late final HomeController homeController;

  @override
  void initState() {
    super.initState();
    Get.find<AuthController>();
    homeController = Get.put(HomeController());
    WidgetsBinding.instance.addObserver(this);

    // Executa após o primeiro build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      homeController.refreshData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Quando o app é retomado, atualiza os dados
      homeController.refreshData();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            if (isLandscape) const ResponsiveNavigation(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cabeçalho com título e barra de pesquisa
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Pesquisar',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 16,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    // Implementar lógica de pesquisa
                                  },
                                ),
                              ),
                              Icon(Icons.search, color: Colors.grey[600]),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Conteúdo principal
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () => homeController.refreshData(),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Título "Destaques"
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Center(
                                  child: Text(
                                    'Destaques',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2196F3),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Lista de destaques
                              SizedBox(
                                height: 180,
                                child: Obx(() {
                                  if (homeController.isLoading) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (homeController.error != null) {
                                    return Center(
                                      child: Text(
                                        homeController.error!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    );
                                  }

                                  if (homeController.books.isEmpty) {
                                    return const Center(
                                      child: Text('Nenhum livro encontrado'),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        homeController.books.length > 5
                                            ? 5
                                            : homeController.books.length,
                                    itemBuilder: (context, index) {
                                      final book = homeController.books[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: BookCard(
                                          book: book,
                                          width: 120,
                                          showDescription: false,
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                              const SizedBox(height: 20),
                              // Botões coloridos
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Builder(
                                  builder: (context) {
                                    final isPortrait =
                                        MediaQuery.of(context).orientation ==
                                        Orientation.portrait;
                                    if (isPortrait) {
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          _HomeButton(
                                            label: 'Todos livros',
                                            color: const Color(0xFF29B6F6),
                                            icon: Icons.menu_book,
                                            onTap: () {},
                                          ),
                                          const SizedBox(height: 12),
                                          _HomeButton(
                                            label: 'Atividades',
                                            color: const Color(0xFFFFB300),
                                            icon: Icons.extension,
                                            onTap: () {},
                                          ),
                                          const SizedBox(height: 12),
                                          _HomeButton(
                                            label: 'Sala de aula',
                                            color: const Color(0xFF1565C0),
                                            icon: Icons.class_,
                                            onTap: () {},
                                          ),
                                        ],
                                      );
                                    } else {
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            child: _HomeButton(
                                              label: 'Todos livros',
                                              color: const Color(0xFF29B6F6),
                                              icon: Icons.menu_book,
                                              onTap: () {},
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _HomeButton(
                                              label: 'Atividades',
                                              color: const Color(0xFFFFB300),
                                              icon: Icons.extension,
                                              onTap: () {},
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: _HomeButton(
                                              label: 'Sala de aula',
                                              color: const Color(0xFF1565C0),
                                              icon: Icons.class_,
                                              onTap: () {},
                                            ),
                                          ),
                                        ],
                                      );
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 24),
                              // Título "Continue de onde parou"
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Center(
                                  child: Text(
                                    'Continue de onde parou',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2196F3),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Lista de "Continue de onde parou"
                              SizedBox(
                                height: 180,
                                child: Obx(() {
                                  if (homeController.isLoadingProgress) {
                                    return const Center(
                                      child: CircularProgressIndicator(),
                                    );
                                  }

                                  if (homeController.booksInProgress.isEmpty) {
                                    return const Center(
                                      child: Text('Nenhum livro em andamento'),
                                    );
                                  }

                                  return ListView.builder(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                    scrollDirection: Axis.horizontal,
                                    itemCount:
                                        homeController.booksInProgress.length,
                                    itemBuilder: (context, index) {
                                      final book =
                                          homeController.booksInProgress[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 16,
                                        ),
                                        child: BookCard(
                                          book: book,
                                          width: 120,
                                          showDescription: false,
                                          onTap: () {
                                            // Ao clicar em um livro em progresso, abrir o leitor na página e step salvos
                                            Get.to(
                                              () => ReaderPage(
                                                bookId: book['id'].toString(),
                                                initialPage:
                                                    book['saved_page'] as int,
                                                initialStep:
                                                    book['saved_step'] as int,
                                              ),
                                              transition: Transition.fadeIn,
                                              duration: const Duration(
                                                milliseconds: 500,
                                              ),
                                              curve: Curves.easeInOut,
                                            );
                                          },
                                        ),
                                      );
                                    },
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: !isLandscape ? const ResponsiveNavigation() : null,
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _HomeButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
