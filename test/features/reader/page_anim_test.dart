import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/constant/page_anim.dart';

void main() {
  group('PageAnim 常數', () {
    test('slide 值為 1（預設翻頁模式）', () {
      expect(PageAnim.slide, 1);
    });

    test('scroll 值為 3（捲動模式）', () {
      expect(PageAnim.scroll, 3);
    });

    test('目前僅保留的模式值互不重複', () {
      final values = [
        PageAnim.slide,
        PageAnim.simulation,
        PageAnim.scroll,
        PageAnim.none,
      ];
      final unique = values.toSet();
      expect(unique.length, values.length, reason: '每個 PageAnim 模式應有唯一的值');
    });
  });
}
