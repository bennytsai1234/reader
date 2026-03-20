import 'text_page.dart';

/// ReadingWindow — 閱讀視窗的純值物件
///
/// 負責將多個章節的分頁結果組裝成一個扁平的頁面列表，
/// 並預計算累積高度以支援 O(log N) 的滾動位置查詢。
/// 所有方法都是純函數、無副作用，方便單元測試。
class ReadingWindow {
  /// 扁平的頁面列表（可跨多章節）
  final List<TextPage> pages;

  /// 預計算的累積高度：cumulativeHeights[i] = pages[0..i] 的總高度
  /// 用於 O(log N) 二分搜尋滾動位置
  final List<double> cumulativeHeights;

  /// 章節索引 → 該章節在 pages 中的起始索引
  final Map<int, int> chapterStartIndex;

  /// 包含的章節索引（已排序）
  final List<int> chapterOrder;

  /// 錨點章節（視窗的中心章節）
  final int anchorChapterIndex;

  const ReadingWindow._({
    required this.pages,
    required this.cumulativeHeights,
    required this.chapterStartIndex,
    required this.chapterOrder,
    required this.anchorChapterIndex,
  });

  /// 空視窗
  static const ReadingWindow empty = ReadingWindow._(
    pages: [],
    cumulativeHeights: [],
    chapterStartIndex: {},
    chapterOrder: [],
    anchorChapterIndex: 0,
  );

  bool get isEmpty => pages.isEmpty;
  bool get isNotEmpty => pages.isNotEmpty;

  /// 從快取的章節頁面組裝閱讀視窗
  ///
  /// [chapterPages]：章節索引 → 分頁結果的映射
  /// [chapterOrder]：要包含的章節索引（已排序）
  /// [anchorChapter]：錨點章節索引
  factory ReadingWindow.assemble({
    required Map<int, List<TextPage>> chapterPages,
    required List<int> chapterOrder,
    required int anchorChapter,
  }) {
    if (chapterOrder.isEmpty) return ReadingWindow.empty;

    final List<TextPage> pages = [];
    final Map<int, int> chapterStartIndex = {};
    final List<int> validOrder = [];

    for (final chIdx in chapterOrder) {
      final chPages = chapterPages[chIdx];
      if (chPages == null || chPages.isEmpty) continue;

      chapterStartIndex[chIdx] = pages.length;
      validOrder.add(chIdx);
      pages.addAll(chPages);
    }

    if (pages.isEmpty) return ReadingWindow.empty;

    // 預計算累積高度
    final List<double> cumHeights = List.filled(pages.length, 0.0);
    double cumH = 0;
    for (int i = 0; i < pages.length; i++) {
      cumH += _pageHeight(pages[i]);
      cumHeights[i] = cumH;
    }

    return ReadingWindow._(
      pages: pages,
      cumulativeHeights: cumHeights,
      chapterStartIndex: chapterStartIndex,
      chapterOrder: validOrder,
      anchorChapterIndex: anchorChapter,
    );
  }

  // --- 位置查詢（O(log N) 二分搜尋）---

