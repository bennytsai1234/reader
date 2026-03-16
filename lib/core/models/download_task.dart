
/// DownloadTask - 下載任務模型
/// 用於持久化儲存下載隊列，確保 App 重啟後能恢復
class DownloadTask {
  final String bookUrl;
  final String bookName;
  final int startChapterIndex;
  final int endChapterIndex;
  int currentChapterIndex;
  int status; // 0: 等待中, 1: 下載中, 2: 已暫停, 3: 已完成, 4: 失敗
  int totalCount;
  int successCount;
  int errorCount;
  int lastUpdateTime;

  DownloadTask({
    required this.bookUrl,
    required this.bookName,
    required this.startChapterIndex,
    required this.endChapterIndex,
    this.currentChapterIndex = 0,
    this.status = 0,
    this.totalCount = 0,
    this.successCount = 0,
    this.errorCount = 0,
    this.lastUpdateTime = 0,
  });

  factory DownloadTask.fromJson(Map<String, dynamic> json) {
    return DownloadTask(
      bookUrl: json['bookUrl'],
      bookName: json['bookName'],
      startChapterIndex: json['startChapterIndex'],
      endChapterIndex: json['endChapterIndex'],
      currentChapterIndex: json['currentChapterIndex'] ?? 0,
      status: json['status'] ?? 0,
      totalCount: json['totalCount'] ?? 0,
      successCount: json['successCount'] ?? 0,
      errorCount: json['errorCount'] ?? 0,
      lastUpdateTime: json['lastUpdateTime'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookUrl': bookUrl,
      'bookName': bookName,
      'startChapterIndex': startChapterIndex,
      'endChapterIndex': endChapterIndex,
      'currentChapterIndex': currentChapterIndex,
      'status': status,
      'totalCount': totalCount,
      'successCount': successCount,
      'errorCount': errorCount,
      'lastUpdateTime': lastUpdateTime,
    };
  }

  DownloadTask copyWith({
    String? bookUrl,
    String? bookName,
    int? startChapterIndex,
    int? endChapterIndex,
    int? currentChapterIndex,
    int? status,
    int? totalCount,
    int? successCount,
    int? errorCount,
    int? lastUpdateTime,
  }) {
    return DownloadTask(
      bookUrl: bookUrl ?? this.bookUrl,
      bookName: bookName ?? this.bookName,
      startChapterIndex: startChapterIndex ?? this.startChapterIndex,
      endChapterIndex: endChapterIndex ?? this.endChapterIndex,
      currentChapterIndex: currentChapterIndex ?? this.currentChapterIndex,
      status: status ?? this.status,
      totalCount: totalCount ?? this.totalCount,
      successCount: successCount ?? this.successCount,
      errorCount: errorCount ?? this.errorCount,
      lastUpdateTime: lastUpdateTime ?? this.lastUpdateTime,
    );
  }
}

