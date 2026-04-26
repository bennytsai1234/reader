import 'dart:math' as math;

import 'package:inkpage_reader/features/reader/engine/line_layout.dart';
import 'package:inkpage_reader/features/reader/runtime/models/reader_location.dart';

enum ReaderScrollItemKind { line, placeholder, separator }

class ReaderScrollItem {
  final ReaderScrollItemKind kind;
  final int chapterIndex;
  final LineItem? lineItem;
  final double extent;
  final double localTop;
  final double linePaintHeight;

  const ReaderScrollItem._({
    required this.kind,
    required this.chapterIndex,
    required this.extent,
    required this.localTop,
    this.lineItem,
    this.linePaintHeight = 0.0,
  });

  factory ReaderScrollItem.line({
    required LineItem lineItem,
    required double extent,
  }) {
    return ReaderScrollItem._(
      kind: ReaderScrollItemKind.line,
      chapterIndex: lineItem.chapterIndex,
      lineItem: lineItem,
      extent: math.max(extent, lineItem.line.height),
      localTop: lineItem.localTop,
      linePaintHeight: lineItem.line.height,
    );
  }

  factory ReaderScrollItem.placeholder({
    required int chapterIndex,
    required double extent,
  }) {
    return ReaderScrollItem._(
      kind: ReaderScrollItemKind.placeholder,
      chapterIndex: chapterIndex,
      extent: extent,
      localTop: 0.0,
    );
  }

  factory ReaderScrollItem.separator({
    required int chapterIndex,
    required double extent,
    required double localTop,
  }) {
    return ReaderScrollItem._(
      kind: ReaderScrollItemKind.separator,
      chapterIndex: chapterIndex,
      extent: extent,
      localTop: localTop,
    );
  }

  bool get isTextLine => kind == ReaderScrollItemKind.line && lineItem!.isText;

  int get charOffset => lineItem?.chapterPosition ?? 0;

  int get endCharOffset => lineItem?.endChapterPosition ?? charOffset;

  ReaderLocation? get location {
    if (!isTextLine) return null;
    return ReaderLocation(
      chapterIndex: chapterIndex,
      charOffset: charOffset,
    ).normalized();
  }

  String get key {
    final item = lineItem;
    return switch (kind) {
      ReaderScrollItemKind.line =>
        'line:$chapterIndex:${item!.pageIndex}:${item.lineIndex}',
      ReaderScrollItemKind.placeholder => 'placeholder:$chapterIndex',
      ReaderScrollItemKind.separator => 'separator:$chapterIndex',
    };
  }

  bool containsCharOffset(int offset) {
    if (!isTextLine) return false;
    return offset >= charOffset && offset < endCharOffset;
  }
}
