import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';

void main() {
  test('TextPage JSON round-trip preserves key fields', () {
    final original = TextPage(
      index: 2,
      title: '第十章',
      chapterIndex: 10,
      chapterSize: 99,
      pageSize: 8,
      lines: [
        TextLine(
          text: '測試',
          width: 120,
          height: 24,
          isTitle: true,
          chapterPosition: 123,
          lineTop: 0,
          lineBottom: 24,
          paragraphNum: 1,
        ),
      ],
    );

    final restored = TextPage.fromJson(original.toJson());

    expect(restored.index, original.index);
    expect(restored.title, original.title);
    expect(restored.chapterIndex, original.chapterIndex);
    expect(restored.chapterSize, original.chapterSize);
    expect(restored.pageSize, original.pageSize);
    expect(restored.lines.length, 1);
    expect(restored.lines.first.text, '測試');
    expect(restored.lines.first.chapterPosition, 123);
    expect(restored.lines.first.lineBottom, 24);
  });
}
