import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../services/book_offline_session.dart';

/// Imagem de livro: ficheiro local (offline) ou rede.
class OfflineBookImage extends StatelessWidget {
  const OfflineBookImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.errorBuilder,
    this.loadingBuilder,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final ImageErrorWidgetBuilder? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;

  @override
  Widget build(BuildContext context) {
    final resolved = BookOfflineSession.resolve(url);
    if (resolved.isEmpty) {
      return errorBuilder?.call(context, Object(), StackTrace.current) ??
          const SizedBox.shrink();
    }

    if (BookOfflineSession.isLocalPath(resolved)) {
      final path = resolved.startsWith('file://')
          ? Uri.parse(resolved).toFilePath()
          : resolved;
      return Image.file(
        File(path),
        fit: fit,
        width: width,
        height: height,
        alignment: alignment,
        errorBuilder: errorBuilder ??
            (_, __, ___) => const Icon(Icons.broken_image, color: Colors.white54),
      );
    }

    // Rede: usa cache em disco/memória (evita rebaixar a cada rebuild).
    return CachedNetworkImage(
      imageUrl: resolved,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      errorWidget: (context, _, error) =>
          errorBuilder?.call(context, error, StackTrace.current) ??
          const Icon(Icons.broken_image, color: Colors.white54),
    );
  }
}
