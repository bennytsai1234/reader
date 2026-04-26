import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';

enum ReaderChapterContentCachePolicy { bookshelfLongTerm, transientNetwork }

class ReaderChapterContentCacheRepository {
  ReaderChapterContentCacheRepository({
    required this.chapterDao,
    required this.contentDao,
    DateTime Function()? now,
    this.transientCacheTtl = const Duration(days: 14),
    this.failureSkipThreshold = 3,
  }) : _now = now ?? DateTime.now;

  final ChapterDao chapterDao;
  final ReaderChapterContentDao contentDao;
  final DateTime Function() _now;
  final Duration transientCacheTtl;
  final int failureSkipThreshold;

  ReaderChapterContentCachePolicy policyFor(Book book) {
    if (book.origin == 'local' || book.isInBookshelf) {
      return ReaderChapterContentCachePolicy.bookshelfLongTerm;
    }
    return ReaderChapterContentCachePolicy.transientNetwork;
  }

  Future<String?> getRawContent({
    required Book book,
    required BookChapter chapter,
    ReaderChapterContentCachePolicy? policy,
  }) async {
    final resolvedPolicy = policy ?? policyFor(book);
    final storedContent = await contentDao.getContent(
      cacheKey: cacheKeyFor(book: book, chapter: chapter),
      minUpdatedAt:
          resolvedPolicy == ReaderChapterContentCachePolicy.transientNetwork
              ? _transientMinUpdatedAt
              : null,
    );
    return storedContent == null || storedContent.isEmpty
        ? null
        : storedContent;
  }

  Future<void> saveRawContent({
    required Book book,
    required BookChapter chapter,
    required String content,
    ReaderChapterContentCachePolicy? policy,
  }) async {
    if (content.isEmpty) return;
    final resolvedPolicy = policy ?? policyFor(book);
    if (resolvedPolicy == ReaderChapterContentCachePolicy.bookshelfLongTerm) {
      await chapterDao.insertChapters(<BookChapter>[chapter]);
    }

    await contentDao.saveContent(
      cacheKey: cacheKeyFor(book: book, chapter: chapter),
      origin: book.origin,
      bookUrl: book.bookUrl,
      chapterUrl: chapter.url,
      chapterIndex: chapter.index,
      content: content,
      updatedAt: _now().millisecondsSinceEpoch,
      isPersistent:
          resolvedPolicy == ReaderChapterContentCachePolicy.bookshelfLongTerm,
    );
  }

  Future<void> promoteTransientCacheToBookshelf({
    required Book book,
    required List<BookChapter> chapters,
    bool insertChapterMetadata = true,
  }) async {
    if (chapters.isEmpty) return;
    if (insertChapterMetadata) {
      await chapterDao.insertChapters(chapters);
    }
    if (book.origin == 'local') return;
    for (final chapter in chapters) {
      final cacheKey = cacheKeyFor(book: book, chapter: chapter);
      final content = await contentDao.getContent(
        cacheKey: cacheKey,
        minUpdatedAt: _transientMinUpdatedAt,
      );
      if (content != null && content.isNotEmpty) {
        await contentDao.saveContent(
          cacheKey: cacheKey,
          origin: book.origin,
          bookUrl: book.bookUrl,
          chapterUrl: chapter.url,
          chapterIndex: chapter.index,
          content: content,
          updatedAt: _now().millisecondsSinceEpoch,
          isPersistent: true,
        );
      }
    }
  }

  Future<Set<int>> cachedChapterIndices({required Book book}) async {
    return contentDao.getCachedChapterIndices(
      origin: book.origin,
      bookUrl: book.bookUrl,
    );
  }

  Future<void> deleteCachedContentForBook({required Book book}) async {
    await contentDao.deleteContentByBook(book.origin, book.bookUrl);
  }

  Future<void> recordFetchFailure({
    required Book book,
    required BookChapter chapter,
  }) {
    if (policyFor(book) == ReaderChapterContentCachePolicy.bookshelfLongTerm) {
      return Future<void>.value();
    }
    return contentDao.recordFailure(
      cacheKey: cacheKeyFor(book: book, chapter: chapter),
      origin: book.origin,
      bookUrl: book.bookUrl,
      chapterUrl: chapter.url,
      chapterIndex: chapter.index,
      updatedAt: _now().millisecondsSinceEpoch,
    );
  }

  Future<bool> shouldSkipFetch({
    required Book book,
    required BookChapter chapter,
  }) async {
    if (policyFor(book) == ReaderChapterContentCachePolicy.bookshelfLongTerm) {
      return false;
    }
    final failures = await contentDao.getFailureCount(
      cacheKeyFor(book: book, chapter: chapter),
    );
    return failures >= failureSkipThreshold;
  }

  Future<int> cleanupTransientCache() {
    return contentDao.cleanupOlderThan(_transientMinUpdatedAt);
  }

  int get _transientMinUpdatedAt =>
      _now().subtract(transientCacheTtl).millisecondsSinceEpoch;

  static String cacheKeyFor({
    required Book book,
    required BookChapter chapter,
  }) => ReaderChapterContentDao.cacheKey(
    origin: book.origin,
    bookUrl: book.bookUrl,
    chapterUrl: chapter.url,
  );
}
