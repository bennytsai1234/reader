import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';

/// ReaderTtsController - 已廢棄，TTS 邏輯已整合至 ReaderProvider
/// 保留此檔案僅為編譯相容，實際不使用
@Deprecated('Use ReaderProvider.toggleTts() and TTSService directly')
class ReaderTtsController {
  final TTSService tts = TTSService();

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
      tts.speak(text);
    }
  }

  void stop() => tts.stop();
  bool get isPlaying => tts.isPlaying;
}
