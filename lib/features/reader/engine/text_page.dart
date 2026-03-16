/// TextImage - 圖片資訊 (原 Android ReadBookViewModel.saveImage)
class TextImage {
  final String url;
  final double width;
  final double height;
  final double left;
  final double top;

  TextImage({
    required this.url,
    this.width = 0,
    this.height = 0,
    this.left = 0,
    this.top = 0,
  });
}

/// TextLine - 單行文字資訊
/// (原 Android ui/book/read/page/entities/TextLine.kt)
class TextLine {
  final String text;
  final double width;
  final double height;
  final bool isTitle;
  final bool isParagraphStart;
  final bool isParagraphEnd;
  final bool shouldJustify;
  final int chapterPosition;
  final double lineTop;
  final double lineBottom;
  final int paragraphNum;
  final TextImage? image; // 深度還原：支援行內圖片互動

  TextLine({
    required this.text,
    required this.width,
    required this.height,
    this.isTitle = false,
    this.isParagraphStart = false,
    this.isParagraphEnd = false,
    this.shouldJustify = false,
    this.chapterPosition = 0,
    this.lineTop = 0,
    this.lineBottom = 0,
    this.paragraphNum = 0,
    this.image,
  });
}

/// TextPage - 單頁文字資訊
/// (原 Android ui/book/read/page/entities/TextPage.kt)
class TextPage {
  final int index;
  final List<TextLine> lines;
  final String title;
  final int chapterIndex;
  final int chapterSize; // 總章節數
  final int pageSize; // 本章總頁數

  TextPage({
    required this.index,
    required this.lines,
    required this.title,
    required this.chapterIndex,
    this.chapterSize = 0,
    this.pageSize = 0,
  });

  int get lineSize => lines.length;

  String get readProgress {
    if (chapterSize == 0 || (pageSize == 0 && chapterIndex == 0)) {
      return '0.0%';
    } else if (pageSize == 0) {
      return '${((chapterIndex + 1.0) / chapterSize * 100).toStringAsFixed(1)}%';
    }
    final percent =
        (chapterIndex / chapterSize) +
        (1.0 / chapterSize) * (index + 1) / pageSize;
    var formatted = '${(percent * 100).toStringAsFixed(1)}%';
    if (formatted == '100.0%' &&
        (chapterIndex + 1 != chapterSize || index + 1 != pageSize)) {
      formatted = '99.9%';
    }
    return formatted;
  }

  TextPage copyWith({
    int? index,
    List<TextLine>? lines,
    String? title,
    int? chapterIndex,
    int? chapterSize,
    int? pageSize,
  }) {
    return TextPage(
      index: index ?? this.index,
      lines: lines ?? this.lines,
      title: title ?? this.title,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      chapterSize: chapterSize ?? this.chapterSize,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}

