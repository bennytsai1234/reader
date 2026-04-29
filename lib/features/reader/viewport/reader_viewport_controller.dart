typedef ReaderViewportDeltaCommand = Future<bool> Function(double delta);
typedef ReaderViewportPageCommand = Future<bool> Function();

typedef ReaderViewportEnsureRangeCommand =
    Future<bool> Function({
      required int chapterIndex,
      required int startCharOffset,
      required int endCharOffset,
    });

class ReaderViewportController {
  ReaderViewportDeltaCommand? scrollBy;
  ReaderViewportDeltaCommand? animateBy;
  ReaderViewportPageCommand? moveToNextPage;
  ReaderViewportPageCommand? moveToPrevPage;
  ReaderViewportEnsureRangeCommand? ensureCharRangeVisible;
}
