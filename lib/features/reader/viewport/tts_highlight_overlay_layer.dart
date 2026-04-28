import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader/engine/page_cache.dart';
import 'package:inkpage_reader/features/reader/engine/read_style.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_tts_highlight.dart';

typedef TtsHighlightPaintObserver =
    void Function(PageCache tile, List<Rect> rects);

class TtsHighlightOverlayLayer extends StatelessWidget {
  const TtsHighlightOverlayLayer({
    super.key,
    required this.tile,
    required this.style,
    required this.textColor,
    this.highlight,
  });

  final PageCache tile;
  final ReadStyle style;
  final Color textColor;
  final ReaderTtsHighlight? highlight;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: CustomPaint(
          painter: TtsHighlightOverlayPainter(
            tile: tile,
            style: style,
            textColor: textColor,
            highlight: highlight,
          ),
        ),
      ),
    );
  }
}

class TtsHighlightOverlayPainter extends CustomPainter {
  TtsHighlightOverlayPainter({
    required this.tile,
    required this.style,
    required this.textColor,
    this.highlight,
  });

  final PageCache tile;
  final ReadStyle style;
  final Color textColor;
  final ReaderTtsHighlight? highlight;

  static TtsHighlightPaintObserver? debugOnPaintRects;

  @override
  void paint(Canvas canvas, Size size) {
    final rects = _highlightRects(size);
    assert(() {
      debugOnPaintRects?.call(tile, rects);
      return true;
    }());
    if (rects.isEmpty) return;

    final shadowPaint =
        Paint()
          ..color = const Color(0xFFFFC857).withValues(alpha: 0.14)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 12);
    final fillPaint =
        Paint()..color = const Color(0xFFFFC857).withValues(alpha: 0.20);
    final strokePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = textColor.withValues(alpha: 0.10);

    for (final rect in rects) {
      final rounded = RRect.fromRectAndRadius(rect, const Radius.circular(6));
      canvas.drawRRect(rounded.inflate(2), shadowPaint);
      canvas.drawRRect(rounded, fillPaint);
      canvas.drawRRect(rounded, strokePaint);
    }
  }

  List<Rect> _highlightRects(Size size) {
    final current = highlight;
    if (current == null ||
        !current.isValid ||
        current.chapterIndex != tile.chapterIndex) {
      return const <Rect>[];
    }
    final lines = tile.linesForRange(
      current.highlightStart,
      current.highlightEnd,
    );
    if (lines.isEmpty) return const <Rect>[];

    final left = (style.paddingLeft - 6).clamp(0.0, size.width).toDouble();
    final right =
        (size.width - style.paddingRight + 6)
            .clamp(left, size.width)
            .toDouble();
    final maxBottom = size.height.isFinite ? size.height : tile.height;
    return lines
        .map((line) {
          final top =
              (style.paddingTop + line.top - 3)
                  .clamp(0.0, maxBottom)
                  .toDouble();
          final bottom =
              (style.paddingTop + line.bottom + 3)
                  .clamp(top, maxBottom)
                  .toDouble();
          return Rect.fromLTRB(left, top, right, bottom);
        })
        .toList(growable: false);
  }

  @override
  bool shouldRepaint(covariant TtsHighlightOverlayPainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.style != style ||
        oldDelegate.textColor != textColor ||
        oldDelegate.highlight != highlight;
  }
}
