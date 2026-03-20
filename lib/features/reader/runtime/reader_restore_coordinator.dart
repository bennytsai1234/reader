class ReaderRestoreCoordinator {
  int _pendingScrollRestoreToken = 0;
  int? _pendingScrollRestoreChapterIndex;
  double? _pendingScrollRestoreLocalOffset;

  int registerPendingScrollRestore({
    required int chapterIndex,
    required double localOffset,
  }) {
    _pendingScrollRestoreToken++;
    _pendingScrollRestoreChapterIndex = chapterIndex;
    _pendingScrollRestoreLocalOffset = localOffset;
    return _pendingScrollRestoreToken;
  }

  int get pendingScrollRestoreToken => _pendingScrollRestoreToken;
  int? get pendingScrollRestoreChapterIndex => _pendingScrollRestoreChapterIndex;
  double? get pendingScrollRestoreLocalOffset => _pendingScrollRestoreLocalOffset;

  bool matchesPendingScrollRestore(int token) =>
      token == _pendingScrollRestoreToken;

  ({int chapterIndex, double localOffset})? consumePendingScrollRestore() {
    final chapterIndex = _pendingScrollRestoreChapterIndex;
    final localOffset = _pendingScrollRestoreLocalOffset;
    if (chapterIndex == null || localOffset == null) return null;
    return (chapterIndex: chapterIndex, localOffset: localOffset);
  }

  void clear() {
    _pendingScrollRestoreChapterIndex = null;
    _pendingScrollRestoreLocalOffset = null;
  }
}
