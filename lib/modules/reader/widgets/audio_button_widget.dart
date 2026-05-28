import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// Botão de play/pause para elementos com áudio vinculado.
/// Visual: fundo escuro com borda âmbar (consistente com o editor).
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
  static const _amber = Color(0xFFF59E0B);
  static const _amberLight = Color(0xFFFCD34D);

  AudioPlayer _getOrCreatePlayer() {
    if (!widget.audioPlayers.containsKey(widget.elementId)) {
      final player = AudioPlayer();
      widget.audioPlayers[widget.elementId] = player;
      debugPrint('Inicializando player para áudio: ${widget.audioUrl}');
      player.setUrl(widget.audioUrl).catchError((error) {
        debugPrint('Erro ao carregar áudio: $error');
        return Duration.zero;
      });
    }
    return widget.audioPlayers[widget.elementId]!;
  }

  Future<void> _handleTap() async {
    try {
      final player = _getOrCreatePlayer();

      // Parar todos os outros players antes de tocar este
      for (final other in widget.audioPlayers.values) {
        if (other != player) {
          await other.pause();
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
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF02060F).withAlpha(230),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _amber, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(100),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: StreamBuilder<PlayerState>(
          stream: widget.audioPlayers[widget.elementId]?.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            return Icon(
              playing ? Icons.pause : Icons.play_arrow,
              color: _amberLight,
              size: 20,
            );
          },
        ),
      ),
    );
  }
}
