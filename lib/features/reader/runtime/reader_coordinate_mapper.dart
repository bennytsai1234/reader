import 'package:inkpage_reader/features/reader/engine/line_layout.dart';
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

  LineLayout? _lineLayoutForChapter(int chapterIndex) {
    final runtimeChapter = chapterAt(chapterIndex);
    if (runtimeChapter != null) return runtimeChapter.lineLayout;
    final pages = pagesForChapter(chapterIndex);
    if (pages.isEmpty) return null;
    return LineLayout.fromPages(pages, chapterIndex: chapterIndex);
  }

  ReaderLocation locationFromScrollOffset({
    required int chapterIndex,
    required double localOffset,
  }) {
    final layout = _lineLayoutForChapter(chapterIndex);
    final charOffset = layout?.charOffsetFromLocalOffset(localOffset) ?? 0;
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
      final layout = _lineLayoutForChapter(page.chapterIndex);
      final charOffset = layout?.charOffsetForPageIndex(page.index) ?? 0;
      return ReaderLocation(
        chapterIndex: page.chapterIndex,
        charOffset: charOffset,
      ).normalized();
    }

    final layout = _lineLayoutForChapter(chapterIndex);
    final safePageIndex =
        layout == null || layout.pageGroups.isEmpty
            ? 0
            : pageIndex.clamp(0, layout.pageGroups.length - 1);
    final charOffset = layout?.charOffsetForPageIndex(safePageIndex) ?? 0;
    return ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    ).normalized();
  }

  double localOffsetForLocation(ReaderLocation location) {
    final normalized = location.normalized();
    final layout = _lineLayoutForChapter(normalized.chapterIndex);
    return layout?.localOffsetForCharOffset(normalized.charOffset) ?? 0.0;
  }

  double alignmentForLocation(ReaderLocation location) {
    final normalized = location.normalized();
    final layout = _lineLayoutForChapter(normalized.chapterIndex);
    if (layout == null || layout.contentHeight <= 0) return 0.0;
    return (layout.localOffsetForCharOffset(normalized.charOffset) /
            layout.contentHeight)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  int? pageIndexForLocation(ReaderLocation location) {
    final normalized = location.normalized();
    final layout = _lineLayoutForChapter(normalized.chapterIndex);
    if (layout == null || layout.pageGroups.isEmpty) return null;
    return layout.findPageIndexByCharOffset(normalized.charOffset);
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
    final layout = _lineLayoutForChapter(normalized.chapterIndex);
    final chapterPageIndex =
        layout?.findPageIndexByCharOffset(normalized.charOffset) ?? 0;
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
