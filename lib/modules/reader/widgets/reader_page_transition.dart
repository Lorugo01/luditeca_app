import 'package:flutter/material.dart';

import '../models/book_element.dart';

/// Transição entre páginas conforme metadados do livro (ex.: PPTX).
Widget buildReaderPageTransition({
  required BookPageTransition transition,
  required Animation<double> animation,
  required Widget child,
}) {
  final t = transition.type.toLowerCase();
  final dir = (transition.direction ?? '').toLowerCase();
  final curved = CurvedAnimation(
    parent: animation,
    curve: Curves.easeInOutCubic,
  );

  switch (t) {
    case 'esmaecer':
    case 'fade':
    case 'dissolve':
      return FadeTransition(opacity: curved, child: child);
    case 'push':
      final begin = _offsetForPush(dir);
      return SlideTransition(
        position: Tween<Offset>(begin: begin, end: Offset.zero).animate(curved),
        child: child,
      );
    case 'reveal':
      return SlideTransition(
        position: Tween<Offset>(
          begin: _offsetForPush(dir),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.92, end: 1).animate(curved),
          child: child,
        ),
      );
    case 'wipe':
    case 'uncover':
    case 'cover':
      return SlideTransition(
        position: Tween<Offset>(
          begin: _offsetForWipe(dir, t),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      );
    case 'split':
      return FadeTransition(
        opacity: Tween<double>(begin: 0.85, end: 1).animate(curved),
        child: child,
      );
    case 'zoom':
    case 'zoom_in':
      return ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
        alignment: Alignment.center,
        child: FadeTransition(opacity: curved, child: child),
      );
    case 'morph':
      return FadeTransition(
        opacity: Tween<double>(begin: 0.96, end: 1).animate(curved),
        child: child,
      );
    case 'flash':
      return FadeTransition(
        opacity: TweenSequence<double>([
          TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.85), weight: 1),
          TweenSequenceItem(tween: Tween(begin: 0.85, end: 1.0), weight: 2),
        ]).animate(curved),
        child: child,
      );
    case 'shreds':
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 0.75, end: 1).animate(curved),
          child: child,
        ),
      );
    case 'none':
    default:
      return child;
  }
}

Offset _offsetForPush(String dir) {
  switch (dir) {
    case 'l':
    case 'left':
      return const Offset(1, 0);
    case 'r':
    case 'right':
      return const Offset(-1, 0);
    case 'u':
    case 'up':
    case 't':
    case 'top':
      return const Offset(0, 1);
    case 'd':
    case 'down':
    case 'b':
    case 'bottom':
      return const Offset(0, -1);
    default:
      return const Offset(1, 0);
  }
}

Offset _offsetForWipe(String dir, String type) {
  final invert = type == 'cover';
  var o = _offsetForPush(dir);
  if (invert) {
    o = Offset(-o.dx, -o.dy);
  }
  return o;
}
