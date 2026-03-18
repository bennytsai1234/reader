import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/constant/page_anim.dart';

void main() {
  group('PageAnim 常數', () {
    test('slide 值為 1（預設翻頁模式）', () {
      expect(PageAnim.slide, 1);
    });

    test('scroll 值為 3（捲動模式）', () {
      expect(PageAnim.scroll, 3);
    });

    test('cover 值為 0（已移除的模式）', () {
      // cover 已從 UI 移除，確保值沒有被誤用為預設
      expect(PageAnim.cover, 0);
      // slide != cover 確保預設值不是 cover
      expect(PageAnim.slide, isNot(PageAnim.cover));
    });

    test('各模式值互不重複', () {
      final values = [PageAnim.cover, PageAnim.slide, PageAnim.simulation, PageAnim.scroll, PageAnim.none];
      final unique = values.toSet();
      expect(unique.length, values.length, reason: '每個 PageAnim 模式應有唯一的值');
    });
  });
}
