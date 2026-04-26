import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

class ReaderCoordinateMapper {
  final ReaderChapter? Function(int chapterIndex) chapterAt;
  final List<TextPage> Function(int chapterIndex) pagesForChapter;
  final List<TextPage> Function() slidePages;

  const ReaderCoordinateMapper({
    required this.chapterAt,
    required this.pagesForChapter,
    required this.slidePages,
  });

  ReaderLocation locationFromScrollOffset({
    required int chapterIndex,
    required double localOffset,
  }) {
    final runtimeChapter = chapterAt(chapterIndex);
    final pages = pagesForChapter(chapterIndex);
    final charOffset =
        runtimeChapter != null
            ? runtimeChapter.charOffsetFromLocalOffset(localOffset)
            : ChapterPositionResolver.localOffsetToCharOffset(
              pages,
              localOffset,
            );
    return ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    ).normalized();
  }

  ReaderLocation locationFromSlidePage({
    required int chapterIndex,
    required int pageIndex,
  }) {
    final currentSlidePages = slidePages();
    if (pageIndex >= 0 && pageIndex < currentSlidePages.length) {
      final page = currentSlidePages[pageIndex];
      final runtimeChapter = chapterAt(page.chapterIndex);
      final chapterPages = pagesForChapter(page.chapterIndex);
      final charOffset =
          runtimeChapter != null
              ? runtimeChapter.charOffsetForPageIndex(page.index)
              : ChapterPositionResolver.getCharOffsetForPage(
                chapterPages,
                page.index,
              );
      return ReaderLocation(
        chapterIndex: page.chapterIndex,
        charOffset: charOffset,
      ).normalized();
    }

    final runtimeChapter = chapterAt(chapterIndex);
    final chapterPages = pagesForChapter(chapterIndex);
    final safePageIndex =
        chapterPages.isEmpty ? 0 : pageIndex.clamp(0, chapterPages.length - 1);
    final charOffset =
        runtimeChapter != null
            ? runtimeChapter.charOffsetForPageIndex(safePageIndex)
            : ChapterPositionResolver.getCharOffsetForPage(
              chapterPages,
              safePageIndex,
            );
    return ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    ).normalized();
  }

  double localOffsetForLocation(ReaderLocation location) {
    final normalized = location.normalized();
    final runtimeChapter = chapterAt(normalized.chapterIndex);
    if (runtimeChapter != null) {
      return runtimeChapter.localOffsetFromCharOffset(normalized.charOffset);
    }
    return ChapterPositionResolver.charOffsetToLocalOffset(
      pagesForChapter(normalized.chapterIndex),
      normalized.charOffset,
    );
  }

  double alignmentForLocation(ReaderLocation location) {
    final normalized = location.normalized();
    final runtimeChapter = chapterAt(normalized.chapterIndex);
    if (runtimeChapter != null) {
      return runtimeChapter.alignmentForCharOffset(normalized.charOffset);
    }
    return ChapterPositionResolver.charOffsetToAlignment(
      pagesForChapter(normalized.chapterIndex),
      normalized.charOffset,
    );
  }

  int? pageIndexForLocation(ReaderLocation location) {
    final normalized = location.normalized();
    final runtimeChapter = chapterAt(normalized.chapterIndex);
    if (runtimeChapter != null) {
      return runtimeChapter.getPageIndexByCharIndex(normalized.charOffset);
    }
    final pages = pagesForChapter(normalized.chapterIndex);
    if (pages.isEmpty) return null;
    return ChapterPositionResolver.findPageIndexByCharOffset(
      pages,
      normalized.charOffset,
    );
  }

  ReaderScrollTarget scrollTargetForLocation(ReaderLocation location) {
    final normalized = location.normalized();
    return ReaderScrollTarget(
      chapterIndex: normalized.chapterIndex,
      localOffset: localOffsetForLocation(normalized),
      alignment: alignmentForLocation(normalized),
    );
  }

  ReaderSlideTarget slideTargetForLocation({
    ReaderLocation? location,
    int? globalPageIndex,
    required int targetChapterIndex,
  }) {
    final currentSlidePages = slidePages();
    if (globalPageIndex != null) {
      final safeIndex =
          currentSlidePages.isEmpty
              ? 0
              : globalPageIndex.clamp(0, currentSlidePages.length - 1);
      final targetPage =
          currentSlidePages.isNotEmpty ? currentSlidePages[safeIndex] : null;
      return ReaderSlideTarget(
        globalPageIndex: safeIndex,
        chapterIndex: targetPage?.chapterIndex ?? targetChapterIndex,
        chapterPageIndex: targetPage?.index ?? 0,
      );
    }

    final normalized =
        (location ??
                ReaderLocation(chapterIndex: targetChapterIndex, charOffset: 0))
            .normalized();
    final runtimeChapter = chapterAt(normalized.chapterIndex);
    final chapterPages = pagesForChapter(normalized.chapterIndex);
    final chapterPageIndex =
        runtimeChapter != null
            ? runtimeChapter.getPageIndexByCharIndex(normalized.charOffset)
            : ChapterPositionResolver.findPageIndexByCharOffset(
              chapterPages,
              normalized.charOffset,
            );
    final globalIndex = currentSlidePages.indexWhere(
      (page) =>
          page.chapterIndex == normalized.chapterIndex &&
          page.index == chapterPageIndex,
    );
    return ReaderSlideTarget(
      globalPageIndex: globalIndex >= 0 ? globalIndex : 0,
      chapterIndex: normalized.chapterIndex,
      chapterPageIndex: chapterPageIndex,
    );
  }
}
