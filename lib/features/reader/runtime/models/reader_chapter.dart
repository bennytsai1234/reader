import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_paragraph.dart';

class ReaderChapter {
  final BookChapter chapter;
  final int index;
  final String title;
  final List<TextPage> pages;

  ReaderChapter({
    required this.chapter,
    required this.index,
    required this.title,
    required this.pages,
  });

  int get pageCount => pages.length;
  int get lastIndex => pages.isEmpty ? -1 : pages.length - 1;
  bool get isEmpty => pages.isEmpty;
  TextPage? get firstPage => pages.isEmpty ? null : pages.first;
  TextPage? get lastPage => pages.isEmpty ? null : pages.last;
  int get lastReadLength => getReadLength(lastIndex);

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

  int getReadLength(int pageIndex) {
    if (pages.isEmpty || pageIndex < 0) return 0;
    final safeIndex = pageIndex.clamp(0, pages.length - 1);
    return firstCharOffset(pages[safeIndex]);
  }

  int getPageIndexByCharIndex(int charIndex) {
    if (pages.isEmpty) return -1;
    return ChapterPositionResolver.findPageIndexByCharOffset(pages, charIndex);
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
    return ChapterPositionResolver.firstCharOffset(page);
  }

  List<TextLine> allLines() {
    final lines = <TextLine>[];
    for (final page in pages) {
      lines.addAll(page.lines);
    }
    return lines;
  }

  String getContent() {
    return pages
        .expand((page) => page.lines)
        .where((line) => line.image == null)
        .map((line) => line.text + (line.isParagraphEnd ? '\n' : ''))
        .join();
  }

  String getUnRead(int pageIndex) {
    if (pages.isEmpty || pageIndex < 0 || pageIndex > lastIndex) return '';
    return pages
        .skip(pageIndex)
        .expand((page) => page.lines)
        .where((line) => line.image == null)
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
        if (line.image != null) continue;
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
    if (pages.isEmpty) return false;
    final first = firstCharOffset(pages.first);
    final last = pageEndCharOffset(pages.last);
    return charOffset >= first && charOffset <= last;
  }

  int pageEndCharOffset(TextPage page) {
    for (final line in page.lines.reversed) {
      if (line.image == null) {
        return line.chapterPosition + line.text.length;
      }
    }
    return firstCharOffset(page);
  }

  List<TextLine> visibleLinesFrom(int startCharOffset) {
    final lines = <TextLine>[];
    for (final page in pages) {
      for (final line in page.lines) {
        if (line.image != null) continue;
        if (line.chapterPosition >= startCharOffset) {
          lines.add(line);
        }
      }
    }
    return lines;
  }

  ({String text, int baseOffset, List<({int ttsOffset, int chapterOffset})> offsetMap})?
      buildReadAloudData({
    required int startCharOffset,
  }) {
    final lines = visibleLinesFrom(startCharOffset);
    if (lines.isEmpty) return null;

    final buffer = StringBuffer();
    final map = <({int ttsOffset, int chapterOffset})>[];
    var ttsPos = 0;
    var lastParagraphNum = -1;
    for (final line in lines) {
      if (lastParagraphNum != -1 && line.paragraphNum != lastParagraphNum) {
        buffer.write('\n');
        ttsPos += 1;
      }
      map.add((ttsOffset: ttsPos, chapterOffset: line.chapterPosition));
      buffer.write(line.text);
      ttsPos += line.text.length;
      lastParagraphNum = line.paragraphNum;
    }
    return (
      text: buffer.toString(),
      baseOffset: lines.first.chapterPosition,
      offsetMap: map,
    );
  }

  List<ReaderParagraph> _buildParagraphs() {
    final grouped = <int, List<TextLine>>{};
    for (final line in allLines()) {
      if (line.image != null || line.paragraphNum <= 0) continue;
      grouped.putIfAbsent(line.paragraphNum, () => <TextLine>[]).add(line);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map((entry) => ReaderParagraph(num: entry.key, textLines: entry.value))
        .toList();
  }

  List<ReaderParagraph> _buildPageParagraphs() {
    final paragraphs = <ReaderParagraph>[];
    for (final page in pages) {
      final grouped = <int, List<TextLine>>{};
      for (final line in page.lines) {
        if (line.image != null || line.paragraphNum <= 0) continue;
        grouped.putIfAbsent(line.paragraphNum, () => <TextLine>[]).add(line);
      }
      final pageParagraphs = grouped.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final entry in pageParagraphs) {
        paragraphs.add(
          ReaderParagraph(
            num: paragraphs.length + 1,
            textLines: entry.value,
          ),
        );
      }
    }
    return paragraphs;
  }
}
