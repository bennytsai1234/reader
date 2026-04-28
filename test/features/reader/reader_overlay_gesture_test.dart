import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/engine/page_cache.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_highlight.dart';
import 'package:inkpage_reader/features/reader/viewport/reader_gesture_layer.dart';
import 'package:inkpage_reader/features/reader/viewport/tts_highlight_overlay_layer.dart';

void main() {
  group('Reader overlay and gesture layers', () {
    testWidgets('TTS overlay paints whole line rects for highlight range', (
      tester,
    ) async {
      final tile = PageCache(
        chapterIndex: 1,
        pageIndexInChapter: 0,
        startCharOffset: 10,
        endCharOffset: 34,
        localStartY: 0,
        localEndY: 160,
        width: 220,
        height: 180,
        lines: <TextLine>[
          _line(text: '第一行', start: 10, end: 16, top: 0, bottom: 24),
          _line(text: '第二行', start: 16, end: 24, top: 30, bottom: 54),
          _line(text: '第三行', start: 24, end: 34, top: 60, bottom: 84),
        ],
      );
      final paintedRects = <Rect>[];
      TtsHighlightOverlayPainter.debugOnPaintRects = (_, rects) {
        paintedRects
          ..clear()
          ..addAll(rects);
      };
      addTearDown(() {
        TtsHighlightOverlayPainter.debugOnPaintRects = null;
      });

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 220,
            height: 180,
            child: TtsHighlightOverlayLayer(
              tile: tile,
              style: _style(),
              textColor: Colors.black,
              highlight: const ReaderTtsHighlight(
                chapterIndex: 1,
                highlightStart: 14,
                highlightEnd: 28,
              ),
            ),
          ),
        ),
      );

      expect(paintedRects, hasLength(3));
      expect(paintedRects.first.left, 10);
      expect(paintedRects.first.top, 9);
      expect(paintedRects.last.bottom, 99);
    });

    testWidgets('GestureLayer routes taps only when enabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ReaderGestureLayer(
            onTapUp: (_) => taps += 1,
            child: const SizedBox(width: 120, height: 120),
          ),
        ),
      );

      await tester.tapAt(const Offset(60, 60));
      expect(taps, 1);

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: ReaderGestureLayer(
            gesturesEnabled: false,
            child: SizedBox(width: 120, height: 120),
          ),
        ),
      );

      await tester.tapAt(const Offset(60, 60));
      expect(taps, 1);
    });
  });
}

TextLine _line({
  required String text,
  required int start,
  required int end,
  required double top,
  required double bottom,
}) {
  return TextLine(
    text: text,
    width: 120,
    lineTop: top,
    lineBottom: bottom,
    chapterPosition: start,
    startCharOffset: start,
    endCharOffset: end,
  );
}

ReadStyle _style() {
  return const ReadStyle(
    fontSize: 18,
    lineHeight: 1.5,
    letterSpacing: 0,
    paragraphSpacing: 0.6,
    paddingTop: 12,
    paddingBottom: 12,
    paddingLeft: 16,
    paddingRight: 16,
    textIndent: 2,
    textFullJustify: false,
    pageMode: ReaderPageMode.scroll,
  );
}
