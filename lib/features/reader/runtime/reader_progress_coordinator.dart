import 'dart:async';

import 'package:inkpage_reader/core/constant/page_anim.dart';
import 'package:inkpage_reader/features/reader/engine/line_layout.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';
import 'package:inkpage_reader/features/reader/runtime/reader_progress_store.dart';

class ReaderProgressCandidate {
  final ReaderLocation location;

  const ReaderProgressCandidate({required this.location});
}

/// 管理閱讀進度的更新與持久化。
///
/// 取代原本 [ReaderProgressMixin] 的 contentCallbacksRef 繞道模式，
/// 改由建構時注入明確的依賴，讓邏輯可以獨立測試。
class ReaderProgressCoordinator {
  final ReaderChapter? Function(int chapterIndex) _chapterAt;
  final List<TextPage> Function(int chapterIndex) _pagesForChapter;
  final ReaderProgressStore _store;
  final ReaderLocation Function() _durableLocation;
  final bool Function() _shouldPersistVisiblePosition;
  final void Function(ReaderLocation location) _updateVisibleLocation;
  final void Function(ReaderLocation location) _updateCommittedLocation;
  final Future<void> Function(ReaderLocation location) _persistLocation;

  Timer? scrollSaveTimer;
  ReaderProgressCandidate? _pendingDebouncedProgress;

  ReaderProgressCoordinator({
    required ReaderChapter? Function(int) chapterAt,
    required List<TextPage> Function(int) pagesForChapter,
    required ReaderProgressStore store,
    required ReaderLocation Function() durableLocation,
    required bool Function() shouldPersistVisiblePosition,
    required void Function(ReaderLocation location) updateVisibleLocation,
    required void Function(ReaderLocation location) updateCommittedLocation,
    required Future<void> Function(ReaderLocation location) persistLocation,
  }) : _chapterAt = chapterAt,
       _pagesForChapter = pagesForChapter,
       _store = store,
       _durableLocation = durableLocation,
       _shouldPersistVisiblePosition = shouldPersistVisiblePosition,
       _updateVisibleLocation = updateVisibleLocation,
       _updateCommittedLocation = updateCommittedLocation,
       _persistLocation = persistLocation;

  LineLayout? _lineLayoutForChapter(int chapterIndex) {
    final runtimeChapter = _chapterAt(chapterIndex);
    if (runtimeChapter != null) return runtimeChapter.lineLayout;
    final pages = _pagesForChapter(chapterIndex);
    if (pages.isEmpty) return null;
    return LineLayout.fromPages(pages, chapterIndex: chapterIndex);
  }

  /// 更新可見章節位置，並在需要時觸發進度持久化（含 debounce）。
  ///
  /// [updateVisible] 由 caller 提供，用於回寫 visibleChapterIndex 等欄位。
  /// [updateCurrentChapterIndex] 在跨章節時更新 currentChapterIndex。
  void updateVisibleChapterPosition({
    required int chapterIndex,
    required double localOffset,
    required double alignment,
    required int pageTurnMode,
    required bool isLoading,
    required int currentPageIndex,
    required bool allowProgressCommit,
    ReaderLocation? anchorLocation,
    required void Function(int ci, double lo, double al) updateVisible,
    required void Function(int ci) updateCurrentChapterIndex,
  }) {
    updateVisible(chapterIndex, localOffset, alignment);

    if (!allowProgressCommit) {
      return;
    }

    if (pageTurnMode != PageAnim.scroll || isLoading) {
      return;
    }
    final currentLocation =
        anchorLocation?.normalized().chapterIndex == chapterIndex
            ? anchorLocation!.normalized()
            : _resolveScrollLocation(
              chapterIndex: chapterIndex,
              localOffset: localOffset,
            );
    final candidate = ReaderProgressCandidate(location: currentLocation);
    _updateVisibleLocation(currentLocation);
    if (!_shouldPersistVisiblePosition()) return;
    final durableLocation = _durableLocation();

    if (durableLocation == currentLocation) {
      _updateCommittedLocation(currentLocation);
      return;
    }
    _updateCommittedLocation(currentLocation);

    final crossThreshold = _store.shouldSaveImmediately(
      currentCharOffset: currentLocation.charOffset,
      currentChapterIndex: durableLocation.chapterIndex,
      targetChapterIndex: currentLocation.chapterIndex,
    );
    updateCurrentChapterIndex(currentLocation.chapterIndex);

    if (crossThreshold) {
      scrollSaveTimer?.cancel();
      scrollSaveTimer = null;
      _pendingDebouncedProgress = null;
      unawaited(_persistLocation(currentLocation));
    } else {
      scrollSaveTimer?.cancel();
      _pendingDebouncedProgress = candidate;
      scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
        scrollSaveTimer = null;
        final pending = _pendingDebouncedProgress;
        _pendingDebouncedProgress = null;
        if (pending == null) return;
        unawaited(_persistLocation(pending.location));
      });
    }
  }

  /// 計算並持久化進度（slide mode 或 scroll mode）。
  void saveProgress({
    required int chapterIndex,
    required int pageIndex,
    required int pageTurnMode,
    required double visibleChapterLocalOffset,
    required List<TextPage> slidePages,
  }) {
    final location =
        pageTurnMode == PageAnim.scroll
            ? _resolveScrollLocation(
              chapterIndex: chapterIndex,
              localOffset: visibleChapterLocalOffset,
            )
            : _resolveSlideLocation(
              chapterIndex: chapterIndex,
              pageIndex: pageIndex,
              slidePages: slidePages,
            );

    _updateCommittedLocation(location);

    unawaited(_persistLocation(location));
  }

  /// 更新 scroll mode 的頁面索引（不觸發持久化）。
  void updateScrollPageIndex({
    required int chapterIndex,
    required double localOffset,
    required void Function(int) setCurrentPageIndex,
    required void Function(int) setVisibleChapterIndex,
    required void Function(int) setCurrentChapterIndex,
  }) {
    setVisibleChapterIndex(chapterIndex);
    final layout = _lineLayoutForChapter(chapterIndex);
    final pageIndex = layout?.pageIndexAtLocalOffset(localOffset) ?? 0;
    setCurrentPageIndex(pageIndex);
    setCurrentChapterIndex(chapterIndex);
  }

  void dispose() {
    scrollSaveTimer?.cancel();
    scrollSaveTimer = null;
    _pendingDebouncedProgress = null;
  }

  Future<ReaderLocation?> flushPendingProgress() async {
    scrollSaveTimer?.cancel();
    scrollSaveTimer = null;

    final pending = _pendingDebouncedProgress;
    _pendingDebouncedProgress = null;
    if (pending == null) return null;

    await _persistLocation(pending.location);
    return pending.location;
  }

  ReaderLocation _resolveScrollLocation({
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

  ReaderLocation _resolveSlideLocation({
    required int chapterIndex,
    required int pageIndex,
    required List<TextPage> slidePages,
  }) {
    if (pageIndex >= 0 && pageIndex < slidePages.length) {
      final page = slidePages[pageIndex];
      final layout = _lineLayoutForChapter(page.chapterIndex);
      final charOffset = layout?.charOffsetForPageIndex(page.index) ?? 0;
      return ReaderLocation(
        chapterIndex: page.chapterIndex,
        charOffset: charOffset,
      );
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
}
