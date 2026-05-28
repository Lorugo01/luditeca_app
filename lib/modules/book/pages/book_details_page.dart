import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../reader/utils/reading_progress_helper.dart';
import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/models/book_model.dart';
import '../../favorites/controllers/favorites_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/luditeca_api_service.dart';
class BookDetailsPage extends StatefulWidget {
  final Map<String, dynamic> book;

  const BookDetailsPage({super.key, required this.book});

  @override
  State<BookDetailsPage> createState() => _BookDetailsPageState();
}

class _BookDetailsPageState extends State<BookDetailsPage>
    with SingleTickerProviderStateMixin {
  late final FavoritesController favoritesController;
  late final BookModel bookModel;
  bool isFavorite = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  late Animation<double> _fadeAnimation;
  bool _isFlipping = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _preloadBookPages();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _flipController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    if (!Get.isRegistered<FavoritesController>()) {
      Get.lazyPut(() => FavoritesController(), fenix: true);
    }
    favoritesController = Get.find<FavoritesController>();
    bookModel = BookModel.fromJson(widget.book);
    isFavorite = favoritesController.isFavorite(bookModel);
  }

  Future<void> _preloadBookPages() async {
    final bookId = widget.book['id'].toString();
    final prefs = await SharedPreferences.getInstance();
    final cacheKey = 'book_pages_$bookId';
    // Se já existe cache, não faz nada
    if (prefs.containsKey(cacheKey)) return;
    try {
      final apiService = LuditecaApiService();
      final response = await apiService.getBookById(bookId);
      if (response != null && response['pages'] != null) {
        // Salvar em cache local
        await prefs.setString(cacheKey, response['pages'].toString());
      }
    } catch (e) {
      debugPrint('Erro ao pré-carregar páginas do livro: $e');
    }
  }

  void _toggleFavorite() async {
    try {
      await favoritesController.toggleFavorite(bookModel);
      setState(() {
        isFavorite = favoritesController.isFavorite(bookModel);
      });

      Get.snackbar(
        'Sucesso',
        isFavorite
            ? 'Livro adicionado aos favoritos'
            : 'Livro removido dos favoritos',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Não foi possível atualizar os favoritos: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  void _onStartReadingWithFlip() async {
    if (_isFlipping) return;
    setState(() => _isFlipping = true);
    await _flipController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    await _navigateWithTransition();
    if (mounted) {
      setState(() => _isFlipping = false);
      _flipController.reset();
    }
  }

  Future<void> _navigateWithTransition() async {
    final saved = await ReadingProgressHelper.getPosition(bookModel.id);
    await openBookForReading(widget.book, position: saved);
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.book['cover_image'] ?? '';
    final title = widget.book['title'] ?? 'Sem título';
    final description =
        widget.book['description'] ?? 'Sem descrição disponível';

    String authorName = 'Autor desconhecido';
    if (widget.book['authors'] != null && widget.book['authors'] is Map) {
      authorName = widget.book['authors']['name'] ?? 'Autor desconhecido';
    }

    final ageRange = bookModel.ageRange ??
        (widget.book['age_range'] ?? widget.book['ageRange'])?.toString().trim();

    final textColor = Colors.black87;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Get.back(),
        ),
        title: Text('Voltar', style: TextStyle(color: textColor, fontSize: 16)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Capa do livro animada com página atrás
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Página de livro atrás
                    AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeAnimation.value,
                          child: child,
                        );
                      },
                      child: Container(
                        height: 300,
                        width: 220,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1), // cor de papel
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(60),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Capa do livro
                    AnimatedBuilder(
                      animation: _flipAnimation,
                      builder: (context, child) {
                        final angle = _flipAnimation.value * 1.2; // ~69 graus
                        return Transform(
                          alignment: Alignment.centerLeft,
                          transform:
                              Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateY(angle),
                          child: child,
                        );
                      },
                      child: Container(
                        height: 300,
                        width: 220,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(100),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child:
                              imageUrl.isNotEmpty
                                  ? Image.network(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildPlaceholder(),
                                  )
                                  : _buildPlaceholder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Botões
              Builder(
                builder: (context) {
                  final isPortrait =
                      MediaQuery.of(context).orientation ==
                      Orientation.portrait;
                  if (isPortrait) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ElevatedButton.icon(
                          onPressed:
                              _isFlipping ? null : _onStartReadingWithFlip,
                          icon: const Icon(Icons.menu_book),
                          label: const Text(
                            'Começar a ler',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF4A261),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            isFavorite ? Icons.bookmark : Icons.bookmark_border,
                            color: Colors.white,
                          ),
                          label: Text(
                            isFavorite
                                ? 'Remover dos Favoritos'
                                : 'Salvar nos Favoritos',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                isFavorite
                                    ? const Color(0xFFE76F51)
                                    : const Color(0xFF64C8C8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed:
                                _isFlipping ? null : _onStartReadingWithFlip,
                            icon: const Icon(Icons.menu_book),
                            label: const Text(
                              'Começar a ler',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF4A261),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _toggleFavorite,
                            icon: Icon(
                              isFavorite
                                  ? Icons.bookmark
                                  : Icons.bookmark_border,
                              color: Colors.white,
                            ),
                            label: Text(
                              isFavorite
                                  ? 'Remover dos Favoritos'
                                  : 'Salvar nos Favoritos',
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  isFavorite
                                      ? const Color(0xFFE76F51)
                                      : const Color(0xFF64C8C8),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
              // Título
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              // Autor
              Text(
                authorName,
                style: TextStyle(fontSize: 18, color: textColor.withAlpha(200)),
              ),
              if (ageRange != null && ageRange.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.child_care_outlined,
                      size: 20,
                      color: AppLayoutTokens.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Faixa etária: $ageRange',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor.withAlpha(220),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              // Descrição
              Text(
                'Descrição',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 16,
                  color: textColor.withAlpha(200),
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.book, size: 100, color: Colors.grey),
      ),
    );
  }
}
