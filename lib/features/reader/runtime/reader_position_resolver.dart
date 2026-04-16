import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

class ReaderPositionResolver {
  const ReaderPositionResolver._();

  static ReaderScrollTarget resolveScrollTarget({
    required ReaderLocation location,
    required ReaderChapter? runtimeChapter,
    required List<TextPage> pages,
  }) {
    final normalized = location.normalized();
    final localOffset = runtimeChapter != null
        ? runtimeChapter.localOffsetFromCharOffset(normalized.charOffset)
        : ChapterPositionResolver.charOffsetToLocalOffset(
            pages,
            normalized.charOffset,
          );
    final alignment = runtimeChapter != null
        ? runtimeChapter.alignmentForCharOffset(normalized.charOffset)
        : ChapterPositionResolver.charOffsetToAlignment(
            pages,
            normalized.charOffset,
          );
    return ReaderScrollTarget(
      chapterIndex: normalized.chapterIndex,
      localOffset: localOffset,
      alignment: alignment,
    );
  }

  static ReaderSlideTarget resolveSlideTarget({
    ReaderLocation? location,
    int? globalPageIndex,
    required ReaderChapter? runtimeChapter,
    required List<TextPage> chapterPages,
    required List<TextPage> slidePages,
    required int targetChapterIndex,
  }) {
    if (globalPageIndex != null) {
      final safeIndex = slidePages.isEmpty
          ? 0
          : globalPageIndex.clamp(0, slidePages.length - 1);
      final targetPage = slidePages.isNotEmpty ? slidePages[safeIndex] : null;
      return ReaderSlideTarget(
        globalPageIndex: safeIndex,
        chapterIndex: targetPage?.chapterIndex ?? targetChapterIndex,
        chapterPageIndex: targetPage?.index ?? 0,
      );
    }

    final normalized = (location ??
            ReaderLocation(chapterIndex: targetChapterIndex, charOffset: 0))
        .normalized();
    final chapterPageIndex = runtimeChapter != null
        ? runtimeChapter.getPageIndexByCharIndex(normalized.charOffset)
        : ChapterPositionResolver.findPageIndexByCharOffset(
            chapterPages,
            normalized.charOffset,
          );
    final globalIndex = slidePages.indexWhere(
      (page) =>
          page.chapterIndex == normalized.chapterIndex &&
          page.index == chapterPageIndex,
    );
    final safeGlobalIndex = globalIndex >= 0 ? globalIndex : 0;
    return ReaderSlideTarget(
      globalPageIndex: safeGlobalIndex,
      chapterIndex: normalized.chapterIndex,
      chapterPageIndex: chapterPageIndex,
    );
  }
}
