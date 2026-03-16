import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'text_page.dart';

class ChapterProvider {
  // 避頭點：不能出現在行首的符號
  static const String _lineStartForbidden = '。，、：；！？）》」』〉】〗;:!?)]}>';
  // 避尾點：不能出現在行尾的符號
  static const String _lineEndForbidden = '（《「『〈【〖([{<';

  static List<TextPage> paginate({
    required String content,
    required BookChapter chapter,
    required int chapterIndex,
    required int chapterSize,
    required Size viewSize,
    required TextStyle titleStyle,
    required TextStyle contentStyle,
    double paragraphSpacing = 1.0,
    int textIndent = 2,
    double titleTopSpacing = 0.0,
    double titleBottomSpacing = 10.0,
    bool textFullJustify = true,
    double padding = 16.0,
  }) {
    final width = viewSize.width - (padding * 2);
    final height = viewSize.height - 80;

    final pages = <TextPage>[];
    var currentLines = <TextLine>[];
    double currentHeight = 0;
    var chapterPos = 0;

    // 1. 處理標題
    final titlePainter = TextPainter(
      text: TextSpan(text: chapter.title, style: titleStyle),
      textDirection: TextDirection.ltr,
      maxLines: 2,
    );
    titlePainter.layout(maxWidth: width);
    
    currentLines.add(TextLine(
      text: chapter.title,
      width: titlePainter.width,
      height: titlePainter.height,
      isTitle: true,
      lineTop: titleTopSpacing,
      lineBottom: titleTopSpacing + titlePainter.height,
      chapterPosition: chapterPos,
    ));
    chapterPos += chapter.title.length;
    currentHeight += titleTopSpacing + titlePainter.height + titleBottomSpacing;

    // 2. 處理段落
    final paragraphs = content.split('\n');
    final indentStr = '　' * textIndent;

    for (var pIdx = 0; pIdx < paragraphs.length; pIdx++) {
      final p = paragraphs[pIdx].trim();
      if (p.isEmpty) {
        chapterPos += 1; // 換行符
        continue;
      }
      
      final text = indentStr + p;
      var start = 0;
      var isFirstLineOfParagraph = true;

      while (start < text.length) {
        final tp = TextPainter(
          text: TextSpan(text: text.substring(start), style: contentStyle),
          textDirection: TextDirection.ltr,
        );
        tp.layout(maxWidth: width);
        
        var end = tp.getPositionForOffset(Offset(width, 0)).offset;
        if (end <= 0) break;

        // 避頭尾處理
        if (start + end < text.length) {
          final nextChar = text.substring(start + end, start + end + 1);
          if (_lineStartForbidden.contains(nextChar) && end > 1) end--;
        }
        final lastChar = text.substring(start + end - 1, start + end);
        if (_lineEndForbidden.contains(lastChar) && end > 1) end--;

        final lineText = text.substring(start, start + end);
        final isLastLine = (start + end == text.length);
        
        // 判斷是否需要兩端對齊
        final shouldJustify = textFullJustify && !isLastLine && !lineText.endsWith('\n');

        currentLines.add(TextLine(
          text: lineText,
          width: tp.width,
          height: tp.preferredLineHeight,
          isParagraphStart: isFirstLineOfParagraph,
          isParagraphEnd: isLastLine,
          shouldJustify: shouldJustify,
          chapterPosition: chapterPos,
          lineTop: currentHeight,
          lineBottom: currentHeight + tp.preferredLineHeight,
          paragraphNum: pIdx,
        ));

        start += end;
        chapterPos += end;
        currentHeight += tp.preferredLineHeight * (contentStyle.height ?? 1.1);
        isFirstLineOfParagraph = false;

        if (currentHeight >= height) {
          pages.add(TextPage(
            index: pages.length,
            lines: List.from(currentLines),
            title: chapter.title,
            chapterIndex: chapterIndex,
            chapterSize: chapterSize,
          ));
          currentLines = [];
          currentHeight = 0;
        }
      }
      chapterPos += 1; // 段落換行符
      currentHeight += (contentStyle.fontSize ?? 18) * (paragraphSpacing - 1.0).clamp(0, 5.0);
    }

    if (currentLines.isNotEmpty) {
      pages.add(TextPage(
        index: pages.length,
        lines: currentLines,
        title: chapter.title,
        chapterIndex: chapterIndex,
        chapterSize: chapterSize,
      ));
    }

    return pages.asMap().entries.map((e) => e.value.copyWith(index: e.key, pageSize: pages.length)).toList();
  }
}

