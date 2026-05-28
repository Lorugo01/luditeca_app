import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/book_element.dart';
import 'reader_rich_text.dart';

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
      child: buildReaderAutoSizeText(
        element,
        maxLines: 10,
        minFontSize: 8,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

}
