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
