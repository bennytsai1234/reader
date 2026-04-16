import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/services/audio_play_service.dart';
import 'audio_player_utils.dart';

class AudioPlayerSlider extends StatelessWidget {
  final AudioPlayService audioService;

  const AudioPlayerSlider({super.key, required this.audioService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: audioService.player.positionStream,
      builder: (context, snapshot) {
        final position = snapshot.data ?? Duration.zero;
        final duration = audioService.player.duration ?? Duration.zero;
        return Column(
          children: [
            Slider(
              value: position.inMilliseconds.toDouble(),
              max: duration.inMilliseconds.toDouble().clamp(0, double.infinity),
              onChanged: (v) => audioService.seek(Duration(milliseconds: v.toInt())),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(AudioPlayerUtils.formatDuration(position), style: const TextStyle(fontSize: 12)),
                  Text(AudioPlayerUtils.formatDuration(duration), style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

