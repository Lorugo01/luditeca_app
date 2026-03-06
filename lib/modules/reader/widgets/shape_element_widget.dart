import 'package:flutter/material.dart';
import '../models/book_element.dart';
import 'package:just_audio/just_audio.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ShapeElementWidget extends StatelessWidget {
  final BookElement element;
  final Map<String, AudioPlayer> audioPlayers;

  const ShapeElementWidget({
    super.key,
    required this.element,
    required this.audioPlayers,
  });

  @override
  Widget build(BuildContext context) {
    return _renderShape(context);
  }

  Widget _renderShape(BuildContext context) {
    // Extrair propriedades do elemento
    final shapeType = element.shapeType ?? 'rectangle';
    final fill = _parseColor(element.fill ?? '#3b82f6');
    final borderColor = _parseColor(element.borderColor ?? '#2563eb');
    final borderWidth = element.borderWidth?.toDouble() ?? 2.0;
    final borderRadius = element.borderRadius?.toDouble() ?? 0.0;
    final rotation = element.rotation?.toDouble() ?? 0.0;
    final flipX = element.flipX ?? false;

    // Widget base para formas que podem conter texto
    Widget shapeWidget;

    switch (shapeType) {
      case 'rectangle':
        if (element.text?.content != null) {
          shapeWidget = Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: fill,
                  border: Border.all(color: borderColor, width: borderWidth),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(borderWidth + 8),
                child: AutoSizeText(
                  element.text!.content!,
                  style: TextStyle(
                    fontFamily: _getFontFamily(),
                    fontSize: _getFontSize(),
                    fontWeight: _getFontWeight(),
                    fontStyle: _getFontStyle(),
                    color: _getFontColor(),
                  ),
                  textAlign: _getTextAlign(),
                  maxLines: 10,
                  minFontSize: 8,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        } else {
          shapeWidget = Container(
            decoration: BoxDecoration(
              color: fill,
              border: Border.all(color: borderColor, width: borderWidth),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          );
        }
        break;

      case 'circle':
        shapeWidget = Container(
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
        );
        break;

      case 'triangle':
        shapeWidget = ClipPath(
          clipper: TriangleClipper(),
          child: Container(
            color: fill,
            child: CustomPaint(
              painter: BorderPainter(
                color: borderColor,
                strokeWidth: borderWidth,
                points: [
                  const Offset(0.5, 0),
                  const Offset(0, 1),
                  const Offset(1, 1),
                ],
              ),
            ),
          ),
        );
        break;

      case 'star':
        shapeWidget = ClipPath(
          clipper: StarClipper(),
          child: Container(
            color: fill,
            child: CustomPaint(
              painter: BorderPainter(
                color: borderColor,
                strokeWidth: borderWidth,
                points: _getStarPoints(),
              ),
            ),
          ),
        );
        break;

      case 'arrow':
        shapeWidget = ClipPath(
          clipper: ArrowClipper(),
          child: Container(
            color: fill,
            child: CustomPaint(
              painter: BorderPainter(
                color: borderColor,
                strokeWidth: borderWidth,
                points: _getArrowPoints(),
              ),
            ),
          ),
        );
        break;

      case 'line':
        shapeWidget = Center(
          child: Container(height: borderWidth, color: borderColor),
        );
        break;

      case 'speechBubbleLeft':
      case 'thoughtBubble':
      case 'shoutBubble':
      case 'ovalBubble':
        Widget bubbleWidget;

        switch (shapeType) {
          case 'speechBubbleLeft':
            bubbleWidget = Transform.rotate(
              angle: rotation * (3.14159 / 180),
              child: CustomPaint(
                painter: SpeechBubblePainter(
                  fill: fill,
                  borderColor: borderColor,
                  borderWidth: borderWidth,
                  flipX: flipX,
                ),
                child: Container(), // Garante área para o Stack
              ),
            );
            shapeWidget = Stack(
              alignment: Alignment.center,
              children: [
                bubbleWidget,
                if (element.text?.content != null)
                  Padding(
                    padding: EdgeInsets.all(borderWidth + 16),
                    child: AutoSizeText(
                      element.text!.content!,
                      style: TextStyle(
                        fontFamily: _getFontFamily(),
                        fontSize: _getFontSize(),
                        fontWeight: _getFontWeight(),
                        fontStyle: _getFontStyle(),
                        color: _getFontColor(),
                      ),
                      textAlign: _getTextAlign(),
                      maxLines: 10,
                      minFontSize: 8,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            );
            break;

          case 'thoughtBubble':
            bubbleWidget = CustomPaint(
              painter: ThoughtBubblePainter(
                fill: fill,
                borderColor: borderColor,
                borderWidth: borderWidth,
                pointPosition: element.pointPosition ?? 'bottom',
              ),
            );
            break;

          case 'shoutBubble':
            bubbleWidget = ClipPath(
              clipper: ShoutBubbleClipper(),
              child: Container(
                color: fill,
                child: CustomPaint(
                  painter: BorderPainter(
                    color: borderColor,
                    strokeWidth: borderWidth,
                    points: _getShoutBubblePoints(),
                  ),
                ),
              ),
            );
            break;

          default: // ovalBubble
            bubbleWidget = CustomPaint(
              painter: OvalBubblePainter(
                fill: fill,
                borderColor: borderColor,
                borderWidth: borderWidth,
                flipX: flipX,
                rotation: rotation,
              ),
            );
        }

        // Adiciona o texto dentro do balão
        shapeWidget = Stack(
          children: [
            bubbleWidget,
            if (element.text?.content != null)
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.all(borderWidth + 8),
                  child: AutoSizeText(
                    element.text!.content!,
                    style: TextStyle(
                      fontFamily: _getFontFamily(),
                      fontSize: _getFontSize(),
                      fontWeight: _getFontWeight(),
                      fontStyle: _getFontStyle(),
                      color: _getFontColor(),
                    ),
                    textAlign: _getTextAlign(),
                    maxLines: 10,
                    minFontSize: 8,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
          ],
        );
        break;

      default:
        shapeWidget = Container(
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: borderColor, width: borderWidth),
          ),
        );
    }

    if (element.audio != null && element.audio!.isNotEmpty) {
      shapeWidget = Stack(
        children: [
          shapeWidget,
          Positioned(top: 4, right: 4, child: _buildAudioButton(context)),
        ],
      );
    }

    return shapeWidget;
  }

  Widget _buildAudioButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          if (!audioPlayers.containsKey(element.id)) {
            final player = AudioPlayer();
            audioPlayers[element.id] = player;
            await player.setUrl(element.audio!);
          }
          final player = audioPlayers[element.id]!;
          for (var otherPlayer in audioPlayers.values) {
            if (otherPlayer != player) {
              await otherPlayer.pause();
            }
          }
          if (player.playing) {
            await player.pause();
          } else {
            await player.play();
          }
        } catch (e) {
          debugPrint('Erro ao manipular áudio: $e');
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          borderRadius: BorderRadius.circular(18),
        ),
        child: StreamBuilder<PlayerState>(
          stream: audioPlayers[element.id]?.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return Icon(
              playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 20,
            );
          },
        ),
      ),
    );
  }

  String? _getFontFamily() {
    return element.text?.fontFamily ?? element.fontFamily ?? 'Roboto';
  }

  double _getFontSize() {
    return element.text?.fontSize?.toDouble() ??
        element.fontSize?.toDouble() ??
        16;
  }

  FontWeight _getFontWeight() {
    final fw = element.text?.fontWeight ?? element.fontWeight;
    return fw == 'bold' ? FontWeight.bold : FontWeight.normal;
  }

  FontStyle _getFontStyle() {
    final fs = element.text?.fontStyle ?? element.fontStyle;
    return fs == 'italic' ? FontStyle.italic : FontStyle.normal;
  }

  Color _getFontColor() {
    final colorStr = element.text?.color ?? element.color;
    return colorStr != null ? _parseColor(colorStr) : Colors.black;
  }

  TextAlign _getTextAlign() {
    final align = element.text?.textAlign ?? element.textAlign;
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }

  Color _parseColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  List<Offset> _getStarPoints() {
    return [
      const Offset(0.50, 0.00),
      const Offset(0.61, 0.35),
      const Offset(0.98, 0.35),
      const Offset(0.68, 0.57),
      const Offset(0.79, 0.91),
      const Offset(0.50, 0.70),
      const Offset(0.21, 0.91),
      const Offset(0.32, 0.57),
      const Offset(0.02, 0.35),
      const Offset(0.39, 0.35),
    ];
  }

  List<Offset> _getArrowPoints() {
    return [
      const Offset(0.00, 0.30),
      const Offset(0.70, 0.30),
      const Offset(0.70, 0.00),
      const Offset(1.00, 0.50),
      const Offset(0.70, 1.00),
      const Offset(0.70, 0.70),
      const Offset(0.00, 0.70),
    ];
  }

  List<Offset> _getShoutBubblePoints() {
    return [
      const Offset(0.00, 0.25),
      const Offset(0.15, 0.00),
      const Offset(0.30, 0.25),
      const Offset(0.45, 0.00),
      const Offset(0.60, 0.25),
      const Offset(0.75, 0.00),
      const Offset(0.90, 0.25),
      const Offset(1.00, 0.10),
      const Offset(1.00, 0.90),
      const Offset(0.90, 0.75),
      const Offset(0.75, 1.00),
      const Offset(0.60, 0.75),
      const Offset(0.45, 1.00),
      const Offset(0.30, 0.75),
      const Offset(0.15, 1.00),
      const Offset(0.00, 0.75),
    ];
  }
}

