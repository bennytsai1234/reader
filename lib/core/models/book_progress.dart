/// BookProgress - 書籍進度同步模型
/// (原 Android data/entities/BookProgress.kt)
class BookProgress {
  final String name;
  final String author;
  final int durChapterIndex;
  final int durChapterPos;
  final String durChapterTitle;
  final int durChapterTime;

  BookProgress({
    required this.name,
    required this.author,
    required this.durChapterIndex,
    required this.durChapterPos,
    required this.durChapterTitle,
    required this.durChapterTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'author': author,
      'durChapterIndex': durChapterIndex,
      'durChapterPos': durChapterPos,
      'durChapterTitle': durChapterTitle,
      'durChapterTime': durChapterTime,
    };
  }

  factory BookProgress.fromJson(Map<String, dynamic> json) {
    return BookProgress(
      name: json['name'] ?? '',
      author: json['author'] ?? '',
      durChapterIndex: json['durChapterIndex'] ?? 0,
      durChapterPos: json['durChapterPos'] ?? 0,
      durChapterTitle: json['durChapterTitle'] ?? '',
      durChapterTime: json['durChapterTime'] ?? 0,
    );
  }
}

