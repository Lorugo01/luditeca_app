import 'dart:async';
import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Fila única de descodificação. Vários GIFs ao mesmo tempo estouram a fila
/// de mensagens do Windows (`Failed to post message to main thread`) e travam.
class StillFrameCache {
  StillFrameCache._();
  static final StillFrameCache instance = StillFrameCache._();

  /// Largura única das capas na biblioteca, para cada URL ser descodificada uma vez.
  static const int catalogWidth = 320;

  static const int _maxConcurrent = 2;

  final Map<String, ui.Image> _images = {};
  final Map<String, double> _ratios = {};
  final Map<String, int> _frameCounts = {};
  final Map<String, List<Completer<ui.Image?>>> _waiters = {};
  final Queue<_StillJob> _queue = Queue<_StillJob>();
  int _running = 0;

  /// Agrupa larguras próximas (múltiplos de 64, 64–1024) para um rebuild
  /// com tamanho ligeiramente diferente não descodificar de novo.
  static int bucketWidth(int width) {
    final clamped = width.clamp(64, 1024);
    return (clamped / 64).ceil() * 64;
  }

  ui.Image? peek(String location, int width) =>
      _images[_key(location, bucketWidth(width))];

  double? peekRatio(String location) => _ratios[location];

  /// `true` se o ficheiro tem mais de um frame (GIF/WebP animado).
  /// `null` enquanto ainda não foi descodificado.
  bool? peekAnimated(String location) {
    final count = _frameCounts[location];
    return count == null ? null : count > 1;
  }

  /// Caminho local do ficheiro (descarrega para a cache se for URL).
  Future<String> filePath(String location) => _localPath(location);

  Future<ui.Image?> load(String location, int width) {
    width = bucketWidth(width);
    final key = _key(location, width);
    final cached = _images[key];
    if (cached != null) return Future.value(cached);

    final completer = Completer<ui.Image?>();
    final waiters = _waiters.putIfAbsent(key, () => <Completer<ui.Image?>>[]);
    waiters.add(completer);
    if (waiters.length == 1) {
      _queue.add(_StillJob(location, width, key));
      _pump();
    }
    return completer.future;
  }

  String _key(String location, int width) => '$width|$location';

  void _pump() {
    if (_running >= _maxConcurrent || _queue.isEmpty) return;
    final job = _queue.removeFirst();
    _running++;
    unawaited(_run(job));
  }

  Future<void> _run(_StillJob job) async {
    ui.Image? image;
    try {
      image = await _decode(job.location, job.width);
      if (image != null && image.height > 0) {
        _images[job.key] = image;
        _ratios[job.location] = image.width / image.height;
      }
    } catch (e) {
      debugPrint('StillFrame: falha em ${job.location}: $e');
      image = null;
    } finally {
      final waiters = _waiters.remove(job.key);
      if (waiters != null) {
        for (final waiter in waiters) {
          if (!waiter.isCompleted) waiter.complete(image);
        }
      }
      _running--;
      // Intervalo curto para a thread do Windows esvaziar o PostMessage.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      _pump();
    }
  }

  Future<ui.Image?> _decode(String location, int width) async {
    final path = await _localPath(location);
    // O motor lê o ficheiro; o GIF inteiro não entra na heap do Dart.
    // O buffer é libertado por instantiateImageCodecFromBuffer.
    final buffer = await ui.ImmutableBuffer.fromFilePath(path);
    final codec = await ui.instantiateImageCodecFromBuffer(
      buffer,
      targetWidth: width,
      allowUpscaling: false,
    );
    _frameCounts[location] = codec.frameCount;
    try {
      final frame = await codec.getNextFrame();
      return frame.image;
    } finally {
      codec.dispose();
    }
  }

  Future<String> _localPath(String location) async {
    if (location.startsWith('file://')) {
      return Uri.parse(location).toFilePath();
    }
    if (!location.startsWith('http://') && !location.startsWith('https://')) {
      return location;
    }
    final file = await DefaultCacheManager().getSingleFile(location);
    return file.path;
  }
}

class _StillJob {
  const _StillJob(this.location, this.width, this.key);
  final String location;
  final int width;
  final String key;
}

/// Primeiro frame apenas, pedido pela fila partilhada.
///
/// Não usa [ImageProvider]: no Windows, um stream por capa dispara
/// «Failed to post message to main thread» quando a rota é trocada.
class StillFrameImage extends StatefulWidget {
  const StillFrameImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.cacheWidth = StillFrameCache.catalogWidth,
    this.alignment = Alignment.center,
    this.errorWidget,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int cacheWidth;
  final Alignment alignment;
  final Widget? errorWidget;

  @override
  State<StillFrameImage> createState() => _StillFrameImageState();
}

class _StillFrameImageState extends State<StillFrameImage> {
  ui.Image? _image;
  bool _failed = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    // Já em cache: pinta no primeiro frame, sem um frame vazio pelo meio.
    _image = StillFrameCache.instance.peek(widget.url.trim(), _width);
    if (_image == null) _load();
  }

  @override
  void didUpdateWidget(StillFrameImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.cacheWidth != widget.cacheWidth) {
      _load();
    }
  }

  int get _width => StillFrameCache.bucketWidth(widget.cacheWidth);

  Future<void> _load() async {
    final url = widget.url.trim();
    final request = ++_request;
    if (url.isEmpty) {
      if (mounted) setState(() => _failed = true);
      return;
    }

    final cached = StillFrameCache.instance.peek(url, _width);
    if (cached != null) {
      if (mounted) {
        setState(() {
          _image = cached;
          _failed = false;
        });
      }
      return;
    }

    final image = await StillFrameCache.instance.load(url, _width);
    if (!mounted || request != _request) return;
    setState(() {
      _image = image;
      _failed = image == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final image = _image;
    if (image == null) {
      if (_failed) {
        return widget.errorWidget ?? const Icon(Icons.broken_image);
      }
      return SizedBox(width: widget.width, height: widget.height);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : widget.width;
        final height = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : widget.height;
        return RawImage(
          image: image,
          fit: widget.fit,
          alignment: widget.alignment,
          width: width,
          height: height,
          filterQuality: FilterQuality.low,
        );
      },
    );
  }
}
