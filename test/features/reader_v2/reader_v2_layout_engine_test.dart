import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_content.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_layout_engine.dart';
import 'package:inkpage_reader/features/reader_v2/engine/reader_v2_layout_spec.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReaderV2Content', () {
    test('normalizes raw chapter text into a single display text', () {
      final content = ReaderV2Content.fromRaw(
        chapterIndex: 3,
        title: ' 第一章 ',
        rawText: '第一段\r\n\r\n\r\n第二段  \n',
      );

      expect(content.title, '第一章');
      expect(content.paragraphs, <String>['第一段', '第二段']);
      expect(content.plainText, '第一段\n\n第二段');
      expect(content.displayText, '第一章\n\n第一段\n\n第二段');
      expect(content.bodyStartOffset, '第一章\n\n'.length);
      expect(content.contentHash, isNotEmpty);
    });
  });

  group('ReaderV2LayoutEngine', () {
    test('lays out title and paragraphs as chapter-local TextLine truth', () {
      final content = ReaderV2Content.fromRaw(
        chapterIndex: 5,
        title: '乾淨邊界',
        rawText: '第一段文字用來確認 offset。\n\n第二段文字也要接在同一份 displayText 後面。',
      );
      final layout = ReaderV2LayoutEngine().layout(content, _spec());

      expect(layout.chapterIndex, content.chapterIndex);
      expect(layout.displayText, content.displayText);
      expect(layout.contentHash, content.contentHash);
      expect(layout.lines, isNotEmpty);
      expect(layout.pages, isNotEmpty);
      expect(layout.lines.first.isTitle, isTrue);
      expect(layout.lines.first.startCharOffset, 0);

      final firstBodyLine = layout.lines.firstWhere((line) => !line.isTitle);
      expect(firstBodyLine.startCharOffset, content.bodyStartOffset);
      expect(layout.lineForCharOffset(0), layout.lines.first);
      expect(layout.lineForCharOffset(content.bodyStartOffset), firstBodyLine);

      for (var index = 0; index < layout.lines.length; index++) {
        final line = layout.lines[index];
        expect(line.chapterIndex, content.chapterIndex);
        expect(line.lineIndex, index);
        expect(line.top, greaterThanOrEqualTo(0));
        expect(line.bottom, greaterThan(line.top));
      }
    });

    test('keeps page slices as line ranges instead of copied line lists', () {
      final content = ReaderV2Content.fromRaw(
        chapterIndex: 7,
        title: '多頁切片',
        rawText: List<String>.generate(
          18,
          (index) =>
              '第$index段文字，這段內容要產生多頁，確認 page 只保存 line range，不保存另一份 lines。',
        ).join('\n\n'),
      );
      final layout = ReaderV2LayoutEngine().layout(
        content,
        _spec(width: 170, height: 150),
      );

      expect(layout.pages.length, greaterThan(1));
      for (final page in layout.pages) {
        final pageLines = layout.linesForPage(page.pageIndex);
        expect(pageLines, isNotEmpty);
        expect(pageLines.first.lineIndex, page.startLineIndex);
        expect(pageLines.last.lineIndex, page.endLineIndexExclusive - 1);
        expect(page.startCharOffset, pageLines.first.startCharOffset);
        expect(page.endCharOffset, pageLines.last.endCharOffset);

        for (final line in pageLines) {
          expect(layout.pageForLine(line), same(page));
          expect(line.top, greaterThanOrEqualTo(page.localStartY));
          expect(line.bottom, lessThanOrEqualTo(page.localEndY + 0.01));
        }
      }
    });

    test(
      'maps char offsets, ranges, and local Y through ChapterLayout only',
      () {
        final content = ReaderV2Content.fromRaw(
          chapterIndex: 8,
          title: '定位',
          rawText: '第一段文字很長很長，用來讓測試能找到 range 內的多行文字。\n\n第二段文字。',
        );
        final layout = ReaderV2LayoutEngine().layout(
          content,
          _spec(width: 150, height: 190),
        );
        final titleLine = layout.lines.firstWhere((line) => line.isTitle);
        final bodyLine = layout.lines.firstWhere((line) => !line.isTitle);

        expect(
          layout.pageForCharOffset(titleLine.startCharOffset).pageIndex,
          0,
        );
        expect(layout.lineAtOrNearLocalY(bodyLine.top + 0.1), bodyLine);
        expect(
          layout.pageForLocalY(bodyLine.top),
          layout.pageForLine(bodyLine),
        );

        final rangeLines = layout.linesForRange(
          titleLine.startCharOffset,
          bodyLine.endCharOffset,
        );
        expect(rangeLines, containsAll(<Object>[titleLine, bodyLine]));
      },
    );

    test('removes hard newline characters from rendered line text', () {
      const rawText = '第一行是來源內硬換行\n第二行要從新的 TextLine 開始。';
      final content = ReaderV2Content.fromRaw(
        chapterIndex: 9,
        title: '硬換行',
        rawText: rawText,
      );
      final layout = ReaderV2LayoutEngine().layout(content, _spec());
      final bodyLines = layout.lines.where((line) => !line.isTitle).toList();
      final newlineOffset = layout.displayText.indexOf(
        '\n',
        content.bodyStartOffset,
      );

      expect(bodyLines, isNotEmpty);
      expect(bodyLines.every((line) => !line.text.contains('\n')), isTrue);
      final hardBreakLine = layout.lineForCharOffset(newlineOffset);
      expect(bodyLines, contains(hardBreakLine));
      expect(layout.lineForCharOffset(newlineOffset + 1), isNot(hardBreakLine));
    });

    test('keeps long unspaced text within the content width', () {
      final content = ReaderV2Content.fromRaw(
        chapterIndex: 10,
        title: '',
        rawText:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      );
      final spec = _spec(width: 160, height: 220);
      final layout = ReaderV2LayoutEngine().layout(content, spec);

      expect(layout.lines.length, greaterThan(1));
      for (final line in layout.lines) {
        expect(line.width, lessThanOrEqualTo(spec.contentWidth + 0.5));
      }
    });
  });
}

ReaderV2LayoutSpec _spec({double width = 190, double height = 260}) {
  return ReaderV2LayoutSpec.fromViewport(
    viewportSize: Size(width, height),
    style: const ReaderV2LayoutStyle(
      fontSize: 18,
      lineHeight: 1.5,
      letterSpacing: 0,
      paragraphSpacing: 0.6,
      paddingTop: 12,
      paddingBottom: 12,
      paddingLeft: 16,
      paddingRight: 16,
      textIndent: 2,
    ),
  );
}
