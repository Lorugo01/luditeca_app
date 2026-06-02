import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../models/book_element.dart';
import 'audio_badge_layout.dart';
import 'audio_button_widget.dart';
import 'offline_book_image.dart';

class ImageElementWidget extends StatelessWidget {
  final BookElement element;
  final Map<String, AudioPlayer>? audioPlayers;

  const ImageElementWidget({
    super.key,
    required this.element,
    this.audioPlayers,
  });

  @override
  Widget build(BuildContext context) {
    final imageChild = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: OfflineBookImage(
          url: element.content ?? '',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: Colors.grey[300],
              child: const Icon(
                Icons.image_not_supported,
                color: Colors.white,
                size: 48,
              ),
            );
          },
        ),
      ),
    );

    final audio = element.audio?.trim();
    if (audio == null || audio.isEmpty || audioPlayers == null) {
      return imageChild;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final off = AudioBadgeLayout.outsideTopLeftFromElement(
          element,
          constraints.maxWidth,
          constraints.maxHeight,
        );
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: imageChild),
            Positioned(
              left: off.dx,
              top: off.dy,
              child: Opacity(
                opacity: (element.opacity ?? 1).clamp(0.0, 1.0),
                child: AudioButtonWidget(
                  audioUrl: audio,
                  audioPlayers: audioPlayers!,
                  elementId: element.id,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
