import 'package:inkpage_reader/features/reader/engine/page_cache.dart';

class TileKey {
  const TileKey({
    required this.chapterIndex,
    required this.tileIndex,
    required this.startOffset,
    required this.endOffset,
    required this.layoutRevision,
  });

  final int chapterIndex;
  final int tileIndex;
  final int startOffset;
  final int endOffset;
  final int layoutRevision;

  factory TileKey.fromPageCache(
    PageCache page, {
    required int layoutRevision,
    int? tileIndex,
  }) {
    return TileKey(
      chapterIndex: page.chapterIndex,
      tileIndex: tileIndex ?? page.pageIndexInChapter,
      startOffset: page.startCharOffset,
      endOffset: page.endCharOffset,
      layoutRevision: layoutRevision,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TileKey &&
        other.chapterIndex == chapterIndex &&
        other.tileIndex == tileIndex &&
        other.startOffset == startOffset &&
        other.endOffset == endOffset &&
        other.layoutRevision == layoutRevision;
  }

  @override
  int get hashCode => Object.hash(
    chapterIndex,
    tileIndex,
    startOffset,
    endOffset,
    layoutRevision,
  );

  @override
  String toString() {
    return 'TileKey(c$chapterIndex t$tileIndex $startOffset-$endOffset r$layoutRevision)';
  }
}
