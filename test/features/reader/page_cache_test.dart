import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_layout.dart';
import 'package:inkpage_reader/features/reader/engine/page_cache.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

TextLine _line({
  required String text,
  required int start,
  required int end,
  required double top,
  required double bottom,
}) {
  return TextLine(
    text: text,
    chapterIndex: 2,
    lineIndex: start,
    width: 120,
    height: bottom - top,
    chapterPosition: start,
    lineTop: top,
    lineBottom: bottom,
    startCharOffset: start,
    endCharOffset: end,
  );
}

void main() {
  group('PageCache render model', () {
    test('ChapterLayout exposes page caches from grouped text pages', () {
      final firstLine = _line(
        text: 'title',
        start: 0,
        end: 5,
        top: 0,
        bottom: 24,
      );
      final secondLine = _line(
        text: 'body',
        start: 7,
        end: 11,
        top: 0,
        bottom: 24,
      );
      final layout = ChapterLayout(
        chapterIndex: 2,
        displayText: 'title\n\nbody',
        contentHash: 'hash',
        layoutSignature: 'sig',
        contentHeight: 240,
        lines: <TextLine>[
          firstLine,
          secondLine.copyWith(lineTop: 120, lineBottom: 144, baseline: 136),
        ],
        pages: <TextPage>[
          TextPage(
            pageIndex: 0,
            chapterIndex: 2,
            startCharOffset: 0,
            endCharOffset: 5,
            localStartY: 0,
            localEndY: 120,
            width: 180,
            contentHeight: 120,
            viewportHeight: 160,
            hasExplicitLocalRange: true,
            lines: <TextLine>[firstLine],
          ),
          TextPage(
            pageIndex: 1,
            chapterIndex: 2,
            startCharOffset: 7,
            endCharOffset: 11,
            localStartY: 120,
            localEndY: 240,
            width: 180,
            contentHeight: 120,
            viewportHeight: 160,
            hasExplicitLocalRange: true,
            lines: <TextLine>[secondLine],
          ),
        ],
      );

      final caches = layout.pageCaches;

      expect(caches, hasLength(2));
      expect(caches.first.chapterIndex, 2);
      expect(caches.first.pageIndexInChapter, 0);
      expect(caches.first.startCharOffset, 0);
      expect(caches.first.endCharOffset, 5);
      expect(caches.first.localStartY, 0);
      expect(caches.first.localEndY, 120);
      expect(caches.first.width, 180);
      expect(caches.first.height, 160);
      expect(caches.first.lines.single, same(firstLine));
      expect(caches.last.pageIndexInChapter, 1);
      expect(caches.last.lines.single, same(secondLine));
    });

    test('PageCache queries line and range data without placement fields', () {
      final page = PageCache(
        chapterIndex: 1,
        pageIndexInChapter: 3,
        startCharOffset: 10,
        endCharOffset: 18,
        localStartY: 240,
        localEndY: 360,
        width: 200,
        height: 160,
        lines: <TextLine>[
          _line(text: 'abcd', start: 10, end: 14, top: 0, bottom: 24),
          _line(text: 'efgh', start: 14, end: 18, top: 28, bottom: 52),
        ],
      );

      expect(page.containsCharOffset(10), isTrue);
      expect(page.containsCharOffset(18), isFalse);
      expect(page.containsLocalY(300), isTrue);
      expect(page.lineForCharOffset(15)!.text, 'efgh');
      expect(page.lineAtOrNearLocalY(268)!.text, 'efgh');
      expect(page.linesForRange(12, 16).map((line) => line.text), [
        'abcd',
        'efgh',
      ]);

      final rects = page.fullLineRectsForRange(
        startCharOffset: 12,
        endCharOffset: 16,
        pageTopOnScreen: 40,
      );
      expect(rects, hasLength(2));
      expect(rects.first.left, 0);
      expect(rects.first.right, 200);
      expect(rects.first.top, 40);
    });

    test('scroll and slide placement are separated from page data', () {
      final page = PageCache(
        chapterIndex: 0,
        pageIndexInChapter: 1,
        startCharOffset: 20,
        endCharOffset: 40,
        localStartY: 120,
        localEndY: 240,
        width: 180,
        height: 160,
        lines: const <TextLine>[],
      );

      final scroll = ScrollPagePlacement(page: page, virtualTop: -80);
      final slide = SlidePagePlacement(
        page: page,
        virtualLeft: 320,
        pageSlot: 1,
      );

      expect(scroll.screenY(30), -110);
      expect(slide.screenX(64), 256);
      expect(slide.pageSlot, 1);
      expect(page.pageIndexInChapter, 1);
    });
  });
}
