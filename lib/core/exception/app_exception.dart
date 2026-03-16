/// AppException - 應用程式例外基類 (原 Android exception/NoStackTraceException.kt)
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);

  @override
  String toString() => message;
}

/// ConcurrentException - 併發限制例外 (對標 ConcurrentException.kt)
class ConcurrentException extends AppException {
  final int waitTime;
  ConcurrentException(super.message, this.waitTime);
}

/// ContentEmptyException - 正文解析為空 (對標 ContentEmptyException.kt)
class ContentEmptyException extends AppException {
  ContentEmptyException(super.message);
}

/// TocEmptyException - 目錄解析為空 (對標 TocEmptyException.kt)
class TocEmptyException extends AppException {
  TocEmptyException(super.message);
}

/// RegexTimeoutException - 正規表達式執行超時 (對標 RegexTimeoutException.kt)
class RegexTimeoutException extends AppException {
  RegexTimeoutException(super.message);
}

/// EmptyFileException - 本地文件為空 (對標 EmptyFileException.kt)
class EmptyFileException extends AppException {
  EmptyFileException(super.message);
}

/// NoBooksDirException - 找不到書籍目錄 (對標 NoBooksDirException.kt)
class NoBooksDirException extends AppException {
  NoBooksDirException(super.message);
}

/// InvalidBooksDirException - 書籍目錄無效 (對標 InvalidBooksDirException.kt)
class InvalidBooksDirException extends AppException {
  InvalidBooksDirException(super.message);
}

/// NoStackTraceException - 傳統 Legacy 命名對位
class NoStackTraceException extends AppException {
  NoStackTraceException(super.message);
}

