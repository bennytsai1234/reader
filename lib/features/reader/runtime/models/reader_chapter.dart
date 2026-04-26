import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/line_layout.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_chapter_metrics.dart';
import 'package:inkpage_reader/features/reader/runtime/models/read_aloud_segment.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_paragraph.dart';

class ReaderChapter {
  final BookChapter chapter;
  final int index;
  final String title;
  final List<TextPage> pages;
  final int contentLength;
  final List<PageGroup> pageGroups;
  final List<int> pageStartOffsets;
  final List<int> pageEndOffsets;
  final LineLayout lineLayout;
  final ReaderChapterMetrics metrics;

  ReaderChapter({
    required this.chapter,
    required this.index,
    required this.title,
    required this.pages,
    int? contentLength,
    List<int>? pageStartOffsets,
    List<int>? pageEndOffsets,
    LineLayout? lineLayout,
    ReaderChapterMetrics? metrics,
  }) : lineLayout =
           lineLayout ?? LineLayout.fromPages(pages, chapterIndex: index),
       pageGroups = List<PageGroup>.unmodifiable(
         (lineLayout ?? LineLayout.fromPages(pages, chapterIndex: index))
             .pageGroups,
       ),
       pageStartOffsets = List<int>.unmodifiable(
         pageStartOffsets ??
             (lineLayout ?? LineLayout.fromPages(pages, chapterIndex: index))
                 .pageStartOffsets,
       ),
       pageEndOffsets = List<int>.unmodifiable(
         pageEndOffsets ??
             (lineLayout ?? LineLayout.fromPages(pages, chapterIndex: index))
                 .pageEndOffsets,
       ),
       contentLength =
           contentLength ??
           (lineLayout ?? LineLayout.fromPages(pages, chapterIndex: index))
               .endCharOffset,
       metrics = metrics ?? ReaderChapterMetrics.fromPages(pages);

  int get pageCount => pageGroups.length;
  int get lastIndex => pageGroups.isEmpty ? -1 : pageGroups.length - 1;
  bool get isEmpty => pageGroups.isEmpty;
  TextPage? get firstPage => pages.isEmpty ? null : pages.first;
  TextPage? get lastPage => pages.isEmpty ? null : pages.last;
  int get lastReadLength => getReadLength(lastIndex);
  double get chapterHeight => metrics.contentHeight;

  late final List<ReaderParagraph> paragraphs = _buildParagraphs();
  late final List<ReaderParagraph> pageParagraphs = _buildPageParagraphs();

