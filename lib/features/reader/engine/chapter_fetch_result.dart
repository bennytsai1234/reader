class FetchResult {
  final String content;
  final String? displayTitle;
  final String? failureMessage;

  FetchResult({required this.content, this.displayTitle, this.failureMessage});

  bool get isFailure => failureMessage?.trim().isNotEmpty == true;
}

typedef ChapterFetchFn = Future<FetchResult> Function(int chapterIndex);
