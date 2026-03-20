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

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'width': width,
      'height': height,
      'left': left,
      'top': top,
    };
  }

  factory TextImage.fromJson(Map<String, dynamic> json) {
    return TextImage(
      url: json['url'] ?? '',
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      left: (json['left'] ?? 0).toDouble(),
      top: (json['top'] ?? 0).toDouble(),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'width': width,
      'height': height,
      'isTitle': isTitle,
      'isParagraphStart': isParagraphStart,
      'isParagraphEnd': isParagraphEnd,
      'shouldJustify': shouldJustify,
      'chapterPosition': chapterPosition,
      'lineTop': lineTop,
      'lineBottom': lineBottom,
      'paragraphNum': paragraphNum,
      'image': image?.toJson(),
    };
  }

  factory TextLine.fromJson(Map<String, dynamic> json) {
    return TextLine(
      text: json['text'] ?? '',
      width: (json['width'] ?? 0).toDouble(),
      height: (json['height'] ?? 0).toDouble(),
      isTitle: json['isTitle'] ?? false,
      isParagraphStart: json['isParagraphStart'] ?? false,
      isParagraphEnd: json['isParagraphEnd'] ?? false,
      shouldJustify: json['shouldJustify'] ?? false,
      chapterPosition: json['chapterPosition'] ?? 0,
      lineTop: (json['lineTop'] ?? 0).toDouble(),
      lineBottom: (json['lineBottom'] ?? 0).toDouble(),
      paragraphNum: json['paragraphNum'] ?? 0,
      image: json['image'] is Map<String, dynamic>
          ? TextImage.fromJson(json['image'])
          : (json['image'] is Map ? TextImage.fromJson(Map<String, dynamic>.from(json['image'])) : null),
    );
  }
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

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'title': title,
      'chapterIndex': chapterIndex,
      'chapterSize': chapterSize,
      'pageSize': pageSize,
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }

  factory TextPage.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] as List? ?? const [];
    return TextPage(
      index: json['index'] ?? 0,
      title: json['title'] ?? '',
      chapterIndex: json['chapterIndex'] ?? 0,
      chapterSize: json['chapterSize'] ?? 0,
      pageSize: json['pageSize'] ?? 0,
      lines: rawLines
          .map((line) => TextLine.fromJson(Map<String, dynamic>.from(line as Map)))
          .toList(),
    );
  }
}

