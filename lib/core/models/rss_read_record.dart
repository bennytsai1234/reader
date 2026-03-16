/// RssReadRecord - RSS 閱讀紀錄模型
/// (原 Android data/entities/RssReadRecord.kt)
class RssReadRecord {
  final String record;
  final String? title;
  final int? readTime;
  final bool read;

  RssReadRecord({
    required this.record,
    this.title,
    this.readTime,
    this.read = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'record': record,
      'title': title,
      'readTime': readTime,
      'read': read,
    };
  }

  factory RssReadRecord.fromJson(Map<String, dynamic> json) {
    return RssReadRecord(
      record: json['record'] ?? '',
      title: json['title'],
      readTime: json['readTime'],
      read: json['read'] ?? true,
    );
  }
}