  /// 取得 scrollY 位置對應的頁面索引
  int pageIndexAtScrollY(double scrollY) {
    if (pages.isEmpty) return 0;
    if (scrollY <= 0) return 0;

    // 二分搜尋：找到第一個 cumulativeHeights[i] > scrollY 的索引
    int lo = 0, hi = cumulativeHeights.length - 1;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (cumulativeHeights[mid] <= scrollY) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// 取得指定頁面的滾動起始像素位置
  double scrollYForPageIndex(int pageIndex) {
    if (pageIndex <= 0 || pages.isEmpty) return 0.0;
    final idx = pageIndex.clamp(1, cumulativeHeights.length) - 1;
    return cumulativeHeights[idx];
  }

  /// 取得指定章節字元偏移量對應的滾動像素位置
  double scrollYForCharOffset(int chapterIndex, int charOffset) {
    if (pages.isEmpty) return 0.0;
    final chapterRange = _chapterRange(chapterIndex);
    if (chapterRange == null) return 0.0;

    final (start, end) = chapterRange;
    final pageIndex = _findPageIndexInChapter(start, end, charOffset);
    final page = pages[pageIndex];
    final pageTop = _pageTop(pageIndex);

    for (final line in page.lines) {
      if (line.image != null) continue;
      if (line.chapterPosition >= charOffset) {
        return (pageTop + line.lineTop).clamp(0.0, double.infinity);
      }
    }

    if (pageIndex < end) {
      return _pageTop(pageIndex + 1);
    }
    return pageTop + _pageHeight(page);
  }

  /// 取得 scrollY 位置對應的章節字元偏移量
  int charOffsetAtScrollY(double scrollY) {
    if (pages.isEmpty) return 0;
    final pageIndex = pageIndexAtScrollY(scrollY);
    final page = pages[pageIndex];
    final pageTop = _pageTop(pageIndex);

    for (final line in page.lines) {
      if (line.image != null) continue;
      if (pageTop + line.lineBottom > scrollY) {
        return line.chapterPosition;
      }
    }

    return _firstCharOffset(page);
  }

  /// 根據字元偏移量尋找對應頁碼
  int findPageIndexByCharOffset(int chapterIndex, int charOffset) {
    final chapterRange = _chapterRange(chapterIndex);
    if (chapterRange == null) return 0;

    final (start, end) = chapterRange;
    return _findPageIndexInChapter(start, end, charOffset);
  }

  /// 取得頁面的首個文字行的 chapterPosition
  int getCharOffsetForPage(int pageIndex) {
    if (pages.isEmpty || pageIndex < 0 || pageIndex >= pages.length) return 0;
    return _firstCharOffset(pages[pageIndex]);
  }

  /// 計算總高度
  double get totalHeight => cumulativeHeights.isEmpty ? 0.0 : cumulativeHeights.last;

  // --- 視窗比較與補償計算 ---

  /// 計算從舊視窗到新視窗時，prepend 了多少像素
  /// 用於 ScrollController 的原子補償
  double prependedPixelsVs(ReadingWindow oldWindow) {
    if (oldWindow.isEmpty || isEmpty) return 0.0;

    final oldFirstChapter = oldWindow.pages.first.chapterIndex;
    final newFirstChapter = pages.first.chapterIndex;

    if (newFirstChapter >= oldFirstChapter) return 0.0;

    // 計算新視窗中，在舊視窗第一個章節之前的所有頁面高度
    double prepended = 0;
    for (final page in pages) {
      if (page.chapterIndex >= oldFirstChapter) break;
      prepended += _pageHeight(page);
    }
    return prepended;
  }

  /// 計算從舊視窗到新視窗時，需要補償的頁面索引偏移
  /// 用於 slide 模式保持使用者的視覺位置不動
  static int computeIndexCompensation(
    ReadingWindow oldWindow,
    ReadingWindow newWindow,
    int oldPageIndex,
  ) {
    if (oldWindow.isEmpty || newWindow.isEmpty) return 0;
    if (oldPageIndex < 0 || oldPageIndex >= oldWindow.pages.length) return 0;

    final oldPage = oldWindow.pages[oldPageIndex];
    final targetChapterIndex = oldPage.chapterIndex;
    final targetCharOffset = _firstCharOffset(oldPage);

    // 在新視窗中找到相同章節、相同字元偏移的頁面
    for (int i = 0; i < newWindow.pages.length; i++) {
      final page = newWindow.pages[i];
      if (page.chapterIndex == targetChapterIndex &&
          _firstCharOffset(page) == targetCharOffset) {
        return i;
      }
    }

    // 回退：找同一章節的最近頁面
    for (int i = 0; i < newWindow.pages.length; i++) {
      if (newWindow.pages[i].chapterIndex == targetChapterIndex) {
        return i;
      }
    }

    return 0;
  }

  // --- 私有輔助 ---

  static double _pageHeight(TextPage page) {
    return page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
  }

  double _pageTop(int pageIndex) {
    if (pageIndex <= 0) return 0.0;
    return cumulativeHeights[pageIndex - 1];
  }

  (int, int)? _chapterRange(int chapterIndex) {
    final start = chapterStartIndex[chapterIndex];
    if (start == null) return null;

    final chapterOrderIndex = chapterOrder.indexOf(chapterIndex);
    if (chapterOrderIndex < 0) return null;

    final nextChapterStart = chapterOrderIndex + 1 < chapterOrder.length
        ? chapterStartIndex[chapterOrder[chapterOrderIndex + 1]]
        : null;
    final end = (nextChapterStart ?? pages.length) - 1;
    return (start, end);
  }

  int _findPageIndexInChapter(int start, int end, int charOffset) {
    int lo = start;
    int hi = end;
    int best = start;

    while (lo <= hi) {
      final mid = (lo + hi) >> 1;
      final firstOffset = _firstCharOffset(pages[mid]);
      if (firstOffset <= charOffset) {
        best = mid;
        lo = mid + 1;
      } else {
        hi = mid - 1;
      }
    }

    return best;
  }

  static int _firstCharOffset(TextPage page) {
    for (final line in page.lines) {
      if (line.image == null) return line.chapterPosition;
    }
    return 0;
  }
}
