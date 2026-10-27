import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../core/models/book_model.dart';
import '../modules/book/pages/book_details_page.dart';
import '../modules/library/widgets/cover_aspect_cache.dart';
import 'still_frame_image.dart';

class BookCard extends StatefulWidget {
  final Map<String, dynamic> book;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final bool showAuthor;
  final bool showDescription;
  final Widget? actionButton;

  const BookCard({
    super.key,
    required this.book,
    this.width,
    this.height,
    this.onTap,
    this.showAuthor = true,
    this.showDescription = false,
    this.actionButton,
  });

  @override
  State<BookCard> createState() => _BookCardState();
}

class _BookCardState extends State<BookCard> {
  double _opacity = 1.0;
  bool _isAnimating = false;

  Future<void> _preloadAndNavigate(BuildContext context) async {
    // Sem precache da capa original (até 5 MB): os detalhes usam a cache
    // de miniaturas e abrem de imediato.
    if (mounted) {
      Get.to(() => BookDetailsPage(book: widget.book));
      setState(() => _opacity = 1.0); // Reset para quando voltar
    }
  }

  void _onCardTap(BuildContext context) async {
    if (_isAnimating) return;
    setState(() {
      _opacity = 0.0;
      _isAnimating = true;
    });
    await Future.delayed(const Duration(milliseconds: 250));
    // ignore: use_build_context_synchronously
    await _preloadAndNavigate(context);
    setState(() => _isAnimating = false);
  }

  String get authorName {
    if (widget.book.containsKey('author') &&
        widget.book['author'] != null &&
        widget.book['author'].toString().trim().isNotEmpty) {
      return widget.book['author'];
    }
    if (widget.book['authors'] != null &&
        widget.book['authors'] is Map &&
        widget.book['authors']['name'] != null) {
      return widget.book['authors']['name'];
    }
    return 'Autor desconhecido';
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.book, size: 50, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = BookModel.catalogCoverOf(widget.book);
    final title = widget.book['title'] ?? 'Sem título';

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 250),
      opacity: _opacity,
      child: GestureDetector(
        onTap: widget.onTap ?? () => _onCardTap(context),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child:
                        imageUrl.isNotEmpty
                            ? StillFrameImage(
                              url: imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              cacheWidth: CoverAspectCache.thumbWidth,
                              errorWidget: _buildPlaceholder(),
                            )
                            : _buildPlaceholder(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.actionButton != null)
                  Container(
                    padding: const EdgeInsets.only(bottom: 4, right: 8),
                    alignment: Alignment.bottomRight,
                    child: widget.actionButton!,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
