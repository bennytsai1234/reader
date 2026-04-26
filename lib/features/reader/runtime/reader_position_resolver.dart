import 'package:inkpage_reader/features/reader/engine/line_layout.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

class ReaderPositionResolver {
  const ReaderPositionResolver._();

  static LineLayout? _lineLayout({
    required ReaderChapter? runtimeChapter,
    required List<TextPage> pages,
    required int chapterIndex,
  }) {
    if (runtimeChapter != null) return runtimeChapter.lineLayout;
    if (pages.isEmpty) return null;
    return LineLayout.fromPages(pages, chapterIndex: chapterIndex);
  }

  static ReaderScrollTarget resolveScrollTarget({
    required ReaderLocation location,
    required ReaderChapter? runtimeChapter,
    required List<TextPage> pages,
  }) {
    final normalized = location.normalized();
    final layout = _lineLayout(
      runtimeChapter: runtimeChapter,
      pages: pages,
      chapterIndex: normalized.chapterIndex,
    );
    final localOffset =
        layout?.localOffsetForCharOffset(normalized.charOffset) ?? 0.0;
    final alignment =
        layout == null || layout.contentHeight <= 0
            ? 0.0
            : (localOffset / layout.contentHeight).clamp(0.0, 1.0).toDouble();
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
      final safeIndex =
          slidePages.isEmpty
              ? 0
              : globalPageIndex.clamp(0, slidePages.length - 1);
      final targetPage = slidePages.isNotEmpty ? slidePages[safeIndex] : null;
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
    final layout = _lineLayout(
      runtimeChapter: runtimeChapter,
      pages: chapterPages,
      chapterIndex: normalized.chapterIndex,
    );
    final chapterPageIndex =
        layout?.findPageIndexByCharOffset(normalized.charOffset) ?? 0;
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
