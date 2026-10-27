import 'package:flutter/material.dart';

import '../../../core/models/book_model.dart';
import '../../../widgets/still_frame_image.dart';
import 'cover_aspect_cache.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAspect();
  }

  @override
  void didUpdateWidget(ShelfBookCover oldWidget) {
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
    final coverUrl = widget.book.catalogCover;
    final w = size.width;
    final h = size.height;

    return Transform.rotate(
      angle: tilt,
      alignment: Alignment.bottomCenter,
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          width: w,
          height: h,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: coverUrl != null ? Colors.white : widget.spineColor,
              borderRadius: BorderRadius.circular(
                pose == CoverShelfPose.lying ? 10 : 12,
              ),
              border: Border.all(color: Colors.black.withAlpha(26)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(
                    pose == CoverShelfPose.lying ? 45 : 56,
                  ),
                  blurRadius: pose == CoverShelfPose.lying ? 10 : 12,
                  offset: Offset(pose == CoverShelfPose.lying ? 2 : 4, 4),
                ),
              ],
            ),
            child: Padding(
              padding: coverUrl != null ? EdgeInsets.all(padding) : EdgeInsets.zero,
              child: coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: StillFrameImage(
                        url: coverUrl,
                        fit: CoverLayout.coverFit(pose),
                        width: double.infinity,
                        height: double.infinity,
                        cacheWidth: CoverAspectCache.thumbWidth,
                        errorWidget: _spineFallback(w, pose),
                      ),
                    )
                  : _spineFallback(w, pose),
            ),
          ),
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
