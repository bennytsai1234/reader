import 'dart:async';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';

class ReaderTtsController {
  final TTSService tts = TTSService();
  double rate = 1.0;
  double pitch = 1.0;

  void toggleTts({
    required List<TextPage> pages,
    required int currentPageIndex,
    required Function onNextPage,
    required Future<void> Function() onNextChapter,
  }) {
    if (tts.isPlaying) {
      tts.stop();
    } else {
      final text = pages.sublist(currentPageIndex).map((p) {
        return p.lines.where((l) => !l.isTitle).map((l) => l.text).join('');
      }).join('\n');

      tts.onComplete = () {
        if (currentPageIndex < pages.length - 1) {
          onNextPage();
        } else {
          onNextChapter();
        }
      };
      tts.speak(text);
    }
  }

  void stop() => tts.stop();
  bool get isPlaying => tts.isPlaying;
}

