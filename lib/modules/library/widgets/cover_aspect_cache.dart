import 'dart:async';

import '../../../widgets/still_frame_image.dart';

/// Proporção das capas, medida no mesmo frame estático da biblioteca.
///
/// Não abre [ImageStream] por livro: no Windows isso gera
/// «Failed to post message to main thread» ao sair do ecrã.
abstract final class CoverAspectCache {
  static const int thumbWidth = StillFrameCache.catalogWidth;

  static final Map<String, double> _ratios = {};
  static final Map<String, Future<double?>> _inflight = {};

  static double? peek(String url) =>
      _ratios[url] ?? StillFrameCache.instance.peekRatio(url);

  static Future<double?> resolve(String url) {
    if (url.isEmpty) return Future.value(null);
    final cached = peek(url);
    if (cached != null) {
      _ratios[url] = cached;
      return Future.value(cached);
    }

    return _inflight.putIfAbsent(url, () async {
      try {
        final image = await StillFrameCache.instance.load(url, thumbWidth);
        if (image == null || image.height == 0) return null;
        final ratio = image.width / image.height;
        _ratios[url] = ratio;
        return ratio;
      } finally {
        _inflight.remove(url);
      }
    });
  }
}
