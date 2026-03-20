class DisplayWindowPolicy {
  static List<int> resolveScrollDisplayChapters({
    required int anchorChapter,
    required List<int> existingDisplayChapters,
    required bool Function(int chapterIndex) isCached,
  }) {
    final existing = existingDisplayChapters.where(isCached).toList()..sort();

    if (existing.isEmpty ||
        anchorChapter < existing.first - 1 ||
        anchorChapter > existing.last + 1) {
      if (!isCached(anchorChapter)) return const [];

      int left = anchorChapter;
      int right = anchorChapter;
      while (isCached(left - 1)) {
        left--;
      }
      while (isCached(right + 1)) {
        right++;
      }

      return [
        for (int chapter = left; chapter <= right; chapter++) chapter,
      ];
    }

    int left = existing.first;
    int right = existing.last;
    while (isCached(left - 1)) {
      left--;
    }
    while (isCached(right + 1)) {
      right++;
    }

    return [
      for (int chapter = left; chapter <= right; chapter++)
        if (isCached(chapter)) chapter,
    ];
  }
}
