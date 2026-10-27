import 'package:flutter/material.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/models/book_model.dart';
import '../../../widgets/still_frame_image.dart';
import 'cover_aspect_cache.dart';
import 'cover_layout.dart';

/// Tile de capa na grelha — proporção adaptada à imagem.
class AdaptiveCoverTile extends StatefulWidget {
  const AdaptiveCoverTile({
    super.key,
    required this.book,
    required this.onTap,
    this.contentWidth,
  });

  final BookModel book;
  final VoidCallback onTap;
  final double? contentWidth;

  @override
  State<AdaptiveCoverTile> createState() => _AdaptiveCoverTileState();
}

class _AdaptiveCoverTileState extends State<AdaptiveCoverTile> {
  double? _aspectRatio;

  @override
  void initState() {
    super.initState();
    _loadAspect();
  }

  @override
  void didUpdateWidget(AdaptiveCoverTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.catalogCover != widget.book.catalogCover) {
      _aspectRatio = null;
      _loadAspect();
    }
  }

  Future<void> _loadAspect() async {
    final url = widget.book.catalogCover;
    if (url == null || url.isEmpty) return;

    final cached = CoverAspectCache.peek(url);
    if (cached != null) {
      if (mounted) setState(() => _aspectRatio = cached);
      return;
    }

    final ratio = await CoverAspectCache.resolve(url);
    if (!mounted || ratio == null) return;
    setState(() => _aspectRatio = ratio);
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.book.catalogCover ?? '';
    final width = widget.contentWidth ?? MediaQuery.sizeOf(context).width;
    final aspect = _aspectRatio ?? 0.71;
    final pose = CoverLayout.poseForRatio(aspect);
    final coverSize = CoverLayout.shelfSize(
      aspectRatio: aspect,
      contentWidth: width,
    );
    final imageHeight = coverSize.height.clamp(100.0, 200.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: widget.onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: AppLayoutTokens.cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppLayoutTokens.primary.withAlpha(40),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: imageHeight,
                  child: ColoredBox(
                    color: cover.isNotEmpty
                        ? Colors.white
                        : AppLayoutTokens.primary.withAlpha(40),
                    child: Padding(
                      padding: cover.isNotEmpty
                          ? EdgeInsets.all(
                              CoverLayout.innerPadding(coverSize, pose),
                            )
                          : EdgeInsets.zero,
                      child: cover.isNotEmpty
                          ? StillFrameImage(
                              url: cover,
                              fit: CoverLayout.coverFit(pose),
                              cacheWidth: CoverAspectCache.thumbWidth,
                              errorWidget: const Icon(
                                Icons.menu_book,
                                size: 36,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.menu_book,
                              size: 36,
                              color: Colors.white,
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    widget.book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppLayoutTokens.textPrimary,
                    ),
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
