class ReaderLocation {
  final int chapterIndex;
  final int charOffset;

  const ReaderLocation({
    required this.chapterIndex,
    required this.charOffset,
  });

  ReaderLocation normalized() {
    return ReaderLocation(
      chapterIndex: chapterIndex < 0 ? 0 : chapterIndex,
      charOffset: charOffset < 0 ? 0 : charOffset,
    );
  }

  ReaderLocation copyWith({
    int? chapterIndex,
    int? charOffset,
  }) {
    return ReaderLocation(
      chapterIndex: chapterIndex ?? this.chapterIndex,
      charOffset: charOffset ?? this.charOffset,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReaderLocation &&
        other.chapterIndex == chapterIndex &&
        other.charOffset == charOffset;
  }

  @override
  int get hashCode => Object.hash(chapterIndex, charOffset);
}

class ReaderScrollTarget {
  final int chapterIndex;
  final double localOffset;
  final double alignment;

  const ReaderScrollTarget({
    required this.chapterIndex,
    required this.localOffset,
    required this.alignment,
  });
}

class ReaderSlideTarget {
  final int globalPageIndex;
  final int chapterIndex;
  final int chapterPageIndex;

  const ReaderSlideTarget({
    required this.globalPageIndex,
    required this.chapterIndex,
    required this.chapterPageIndex,
  });
}
