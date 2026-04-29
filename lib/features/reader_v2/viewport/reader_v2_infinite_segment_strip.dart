import 'dart:math' as math;

class ReaderV2ChapterSegment {
  ReaderV2ChapterSegment({
    required int chapterIndex,
    required double startY,
    required double height,
  }) : chapterIndex = chapterIndex < 0 ? 0 : chapterIndex,
       startY = _finite(startY),
       height = _height(height);

  final int chapterIndex;
  final double startY;
  final double height;

  double get endY => startY + height;

  static double _finite(double value) {
    return value.isFinite ? value : 0.0;
  }

  static double _height(double value) {
    final finite = _finite(value);
    return finite <= 0 ? 1.0 : finite;
  }
}

class ReaderV2InfiniteSegmentStrip {
  final Map<int, ReaderV2ChapterSegment> _segments =
      <int, ReaderV2ChapterSegment>{};

  bool get isEmpty => _segments.isEmpty;

  bool containsChapter(int chapterIndex) {
    return _segments.containsKey(chapterIndex);
  }

  ReaderV2ChapterSegment? segmentForChapter(int chapterIndex) {
    return _segments[chapterIndex];
  }

  double? chapterTop(int chapterIndex) {
    return _segments[chapterIndex]?.startY;
  }

  double? chapterEnd(int chapterIndex) {
    return _segments[chapterIndex]?.endY;
  }

  void placeChapter({
    required int chapterIndex,
    required double startY,
    required double height,
  }) {
    _segments[chapterIndex] = ReaderV2ChapterSegment(
      chapterIndex: chapterIndex,
      startY: startY,
      height: height,
    );
  }

  double placeCenterIfAbsent({
    required int chapterIndex,
    required double height,
  }) {
    final existing = chapterTop(chapterIndex);
    if (existing != null) return existing;
    placeChapter(chapterIndex: chapterIndex, startY: 0.0, height: height);
    return 0.0;
  }

  List<ReaderV2ChapterSegment> orderedSegments() {
    final segments = _segments.values.toList(growable: false)..sort((a, b) {
      final byTop = a.startY.compareTo(b.startY);
      if (byTop != 0) return byTop;
      return a.chapterIndex.compareTo(b.chapterIndex);
    });
    return segments;
  }

  void retain(Set<int> retained) {
    _segments.removeWhere(
      (chapterIndex, _) => !retained.contains(chapterIndex),
    );
  }

  void clear() {
    _segments.clear();
  }

  ({double min, double max})? scrollBounds({
    required double viewportHeight,
    required double anchorOffset,
  }) {
    final segments = orderedSegments();
    if (segments.isEmpty) return null;
    final minTop = segments.map((segment) => segment.startY).reduce(math.min);
    final maxBottom = segments.map((segment) => segment.endY).reduce(math.max);
    final minScrollY = minTop;
    final maxScrollY = math.max(
      minScrollY,
      math.max(maxBottom - viewportHeight, maxBottom - anchorOffset),
    );
    return (min: minScrollY, max: maxScrollY);
  }

  bool isNearEdge({
    required bool forward,
    required double readingY,
    required double threshold,
    required double viewportHeight,
    required double anchorOffset,
  }) {
    final bounds = scrollBounds(
      viewportHeight: viewportHeight,
      anchorOffset: anchorOffset,
    );
    if (bounds == null) return false;
    const tolerance = 0.5;
    return forward
        ? bounds.max - readingY <= threshold + tolerance
        : readingY - bounds.min <= threshold + tolerance;
  }
}
