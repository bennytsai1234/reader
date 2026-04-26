import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';

void main() {
  group('TextPage.readProgress', () {
    test('第一章第一頁顯示約 0%', () {
      final page = TextPage(
        index: 0,
        lines: [],
        title: '第一章',
        chapterIndex: 0,
        chapterSize: 10,
        pageSize: 5,
      );
      // chapterIndex=0, pageSize=5, index=0 → (0/10) + (1/10)*(1/5) = 0.02 = 2.0%
      expect(page.readProgress, '2.0%');
    });

    test('最後一章最後一頁顯示 100%', () {
      final page = TextPage(
        index: 4,
        lines: [],
        title: '最後章',
        chapterIndex: 9,
        chapterSize: 10,
        pageSize: 5,
      );
      expect(page.readProgress, '100.0%');
    });

    test('中間章節顯示合理百分比', () {
      final page = TextPage(
        index: 0,
        lines: [],
        title: '第五章',
        chapterIndex: 4,
        chapterSize: 10,
        pageSize: 4,
      );
      // (4/10) + (1/10)*(1/4) = 0.4 + 0.025 = 0.425 = 42.5%
      expect(page.readProgress, '42.5%');
    });

    test('pageSize 為 0 時按章節計算', () {
      final page = TextPage(
        index: 0,
        lines: [],
        title: '第三章',
        chapterIndex: 2,
        chapterSize: 5,
        pageSize: 0,
      );
      // (chapterIndex+1)/chapterSize = 3/5 = 60%
      expect(page.readProgress, '60.0%');
    });

    test('chapterSize 為 0 時回傳 0.0%', () {
      final page = TextPage(
        index: 0,
        lines: [],
        title: '',
        chapterIndex: 0,
        chapterSize: 0,
        pageSize: 0,
      );
      expect(page.readProgress, '0.0%');
    });

    test('非最後一頁不顯示 100.0%（避免誤導）', () {
      final page = TextPage(
        index: 3, // 第4頁，但不是最後一頁（pageSize=5）
        lines: [],
        title: '最後章',
        chapterIndex: 9,
        chapterSize: 10,
        pageSize: 5,
      );
      final progress = page.readProgress;
      // 不應該是 100.0%（因為不是最後一頁）
      expect(progress, isNot('100.0%'));
    });
  });

  group('TextPage.copyWith', () {
    test('copyWith 正確複製指定欄位', () {
      final original = TextPage(
        index: 0,
        lines: [],
        title: '原始',
        chapterIndex: 1,
        chapterSize: 5,
        pageSize: 3,
      );

      final copied = original.copyWith(title: '新標題', index: 2);
      expect(copied.title, '新標題');
      expect(copied.index, 2);
      expect(copied.chapterIndex, 1); // 未改變
      expect(copied.chapterSize, 5); // 未改變
    });
  });

  group('TextLine', () {
    test('建立 TextLine 時預設值正確', () {
      final line = TextLine(text: '測試文字', width: 100, height: 20);
      expect(line.chapterPosition, 0);
      expect(line.isTitle, false);
      expect(line.paragraphNum, 0);
    });
  });
}
