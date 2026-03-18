import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/engine/chapter_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  BookChapter makeChapter({String title = '', int index = 0}) {
    return BookChapter(title: title, index: index);
  }

  // 極寬視窗確保段落不換行，讓 chapterPosition 計算可預測
  const wideSize = Size(100000, 100000);
  const testStyle = TextStyle(fontSize: 16, height: 1.5);

  group('ChapterProvider.paginate() - chapterPosition 計算', () {
    test('縮排段落的 chapterPosition 與無縮排相同（縮排字元不計入偏移）', () {
      final chapter = makeChapter(title: 'T'); // 1 char
      const content = 'ABC\nDEF';

      final pagesNoIndent = ChapterProvider.paginate(
        content: content,
        chapter: chapter,
        chapterIndex: 0,
        chapterSize: 1,
        viewSize: wideSize,
        titleStyle: testStyle,
        contentStyle: testStyle,
        textIndent: 0,
      );

      final pagesWithIndent = ChapterProvider.paginate(
        content: content,
        chapter: chapter,
        chapterIndex: 0,
        chapterSize: 1,
        viewSize: wideSize,
        titleStyle: testStyle,
        contentStyle: testStyle,
        textIndent: 2,
      );

      final posNoIndent = pagesNoIndent
          .expand((p) => p.lines)
          .where((l) => !l.isTitle)
          .map((l) => l.chapterPosition)
          .toList();

      final posWithIndent = pagesWithIndent
          .expand((p) => p.lines)
          .where((l) => !l.isTitle)
          .map((l) => l.chapterPosition)
          .toList();

      expect(posNoIndent.length, greaterThan(0), reason: '應有內容行');
      expect(posNoIndent.length, posWithIndent.length,
          reason: '縮排不應改變行數（視窗夠寬時）');

      for (int i = 0; i < posNoIndent.length; i++) {
        expect(posWithIndent[i], posNoIndent[i],
            reason:
                'Line $i：縮排不應影響 chapterPosition（應對應原始內容偏移）');
      }
    });

    test('第一段落第一行 chapterPosition = 標題長度', () {
      const title = 'AB'; // 2 chars
      final chapter = makeChapter(title: title);

      final pages = ChapterProvider.paginate(
        content: 'Hello',
        chapter: chapter,
        chapterIndex: 0,
        chapterSize: 1,
        viewSize: wideSize,
        titleStyle: testStyle,
        contentStyle: testStyle,
        textIndent: 0,
      );

      final firstContentLine = pages
          .expand((p) => p.lines)
          .firstWhere((l) => !l.isTitle);

      // 標題 "AB" 佔 2 個字元，因此第一個內容行應在 chapterPosition = 2
      expect(firstContentLine.chapterPosition, title.length);
    });

    test('空段落使 chapterPos 增加 1', () {
      // content = "A\n\nB" → paragraphs: ["A", "", "B"]
      // 空標題（0 chars）
      // 段落 "A"：chapterPosition=0，結束後 chapterPos = 1（A）+ 1（newline）= 2
      // 空段落：chapterPos += 1 → 3
      // 段落 "B"：chapterPosition = 3
      final chapter = makeChapter(title: '');

      final pages = ChapterProvider.paginate(
        content: 'A\n\nB',
        chapter: chapter,
        chapterIndex: 0,
        chapterSize: 1,
        viewSize: wideSize,
        titleStyle: testStyle,
        contentStyle: testStyle,
        textIndent: 0,
      );

      final contentLines = pages
          .expand((p) => p.lines)
          .where((l) => !l.isTitle)
          .toList();

      expect(contentLines.length, 2, reason: '"A" 和 "B" 各一行');
      expect(contentLines[0].chapterPosition, 0, reason: '"A" 起始於位置 0');
      // "A"(1) + newline(1) + emptyPara(1) = 3 before "B"
      expect(contentLines[1].chapterPosition, 3, reason: '"B" 起始於位置 3（跨越空段落）');
    });

    test('多段落 chapterPosition 嚴格遞增', () {
      final chapter = makeChapter(title: '標題'); // 2 chars
      const content = '第一段文字\n第二段文字\n第三段文字';

      final pages = ChapterProvider.paginate(
        content: content,
        chapter: chapter,
        chapterIndex: 0,
        chapterSize: 1,
        viewSize: wideSize,
        titleStyle: testStyle,
        contentStyle: testStyle,
        textIndent: 2,
      );

      final allLines = pages.expand((p) => p.lines).toList();
      int prev = -1;
      for (final line in allLines) {
        expect(
          line.chapterPosition,
          greaterThanOrEqualTo(prev),
          reason: 'chapterPosition 不應倒退（line: "${line.text}"）',
        );
        prev = line.chapterPosition;
      }
    });

    test('無縮排：各段落首行 chapterPosition 正確對應原始偏移', () {
      // title="" (0), content="ABC\nDE\nF"
      // 段落 "ABC"：chapterPosition=0，長度=3，newline=1 → 下一段起始=4
      // 段落 "DE" ：chapterPosition=4，長度=2，newline=1 → 下一段起始=7
      // 段落 "F"  ：chapterPosition=7
      final chapter = makeChapter(title: '');

      final pages = ChapterProvider.paginate(
        content: 'ABC\nDE\nF',
        chapter: chapter,
        chapterIndex: 0,
        chapterSize: 1,
        viewSize: wideSize,
        titleStyle: testStyle,
        contentStyle: testStyle,
        textIndent: 0,
      );

      final contentLines = pages
          .expand((p) => p.lines)
          .where((l) => !l.isTitle)
          .toList();

      expect(contentLines.length, 3, reason: '三個段落各一行');
      expect(contentLines[0].chapterPosition, 0,  reason: '"ABC" 段落起始位置');
      expect(contentLines[1].chapterPosition, 4,  reason: '"DE" 段落起始位置');
      expect(contentLines[2].chapterPosition, 7,  reason: '"F" 段落起始位置');
    });
  });

  group('ChapterProvider.paginate() - 避頭尾保護（不產生零寬行）', () {
    test('包含避頭符號的內容不應卡死（完整執行）', () {
      final chapter = makeChapter(title: '');
      final content = '你好，世界。今天天氣很好！是的，沒問題。' * 10;

      expect(
        () => ChapterProvider.paginate(
          content: content,
          chapter: chapter,
          chapterIndex: 0,
          chapterSize: 1,
          viewSize: const Size(300, 600),
          titleStyle: testStyle,
          contentStyle: testStyle,
        ),
        returnsNormally,
        reason: '包含標點的內容應正常完成分頁',
      );
    });

    test('縮排段落分行後每行文字長度不為 0', () {
      final chapter = makeChapter(title: '');
      final content = '這是一段較長的文字，用來測試分行是否正常工作，不會因為避頭尾邏輯而產生空行。' * 5;

      final pages = ChapterProvider.paginate(
        content: content,
        chapter: chapter,
        chapterIndex: 0,
        chapterSize: 1,
        viewSize: const Size(200, 800), // 窄視窗強制換行
        titleStyle: testStyle,
        contentStyle: testStyle,
        textIndent: 2,
      );

      for (final page in pages) {
        for (final line in page.lines) {
          if (!line.isTitle) {
            expect(
              line.text.length,
              greaterThan(0),
              reason: '每行文字長度不應為 0（零寬行保護）',
            );
          }
        }
      }
    });

    test('連續避頭符號開頭的段落不卡死', () {
      final chapter = makeChapter(title: '');
      // Paragraph starting with many forbidden-head chars
      const content = '。，、你好世界，今天天氣不錯，繼續往下走吧！';

      expect(
        () => ChapterProvider.paginate(
          content: content,
          chapter: chapter,
          chapterIndex: 0,
          chapterSize: 1,
          viewSize: const Size(50, 400), // 超窄視窗
          titleStyle: testStyle,
          contentStyle: testStyle,
          textIndent: 2,
        ),
        returnsNormally,
        reason: '避頭符號開頭的段落應正常完成分頁',
      );
    });
  });

  group('ChapterProvider.paginate() - 基本健全性', () {
    test('空內容應回傳至少一頁（標題頁）', () {
      final chapter = makeChapter(title: '第一章');

      final pages = ChapterProvider.paginate(
        content: '',
        chapter: chapter,
        chapterIndex: 0,
        chapterSize: 1,
        viewSize: const Size(300, 600),
        titleStyle: testStyle,
        contentStyle: testStyle,
      );

      expect(pages, isNotEmpty, reason: '即使內容為空，標題仍應產生至少一頁');
    });

    test('pageSize 正確設定為總頁數', () {
      final chapter = makeChapter(title: '');
      // Long content to ensure multiple pages
      final content = 'A' * 500;

      final pages = ChapterProvider.paginate(
        content: content,
        chapter: chapter,
        chapterIndex: 0,
        chapterSize: 1,
        viewSize: const Size(100, 200), // 小視窗，確保分出多頁
        titleStyle: testStyle,
        contentStyle: testStyle,
        textIndent: 0,
      );

      for (final page in pages) {
        expect(page.pageSize, pages.length,
            reason: '每頁的 pageSize 應等於總頁數');
      }
    });
  });
}
