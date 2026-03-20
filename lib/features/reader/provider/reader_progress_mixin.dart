import 'dart:async';

import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';

import 'reader_content_mixin.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';

mixin ReaderProgressMixin
    on ReaderProviderBase, ReaderSettingsMixin, ReaderContentMixin {
  int initialCharOffset = 0;
  int? pendingRestorePos;
  Timer? scrollSaveTimer;
  int _lastSavedCharOffset = -1;

  List<TextPage> _pagesForChapter(int chapterIndex) =>
      (this as dynamic).pagesForChapter(chapterIndex) as List<TextPage>;

  void updateVisibleChapterPosition({
    required int chapterIndex,
    required double localOffset,
    required double alignment,
  }) {
    visibleChapterIndex = chapterIndex;
    visibleChapterLocalOffset = localOffset;
    visibleChapterAlignment = alignment;

    if (pageTurnMode != PageAnim.scroll || isRestoring || isLoading) return;

    final pages = _pagesForChapter(chapterIndex);
    final currentCharOffset =
        ChapterPositionResolver.localOffsetToCharOffset(pages, localOffset);
    if (book.durChapterIndex == chapterIndex &&
        book.durChapterPos == currentCharOffset) {
      return;
    }

    book.durChapterIndex = chapterIndex;
    book.durChapterPos = currentCharOffset;
    final crossThreshold = _lastSavedCharOffset == -1 ||
        (currentCharOffset - _lastSavedCharOffset).abs() > 600 ||
        currentChapterIndex != chapterIndex;
    currentChapterIndex = chapterIndex;

    if (crossThreshold) {
      scrollSaveTimer?.cancel();
      saveProgress(chapterIndex, currentPageIndex);
    } else {
      scrollSaveTimer?.cancel();
      scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
        if (!isDisposed) saveProgress(chapterIndex, currentPageIndex);
      });
    }
  }

  @override
  void jumpToPosition({
    int? chapterIndex,
    int? charOffset,
    int? pageIndex,
    bool isRestoringJump = false,
  }) {
    final targetChapter = chapterIndex ?? currentChapterIndex;
    if (isRestoringJump) lifecycle = ReaderLifecycle.restoring;

    if (pageTurnMode == PageAnim.scroll) {
      final pages = _pagesForChapter(targetChapter);
      final targetCharOffset = charOffset ?? 0;
      final localOffset =
          ChapterPositionResolver.charOffsetToLocalOffset(pages, targetCharOffset);
      final alignment =
          ChapterPositionResolver.charOffsetToAlignment(pages, targetCharOffset);
      requestJumpToChapter(
        chapterIndex: targetChapter,
        alignment: alignment,
        localOffset: localOffset,
      );
      notifyListeners();
      return;
    }

    final pages = _pagesForChapter(targetChapter);
    var targetPage = 0;
    if (charOffset != null && charOffset > 0) {
      final localPageIndex =
          ChapterPositionResolver.findPageIndexByCharOffset(pages, charOffset);
      final globalIndex = slidePages.indexWhere(
        (page) =>
            page.chapterIndex == targetChapter && page.index == localPageIndex,
      );
      targetPage = globalIndex >= 0 ? globalIndex : 0;
    } else if (pageIndex != null) {
      targetPage = pageIndex.clamp(0, slidePages.length - 1);
    }
    currentPageIndex = targetPage;
    requestJumpToPage(targetPage);
    notifyListeners();
  }

  void applyPendingRestore() {
    if (pendingRestorePos == null) return;
    final pos = pendingRestorePos!;
    pendingRestorePos = null;
    jumpToPosition(
      chapterIndex: currentChapterIndex,
      charOffset: pos,
      isRestoringJump: true,
    );
  }

  void saveProgress(int chapterIndex, int pageIndex) {
    final title = chapters.isNotEmpty && chapterIndex < chapters.length
        ? chapters[chapterIndex].title
        : null;
    final pages = _pagesForChapter(chapterIndex);
    final charOffset = pageTurnMode == PageAnim.scroll
        ? ChapterPositionResolver.localOffsetToCharOffset(
            _pagesForChapter(chapterIndex),
            visibleChapterLocalOffset,
          )
        : () {
            if (pageIndex >= 0 && pageIndex < slidePages.length) {
              final page = slidePages[pageIndex];
              final chapterPages = _pagesForChapter(page.chapterIndex);
              return ChapterPositionResolver.getCharOffsetForPage(
                chapterPages,
                page.index,
              );
            }
            return ChapterPositionResolver.getCharOffsetForPage(
              pages,
              pageIndex.clamp(0, (pages.length - 1).clamp(0, 1 << 20)),
            );
          }();

    book.durChapterIndex = chapterIndex;
    book.durChapterPos = charOffset;
    book.durChapterTitle = title;
    _lastSavedCharOffset = charOffset;
    unawaited(
      bookDao.updateProgress(book.bookUrl, chapterIndex, title ?? '', charOffset),
    );
  }

  void updateScrollPageIndex(int chapterIndex, double localOffset) {
    visibleChapterIndex = chapterIndex;
    final pages = _pagesForChapter(chapterIndex);
    currentPageIndex = ChapterPositionResolver.pageIndexAtLocalOffset(
      pages,
      localOffset,
    );
    currentChapterIndex = chapterIndex;
  }
}