// Clippers e Painters customizados
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width * 0.5, 0);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class StarClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final points = [
      Offset(size.width * 0.50, 0),
      Offset(size.width * 0.61, size.height * 0.35),
      Offset(size.width * 0.98, size.height * 0.35),
      Offset(size.width * 0.68, size.height * 0.57),
      Offset(size.width * 0.79, size.height * 0.91),
      Offset(size.width * 0.50, size.height * 0.70),
      Offset(size.width * 0.21, size.height * 0.91),
      Offset(size.width * 0.32, size.height * 0.57),
      Offset(size.width * 0.02, size.height * 0.35),
      Offset(size.width * 0.39, size.height * 0.35),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class ArrowClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.lineTo(size.width * 0.7, size.height * 0.3);
    path.lineTo(size.width * 0.7, 0);
    path.lineTo(size.width, size.height * 0.5);
    path.lineTo(size.width * 0.7, size.height);
    path.lineTo(size.width * 0.7, size.height * 0.7);
    path.lineTo(0, size.height * 0.7);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class BorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final List<Offset> points;

  BorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.points,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx * size.width, points[0].dy * size.height);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx * size.width, points[i].dy * size.height);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SpeechBubblePainter extends CustomPainter {
  final Color fill;
  final Color borderColor;
  final double borderWidth;
  final bool flipX;

  SpeechBubblePainter({
    required this.fill,
    required this.borderColor,
    required this.borderWidth,
    required this.flipX,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    final path = Path();
    if (flipX) {
      path.moveTo(size.width * 0.95, size.height * 0.067);
      path.lineTo(size.width * 0.05, size.height * 0.067);
      path.quadraticBezierTo(0, size.height * 0.067, 0, size.height * 0.133);
      path.lineTo(0, size.height * 0.867);
      path.quadraticBezierTo(
        0,
        size.height * 0.933,
        size.width * 0.05,
        size.height * 0.933,
      );
      path.lineTo(size.width * 0.75, size.height * 0.933);
      path.lineTo(size.width * 0.85, size.height);
      path.lineTo(size.width * 0.85, size.height * 0.933);
      path.lineTo(size.width * 0.95, size.height * 0.933);
      path.quadraticBezierTo(
        size.width,
        size.height * 0.933,
        size.width,
        size.height * 0.867,
      );
      path.lineTo(size.width, size.height * 0.133);
      path.quadraticBezierTo(
        size.width,
        size.height * 0.067,
        size.width * 0.95,
        size.height * 0.067,
      );
    } else {
      path.moveTo(size.width * 0.05, size.height * 0.067);
      path.lineTo(size.width * 0.95, size.height * 0.067);
      path.quadraticBezierTo(
        size.width,
        size.height * 0.067,
        size.width,
        size.height * 0.133,
      );
      path.lineTo(size.width, size.height * 0.867);
      path.quadraticBezierTo(
        size.width,
        size.height * 0.933,
        size.width * 0.95,
        size.height * 0.933,
      );
      path.lineTo(size.width * 0.25, size.height * 0.933);
      path.lineTo(size.width * 0.15, size.height);
      path.lineTo(size.width * 0.15, size.height * 0.933);
      path.lineTo(size.width * 0.05, size.height * 0.933);
      path.quadraticBezierTo(0, size.height * 0.933, 0, size.height * 0.867);
      path.lineTo(0, size.height * 0.133);
      path.quadraticBezierTo(
        0,
        size.height * 0.067,
        size.width * 0.05,
        size.height * 0.067,
      );
    }
    path.close();

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ThoughtBubblePainter extends CustomPainter {
  final Color fill;
  final Color borderColor;
  final double borderWidth;
  final String pointPosition;

  ThoughtBubblePainter({
    required this.fill,
    required this.borderColor,
    required this.borderWidth,
    required this.pointPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    // Desenhar círculo principal
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      borderPaint,
    );

    // Desenhar bolhas de pensamento
    switch (pointPosition) {
      case 'left':
        _drawThoughtDots(canvas, paint, borderPaint, size, -1, 0);
        break;
      case 'right':
        _drawThoughtDots(canvas, paint, borderPaint, size, 1, 0);
        break;
      default: // 'bottom'
        _drawThoughtDots(canvas, paint, borderPaint, size, 0, 1);
    }
  }

  void _drawThoughtDots(
    Canvas canvas,
    Paint fill,
    Paint border,
    Size size,
    double dx,
    double dy,
  ) {
    final dot1Center = Offset(
      size.width / 2 + (size.width * 0.4 * dx),
      size.height / 2 + (size.height * 0.4 * dy),
    );
    final dot2Center = Offset(
      size.width / 2 + (size.width * 0.6 * dx),
      size.height / 2 + (size.height * 0.6 * dy),
    );

    canvas.drawCircle(dot1Center, size.width * 0.1, fill);
    canvas.drawCircle(dot1Center, size.width * 0.1, border);
    canvas.drawCircle(dot2Center, size.width * 0.06, fill);
    canvas.drawCircle(dot2Center, size.width * 0.06, border);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class OvalBubblePainter extends CustomPainter {
  final Color fill;
  final Color borderColor;
  final double borderWidth;
  final bool flipX;
  final double rotation;

  OvalBubblePainter({
    required this.fill,
    required this.borderColor,
    required this.borderWidth,
    required this.flipX,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(rotation * (3.14159 / 180));
    canvas.translate(-size.width / 2, -size.height / 2);

    final paint =
        Paint()
          ..color = fill
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;

    // Desenhar oval principal
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.7,
    );
    canvas.drawOval(rect, paint);
    canvas.drawOval(rect, borderPaint);

    // Desenhar ponta
    final path = Path();
    final pointBaseX = flipX ? size.width * 0.25 : size.width * 0.75;
    path.moveTo(pointBaseX, size.height * 0.4);
    path.lineTo(flipX ? size.width * 0.1 : size.width * 0.9, size.height * 0.5);
    path.lineTo(pointBaseX, size.height * 0.6);

    canvas.drawPath(path, paint);
    canvas.drawPath(path, borderPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ShoutBubbleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    final points = [
      Offset(0, size.height * 0.25),
      Offset(size.width * 0.15, 0),
      Offset(size.width * 0.30, size.height * 0.25),
      Offset(size.width * 0.45, 0),
      Offset(size.width * 0.60, size.height * 0.25),
      Offset(size.width * 0.75, 0),
      Offset(size.width * 0.90, size.height * 0.25),
      Offset(size.width, size.height * 0.10),
      Offset(size.width, size.height * 0.90),
      Offset(size.width * 0.90, size.height * 0.75),
      Offset(size.width * 0.75, size.height),
      Offset(size.width * 0.60, size.height * 0.75),
      Offset(size.width * 0.45, size.height),
      Offset(size.width * 0.30, size.height * 0.75),
      Offset(size.width * 0.15, size.height),
      Offset(0, size.height * 0.75),
    ];

    path.moveTo(points[0].dx, points[0].dy);
    for (var i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
