import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class AudioButtonWidget extends StatefulWidget {
  final String audioUrl;
  final Map<String, AudioPlayer> audioPlayers;
  final String elementId;

  const AudioButtonWidget({
    super.key,
    required this.audioUrl,
    required this.audioPlayers,
    required this.elementId,
  });

  @override
  State<AudioButtonWidget> createState() => _AudioButtonWidgetState();
}

class _AudioButtonWidgetState extends State<AudioButtonWidget> {
  AudioPlayer? _getAudioPlayer() {
    if (!widget.audioPlayers.containsKey(widget.elementId)) {
      final player = AudioPlayer();
      widget.audioPlayers[widget.elementId] = player;
      debugPrint('Inicializando player para áudio: ${widget.audioUrl}');
      player.setUrl(widget.audioUrl).catchError((error) {
        debugPrint('Erro ao carregar áudio: $error');
        return Duration.zero;
      });
    }
    return widget.audioPlayers[widget.elementId];
  }

  void _handleAudioTap() {
    final player = _getAudioPlayer();
    if (player == null) return;

    debugPrint('Tocando áudio: ${widget.audioUrl}');

    // Parar todos os outros players
    for (var otherPlayer in widget.audioPlayers.values) {
      if (otherPlayer != player) {
        otherPlayer.pause();
      }
    }

    // Toggle play/pause
    if (player.playing) {
      player.pause();
    } else {
      player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleAudioTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          borderRadius: BorderRadius.circular(20),
        ),
        child: StreamBuilder<PlayerState>(
          stream: _getAudioPlayer()?.playerStateStream,
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
