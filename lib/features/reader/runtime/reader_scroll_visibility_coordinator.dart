class ReaderScrollVisibilityUpdate {
  final List<int> chaptersToEnsure;
  final int? preloadCenterChapter;

  const ReaderScrollVisibilityUpdate({
    this.chaptersToEnsure = const [],
    this.preloadCenterChapter,
  });
}

class ReaderScrollVisibilityCoordinator {
  final Set<int> _requestedVisibleChapterLoads = <int>{};
  int _lastPreloadChapterIndex = -1;

  void reconcile(bool Function(int chapterIndex) hasRuntimeChapter) {
    _requestedVisibleChapterLoads.removeWhere(hasRuntimeChapter);
  }

  ReaderScrollVisibilityUpdate evaluate({
    required List<int> visibleChapterIndexes,
    required int currentChapterIndex,
    required bool Function(int chapterIndex) hasRuntimeChapter,
    required bool Function(int chapterIndex) isLoadingChapter,
  }) {
    final chaptersToEnsure = <int>[];
    for (final visibleChapter in visibleChapterIndexes) {
      if (hasRuntimeChapter(visibleChapter) ||
          isLoadingChapter(visibleChapter) ||
          _requestedVisibleChapterLoads.contains(visibleChapter)) {
        continue;
      }
      if ((visibleChapter - currentChapterIndex).abs() > 1) continue;
      _requestedVisibleChapterLoads.add(visibleChapter);
      chaptersToEnsure.add(visibleChapter);
    }

    int? preloadCenterChapter;
    if (visibleChapterIndexes.isNotEmpty) {
      final topChapter = visibleChapterIndexes.first;
      if (_lastPreloadChapterIndex != topChapter || chaptersToEnsure.isNotEmpty) {
        _lastPreloadChapterIndex = topChapter;
        preloadCenterChapter = topChapter;
      }
    }

    return ReaderScrollVisibilityUpdate(
      chaptersToEnsure: chaptersToEnsure,
      preloadCenterChapter: preloadCenterChapter,
    );
  }
}
