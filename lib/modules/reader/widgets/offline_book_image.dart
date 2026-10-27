import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../widgets/still_frame_image.dart';
import '../services/book_offline_session.dart';

/// Imagem de livro: ficheiro local (offline) ou rede.
///
/// Mostra logo o primeiro frame (descodificação leve). Com [animate], depois
/// de a página assentar carrega o GIF animado por baixo e troca sem piscar
/// quando o primeiro frame animado estiver pronto.
class OfflineBookImage extends StatefulWidget {
  const OfflineBookImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.errorBuilder,
    this.animate = false,
  });

  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final ImageErrorWidgetBuilder? errorBuilder;

  /// Liga a animação de GIF/WebP. Só deve ser `true` na página visível.
  final bool animate;

  @override
  State<OfflineBookImage> createState() => _OfflineBookImageState();
}

class _OfflineBookImageState extends State<OfflineBookImage> {
  /// Limite do lado maior descodificado (px físicos).
  static const int _maxDecodePx = 1024;

  /// Espera antes de animar: deixa terminar a transição de página.
  static const Duration _settleDelay = Duration(milliseconds: 350);

  /// Intervalo entre tentativas quando todas as vagas de animação estão ocupadas.
  static const Duration _retryDelay = Duration(milliseconds: 600);

  /// GIFs a animar ao mesmo tempo na app inteira (cada um descodifica
  /// frames continuamente; aparelhos fracos não aguentam muitos).
  static const int _maxAnimating = 3;
  static int _animatingCount = 0;

  /// Tentativas (~12 s) à espera do frame estático antes de desistir.
  static const int _maxPendingChecks = 20;

  Timer? _timer;
  int _pendingChecks = 0;
  String? _animatedPath;
  ImageProvider? _animatedProvider;
  int? _providerDecode;
  bool _holdsSlot = false;
  int _generation = 0;

  String get _resolved => BookOfflineSession.resolve(widget.url);

  @override
  void initState() {
    super.initState();
    _scheduleAnimation();
  }

  @override
  void didUpdateWidget(OfflineBookImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url || oldWidget.animate != widget.animate) {
      _stopAnimation();
      _scheduleAnimation();
    }
  }

  @override
  void dispose() {
    _stopAnimation();
    super.dispose();
  }

  void _scheduleAnimation({Duration delay = _settleDelay}) {
    _timer?.cancel();
    if (!widget.animate || _resolved.isEmpty) return;
    final generation = _generation;
    _timer = Timer(delay, () => _startAnimation(generation));
  }

  Future<void> _startAnimation(int generation) async {
    if (!mounted || generation != _generation || !widget.animate) return;
    // «Reduzir movimento» do sistema: fica no frame estático.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;

    final location = _resolved;
    final isAnimated = StillFrameCache.instance.peekAnimated(location);
    if (isAnimated == null) {
      // O frame estático ainda não foi descodificado; tenta mais tarde
      // (desiste se a descodificação falhou).
      if (++_pendingChecks <= _maxPendingChecks) {
        _scheduleAnimation(delay: _retryDelay);
      }
      return;
    }
    if (!isAnimated) return;

    if (_animatingCount >= _maxAnimating) {
      _scheduleAnimation(delay: _retryDelay);
      return;
    }
    _animatingCount++;
    _holdsSlot = true;

    try {
      final path = await StillFrameCache.instance.filePath(location);
      if (!mounted || generation != _generation) {
        _releaseSlot();
        return;
      }
      setState(() => _animatedPath = path);
    } catch (e) {
      debugPrint('OfflineBookImage: GIF animado indisponível — $e');
      _releaseSlot();
    }
  }

  /// Pára a animação e liberta o codec (o GIF inteiro fica em memória nativa
  /// enquanto o provider estiver na ImageCache).
  void _stopAnimation() {
    _generation++;
    _pendingChecks = 0;
    _timer?.cancel();
    _timer = null;
    _animatedProvider?.evict();
    _animatedProvider = null;
    _providerDecode = null;
    _animatedPath = null;
    _releaseSlot();
  }

  void _releaseSlot() {
    if (!_holdsSlot) return;
    _holdsSlot = false;
    _animatingCount = math.max(0, _animatingCount - 1);
  }

  /// Provider estável entre rebuilds: um novo a cada build reiniciaria o GIF.
  ImageProvider _providerFor(String path, int decode) {
    final current = _animatedProvider;
    if (current != null && _providerDecode == decode) return current;
    current?.evict();
    _providerDecode = decode;
    return _animatedProvider = ResizeImage(
      FileImage(File(path)),
      width: decode,
      height: decode,
      policy: ResizeImagePolicy.fit,
      allowUpscaling: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = _resolved;
    if (resolved.isEmpty) {
      return widget.errorBuilder?.call(context, Object(), StackTrace.current) ??
          const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final decode = _decodeSize(context, constraints);
        final fallback =
            widget.errorBuilder?.call(context, Object(), StackTrace.current) ??
            const Icon(Icons.broken_image, color: Colors.white54);

        final still = StillFrameImage(
          url: resolved,
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          cacheWidth: decode,
          alignment: widget.alignment,
          errorWidget: fallback,
        );

        final path = _animatedPath;
        if (path == null) return still;

        return Image(
          image: _providerFor(path, decode),
          fit: widget.fit,
          width: widget.width,
          height: widget.height,
          alignment: widget.alignment,
          filterQuality: FilterQuality.low,
          gaplessPlayback: true,
          // Até o primeiro frame animado chegar, continua o estático.
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            return frame == null ? still : child;
          },
          errorBuilder: (_, __, ___) => still,
        );
      },
    );
  }

  /// Maior lado da área disponível em px físicos — cobre `contain` e `cover`.
  int _decodeSize(BuildContext context, BoxConstraints constraints) {
    final screen = MediaQuery.sizeOf(context);
    final w = constraints.hasBoundedWidth ? constraints.maxWidth : screen.width;
    final h =
        constraints.hasBoundedHeight ? constraints.maxHeight : screen.height;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final px = (math.max(w, h) * dpr).round();
    return StillFrameCache.bucketWidth(px.clamp(256, _maxDecodePx));
  }
}
