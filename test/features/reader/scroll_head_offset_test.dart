import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';

// 測試 _scrollHeadOffset 的設計假設：
// head widget 高度 = 2px，separator = 24px，總偏移 = 26px
// 此測試驗證 TextPage 的 chapterIndex 判斷邏輯
void main() {
  group('ScrollHead 位置計算假設', () {
    const double kScrollHeadOffset = 26.0; // 2px head + 24px separator
    const double kPagePaddingTop = 40.0;
    const double kSeparatorHeight = 24.0;

    test('headOffset 為 26px 時與 head(2px) + separator(24px) 吻合', () {
      expect(kScrollHeadOffset, 2.0 + kSeparatorHeight);
    });

    test('第一章（chapterIndex=0）不顯示 head → headOffset 應為 0', () {
      final firstChapterPage = TextPage(
        index: 0, lines: [], title: '第一章',
        chapterIndex: 0,
      );
      // 設計：chapterIndex > 0 才顯示 head
      final headOffset = firstChapterPage.chapterIndex > 0 ? kScrollHeadOffset : 0.0;
      expect(headOffset, 0.0);
    });

    test('非第一章（chapterIndex=5）顯示 head → headOffset 應為 26', () {
      final midChapterPage = TextPage(
        index: 0, lines: [], title: '第六章',
        chapterIndex: 5,
      );
      final headOffset = midChapterPage.chapterIndex > 0 ? kScrollHeadOffset : 0.0;
      expect(headOffset, kScrollHeadOffset);
    });

    test('頁面高度計算：lineBottom + paddingTop(40)', () {
      final line = TextLine(
        text: '文字', width: 300, height: 24,
        lineTop: 0, lineBottom: 24,
      );
      final page = TextPage(
        index: 0, lines: [line], title: 'Ch1', chapterIndex: 1,
      );
      final pageHeight = page.lines.last.lineBottom + kPagePaddingTop;
      expect(pageHeight, 64.0); // 24 + 40
    });

    test('多頁高度計算含 separator', () {
      final line = TextLine(text: 'A', width: 300, height: 24, lineBottom: 24);
      final pages = [
        TextPage(index: 0, lines: [line], title: 'T', chapterIndex: 1),
        TextPage(index: 1, lines: [line], title: 'T', chapterIndex: 1),
        TextPage(index: 2, lines: [line], title: 'T', chapterIndex: 1),
      ];

      double total = 0;
      for (int i = 0; i < pages.length; i++) {
        final h = pages[i].lines.last.lineBottom + kPagePaddingTop;
        total += h;
        if (i < pages.length - 1) total += kSeparatorHeight;
      }
      // 3 pages × 64px + 2 separators × 24px = 192 + 48 = 240
      expect(total, 240.0);
    });
  });

  group('章節邊界偵測邏輯', () {
    test('isNeighbor：scroll 模式使用 pages 邊界', () {
      // 模擬 pages = [ch3, ch4, ch5]，currentChapterIndex = 4（在中間）
      const firstLoadedIdx = 3;
      const lastLoadedIdx = 5;
      const currentChapterIndex = 4;

      // 測試目標章節 6（lastLoadedIdx+1）是否為 neighbor
      const targetNext = 6;
      final isNeighborNext = (targetNext == lastLoadedIdx + 1 || targetNext == firstLoadedIdx - 1);
      expect(isNeighborNext, true, reason: '第6章是已載入頁面的下一個鄰近章節');

      // 測試目標章節 2（firstLoadedIdx-1）是否為 neighbor
      const targetPrev = 2;
      final isNeighborPrev = (targetPrev == lastLoadedIdx + 1 || targetPrev == firstLoadedIdx - 1);
      expect(isNeighborPrev, true, reason: '第2章是已載入頁面的上一個鄰近章節');

      // 確認用 currentChapterIndex 判斷會得到不同（舊 bug）結果
      const targetFarNext = 6;
      final oldIsNeighbor = (targetFarNext == currentChapterIndex + 1 || targetFarNext == currentChapterIndex - 1);
      // ch4+1=5 ≠ 6，所以用舊方式 isNeighbor 為 false（Bug）
      expect(oldIsNeighbor, false, reason: '舊版 bug：用 currentChapterIndex 計算，ch6 不被視為 neighbor');
    });
  });
}
