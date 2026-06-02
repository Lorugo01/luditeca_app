import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/layout/app_layout_tokens.dart';
import '../../../core/models/book_model.dart';
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
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _resolveCoverDimensions();
  }

  @override
  void didUpdateWidget(AdaptiveCoverTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.coverImage != widget.book.coverImage) {
      _disposeImageListener();
      _aspectRatio = null;
      _resolveCoverDimensions();
    }
  }

  @override
  void dispose() {
    _disposeImageListener();
    super.dispose();
  }

  void _disposeImageListener() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _imageStream = null;
    _imageListener = null;
  }

  void _resolveCoverDimensions() {
    final url = widget.book.coverImage;
    if (url == null || url.isEmpty) return;

    final provider = CachedNetworkImageProvider(url);
    _imageStream = provider.resolve(ImageConfiguration.empty);
    _imageListener = ImageStreamListener(
      (ImageInfo info, bool _) {
        final w = info.image.width.toDouble();
        final h = info.image.height.toDouble();
        if (w > 0 && h > 0 && mounted) {
          setState(() => _aspectRatio = w / h);
        }
        _disposeImageListener();
      },
      onError: (_, __) => _disposeImageListener(),
    );
    _imageStream!.addListener(_imageListener!);
  }

  @override
  Widget build(BuildContext context) {
    final cover = widget.book.coverImage ?? '';
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
                AnimatedContainer(
                  duration: const Duration(milliseconds: 280),
                  height: imageHeight,
                  color: cover.isNotEmpty ? Colors.white : AppLayoutTokens.primary.withAlpha(40),
                  padding: cover.isNotEmpty
                      ? EdgeInsets.all(CoverLayout.innerPadding(coverSize, pose))
                      : EdgeInsets.zero,
                  child: cover.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: cover,
                          fit: CoverLayout.coverFit(pose),
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.menu_book,
                            size: 36,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.menu_book, size: 36, color: Colors.white),
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
