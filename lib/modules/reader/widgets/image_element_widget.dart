import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/book_element.dart';

class ImageElementWidget extends StatelessWidget {
  final BookElement element;
  final Map<String, AudioPlayer> audioPlayers;

  const ImageElementWidget({
    super.key,
    required this.element,
    required this.audioPlayers,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          element.content ?? '',
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
    if (element.audio != null && element.audio!.isNotEmpty) {
      imageWidget = Stack(
        children: [
          imageWidget,
          Positioned(top: 4, right: 4, child: _buildAudioButton(context)),
        ],
      );
    }
    return imageWidget;
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
}
