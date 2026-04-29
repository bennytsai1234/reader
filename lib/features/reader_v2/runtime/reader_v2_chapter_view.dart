import 'dart:ui';

import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_layout.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_render_page.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_text_adapter.dart';

class ReaderV2ChapterView {
  ReaderV2ChapterView(
    this.layout, {
    required this.chapterSize,
    required this.title,
  }) : pages = layout.pages
           .map(
             (slice) => readerV2PageSliceToRenderPage(
               layout: layout,
               slice: slice,
               chapterSize: chapterSize,
               title: title,
             ),
           )
           .toList(growable: false),
       lines = layout.lines
           .map(readerV2TextLineToRenderLine)
           .toList(growable: false);

  final ReaderV2ChapterLayout layout;
  final int chapterSize;
  final String title;
  final List<ReaderV2RenderPage> pages;
  final List<ReaderV2RenderLine> lines;

  int get chapterIndex => layout.chapterIndex;
  String get displayText => layout.displayText;
  String get contentHash => layout.contentHash;
  String get layoutSignature => layout.layoutSignature;
  double get contentHeight => layout.contentHeight;

  ReaderV2RenderPage pageForCharOffset(int charOffset) {
    if (pages.isEmpty) {
      return ReaderV2RenderPage(
        pageIndex: 0,
        chapterIndex: chapterIndex,
        lines: const <ReaderV2RenderLine>[],
        height: 1,
      );
    }
    for (final page in pages) {
      if (page.containsCharOffset(charOffset)) return page;
    }
    final line = lineForCharOffset(charOffset);
    if (line != null) {
      final page = pageForLocalY(line.top);
      if (page != null) return page;
    }
    if (charOffset <= pages.first.startCharOffset) return pages.first;
    var best = pages.first;
    for (final page in pages) {
      if (page.startCharOffset <= charOffset) {
        best = page;
      } else {
        break;
      }
    }
    return best;
  }

  ReaderV2RenderLine? lineForCharOffset(int charOffset) {
    final queryLines = lines;
    if (queryLines.isEmpty) return null;
    ReaderV2RenderLine? previous;
    for (var index = 0; index < queryLines.length; index++) {
      final line = queryLines[index];
      if (line.text.isEmpty) continue;
      final effectiveEnd = _effectiveLineEnd(queryLines, index);
      if (charOffset >= line.startCharOffset && charOffset < effectiveEnd) {
        return line;
      }
      if (charOffset < line.startCharOffset) return line;
      previous = line;
    }
    return previous;
  }

  ReaderV2RenderPage? pageForLine(ReaderV2RenderLine line) =>
      pageForLocalY(line.top);

  ReaderV2RenderLine? lineAtOrNearLocalY(double localY) {
    ReaderV2RenderLine? nearest;
    var nearestDistance = double.infinity;
    for (final line in lines) {
      if (line.text.isEmpty) continue;
      if (localY >= line.top && localY <= line.bottom) return line;
      final distance =
          localY < line.top ? line.top - localY : localY - line.bottom;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = line;
      }
    }
    return nearest;
  }

  ReaderV2RenderPage? pageForLocalY(double localY) {
    if (pages.isEmpty) return null;
    if (localY <= pages.first.localStartY) return pages.first;
    var best = pages.first;
    for (final page in pages) {
      if (page.localStartY <= localY) {
        best = page;
      } else {
        break;
      }
    }
    return best;
  }

  List<ReaderV2RenderLine> linesForRange(
    int startCharOffset,
    int endCharOffset,
  ) {
    final start =
        startCharOffset <= endCharOffset ? startCharOffset : endCharOffset;
    final end =
        startCharOffset <= endCharOffset ? endCharOffset : startCharOffset;
    if (start == end) {
      final line = lineForCharOffset(start);
      return line == null
          ? const <ReaderV2RenderLine>[]
          : <ReaderV2RenderLine>[line];
    }
    final queryLines = lines;
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

  int _effectiveLineEnd(List<ReaderV2RenderLine> queryLines, int index) {
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
