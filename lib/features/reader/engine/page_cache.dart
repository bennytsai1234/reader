import 'dart:ui';

import 'text_page.dart';

class PageCache {
  PageCache({
    required this.chapterIndex,
    required this.pageIndexInChapter,
    required this.startCharOffset,
    required this.endCharOffset,
    required this.localStartY,
    required this.localEndY,
    required this.width,
    required this.height,
    required List<TextLine> lines,
  }) : lines = List<TextLine>.unmodifiable(lines);

  factory PageCache.fromTextPage(TextPage page, {double? height}) {
    return PageCache(
      chapterIndex: page.chapterIndex,
      pageIndexInChapter: page.pageIndex,
      startCharOffset: page.startCharOffset,
      endCharOffset: page.endCharOffset,
      localStartY: page.localStartY,
      localEndY: page.localEndY,
      width: page.width,
      height: height ?? page.viewportHeight,
      lines: page.lines,
    );
  }

  final int chapterIndex;
  final int pageIndexInChapter;
  final int startCharOffset;
  final int endCharOffset;
  final double localStartY;
  final double localEndY;
  final double width;
  final double height;
  final List<TextLine> lines;

  int get pageIndex => pageIndexInChapter;

  double get contentHeight =>
      (localEndY - localStartY).clamp(0.0, double.infinity).toDouble();

  bool containsCharOffset(int charOffset) {
    if (lines.isEmpty) return charOffset == startCharOffset;
    if (charOffset < startCharOffset || charOffset > endCharOffset) {
      return false;
    }
    return charOffset < endCharOffset;
  }

  bool intersectsCharRange(int startCharOffset, int endCharOffset) {
    final start =
        startCharOffset <= endCharOffset ? startCharOffset : endCharOffset;
    final end =
        startCharOffset <= endCharOffset ? endCharOffset : startCharOffset;
    if (start == end) return containsCharOffset(start);
    return end > this.startCharOffset && start < this.endCharOffset;
  }

  bool containsLocalY(double localY) {
    return localY >= localStartY && localY < localEndY;
  }

  TextLine? lineForCharOffset(int charOffset) {
    TextLine? previous;
    for (final line in lines) {
      if (line.text.isEmpty) continue;
      if (charOffset >= line.startCharOffset &&
          charOffset < line.endCharOffset) {
        return line;
      }
      if (charOffset < line.startCharOffset) return line;
      previous = line;
    }
    return previous;
  }

  TextLine? lineAtOrNearLocalY(double localY) {
    if (lines.isEmpty) return null;
    final pageLocalY =
        (localY - localStartY).clamp(0.0, contentHeight).toDouble();
    TextLine? nearest;
    var nearestDistance = double.infinity;
    for (final line in lines) {
      if (line.text.isEmpty) continue;
      if (pageLocalY >= line.top && pageLocalY <= line.bottom) return line;
      final distance =
          pageLocalY < line.top
              ? line.top - pageLocalY
              : pageLocalY - line.bottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = line;
      }
    }
    return nearest;
  }

  List<TextLine> linesForRange(int startCharOffset, int endCharOffset) {
    final start =
        startCharOffset <= endCharOffset ? startCharOffset : endCharOffset;
    final end =
        startCharOffset <= endCharOffset ? endCharOffset : startCharOffset;
    if (start == end) {
      final line = lineForCharOffset(start);
      return line == null ? const <TextLine>[] : <TextLine>[line];
    }
    return lines
        .where(
          (line) =>
              line.text.isNotEmpty &&
              line.endCharOffset > start &&
              line.startCharOffset < end,
        )
        .toList(growable: false);
  }

  List<Rect> fullLineRectsForRange({
    required int startCharOffset,
    required int endCharOffset,
    double pageTopOnScreen = 0.0,
  }) {
    return linesForRange(startCharOffset, endCharOffset)
        .map(
          (line) => Rect.fromLTRB(
            0,
            pageTopOnScreen + line.top,
            width,
            pageTopOnScreen + line.bottom,
          ),
        )
        .toList(growable: false);
  }

  PageCache copyWith({
    int? chapterIndex,
    int? pageIndexInChapter,
    int? startCharOffset,
    int? endCharOffset,
    double? localStartY,
    double? localEndY,
    double? width,
    double? height,
    List<TextLine>? lines,
  }) {
    return PageCache(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      pageIndexInChapter: pageIndexInChapter ?? this.pageIndexInChapter,
      startCharOffset: startCharOffset ?? this.startCharOffset,
      endCharOffset: endCharOffset ?? this.endCharOffset,
      localStartY: localStartY ?? this.localStartY,
      localEndY: localEndY ?? this.localEndY,
      width: width ?? this.width,
      height: height ?? this.height,
      lines: lines ?? this.lines,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is PageCache &&
        other.chapterIndex == chapterIndex &&
        other.pageIndexInChapter == pageIndexInChapter &&
        other.startCharOffset == startCharOffset &&
        other.endCharOffset == endCharOffset &&
        other.localStartY == localStartY &&
        other.localEndY == localEndY &&
        other.width == width &&
        other.height == height &&
        _sameLines(other.lines, lines);
  }

  @override
  int get hashCode => Object.hash(
    chapterIndex,
    pageIndexInChapter,
    startCharOffset,
    endCharOffset,
    localStartY,
    localEndY,
    width,
    height,
    Object.hashAll(lines),
  );

  static bool _sameLines(List<TextLine> a, List<TextLine> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var index = 0; index < a.length; index++) {
      if (!identical(a[index], b[index]) && a[index] != b[index]) {
        return false;
      }
    }
    return true;
  }
}

extension TextPageCacheAdapter on TextPage {
  PageCache toPageCache({double? height}) {
    return PageCache.fromTextPage(this, height: height);
  }
}

class ScrollPagePlacement {
  const ScrollPagePlacement({required this.page, required this.virtualTop});

  final PageCache page;
  final double virtualTop;

  double screenY(double virtualScrollY) => virtualTop - virtualScrollY;
}

class SlidePagePlacement {
  const SlidePagePlacement({
    required this.page,
    required this.virtualLeft,
    required this.pageSlot,
  });

  final PageCache page;
  final double virtualLeft;
  final int pageSlot;

  double screenX(double pageOffsetX) => virtualLeft - pageOffsetX;
}
