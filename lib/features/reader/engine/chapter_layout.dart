import 'dart:ui';

import 'page_cache.dart';
import 'text_page.dart';

class ChapterLayout {
  const ChapterLayout({
    required this.chapterIndex,
    this.displayText = '',
    required this.contentHash,
    required this.layoutSignature,
    required this.lines,
    required this.pages,
    this.contentHeight = 0.0,
  });

  final int chapterIndex;
  final String displayText;
  final String contentHash;
  final String layoutSignature;
  final List<TextLine> lines;
  final List<TextPage> pages;
  final double contentHeight;

  List<PageCache> get pageCaches {
    return pages.map((page) => page.toPageCache()).toList(growable: false);
  }

  TextPage pageForCharOffset(int charOffset) {
    if (pages.isEmpty) {
      return TextPage(
        pageIndex: 0,
        chapterIndex: chapterIndex,
        lines: const <TextLine>[],
        height: 1,
      );
    }
    for (final page in pages) {
      if (page.containsCharOffset(charOffset)) {
        return page;
      }
    }
    final line = lineForCharOffset(charOffset);
    if (line != null) {
      final page = pageForLocalY(line.top);
      if (page != null) return page;
    }
    if (charOffset <= pages.first.startCharOffset) {
      return pages.first;
    }
    var best = pages.first;
    for (final page in pages) {
      if (page.startCharOffset <= charOffset) {
        best = page;
        continue;
      }
      break;
    }
    return best;
  }

  TextLine? lineForCharOffset(int charOffset) {
    final queryLines = _queryLines;
    if (queryLines.isEmpty) return null;
    TextLine? previous;
    for (var index = 0; index < queryLines.length; index++) {
      final line = queryLines[index];
      if (line.text.isEmpty) continue;
      final effectiveEnd = _effectiveLineEnd(queryLines, index);
      if (charOffset >= line.startCharOffset && charOffset < effectiveEnd) {
        return line;
      }
      if (charOffset < line.startCharOffset) {
        return line;
      }
      previous = line;
    }
    return previous;
  }

  TextLine? lineAtOrNearLocalY(double localY) {
    final queryLines = _queryLines.where((line) => line.text.isNotEmpty);
    TextLine? nearest;
    var nearestDistance = double.infinity;
    for (final line in queryLines) {
      if (localY >= line.top && localY <= line.bottom) {
        return line;
      }
      final distance =
          localY < line.top ? line.top - localY : localY - line.bottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = line;
      }
    }
    return nearest;
  }

  TextPage? pageForLocalY(double localY) {
    if (pages.isEmpty) return null;
    if (pages.any((page) => page.hasExplicitLocalRange)) {
      final safeY = localY.clamp(0.0, _lastPageBottom).toDouble();
      for (final page in pages) {
        if (safeY >= page.localStartY && safeY < page.localEndY) {
          return page;
        }
      }
      return pages.last;
    }

    var top = 0.0;
    for (final page in pages) {
      final bottom = top + page.height;
      if (localY >= top && localY < bottom) return page;
      top = bottom;
    }
    return localY <= 0 ? pages.first : pages.last;
  }

  TextPage pageForLocalYOrFirst(double localY) {
    return pageForLocalY(localY) ?? pageForCharOffset(0);
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
    final queryLines = _queryLines;
    return queryLines
        .asMap()
        .entries
        .where((entry) {
          final line = entry.value;
          if (line.text.isEmpty) return false;
          return _effectiveLineEnd(queryLines, entry.key) > start &&
              line.startCharOffset < end;
        })
        .map((entry) => entry.value)
        .toList(growable: false);
  }

  List<Rect> fullLineRectsForRange({
    required int startCharOffset,
    required int endCharOffset,
    double pageTopOnScreen = 0.0,
  }) {
    return linesForRange(startCharOffset, endCharOffset)
        .map((line) {
          final page = pageForLocalY(line.top);
          final pageTop = page?.localStartY ?? 0.0;
          final width = (page?.width ?? 0) > 0 ? page!.width : line.width;
          return Rect.fromLTRB(
            0,
            pageTopOnScreen + line.top - pageTop,
            width,
            pageTopOnScreen + line.bottom - pageTop,
          );
        })
        .toList(growable: false);
  }

  double get _lastPageBottom {
    if (pages.isEmpty) return 0.0;
    return pages
        .map((page) => page.localEndY)
        .fold<double>(0, (max, bottom) => bottom > max ? bottom : max);
  }

  List<TextLine> get _queryLines {
    if (lines.isNotEmpty) return lines;
    final resolved = <TextLine>[];
    var pageTop = 0.0;
    for (final page in pages) {
      final top = page.hasExplicitLocalRange ? page.localStartY : pageTop;
      for (final line in page.lines) {
        resolved.add(
          line.copyWith(
            lineTop: top + line.lineTop,
            lineBottom: top + line.lineBottom,
            baseline: top + line.baseline,
          ),
        );
      }
      pageTop = top + page.height;
    }
    return resolved;
  }

  int _effectiveLineEnd(List<TextLine> queryLines, int index) {
    final line = queryLines[index];
    for (
      var nextIndex = index + 1;
      nextIndex < queryLines.length;
      nextIndex++
    ) {
      final next = queryLines[nextIndex];
      if (next.text.isEmpty) continue;
      if (next.startCharOffset > line.endCharOffset) {
        return next.startCharOffset;
      }
      break;
    }
    return line.endCharOffset;
  }
}
