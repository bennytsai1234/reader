import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_location.dart';
import 'package:legado_reader/features/reader/runtime/reader_position_resolver.dart';

List<TextPage> _buildPages(
  int chapterIndex,
  List<int> pageStarts, {
  String title = 'chapter',
}) {
  return List.generate(pageStarts.length, (pageIndex) {
    final start = pageStarts[pageIndex];
    final nextStart = pageIndex + 1 < pageStarts.length
        ? pageStarts[pageIndex + 1]
        : start + 8;
    final length = (nextStart - start).clamp(4, 12);
    return TextPage(
      index: pageIndex,
      title: title,
      chapterIndex: chapterIndex,
      pageSize: pageStarts.length,
      lines: [
        TextLine(
          text: List.filled(length, 'X').join(),
          width: 100,
          height: 20,
          chapterPosition: start,
          lineTop: pageIndex * 100,
          lineBottom: pageIndex * 100 + 40,
          paragraphNum: pageIndex + 1,
          isParagraphEnd: true,
        ),
      ],
    );
  });
}

ReaderChapter _makeRuntimeChapter(
  int chapterIndex,
  List<int> pageStarts,
) {
  return ReaderChapter(
    chapter: BookChapter(title: 'c$chapterIndex', index: chapterIndex),
    index: chapterIndex,
    title: 'c$chapterIndex',
    pages: _buildPages(chapterIndex, pageStarts, title: 'c$chapterIndex'),
  );
}

void main() {
  group('ReaderPositionResolver', () {
    test('scroll target 會把 durable location 轉成 scroll target', () {
      final chapter = _makeRuntimeChapter(1, [0, 8, 16]);

      final target = ReaderPositionResolver.resolveScrollTarget(
        location: const ReaderLocation(chapterIndex: 1, charOffset: 9),
        runtimeChapter: chapter,
        pages: chapter.pages,
      );

      expect(target.chapterIndex, 1);
      expect(target.localOffset, chapter.localOffsetFromCharOffset(9));
      expect(target.alignment, chapter.alignmentForCharOffset(9));
    });

    test('slide target 會把章首 offset 0 定位到目標章第一頁', () {
      final chapter0 = _makeRuntimeChapter(0, [0]);
      final chapter1 = _makeRuntimeChapter(1, [0, 8, 16]);
      final slidePages = [...chapter0.pages, ...chapter1.pages];

      final target = ReaderPositionResolver.resolveSlideTarget(
        location: const ReaderLocation(chapterIndex: 1, charOffset: 0),
        runtimeChapter: chapter1,
        chapterPages: chapter1.pages,
        slidePages: slidePages,
        targetChapterIndex: 1,
      );

      expect(target.globalPageIndex, 1);
      expect(target.chapterIndex, 1);
      expect(target.chapterPageIndex, 0);
    });

    test('slide target 會把負值 offset clamp 到章首', () {
      final chapter = _makeRuntimeChapter(2, [0, 10]);

      final target = ReaderPositionResolver.resolveSlideTarget(
        location: const ReaderLocation(chapterIndex: 2, charOffset: -5),
        runtimeChapter: chapter,
        chapterPages: chapter.pages,
        slidePages: chapter.pages,
        targetChapterIndex: 2,
      );

      expect(target.globalPageIndex, 0);
      expect(target.chapterPageIndex, 0);
    });
  });
}
