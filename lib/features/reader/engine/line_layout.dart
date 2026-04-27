import 'text_page.dart';

class LineItem {
  final int chapterIndex;
  final int chapterPosition;
  final TextLine line;
  final int pageIndex;
  final int lineIndex;
  final double localTop;
  final double localBottom;
  final int? _endChapterPosition;

  const LineItem({
    required this.chapterIndex,
    required this.chapterPosition,
    required this.line,
    required this.pageIndex,
    required this.lineIndex,
    required this.localTop,
    required this.localBottom,
    int? endChapterPosition,
  }) : _endChapterPosition = endChapterPosition;

  bool get isText => line.text.isNotEmpty && !line.isTitle;
  int get endChapterPosition =>
      _endChapterPosition ?? chapterPosition + _sourceTextLength(line);

  LineItem copyWithEndChapterPosition(int endChapterPosition) {
    return LineItem(
      chapterIndex: chapterIndex,
      chapterPosition: chapterPosition,
      line: line,
      pageIndex: pageIndex,
      lineIndex: lineIndex,
      localTop: localTop,
      localBottom: localBottom,
      endChapterPosition: endChapterPosition,
    );
  }

  static int _sourceTextLength(TextLine line) {
    if (!line.isParagraphStart) return line.text.length;
    return line.text.replaceFirst(RegExp(r'^[\s　]+'), '').length;
  }
}

class PageGroup {
  final int chapterIndex;
  final int pageIndex;
  final List<LineItem> items;
  final double localTop;
  final double localBottom;

  const PageGroup({
    required this.chapterIndex,
    required this.pageIndex,
    required this.items,
    required this.localTop,
    required this.localBottom,
  });

  Iterable<LineItem> get textItems => items.where((item) => item.isText);

  int get firstCharOffset {
    for (final item in textItems) {
      return item.chapterPosition;
    }
    return 0;
  }

  int get endCharOffset {
    for (final item in items.reversed) {
      if (item.isText) return item.endChapterPosition;
    }
    return firstCharOffset;
  }

  bool containsCharOffset(int charOffset) {
    if (items.isEmpty) return false;
    return charOffset >= firstCharOffset && charOffset <= endCharOffset;
  }
}

class LineLayout {
  final int chapterIndex;
  final List<LineItem> items;
  final List<PageGroup> pageGroups;
  final List<double> pageTopOffsets;
  final List<double> pageHeights;
  final double contentHeight;

  LineLayout._({
    required this.chapterIndex,
    required this.items,
    required this.pageGroups,
    required this.pageTopOffsets,
    required this.pageHeights,
    required this.contentHeight,
  });

  factory LineLayout.fromPages(List<TextPage> pages, {int? chapterIndex}) {
    final resolvedChapterIndex =
        chapterIndex ?? (pages.isEmpty ? 0 : pages.first.chapterIndex);
    final items = <LineItem>[];
    final pageTopOffsets = <double>[];
    final pageHeights = <double>[];
    var pageTop = 0.0;

    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final page = pages[pageIndex];
      pageTopOffsets.add(pageTop);
      final pageHeight = _pageHeight(page);
      pageHeights.add(pageHeight);
      for (var lineIndex = 0; lineIndex < page.lines.length; lineIndex++) {
        final line = page.lines[lineIndex];
        items.add(
          LineItem(
            chapterIndex: page.chapterIndex,
            chapterPosition: line.chapterPosition,
            line: line,
            pageIndex: pageIndex,
            lineIndex: lineIndex,
            localTop: pageTop + line.lineTop,
            localBottom: pageTop + line.lineBottom,
          ),
        );
      }
      pageTop += pageHeight;
    }

    final lineItems = _withEndPositions(items);

    final pageGroups = _buildPageGroups(
      pages: pages,
      items: lineItems,
      pageTopOffsets: pageTopOffsets,
      pageHeights: pageHeights,
      fallbackChapterIndex: resolvedChapterIndex,
    );

