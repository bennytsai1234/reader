import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:inkpage_reader/features/reader/reader_provider.dart';

class ScrollExecutionAdapter {
  final Map<String, GlobalKey> pageKeys;
  final VoidCallback? onStateChanged;

  const ScrollExecutionAdapter({
    required this.pageKeys,
    this.onStateChanged,
  });

  void scrollToPageKey({
    required int chapterIndex,
    required int pageIndex,
    bool animate = false,
  }) {
    final key = pageKeys['$chapterIndex:$pageIndex'];
    final context = key?.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      duration: animate ? const Duration(milliseconds: 240) : Duration.zero,
      alignment: 0,
      curve: Curves.easeOut,
    );
  }

  void scrollToChapterLocalOffset({
    required ReaderProvider provider,
    required int chapterIndex,
    required double localOffset,
    bool animate = false,
    Duration duration = Duration.zero,
    double topPadding = 0.0,
  }) {
    final runtimeChapter = provider.chapterAt(chapterIndex);
    final pages = provider.pagesForChapter(chapterIndex);
    if ((runtimeChapter == null && pages.isEmpty) ||
        (runtimeChapter != null && runtimeChapter.isEmpty)) {
      return;
    }
    final target = runtimeChapter != null
        ? runtimeChapter.resolveRestoreTarget(localOffset: localOffset)
        : () {
            final pageIndex = ChapterPositionResolver.pageIndexAtLocalOffset(
              pages,
              localOffset,
            );
            final pageStartOffset = ChapterPositionResolver.getCharOffsetForPage(
              pages,
              pageIndex,
            );
            final pageStartLocalOffset =
                ChapterPositionResolver.charOffsetToLocalOffset(
              pages,
              pageStartOffset,
            );
            final intraPageOffset = (localOffset - pageStartLocalOffset).clamp(
              0.0,
              double.infinity,
            );
            return (
              pageIndex: pageIndex,
              pageStartCharOffset: pageStartOffset,
              pageStartLocalOffset: pageStartLocalOffset,
              targetLocalOffset: localOffset,
              intraPageOffset: intraPageOffset,
              alignment: ChapterPositionResolver.charOffsetToAlignment(
                pages,
                pageStartOffset,
              ),
            );
          }();
    final key = pageKeys['$chapterIndex:${target.pageIndex}'];
    final pageContext = key?.currentContext;
    if (pageContext == null) {
      scrollToPageKey(
        chapterIndex: chapterIndex,
        pageIndex: target.pageIndex,
        animate: animate,
      );
      return;
    }
    void applyScrollOffset() {
      final position = Scrollable.maybeOf(pageContext)?.position;
      final renderObject = pageContext.findRenderObject();
      final viewportObject =
          Scrollable.maybeOf(pageContext)?.context.findRenderObject();
      if (position == null ||
          renderObject is! RenderBox ||
          viewportObject is! RenderBox) {
        return;
      }
      final pageTop =
          renderObject.localToGlobal(Offset.zero, ancestor: viewportObject).dy;
      final targetPixels =
          (position.pixels + pageTop + target.intraPageOffset - topPadding)
              .clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (animate) {
        position.animateTo(
          targetPixels,
          duration: duration,
          curve: Curves.easeOut,
        );
      } else {
        position.jumpTo(targetPixels);
      }
      onStateChanged?.call();
    }

    final renderObject = pageContext.findRenderObject();
    final viewportObject =
        Scrollable.maybeOf(pageContext)?.context.findRenderObject();
    if (renderObject is RenderBox && viewportObject is RenderBox) {
      final pageTop =
          renderObject.localToGlobal(Offset.zero, ancestor: viewportObject).dy;
      final pageBottom = pageTop + renderObject.size.height;
      final viewportHeight = viewportObject.size.height;
      final isVisible = pageBottom > 0 && pageTop < viewportHeight;
      if (isVisible) {
        applyScrollOffset();
        return;
      }
    }

    Scrollable.ensureVisible(
      pageContext,
      duration: animate ? duration : Duration.zero,
      alignment: 0,
      curve: Curves.easeOut,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => applyScrollOffset());
  }
}