  TextPage? pageAt(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pages.length) return null;
    return pages[pageIndex];
  }

  TextPage? getPageByReadPos(int readPos) {
    final index = getPageIndexByCharIndex(readPos);
    if (index < 0) return null;
    return pageAt(index);
  }

  TextPage? pageAtLocalOffset(double localOffset) {
    final pageIndex = pageIndexAtLocalOffset(localOffset);
    if (pageIndex < 0) return null;
    return pageAt(pageIndex);
  }

  int getReadLength(int pageIndex) {
    if (pageGroups.isEmpty || pageIndex < 0) return 0;
    final safeIndex = pageIndex.clamp(0, pageGroups.length - 1);
    return pageStartOffsets[safeIndex];
  }

  int getPageIndexByCharIndex(int charIndex) {
    if (pageGroups.isEmpty) return -1;
    return lineLayout.findPageIndexByCharOffset(charIndex);
  }

  TextLine? lineAtCharOffset(int charOffset) {
    return locateLineAtCharOffset(charOffset)?.line;
  }

  ({TextLine line, int pageIndex, int lineIndex})? locateLineAtCharOffset(
    int charOffset,
  ) {
    return lineLayout.locateLineAtCharOffset(charOffset);
  }

  ReaderParagraph? paragraphAtCharOffset(
    int charOffset, {
    bool pageSplit = false,
  }) {
    for (final paragraph in getParagraphs(pageSplit: pageSplit)) {
      if (paragraph.containsCharOffset(charOffset)) {
        return paragraph;
      }
    }
    return null;
  }

  int charOffsetFromLocalOffset(double localOffset) {
    return lineLayout.charOffsetFromLocalOffset(localOffset);
  }

  double localOffsetFromCharOffset(int charOffset) {
    return lineLayout.localOffsetForCharOffset(charOffset);
  }

  double alignmentForCharOffset(int charOffset) {
    final total = chapterHeight;
    if (total <= 0) return 0.0;
    return (localOffsetFromCharOffset(charOffset) / total).clamp(0.0, 1.0);
  }

  int pageIndexAtLocalOffset(double localOffset) {
    return pageGroups.isEmpty
        ? -1
        : lineLayout.pageIndexAtLocalOffset(localOffset);
  }

  int charOffsetForPageIndex(int pageIndex) {
    if (pageGroups.isEmpty) return 0;
    final safeIndex = pageIndex.clamp(0, pageGroups.length - 1);
    return pageGroups[safeIndex].firstCharOffset;
  }

  int nextPageStartCharOffset(int charOffset) {
    final pageIndex = getPageIndexByCharIndex(charOffset);
    if (pageIndex < 0 || pageIndex >= lastIndex) return -1;
    return charOffsetForPageIndex(pageIndex + 1);
  }

  int prevPageStartCharOffset(int charOffset) {
    final pageIndex = getPageIndexByCharIndex(charOffset);
    if (pageIndex <= 0) return -1;
    return charOffsetForPageIndex(pageIndex - 1);
  }

  double localOffsetForPageIndex(int pageIndex) {
    if (pageGroups.isEmpty) return 0.0;
    final charOffset = charOffsetForPageIndex(pageIndex);
    return localOffsetFromCharOffset(charOffset);
  }

  double pageHeightAt(int pageIndex) {
    return lineLayout.pageHeightAt(pageIndex);
  }

  bool isCharOffsetVisibleInPage(int charOffset, int pageIndex) {
    if (pageIndex < 0 || pageIndex >= pageGroups.length) return false;
    return pageGroups[pageIndex].containsCharOffset(charOffset);
  }

  ({
    int pageIndex,
    int pageStartCharOffset,
    double pageStartLocalOffset,
    double intraPageOffset,
  })
  resolveLocalOffsetTarget(double localOffset) {
    final pageIndex = pageIndexAtLocalOffset(localOffset);
    final safePageIndex = pageIndex < 0 ? 0 : pageIndex;
    final pageStartCharOffset = charOffsetForPageIndex(safePageIndex);
    final pageStartLocalOffset = localOffsetFromCharOffset(pageStartCharOffset);
    final intraPageOffset = (localOffset - pageStartLocalOffset).clamp(
      0.0,
      double.infinity,
    );
    return (
      pageIndex: safePageIndex,
      pageStartCharOffset: pageStartCharOffset,
      pageStartLocalOffset: pageStartLocalOffset,
      intraPageOffset: intraPageOffset,
    );
  }

  ({int start, int end, int pageIndex, int paragraphNum}) resolveHighlightRange(
    int charOffset, {
    bool pageSplit = true,
  }) {
    final pageIndex = getPageIndexByCharIndex(charOffset);
    final safePageIndex = pageIndex < 0 ? 0 : pageIndex;
    final paragraph = paragraphAtCharOffset(charOffset, pageSplit: pageSplit);
    if (paragraph == null) {
      return (
        start: charOffset,
        end: charOffset + 1,
        pageIndex: safePageIndex,
        paragraphNum: -1,
      );
    }
    return (
      start: paragraph.chapterPosition,
      end: paragraph.chapterEndPosition,
      pageIndex: safePageIndex,
      paragraphNum: paragraph.num,
    );
  }

  ({
    int pageIndex,
    int pageStartCharOffset,
    double pageStartLocalOffset,
    double targetLocalOffset,
    double intraPageOffset,
    double alignment,
  })
  resolveRestoreTarget({int? charOffset, double? localOffset}) {
    final targetLocalOffset =
        localOffset ?? localOffsetFromCharOffset(charOffset ?? 0);
    final target = resolveLocalOffsetTarget(targetLocalOffset);
    return (
      pageIndex: target.pageIndex,
      pageStartCharOffset: target.pageStartCharOffset,
      pageStartLocalOffset: target.pageStartLocalOffset,
      targetLocalOffset: targetLocalOffset,
      intraPageOffset: target.intraPageOffset,
      alignment: alignmentForCharOffset(
        charOffset ?? target.pageStartCharOffset,
      ),
    );
  }

  ({int pageIndex, double localOffset, double alignment}) resolveScrollAnchor(
    int charOffset, {
    double anchorPadding = 0.0,
  }) {
    final localOffset = localOffsetFromCharOffset(charOffset);
    final targetLocalOffset = (localOffset - anchorPadding).clamp(
      0.0,
      double.infinity,
    );
    return (
      pageIndex: pageIndexAtLocalOffset(localOffset),
      localOffset: targetLocalOffset,
      alignment: alignmentForCharOffset(charOffset),
    );
  }

  int getNextPageLength(int charIndex) {
    final pageIndex = getPageIndexByCharIndex(charIndex);
    if (pageIndex + 1 >= pages.length) return -1;
    return getReadLength(pageIndex + 1);
  }

  int getPrevPageLength(int charIndex) {
    final pageIndex = getPageIndexByCharIndex(charIndex);
    if (pageIndex - 1 < 0) return -1;
    return getReadLength(pageIndex - 1);
  }

  int firstCharOffset(TextPage page) {
    if (page.chapterIndex == index &&
        page.index >= 0 &&
        page.index < pageGroups.length) {
      return pageGroups[page.index].firstCharOffset;
    }
    return LineLayout.fromPages([
      page,
    ], chapterIndex: page.chapterIndex).firstCharOffset;
  }

  List<TextLine> allLines() {
    return lineLayout.allLines();
  }

  String getContent() {
    return pages
        .expand((page) => page.lines)
        .map((line) => line.text + (line.isParagraphEnd ? '\n' : ''))
        .join();
  }

  String getUnRead(int pageIndex) {
    if (pages.isEmpty || pageIndex < 0 || pageIndex > lastIndex) return '';
    return pages
        .skip(pageIndex)
        .expand((page) => page.lines)
        .map((line) => line.text + (line.isParagraphEnd ? '\n' : ''))
        .join();
  }

  String getNeedReadAloud({
    required int pageIndex,
    required bool pageSplit,
    required int startPos,
    int? pageEndIndex,
  }) {
    if (pages.isEmpty || pageIndex < 0 || pageIndex > lastIndex) return '';
    final endIndex = (pageEndIndex ?? lastIndex).clamp(pageIndex, lastIndex);
    final buffer = StringBuffer();
    for (var index = pageIndex; index <= endIndex; index++) {
      final page = pages[index];
      for (final line in page.lines) {
        buffer.write(line.text);
        if (line.isParagraphEnd || pageSplit) {
          buffer.write('\n');
        }
      }
    }
    final text = buffer.toString();
    if (startPos <= 0) return text;
    if (startPos >= text.length) return '';
    return text.substring(startPos);
  }

  int getParagraphNum(int position, {required bool pageSplit}) {
    for (final paragraph in getParagraphs(pageSplit: pageSplit)) {
      if (paragraph.containsCharOffset(position)) {
        return paragraph.num;
      }
    }
    return -1;
  }

  List<ReaderParagraph> getParagraphs({required bool pageSplit}) {
    return pageSplit ? pageParagraphs : paragraphs;
  }

  int getLastParagraphPosition() {
    if (pageParagraphs.isEmpty) return 0;
    return pageParagraphs.last.chapterPosition;
  }

  bool containsCharOffset(int charOffset) {
    return lineLayout.containsCharOffset(charOffset);
  }

  int pageEndCharOffset(TextPage page) {
    if (page.chapterIndex == index &&
        page.index >= 0 &&
        page.index < pageGroups.length) {
      return pageGroups[page.index].endCharOffset;
    }
    return LineLayout.fromPages([
      page,
    ], chapterIndex: page.chapterIndex).endCharOffset;
  }

  List<TextLine> visibleLinesFrom(int startCharOffset) {
    return lineLayout.visibleLinesFrom(startCharOffset);
  }

  ({
    String text,
    int baseOffset,
    List<({int ttsOffset, int chapterOffset})> offsetMap,
  })?
  buildReadAloudData({required int startCharOffset}) {
    final visibleSegments = <({TextLine line, int startOffset})>[];
    for (final page in pages) {
      for (final line in page.lines) {
        final lineStart = line.chapterPosition;
        final lineEnd = lineStart + line.text.length;
        if (startCharOffset <= lineStart) {
          visibleSegments.add((line: line, startOffset: 0));
          continue;
        }
        if (startCharOffset > lineStart && startCharOffset < lineEnd) {
          visibleSegments.add((
            line: line,
            startOffset: startCharOffset - lineStart,
          ));
        }
      }
    }
    if (visibleSegments.isEmpty) return null;

    final buffer = StringBuffer();
    final map = <({int ttsOffset, int chapterOffset})>[];
    var ttsPos = 0;
    var lastParagraphNum = -1;
    for (final segment in visibleSegments) {
      final line = segment.line;
      final startOffset = segment.startOffset;
      if (lastParagraphNum != -1 && line.paragraphNum != lastParagraphNum) {
        buffer.write('\n');
        ttsPos += 1;
      }
      final text =
          startOffset <= 0 ? line.text : line.text.substring(startOffset);
      if (text.isEmpty) {
        lastParagraphNum = line.paragraphNum;
        continue;
      }
      map.add((
        ttsOffset: ttsPos,
        chapterOffset: line.chapterPosition + startOffset,
      ));
      buffer.write(text);
      ttsPos += text.length;
      lastParagraphNum = line.paragraphNum;
    }
    if (map.isEmpty || buffer.isEmpty) return null;
    return (
      text: buffer.toString(),
      baseOffset: map.first.chapterOffset,
      offsetMap: map,
    );
  }

  ReadAloudBuildResult? buildReadAloudSegments({required int startCharOffset}) {
    final segments = <ReadAloudSegment>[];
    for (var pageIndex = 0; pageIndex < pages.length; pageIndex++) {
      final page = pages[pageIndex];
      for (var lineIndex = 0; lineIndex < page.lines.length; lineIndex++) {
        final line = page.lines[lineIndex];
        final lineStart = line.chapterPosition;
        final lineEnd = lineStart + line.text.length;
        if (lineEnd <= startCharOffset) continue;

        final speakStart =
            startCharOffset > lineStart ? startCharOffset - lineStart : 0;
        final text =
            speakStart <= 0 ? line.text : line.text.substring(speakStart);
        if (text.trim().isEmpty) continue;

        segments.add(
          ReadAloudSegment(
            chapterIndex: index,
            pageIndex: pageIndex,
            lineIndex: lineIndex,
            chapterStart: lineStart + speakStart,
            chapterEnd: lineEnd,
            text: text,
          ),
        );
      }
    }

    if (segments.isEmpty) return null;
    return ReadAloudBuildResult(
      chapterIndex: index,
      startCharOffset: startCharOffset,
      segments: List<ReadAloudSegment>.unmodifiable(segments),
    );
  }

  ReadAloudBuildResult? buildParagraphReadAloudSegments({
    required int startCharOffset,
  }) {
    final segments = <ReadAloudSegment>[];

    for (final paragraph in paragraphs) {
      if (paragraph.textLines.isEmpty) continue;

      final paragraphEnd = paragraph.chapterEndPosition;
      if (paragraphEnd <= startCharOffset) continue;

      final buffer = StringBuffer();
      final offsetMap = <ReadAloudOffsetMap>[];
      int? segmentStart;
      int? firstPageIndex;
      int? firstLineIndex;

      for (final line in paragraph.textLines) {
        final lineStart = line.chapterPosition;
        final lineEnd = lineStart + line.text.length;
        if (lineEnd <= startCharOffset) continue;

        final speakStart =
            startCharOffset > lineStart ? startCharOffset - lineStart : 0;
        final text =
            speakStart <= 0 ? line.text : line.text.substring(speakStart);
        if (text.isEmpty) continue;

        final chapterOffset = lineStart + speakStart;
        segmentStart ??= chapterOffset;
        final locatedLine = locateLineAtCharOffset(chapterOffset);
        firstPageIndex ??= locatedLine?.pageIndex;
        firstLineIndex ??= locatedLine?.lineIndex;
        offsetMap.add(
          ReadAloudOffsetMap(
            ttsOffset: buffer.length,
            chapterOffset: chapterOffset,
          ),
        );
        buffer.write(text);
      }

      final speakText = buffer.toString();
      if (speakText.trim().isEmpty || segmentStart == null) continue;

      segments.add(
        ReadAloudSegment(
          chapterIndex: index,
          pageIndex: firstPageIndex ?? getPageIndexByCharIndex(segmentStart),
          lineIndex: firstLineIndex ?? -1,
          chapterStart: segmentStart,
          chapterEnd: paragraphEnd,
          text: speakText,
          offsetMap: List<ReadAloudOffsetMap>.unmodifiable(offsetMap),
        ),
      );
    }

    if (segments.isEmpty) return null;
    return ReadAloudBuildResult(
      chapterIndex: index,
      startCharOffset: startCharOffset,
      segments: List<ReadAloudSegment>.unmodifiable(segments),
    );
  }

  List<ReaderParagraph> _buildParagraphs() {
    final grouped = <int, List<TextLine>>{};
    for (final line in allLines()) {
      if (line.paragraphNum <= 0) continue;
      grouped.putIfAbsent(line.paragraphNum, () => <TextLine>[]).add(line);
    }
    final entries =
        grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((entry) => ReaderParagraph(num: entry.key, textLines: entry.value))
        .toList();
  }

  List<ReaderParagraph> _buildPageParagraphs() {
    final paragraphs = <ReaderParagraph>[];
    for (final page in pages) {
      final grouped = <int, List<TextLine>>{};
      for (final line in page.lines) {
        if (line.paragraphNum <= 0) continue;
        grouped.putIfAbsent(line.paragraphNum, () => <TextLine>[]).add(line);
      }
      final pageParagraphs =
          grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in pageParagraphs) {
        paragraphs.add(
          ReaderParagraph(num: paragraphs.length + 1, textLines: entry.value),
        );
      }
    }
    return paragraphs;
  }
}