    return LineLayout._(
      chapterIndex: resolvedChapterIndex,
      items: List<LineItem>.unmodifiable(lineItems),
      pageGroups: List<PageGroup>.unmodifiable(pageGroups),
      pageTopOffsets: List<double>.unmodifiable(pageTopOffsets),
      pageHeights: List<double>.unmodifiable(pageHeights),
      contentHeight: pageTop,
    );
  }

  Iterable<LineItem> get textItems => items.where((item) => item.isText);

  List<TextLine> allLines() {
    return items.map((item) => item.line).toList(growable: false);
  }

  int get firstCharOffset {
    for (final item in textItems) {
      return item.chapterPosition;
    }
    return 0;
  }

  int get endCharOffset {
    for (final item in items.reversed) {
      if (item.isText) return item.endChapterPosition;
    }
    return firstCharOffset;
  }

  List<int> get pageStartOffsets {
    return pageGroups
        .map((group) => group.firstCharOffset)
        .toList(growable: false);
  }

  List<int> get pageEndOffsets {
    return pageGroups
        .map((group) => group.endCharOffset)
        .toList(growable: false);
  }

  double pageHeightAt(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pageHeights.length) return 0.0;
    return pageHeights[pageIndex];
  }

  int pageIndexAtLocalOffset(double localOffset) {
    if (pageHeights.isEmpty) return 0;
    final safeLocalOffset = localOffset.clamp(0.0, contentHeight).toDouble();
    for (var i = 0; i < pageHeights.length; i++) {
      if (pageTopOffsets[i] + pageHeights[i] > safeLocalOffset) {
        return i;
      }
    }
    return pageHeights.length - 1;
  }

  int findPageIndexByCharOffset(int charOffset) {
    if (pageGroups.isEmpty || textItems.isEmpty) return 0;
    var best = 0;
    for (final group in pageGroups) {
      final offset = group.firstCharOffset;
      if (offset <= charOffset) {
        best = group.pageIndex;
      } else {
        break;
      }
    }
    return best;
  }

  int charOffsetForPageIndex(int pageIndex) {
    if (pageGroups.isEmpty || pageIndex < 0 || pageIndex >= pageGroups.length) {
      return 0;
    }
    return pageGroups[pageIndex].firstCharOffset;
  }

  int pageEndCharOffset(int pageIndex) {
    if (pageGroups.isEmpty || pageIndex < 0 || pageIndex >= pageGroups.length) {
      return 0;
    }
    return pageGroups[pageIndex].endCharOffset;
  }

  LineItem? itemAtCharOffset(int charOffset) {
    for (final item in textItems) {
      final containsOffset =
          charOffset >= item.chapterPosition &&
          charOffset < item.endChapterPosition;
      final fallsBeforeLine = charOffset < item.chapterPosition;
      if (containsOffset || fallsBeforeLine) {
        return item;
      }
    }
    return null;
  }

  ({TextLine line, int pageIndex, int lineIndex})? locateLineAtCharOffset(
    int charOffset,
  ) {
    for (final item in textItems) {
      if (charOffset >= item.chapterPosition &&
          charOffset < item.endChapterPosition) {
        return (
          line: item.line,
          pageIndex: item.pageIndex,
          lineIndex: item.lineIndex,
        );
      }
    }
    return null;
  }

  double localOffsetForCharOffset(int charOffset) {
    if (textItems.isEmpty) return 0.0;
    final item = itemAtCharOffset(charOffset);
    return item?.localTop ?? contentHeight;
  }

  int charOffsetFromLocalOffset(double localOffset) {
    if (items.isEmpty) return 0;
    final safeLocalOffset = localOffset.clamp(0.0, contentHeight).toDouble();
    for (final item in textItems) {
      if (item.localBottom > safeLocalOffset) {
        return item.chapterPosition;
      }
    }
    return endCharOffset;
  }

  bool containsCharOffset(int charOffset) {
    if (items.isEmpty) return false;
    return charOffset >= firstCharOffset && charOffset <= endCharOffset;
  }

  List<TextLine> visibleLinesFrom(int startCharOffset) {
    return textItems
        .where((item) => item.chapterPosition >= startCharOffset)
        .map((item) => item.line)
        .toList(growable: false);
  }

  static double _pageHeight(TextPage page) {
    return page.lines.isEmpty ? 0.0 : page.lines.last.lineBottom;
  }

  static List<LineItem> _withEndPositions(List<LineItem> items) {
    final resolved = <LineItem>[];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (!item.isText) {
        resolved.add(item);
        continue;
      }
      LineItem? nextTextItem;
      for (var nextIndex = index + 1; nextIndex < items.length; nextIndex++) {
        final candidate = items[nextIndex];
        if (candidate.isText) {
          nextTextItem = candidate;
          break;
        }
      }
      final fallbackEnd = item.endChapterPosition;
      final nextStart = nextTextItem?.chapterPosition;
      final end =
          nextStart != null && nextStart >= item.chapterPosition
              ? nextStart
              : fallbackEnd;
      resolved.add(item.copyWithEndChapterPosition(end));
    }
    return resolved;
  }

  static List<PageGroup> _buildPageGroups({
    required List<TextPage> pages,
    required List<LineItem> items,
    required List<double> pageTopOffsets,
    required List<double> pageHeights,
    required int fallbackChapterIndex,
  }) {
    final groups = <PageGroup>[];
    for (var pageIndex = 0; pageIndex < pageHeights.length; pageIndex++) {
      final pageItems = items
          .where((item) => item.pageIndex == pageIndex)
          .toList(growable: false);
      groups.add(
        PageGroup(
          chapterIndex:
              pageIndex < pages.length
                  ? pages[pageIndex].chapterIndex
                  : fallbackChapterIndex,
          pageIndex: pageIndex,
          items: List<LineItem>.unmodifiable(pageItems),
          localTop: pageTopOffsets[pageIndex],
          localBottom: pageTopOffsets[pageIndex] + pageHeights[pageIndex],
        ),
      );
    }
    return groups;
  }
}
