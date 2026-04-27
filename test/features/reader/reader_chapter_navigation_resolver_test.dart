import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_chapter_navigation_resolver.dart';

void main() {
  group('ReaderChapterNavigationResolver', () {
    test('out-of-range previous chapter returns null', () {
      expect(
        ReaderChapterNavigationResolver.resolveRelativeTarget(
          currentChapterIndex: 0,
          chapterCount: 3,
          delta: -1,
        ),
        isNull,
      );
    });

    test('out-of-range next chapter returns null', () {
      expect(
        ReaderChapterNavigationResolver.resolveRelativeTarget(
          currentChapterIndex: 2,
          chapterCount: 3,
          delta: 1,
        ),
        isNull,
      );
    });

    test('in-range target resolves without resetting to chapter start', () {
      expect(
        ReaderChapterNavigationResolver.resolveRelativeTarget(
          currentChapterIndex: 1,
          chapterCount: 3,
          delta: 1,
        ),
        2,
      );
    });
  });
}
