import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_page_cache.dart';
import 'package:inkpage_reader/features/reader_v2/layout/reader_v2_style.dart';
import 'package:inkpage_reader/features/reader_v2/render/reader_v2_render_page.dart';

typedef ReaderV2TilePaintObserver = void Function(ReaderV2PageCache tile);

class ReaderV2TilePainter extends CustomPainter {
  ReaderV2TilePainter({
    required this.tile,
    required this.backgroundColor,
    required this.textColor,
    required this.style,
    this.debugOverlay = false,
    this.paintBackground = true,
  });

  final ReaderV2PageCache tile;
  final Color backgroundColor;
  final Color textColor;
  final ReaderV2Style style;
  final bool debugOverlay;
  final bool paintBackground;

  /// Capacity for the TextPainter cache.
  /// ~1 painter/line × 25 lines/page × 8 visible pages ≈ 200 active entries.
  /// We keep a comfortable headroom for scrolling overlap and preloaded tiles.
  static const int _cacheCapacity = 800;

  /// LinkedHashMap preserves insertion order, enabling efficient
  /// eviction of the oldest half instead of clearing everything at once.
  static final LinkedHashMap<String, TextPainter> _textPainterCache =
      LinkedHashMap<String, TextPainter>();
  static ReaderV2TilePaintObserver? debugOnPaint;

  /// Call when reader style changes (font, size, color, etc.) to avoid
  /// stale painters lingering in the cache.
  static void invalidateCache() {
    _textPainterCache.clear();
  }

  @override
  void paint(Canvas canvas, Size size) {
    assert(() {
      debugOnPaint?.call(tile);
      return true;
    }());

    if (paintBackground) {
      canvas.drawColor(backgroundColor, BlendMode.src);
    }
    final left = style.paddingLeft;
    final top = style.paddingTop;
    final contentWidth =
        (size.width - style.paddingLeft - style.paddingRight)
            .clamp(1.0, double.infinity)
            .toDouble();

    final contentRect = Rect.fromLTWH(
      left,
      top,
      contentWidth,
      tile.contentHeight,
    );
    canvas.save();
    canvas.clipRect(contentRect);
    for (final line in tile.lines) {
      final painter = _painterFor(line);
      painter.paint(canvas, Offset(left, top + line.top));
    }
    canvas.restore();

    if (debugOverlay) {
      final debugPainter = TextPainter(
        text: TextSpan(
          text:
              'c${tile.chapterIndex} p${tile.pageIndex} ${tile.startCharOffset}-${tile.endCharOffset}',
          style: TextStyle(
            color: textColor.withValues(alpha: 0.45),
            fontSize: 10,
          ),
        ),
        textDirection: TextDirection.ltr,
        textScaler: TextScaler.noScaling,
      )..layout(maxWidth: size.width);
      debugPainter.paint(canvas, Offset(left, top + 2));
    }
  }

  TextPainter _painterFor(ReaderV2RenderLine line) {
    final effectiveLineHeight = style.effectiveLineHeight;
    final key = <Object?>[
      line.text,
      line.isTitle,
      style.fontSize,
      effectiveLineHeight,
      style.letterSpacing,
      style.fontFamily,
      style.bold,
      textColor.toARGB32(),
    ].join('|');
    final cached = _textPainterCache[key];
    if (cached != null) return cached;

    final textStyle = TextStyle(
      color: textColor,
      fontSize: line.isTitle ? style.fontSize + 4 : style.fontSize,
      height: effectiveLineHeight,
      letterSpacing: style.letterSpacing,
      fontFamily: style.fontFamily,
      fontWeight:
          line.isTitle || style.bold ? FontWeight.bold : FontWeight.normal,
    );
    final painter = TextPainter(
      text: TextSpan(text: line.text, style: textStyle),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
      maxLines: 1,
    )..layout(maxWidth: double.infinity);

    if (_textPainterCache.length > _cacheCapacity) {
      // Evict the oldest half instead of clearing all at once.
      // LinkedHashMap iterates in insertion order, so the first keys
      // are the oldest. This avoids a full cache-miss stutter.
      final evictCount = _cacheCapacity ~/ 2;
      final keysToRemove =
          _textPainterCache.keys.take(evictCount).toList(growable: false);
      for (final key in keysToRemove) {
        _textPainterCache.remove(key);
      }
    }
    _textPainterCache[key] = painter;
    return painter;
  }

  @override
  bool shouldRepaint(covariant ReaderV2TilePainter oldDelegate) {
    return oldDelegate.tile != tile ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.textColor != textColor ||
        oldDelegate.style != style ||
        oldDelegate.debugOverlay != debugOverlay ||
        oldDelegate.paintBackground != paintBackground;
  }
}
