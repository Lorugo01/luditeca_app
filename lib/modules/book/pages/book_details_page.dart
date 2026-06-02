import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/models/book_model.dart';
import '../../../core/preferences/app_preferences_controller.dart';
import '../../../core/services/luditeca_api_service.dart';
import '../../../core/utils/app_messenger.dart';
import '../../favorites/controllers/favorites_controller.dart';
import '../../library/widgets/library_pattern_background.dart';
import '../../reader/utils/reading_progress_helper.dart';

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
    if (prefs.containsKey(cacheKey)) return;
    try {
      final apiService = LuditecaApiService();
      final response = await apiService.getBookById(bookId);
      if (response != null && response['pages'] != null) {
        await prefs.setString(cacheKey, response['pages'].toString());
      }
    } catch (e) {
      debugPrint('Erro ao pré-carregar páginas do livro: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await favoritesController.toggleFavorite(bookModel);
      setState(() {
        isFavorite = favoritesController.isFavorite(bookModel);
      });
      AppMessenger.success(
        isFavorite
            ? 'Livro adicionado aos favoritos'
            : 'Livro removido dos favoritos',
      );
    } catch (e) {
      AppMessenger.error('Não foi possível atualizar os favoritos: $e');
    }
  }

  Future<void> _onStartReadingWithFlip() async {
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
    return Obx(_buildBody);
  }

  Widget _buildBody() {
    if (Get.isRegistered<AppPreferencesController>()) {
      Get.find<AppPreferencesController>().appThemeId.value;
    }

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

    return Scaffold(
      backgroundColor: AppLayoutTokens.scaffoldBackground,
      body: LibraryPatternBackground(
        child: Stack(
          children: [
            _DetailsBackground(),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _DetailsHeader(onBack: () => Get.back()),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _CoverSection(
                            imageUrl: imageUrl.toString(),
                            flipAnimation: _flipAnimation,
                            fadeAnimation: _fadeAnimation,
                            placeholder: _buildPlaceholder(),
                          ),
                          const SizedBox(height: 20),
                          _ActionButtons(
                            isFlipping: _isFlipping,
                            isFavorite: isFavorite,
                            onRead: _onStartReadingWithFlip,
                            onFavorite: _toggleFavorite,
                          ),
                          const SizedBox(height: 24),
                          _InfoCard(
                            title: title.toString(),
                            authorName: authorName,
                            ageRange: ageRange,
                            description: description.toString(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppLayoutTokens.elevatedSurface,
      child: Center(
        child: Icon(
          Icons.menu_book_rounded,
          size: 88,
          color: AppLayoutTokens.primary.withAlpha(120),
        ),
      ),
    );
  }
}

class _DetailsBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppLayoutTokens.primary.withAlpha(56),
            AppLayoutTokens.accent.withAlpha(40),
            Colors.transparent,
          ],
          stops: const [0.0, 0.4, 0.85],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: _bubble(140, AppLayoutTokens.primary.withAlpha(64)),
          ),
          Positioned(
            bottom: 80,
            left: -40,
            child: _bubble(160, AppLayoutTokens.accent.withAlpha(48)),
          ),
        ],
      ),
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 16, 4),
      child: Row(
        children: [
          Material(
            color: AppLayoutTokens.cardBackground,
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black.withAlpha(28),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: AppLayoutTokens.textPrimary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '📖 Detalhes do livro',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppLayoutTokens.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverSection extends StatelessWidget {
  const _CoverSection({
    required this.imageUrl,
    required this.flipAnimation,
    required this.fadeAnimation,
    required this.placeholder,
  });

  final String imageUrl;
  final Animation<double> flipAnimation;
  final Animation<double> fadeAnimation;
  final Widget placeholder;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: fadeAnimation,
            builder: (context, child) {
              return Opacity(opacity: fadeAnimation.value, child: child);
            },
            child: Container(
              height: 280,
              width: 200,
              decoration: BoxDecoration(
                color: AppLayoutTokens.cardBackground,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppLayoutTokens.subtleBorder),
                boxShadow: [
                  BoxShadow(
                    color: AppLayoutTokens.primary.withAlpha(36),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: flipAnimation,
            builder: (context, child) {
              final angle = flipAnimation.value * 1.2;
              return Transform(
                alignment: Alignment.centerLeft,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: child,
              );
            },
            child: Container(
              height: 280,
              width: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppLayoutTokens.primary.withAlpha(48),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(AppLayoutTokens.isDark ? 80 : 45),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => placeholder,
                      )
                    : placeholder,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isFlipping,
    required this.isFavorite,
    required this.onRead,
    required this.onFavorite,
  });

  final bool isFlipping;
  final bool isFavorite;
  final VoidCallback onRead;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final readButton = _ThemedActionButton(
      label: 'Começar a ler',
      icon: Icons.menu_book_rounded,
      background: AppLayoutTokens.primary,
      onPressed: isFlipping ? null : onRead,
    );

    final favButton = _ThemedActionButton(
      label: isFavorite ? 'Remover dos Favoritos' : 'Salvar nos Favoritos',
      icon: isFavorite ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
      background: isFavorite ? AppLayoutTokens.secondary : AppLayoutTokens.accent,
      onPressed: onFavorite,
    );

    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          readButton,
          const SizedBox(height: 12),
          favButton,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: readButton),
        const SizedBox(width: 12),
        Expanded(child: favButton),
      ],
    );
  }
}

class _ThemedActionButton extends StatelessWidget {
  const _ThemedActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color background;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      shadowColor: background.withAlpha(120),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.authorName,
    required this.ageRange,
    required this.description,
  });

  final String title;
  final String authorName;
  final String? ageRange;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppLayoutTokens.elevatedSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppLayoutTokens.subtleBorder),
        boxShadow: [
          BoxShadow(
            color: AppLayoutTokens.primary.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppLayoutTokens.textPrimary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            authorName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppLayoutTokens.elevatedSurfaceMuted,
            ),
          ),
          if (ageRange != null && ageRange!.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppLayoutTokens.primary.withAlpha(28),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.child_care_outlined,
                    size: 20,
                    color: AppLayoutTokens.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Faixa etária: $ageRange',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppLayoutTokens.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          Text(
            'Descrição',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppLayoutTokens.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: AppLayoutTokens.elevatedSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}
