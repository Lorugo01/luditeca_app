import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/models/book_model.dart';
import 'cover_layout.dart';

/// Capa na prateleira — tamanho e pose adaptados à orientação da imagem.
class ShelfBookCover extends StatefulWidget {
  const ShelfBookCover({
    super.key,
    required this.book,
    required this.spineColor,
    required this.onTap,
    required this.contentWidth,
    this.tiltRadians = 0,
    this.index = 0,
    this.count = 1,
    this.compact = false,
  });

  final BookModel book;
  final Color spineColor;
  final VoidCallback onTap;
  final double contentWidth;
  final double tiltRadians;
  final int index;
  final int count;
  final bool compact;

  static const List<Color> _spinePalette = [
    Color(0xFFE8A87C),
    Color(0xFF7EC8E3),
    Color(0xFFC8E6C9),
    Color(0xFFF48FB1),
    Color(0xFFCE93D8),
    Color(0xFF80CBC4),
    Color(0xFFFFCC80),
    Color(0xFFEF9A9A),
    Color(0xFF80DEEA),
  ];

  static Color spineColorAt(int index) =>
      _spinePalette[index % _spinePalette.length];

  @override
  State<ShelfBookCover> createState() => _ShelfBookCoverState();
}

class _ShelfBookCoverState extends State<ShelfBookCover> {
  double? _aspectRatio;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  @override
  void initState() {
    super.initState();
    _resolveCoverDimensions();
  }

  @override
  void didUpdateWidget(ShelfBookCover oldWidget) {
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
    final aspect = _aspectRatio ?? 0.71;
    final pose = CoverLayout.poseForRatio(aspect);
    final size = CoverLayout.shelfSize(
      aspectRatio: aspect,
      contentWidth: widget.contentWidth,
    );
    final tilt = widget.tiltRadians +
        CoverLayout.shelfTilt(
          pose: pose,
          index: widget.index,
          count: widget.count,
          compact: widget.compact,
        );
    final padding = CoverLayout.innerPadding(size, pose);
    final coverUrl = widget.book.coverImage;
    final w = size.width;
    final h = size.height;

    return Transform.rotate(
      angle: tilt,
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: coverUrl != null ? Colors.white : widget.spineColor,
            borderRadius: BorderRadius.circular(pose == CoverShelfPose.lying ? 10 : 12),
            border: Border.all(color: Colors.black.withAlpha(26)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(pose == CoverShelfPose.lying ? 45 : 56),
                blurRadius: pose == CoverShelfPose.lying ? 10 : 12,
                offset: Offset(pose == CoverShelfPose.lying ? 2 : 4, 4),
              ),
            ],
          ),
          padding: coverUrl != null ? EdgeInsets.all(padding) : EdgeInsets.zero,
          child: coverUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: coverUrl,
                    fit: CoverLayout.coverFit(pose),
                    width: double.infinity,
                    height: double.infinity,
                    errorWidget: (_, __, ___) => _spineFallback(w, pose),
                  ),
                )
              : _spineFallback(w, pose),
        ),
      ),
    );
  }

  Widget _spineFallback(double width, CoverShelfPose pose) {
    final maxChars = width < 95 ? 14 : 22;
    final title = widget.book.title.length > maxChars
        ? '${widget.book.title.substring(0, maxChars)}…'
        : widget.book.title;

    if (pose == CoverShelfPose.lying) {
      return Center(
        child: Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: width < 95 ? 9 : 10,
            fontWeight: FontWeight.w900,
            color: Colors.black.withAlpha(179),
            height: 1.2,
          ),
        ),
      );
    }

    return Center(
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: width < 95 ? 9 : 10,
            fontWeight: FontWeight.w900,
            color: Colors.black.withAlpha(179),
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
