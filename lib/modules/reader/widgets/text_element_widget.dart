import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:auto_size_text/auto_size_text.dart';
import '../models/book_element.dart';

class TextElementWidget extends StatelessWidget {
  final BookElement element;
  final Map<String, AudioPlayer> audioPlayers;

  const TextElementWidget({
    super.key,
    required this.element,
    required this.audioPlayers,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(4),
      child: AutoSizeText(
        element.content ?? '',
        style: TextStyle(
          fontFamily: element.fontFamily ?? 'Roboto',
          fontSize: element.fontSize?.toDouble() ?? 16,
          fontWeight:
              element.fontWeight == 'bold'
                  ? FontWeight.bold
                  : FontWeight.normal,
          fontStyle:
              element.fontStyle == 'italic'
                  ? FontStyle.italic
                  : FontStyle.normal,
          color:
              element.color != null
                  ? Color(int.parse(element.color!.replaceAll('#', '0xFF')))
                  : Colors.black,
        ),
        textAlign: _getTextAlignment(element.textAlign),
        maxLines: 10,
        minFontSize: 8,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  TextAlign _getTextAlignment(String? align) {
    switch (align) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }
}
