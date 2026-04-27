import 'package:flutter/material.dart';

import 'book_content.dart';
import 'chapter_layout.dart';
import 'layout_spec.dart';
import 'text_page.dart';

class LayoutEngine {
  static const String _lineStartForbidden = '。，、：；！？）》」』〉】〗;:!?)]}>';
  static const String _lineEndForbidden = '（《「『〈【〖([{<';
  final Map<String, ChapterLayout> _cache = <String, ChapterLayout>{};

  ChapterLayout layout(
    BookContent content,
    LayoutSpec spec, {
    int chapterSize = 0,
  }) {
    final cacheKey =
        '${content.chapterIndex}:$chapterSize:${content.contentHash}:${spec.layoutSignature}';
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    final lines = <TextLine>[];
    var y = 0.0;
    var paragraphOffset = 0;
    var paragraphNum = 0;

    if (content.title.isNotEmpty) {
      final titleStyle = _titleTextStyle(spec);
      final titleLines = _layoutBlock(
        text: content.title,
        style: titleStyle,
        maxWidth: spec.contentWidth,
        top: y,
        startOffset: 0,
        isTitle: true,
        paragraphNum: -1,
      );
      lines.addAll(titleLines);
      if (titleLines.isNotEmpty) {
        y = titleLines.last.bottom + spec.style.paragraphSpacing * 8;
      }
    }

    for (final paragraph in content.paragraphs) {
      final paragraphLines = _layoutBlock(
        text: paragraph,
        style: _contentTextStyle(spec),
        maxWidth: spec.contentWidth,
        top: y,
        startOffset: paragraphOffset,
        paragraphNum: paragraphNum,
        textIndent: spec.style.textIndent,
        textFullJustify: spec.style.textFullJustify,
      );
      lines.addAll(paragraphLines);
      if (paragraphLines.isNotEmpty) {
        y = paragraphLines.last.bottom + _paragraphSpacingPixels(spec);
      }
      paragraphOffset += paragraph.length + 2;
      paragraphNum += 1;
    }

    final pages = _paginate(
      lines: lines,
      spec: spec,
      content: content,
      chapterSize: chapterSize,
    );
    final layout = ChapterLayout(
      chapterIndex: content.chapterIndex,
      contentHash: content.contentHash,
      layoutSignature: spec.layoutSignature,
      lines: List<TextLine>.unmodifiable(lines),
      pages: List<TextPage>.unmodifiable(pages),
    );
    _cache[cacheKey] = layout;
    return layout;
  }

  void clear() => _cache.clear();

  void invalidateWhere(bool Function(ChapterLayout layout) test) {
    _cache.removeWhere((_, layout) => test(layout));
  }

  TextStyle _contentTextStyle(LayoutSpec spec) {
    return TextStyle(
      fontSize: spec.style.fontSize,
      height: spec.style.lineHeight,
      letterSpacing: spec.style.letterSpacing,
      fontFamily: spec.style.fontFamily,
      fontWeight: spec.style.bold ? FontWeight.bold : FontWeight.normal,
    );
  }

  TextStyle _titleTextStyle(LayoutSpec spec) {
    return TextStyle(
      fontSize: spec.style.fontSize + 4,
      height: spec.style.lineHeight,
      letterSpacing: spec.style.letterSpacing,
      fontFamily: spec.style.fontFamily,
      fontWeight: FontWeight.bold,
    );
  }

  double _paragraphSpacingPixels(LayoutSpec spec) {
    return (spec.style.fontSize * spec.style.lineHeight) *
        spec.style.paragraphSpacing;
  }

