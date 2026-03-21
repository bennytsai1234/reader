class ReaderTtsFollowTarget {
  final int chapterIndex;
  final double localOffset;
  final double topPadding;

  const ReaderTtsFollowTarget({
    required this.chapterIndex,
    required this.localOffset,
    required this.topPadding,
  });
}

class ReaderTtsFollowCoordinator {
  const ReaderTtsFollowCoordinator();

  ReaderTtsFollowTarget? evaluate({
    required int chapterIndex,
    required int visibleChapterIndex,
    required double targetLocalOffset,
    required double visibleChapterLocalOffset,
    required double viewportHeight,
  }) {
    if (viewportHeight <= 0) return null;
    final anchorPadding = viewportHeight * 0.12;
    if (chapterIndex == visibleChapterIndex) {
      final visibleTop = visibleChapterLocalOffset;
      if (targetLocalOffset <= anchorPadding && visibleTop <= 2.0) {
        return null;
      }
      final anchorTop = visibleTop;
      final anchorBottom = visibleTop + anchorPadding;
      if (targetLocalOffset >= anchorTop && targetLocalOffset <= anchorBottom) {
        return null;
      }
    }
    return ReaderTtsFollowTarget(
      chapterIndex: chapterIndex,
      localOffset: targetLocalOffset,
      topPadding: targetLocalOffset < anchorPadding ? 0.0 : anchorPadding,
    );
  }
}
