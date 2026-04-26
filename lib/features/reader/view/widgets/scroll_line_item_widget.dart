import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/text_page.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_scroll_item.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_position.dart';

class ScrollLineItemWidget extends StatelessWidget {
  final ReaderScrollItem item;
  final TextStyle contentStyle;
  final TextStyle titleStyle;
  final double paddingLeft;
  final Color backgroundColor;
  final ReaderTtsPosition? ttsPosition;
  final GestureTapUpCallback? onTapUp;
  final void Function(int charOffset)? onLineTap;

  const ScrollLineItemWidget({
    super.key,
    required this.item,
    required this.contentStyle,
    required this.titleStyle,
    required this.paddingLeft,
    required this.backgroundColor,
    this.ttsPosition,
    this.onTapUp,
    this.onLineTap,
  });

  @override
  Widget build(BuildContext context) {
    final lineItem = item.lineItem!;
    final line = lineItem.line;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: (details) {
        onTapUp?.call(details);
        if (details.localPosition.dy <= line.height) {
          onLineTap?.call(line.chapterPosition);
        }
      },
      child: SizedBox(
        height: item.extent,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _ScrollTextLinePainter(
                  line: line,
                  chapterIndex: item.chapterIndex,
                  contentStyle: contentStyle,
                  titleStyle: titleStyle,
                  paddingLeft: paddingLeft,
                  backgroundColor: backgroundColor,
                  ttsPosition: ttsPosition,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScrollTextLinePainter extends CustomPainter {
  final TextLine line;
  final int chapterIndex;
  final TextStyle contentStyle;
  final TextStyle titleStyle;
  final double paddingLeft;
  final Color backgroundColor;
  final ReaderTtsPosition? ttsPosition;

  const _ScrollTextLinePainter({
    required this.line,
    required this.chapterIndex,
    required this.contentStyle,
    required this.titleStyle,
    required this.paddingLeft,
    required this.backgroundColor,
    this.ttsPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    if (line.text.isEmpty) return;

    final width = size.width - paddingLeft * 2;
    final lineStart = line.chapterPosition;
    final lineEnd = lineStart + line.text.length;
    final position = ttsPosition;
    final ttsStart = position?.highlightStart ?? -1;
    final ttsEnd = position?.highlightEnd ?? -1;
    final ttsWordStart = position?.wordStart ?? -1;
    final ttsWordEnd = position?.wordEnd ?? -1;
    final ttsChapterIndex = position?.chapterIndex ?? -1;
    final ttsMatchesChapter =
        ttsChapterIndex < 0 || ttsChapterIndex == chapterIndex;
    final isTtsActive =
        ttsStart != -1 &&
        ttsMatchesChapter &&
        lineEnd > ttsStart &&
        lineStart < ttsEnd;

    if (isTtsActive) {
      final highlightPaint =
          Paint()
            ..color =
                contentStyle.color?.withValues(alpha: 0.12) ??
                Colors.yellow.withValues(alpha: 0.22);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(paddingLeft, 0, width, line.height),
          const Radius.circular(4),
        ),
        highlightPaint,
      );
    }

    final hasWordFocus =
        ttsWordStart >= 0 &&
        ttsMatchesChapter &&
        lineEnd > ttsWordStart &&
        lineStart < ttsWordEnd;
    if (hasWordFocus && !line.shouldJustify) {
      final lineStyle = line.isTitle ? titleStyle : contentStyle;
      final activeStart = (ttsWordStart - lineStart).clamp(0, line.text.length);
      final activeEnd = (ttsWordEnd - lineStart).clamp(
        activeStart,
        line.text.length,
      );
      if (activeEnd > activeStart) {
        final prefixPainter = TextPainter(
          text: TextSpan(
            text: line.text.substring(0, activeStart),
            style: lineStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        final activePainter = TextPainter(
          text: TextSpan(
            text: line.text.substring(activeStart, activeEnd),
            style: lineStyle,
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              paddingLeft + prefixPainter.width - 1,
              0,
              activePainter.width + 2,
              line.height,
            ),
            const Radius.circular(4),
          ),
          Paint()
            ..color =
                contentStyle.color?.withValues(alpha: 0.2) ??
                Colors.yellow.withValues(alpha: 0.28),
        );
      }
    }

    final textPainter = TextPainter(
      text: TextSpan(
        text: line.text,
        style: line.isTitle ? titleStyle : contentStyle,
      ),
      textAlign: line.shouldJustify ? TextAlign.justify : TextAlign.left,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: width, maxWidth: width);
    textPainter.paint(canvas, Offset(paddingLeft, 0));
  }

  @override
  bool shouldRepaint(covariant _ScrollTextLinePainter oldDelegate) {
    return oldDelegate.line != line ||
        oldDelegate.chapterIndex != chapterIndex ||
        oldDelegate.contentStyle != contentStyle ||
        oldDelegate.titleStyle != titleStyle ||
        oldDelegate.paddingLeft != paddingLeft ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.ttsPosition != ttsPosition;
  }
}
