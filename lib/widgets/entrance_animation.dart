import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Efeitos de entrada suportados (nomes vindos do editor de livros).
enum EntranceEffect {
  fade,
  fadeUp,
  fadeDown,
  fadeLeft,
  fadeRight,
  zoom,
  elastic,
  pulse,
  rubberBand,
  slideLeft,
  slideRight,
  flash,
}

/// Animação de entrada que corre uma única vez.
///
/// Substitui o `animate_do`: a versão 3.3.9 faz `print` e agenda um
/// `Future.delayed` em cada `build()`, o que satura a thread principal no
/// Windows («Failed to post message to main thread») e em aparelhos fracos.
class EntranceAnimation extends StatefulWidget {
  const EntranceAnimation({
    super.key,
    required this.effect,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
    this.distance = 40,
  });

  final EntranceEffect effect;
  final Widget child;
  final Duration duration;
  final Duration delay;

  /// Deslocamento inicial (px lógicos) dos efeitos de translação.
  final double distance;

  @override
  State<EntranceAnimation> createState() => _EntranceAnimationState();
}

class _EntranceAnimationState extends State<EntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _delayTimer;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    // Acessibilidade «reduzir movimento»: mostra o estado final sem animar.
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => _apply(_controller.value, child!),
    );
  }

  /// Estrutura fixa (Opacity + Transform) para o filho nunca ser remontado.
  Widget _apply(double t, Widget child) {
    final eased = Curves.easeOut.transform(t);
    var opacity = 1.0;
    var offset = Offset.zero;
    var scaleX = 1.0;
    var scaleY = 1.0;

    switch (widget.effect) {
      case EntranceEffect.fade:
        opacity = eased;
      case EntranceEffect.fadeUp:
        opacity = eased;
        offset = Offset(0, widget.distance * (1 - eased));
      case EntranceEffect.fadeDown:
        opacity = eased;
        offset = Offset(0, -widget.distance * (1 - eased));
      case EntranceEffect.fadeLeft:
        opacity = eased;
        offset = Offset(-widget.distance * (1 - eased), 0);
      case EntranceEffect.fadeRight:
        opacity = eased;
        offset = Offset(widget.distance * (1 - eased), 0);
      case EntranceEffect.zoom:
        opacity = eased;
        scaleX = scaleY = eased;
      case EntranceEffect.elastic:
        opacity = eased;
        scaleX = scaleY = Curves.elasticOut.transform(t);
      case EntranceEffect.pulse:
        scaleX = scaleY = 1 + 0.2 * math.sin(t * math.pi);
      case EntranceEffect.rubberBand:
        final wobble = 0.25 * math.sin(t * math.pi * 3) * (1 - t);
        scaleX = 1 + wobble;
        scaleY = 1 - wobble;
      case EntranceEffect.slideLeft:
        offset = Offset(-widget.distance * 2.5 * (1 - eased), 0);
      case EntranceEffect.slideRight:
        offset = Offset(widget.distance * 2.5 * (1 - eased), 0);
      case EntranceEffect.flash:
        opacity = (math.cos(t * math.pi * 4) + 1) / 2;
    }

    return Opacity(
      opacity: opacity.clamp(0.0, 1.0),
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.translationValues(offset.dx, offset.dy, 0)
          ..scaleByDouble(scaleX, scaleY, 1.0, 1.0),
        child: child,
      ),
    );
  }
}
