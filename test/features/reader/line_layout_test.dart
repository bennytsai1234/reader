import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/engine/line_layout.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

TextLine _line({
  required String text,
  required int chapterPosition,
  required double top,
  required double bottom,
}) {
  return TextLine(
    text: text,
    width: 100,
    height: bottom - top,
    chapterPosition: chapterPosition,
    lineTop: top,
    lineBottom: bottom,
  );
}

void main() {
  group('LineLayout', () {
    test('fromPages produces ordered line items with absolute offsets', () {
      final pages = <TextPage>[
        TextPage(
          index: 0,
          title: 'c0',
          chapterIndex: 0,
          lines: [
            _line(text: 'aaaa', chapterPosition: 0, top: 0, bottom: 40),
            _line(text: 'bbbb', chapterPosition: 4, top: 40, bottom: 90),
          ],
        ),
        TextPage(
          index: 1,
          title: 'c0',
          chapterIndex: 0,
          lines: [_line(text: 'cccc', chapterPosition: 8, top: 0, bottom: 60)],
        ),
      ];

      final layout = LineLayout.fromPages(pages);

      expect(layout.items.map((item) => item.chapterIndex), [0, 0, 0]);
      expect(layout.items.map((item) => item.chapterPosition), [0, 4, 8]);
      expect(layout.items.map((item) => item.localTop), [0, 40, 90]);
      expect(layout.contentHeight, 150);
    });

    test(
      'charOffset and localOffset resolve to the first visible text line',
      () {
        final layout = LineLayout.fromPages([
          TextPage(
            index: 0,
            title: 'c0',
            chapterIndex: 0,
            lines: [
              _line(text: '', chapterPosition: 0, top: 0, bottom: 20),
              _line(text: 'aaaa', chapterPosition: 0, top: 20, bottom: 60),
              _line(text: 'bbbb', chapterPosition: 4, top: 60, bottom: 100),
            ],
          ),
        ]);

        expect(layout.charOffsetFromLocalOffset(10), 0);
        expect(layout.charOffsetFromLocalOffset(65), 4);
        expect(layout.localOffsetForCharOffset(2), 20);
        expect(layout.localOffsetForCharOffset(4), 60);
      },
    );

    test('page lookup uses page groups as render output only', () {
      final pages = <TextPage>[
        TextPage(
          index: 0,
          title: 'c0',
          chapterIndex: 0,
          lines: [_line(text: 'aaaa', chapterPosition: 0, top: 0, bottom: 40)],
        ),
        TextPage(
          index: 1,
          title: 'c0',
          chapterIndex: 0,
          lines: [_line(text: 'bbbb', chapterPosition: 4, top: 0, bottom: 40)],
        ),
      ];
      final layout = LineLayout.fromPages(pages);

      expect(layout.pageGroups, hasLength(2));
      expect(layout.pageGroups[1].items.single.chapterPosition, 4);
      expect(layout.findPageIndexByCharOffset(4), 1);
      expect(layout.charOffsetForPageIndex(1), 4);
    });

    test(
      'line end uses next source offset instead of rendered indent width',
      () {
        final layout = LineLayout.fromPages([
          TextPage(
            index: 0,
            title: 'c0',
            chapterIndex: 0,
            lines: [
              TextLine(
                text: '　　abcd',
                width: 100,
                height: 40,
                chapterPosition: 0,
                lineTop: 0,
                lineBottom: 40,
                isParagraphStart: true,
              ),
              _line(text: 'efgh', chapterPosition: 4, top: 40, bottom: 80),
            ],
          ),
        ]);

        expect(layout.items.first.endChapterPosition, 4);
        expect(layout.localOffsetForCharOffset(4), 40);
      },
    );

    test('title-only lines participate in durable charOffset lookup', () {
      final layout = LineLayout.fromPages([
        TextPage(
          index: 0,
          title: 'c0',
          chapterIndex: 0,
          lines: [
            TextLine(
              text: '很長很長的章節標題',
              width: 100,
              height: 40,
              isTitle: true,
              chapterPosition: 0,
              lineTop: 0,
              lineBottom: 40,
              startCharOffset: 0,
              endCharOffset: 8,
            ),
          ],
        ),
        TextPage(
          index: 1,
          title: 'c0',
          chapterIndex: 0,
          lines: [
            _line(text: '正文第一行', chapterPosition: 10, top: 0, bottom: 40),
          ],
        ),
      ]);

      expect(layout.findPageIndexByCharOffset(0), 0);
      expect(layout.findPageIndexByCharOffset(10), 1);
      expect(layout.localOffsetForCharOffset(0), 0);
      expect(layout.localOffsetForCharOffset(10), 40);
      expect(layout.charOffsetFromLocalOffset(10), 0);
      expect(layout.charOffsetFromLocalOffset(45), 10);
    });
  });
}
