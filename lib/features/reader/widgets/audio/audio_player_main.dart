import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/services/audio_play_service.dart';
import 'audio_player_utils.dart';

class AudioPlayerMain extends StatelessWidget {
  final Book book;
  final List<BookChapter> chapters;
  final int currentIndex;
  final AudioPlayService audioService;
  final Function(int) onLoadChapter;
  final VoidCallback onShowSpeed;

  const AudioPlayerMain({
    super.key, required this.book, required this.chapters, 
    required this.currentIndex, required this.audioService, 
    required this.onLoadChapter, required this.onShowSpeed
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Hero(tag: book.bookUrl, child: ClipRRect(borderRadius: BorderRadius.circular(12), child: CachedNetworkImage(imageUrl: book.coverUrl ?? '', width: 200, height: 280, fit: BoxFit.cover, errorWidget: (_, __, ___) => const Icon(Icons.book, size: 100)))),
          const SizedBox(height: 30),
          Text(book.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text(chapters.isNotEmpty ? chapters[currentIndex].title : '', style: const TextStyle(fontSize: 16, color: Colors.grey)),
          const SizedBox(height: 40),
          _buildControls(context),
        ],
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(iconSize: 32, icon: AudioPlayerUtils.getPlayModeIcon(audioService.playMode), onPressed: audioService.nextPlayMode),
        const SizedBox(width: 16),
        IconButton(iconSize: 48, icon: const Icon(Icons.skip_previous), onPressed: currentIndex > 0 ? () => onLoadChapter(currentIndex - 1) : null),
        StreamBuilder<PlayerState>(
          stream: audioService.player.playerStateStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            final state = snapshot.data?.processingState;
            if (state == ProcessingState.loading || state == ProcessingState.buffering) return const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator());
            return GestureDetector(
              onLongPress: () => audioService.stop(),
              child: IconButton(iconSize: 72, icon: Icon(playing ? Icons.pause_circle_filled : Icons.play_circle_filled), onPressed: playing ? audioService.pause : audioService.resume),
            );
          },
        ),
        IconButton(iconSize: 48, icon: const Icon(Icons.skip_next), onPressed: currentIndex < chapters.length - 1 ? () => onLoadChapter(currentIndex + 1) : null),
        const SizedBox(width: 16),
        IconButton(iconSize: 32, icon: const Icon(Icons.speed), onPressed: onShowSpeed),
      ],
    );
  }
}