  List<TextLine> _layoutBlock({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required double top,
    required int startOffset,
    bool isTitle = false,
    int paragraphNum = 0,
    int textIndent = 0,
    bool textFullJustify = false,
  }) {
    if (text.isEmpty) return const <TextLine>[];
    final indentText =
        !isTitle && textIndent > 0 ? '　' * textIndent.clamp(0, 8) : '';
    final laidOutText = indentText.isEmpty ? text : '$indentText$text';
    final indentLength = indentText.length;
    final painter = TextPainter(
      text: const TextSpan(text: ''),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: null,
    );
    final lines = <TextLine>[];
    var localStart = 0;
    var lineTop = top;
    var lineIndex = 0;

    while (localStart < laidOutText.length) {
      final remaining = laidOutText.substring(localStart);
      painter.text = TextSpan(text: remaining, style: style);
      painter.layout(maxWidth: maxWidth);
      final metrics = painter.computeLineMetrics();
      if (metrics.isEmpty) break;
      final metric = metrics.first;
      final charsConsumed = _lineCharsConsumed(
        painter: painter,
        remaining: remaining,
      );
      if (charsConsumed <= 0) break;
      final localEnd =
          (localStart + charsConsumed)
              .clamp(localStart + 1, laidOutText.length)
              .toInt();
      final lineText = laidOutText.substring(localStart, localEnd);
      final contentStart =
          (localStart - indentLength).clamp(0, text.length).toInt();
      final contentEnd =
          (localEnd - indentLength).clamp(contentStart, text.length).toInt();
      final lineHeight =
          metric.height > 0
              ? metric.height
              : (style.fontSize ?? 0) * (style.height ?? 1.0);
      final lineBottom = lineTop + lineHeight;
      final isParagraphEnd = localEnd >= laidOutText.length;
      lines.add(
        TextLine(
          text: lineText,
          width: metric.width,
          height: lineHeight,
          isTitle: isTitle,
          isParagraphStart: lineIndex == 0,
          isParagraphEnd: isParagraphEnd,
          shouldJustify: !isTitle && textFullJustify && !isParagraphEnd,
          chapterPosition: startOffset + contentStart,
          lineTop: lineTop,
          lineBottom: lineBottom,
          paragraphNum: paragraphNum,
          startCharOffset: startOffset + contentStart,
          endCharOffset: startOffset + contentEnd,
          baseline: lineTop + metric.baseline,
        ),
      );
      localStart = localEnd;
      lineTop = lineBottom;
      lineIndex += 1;
    }
    return lines;
  }

  int _lineCharsConsumed({
    required TextPainter painter,
    required String remaining,
  }) {
    if (remaining.isEmpty) return 0;
    var boundary = painter.getLineBoundary(const TextPosition(offset: 0));
    var end = boundary.end.clamp(0, remaining.length).toInt();
    if (end <= 0 && remaining.length > 1) {
      boundary = painter.getLineBoundary(const TextPosition(offset: 1));
      end = boundary.end.clamp(0, remaining.length).toInt();
    }
    if (end <= 0) return 0;

    if (end < remaining.length) {
      final nextChar = remaining.substring(end, end + 1);
      if (_lineStartForbidden.contains(nextChar) && end > 1) {
        end -= 1;
      }
    }
    if (end > 1) {
      final lastChar = remaining.substring(end - 1, end);
      if (_lineEndForbidden.contains(lastChar)) {
        end -= 1;
      }
    }
    if (end <= 0) {
      end = remaining.isEmpty ? 0 : 1;
    }
    return end.clamp(0, remaining.length).toInt();
  }

  List<TextPage> _paginate({
    required List<TextLine> lines,
    required LayoutSpec spec,
    required BookContent content,
    required int chapterSize,
  }) {
    final pageHeight = spec.contentHeight <= 0 ? 1.0 : spec.contentHeight;
    if (lines.isEmpty) {
      return <TextPage>[
        TextPage(
          pageIndex: 0,
          chapterIndex: content.chapterIndex,
          chapterSize: chapterSize,
          pageSize: 1,
          title: content.title,
          lines: const <TextLine>[],
          startCharOffset: 0,
          endCharOffset: content.plainText.length,
          height: pageHeight,
          isChapterStart: true,
          isChapterEnd: true,
        ),
      ];
    }

    final buckets = <int, List<TextLine>>{};
    for (final line in lines) {
      final pageIndex = (line.top / pageHeight).floor().clamp(0, 1 << 30);
      buckets.putIfAbsent(pageIndex, () => <TextLine>[]).add(line);
    }
    final maxPageIndex = buckets.keys.fold<int>(0, (max, value) {
      return value > max ? value : max;
    });
    final pages = <TextPage>[];
    for (var pageIndex = 0; pageIndex <= maxPageIndex; pageIndex++) {
      final pageTop = pageIndex * pageHeight;
      final pageLines = (buckets[pageIndex] ?? const <TextLine>[])
          .map((line) => line.toPageLocal(pageTop))
          .toList(growable: false);
      pages.add(
        TextPage(
          pageIndex: pageIndex,
          chapterIndex: content.chapterIndex,
          chapterSize: chapterSize,
          pageSize: maxPageIndex + 1,
          title: content.title,
          lines: pageLines,
          startCharOffset:
              pageLines.isEmpty
                  ? (pages.isEmpty ? 0 : pages.last.endCharOffset)
                  : pageLines.first.startCharOffset,
          endCharOffset:
              pageLines.isEmpty
                  ? (pages.isEmpty ? 0 : pages.last.endCharOffset)
                  : pageLines.last.endCharOffset,
          height: pageHeight,
          isChapterStart: pageIndex == 0,
          isChapterEnd: pageIndex == maxPageIndex,
        ),
      );
    }
    return pages;
  }
}
