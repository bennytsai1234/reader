class ReaderTtsHighlight {
  const ReaderTtsHighlight({
    required this.chapterIndex,
    required this.highlightStart,
    required this.highlightEnd,
  });

  final int chapterIndex;
  final int highlightStart;
  final int highlightEnd;

  bool get isValid => highlightEnd > highlightStart;

  @override
  bool operator ==(Object other) {
    return other is ReaderTtsHighlight &&
        other.chapterIndex == chapterIndex &&
        other.highlightStart == highlightStart &&
        other.highlightEnd == highlightEnd;
  }

  @override
  int get hashCode => Object.hash(chapterIndex, highlightStart, highlightEnd);
}
