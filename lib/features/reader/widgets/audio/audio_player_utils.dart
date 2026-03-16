import 'package:flutter/material.dart';
import 'package:legado_reader/core/services/audio_play_service.dart';

class AudioPlayerUtils {
  static String formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$minutes:$seconds";
  }

  static Widget getPlayModeIcon(AudioPlayMode mode) {
    switch (mode) {
      case AudioPlayMode.listLoop: return const Icon(Icons.repeat);
      case AudioPlayMode.singleLoop: return const Icon(Icons.repeat_one);
      case AudioPlayMode.shuffle: return const Icon(Icons.shuffle);
      case AudioPlayMode.listEndStop: return const Icon(Icons.trending_flat);
    }
  }
}

