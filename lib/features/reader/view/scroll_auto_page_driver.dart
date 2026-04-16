import 'package:flutter/scheduler.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/provider/reader_provider_base.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';

class ScrollAutoPageDriver {
  ScrollAutoPageDriver({
    required this.createTicker,
    required this.isMounted,
    required this.scrollToChapterLocalOffset,
  });

  final Ticker Function(TickerCallback onTick) createTicker;
  final bool Function() isMounted;
  final void Function({
    required int chapterIndex,
    required double localOffset,
    required bool animate,
  }) scrollToChapterLocalOffset;

  Ticker? _ticker;
  Duration _lastTickTime = Duration.zero;

  void sync(ReaderProvider provider) {
    if (_shouldRun(provider)) {
      _start(provider);
    } else {
      stop();
    }
  }

  void stop() {
    _ticker?.stop();
    _ticker?.dispose();
    _ticker = null;
    _lastTickTime = Duration.zero;
  }

  bool _shouldRun(ReaderProvider provider) {
    return provider.isAutoPaging &&
        !provider.isAutoPagePaused &&
        provider.pageTurnMode == PageAnim.scroll;
  }

  void _start(ReaderProvider provider) {
    if (_ticker != null) return;
    _lastTickTime = Duration.zero;
    _ticker = createTicker((elapsed) {
      if (!isMounted()) {
        stop();
        return;
      }
      if (!_shouldRun(provider)) {
        stop();
        return;
      }
      if (_lastTickTime == Duration.zero) {
        _lastTickTime = elapsed;
        return;
      }
      final dtSeconds =
          (elapsed.inMicroseconds - _lastTickTime.inMicroseconds) / 1000000.0;
      _lastTickTime = elapsed;
      final step = provider.evaluateScrollAutoPageStep(dtSeconds);
      if (step == null) return;
      if (!step.advanceChapter &&
          step.chapterIndex != null &&
          step.localOffset != null) {
        scrollToChapterLocalOffset(
          chapterIndex: step.chapterIndex!,
          localOffset: step.localOffset!,
          animate: false,
        );
      } else if (step.advanceChapter) {
        provider.nextChapter(reason: ReaderCommandReason.autoPage);
      }
    });
    _ticker!.start();
  }
}
