import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_cache_repository.dart';

class _FakeChapterDao implements ChapterDao {
  final List<List<BookChapter>> insertedBatches = <List<BookChapter>>[];

  @override
  Future<void> insertChapters(List<BookChapter> chapterList) async {
    insertedBatches.add(List<BookChapter>.from(chapterList));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeChapterContentDao implements ReaderChapterContentDao {
  final Map<String, String> contentByKey = <String, String>{};
  final Map<String, int> failuresByKey = <String, int>{};

  @override
  Future<String?> getContent({
    required String cacheKey,
    int? minUpdatedAt,
  }) async {
    return contentByKey[cacheKey];
  }

  @override
  Future<void> saveContent({
    required String cacheKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required String content,
    required int updatedAt,
    bool isPersistent = false,
  }) async {
    contentByKey[cacheKey] = content;
    failuresByKey[cacheKey] = 0;
  }

  @override
  Future<Set<int>> getCachedChapterIndices({
    required String origin,
    required String bookUrl,
    bool persistentOnly = false,
  }) async {
    return contentByKey.keys.map((_) => 1).toSet();
  }

  @override
  Future<int> getFailureCount(String cacheKey) async =>
      failuresByKey[cacheKey] ?? 0;

  @override
  Future<void> recordFailure({
    required String cacheKey,
    required String origin,
    required String bookUrl,
    required String chapterUrl,
    required int chapterIndex,
    required int updatedAt,
  }) async {
    failuresByKey[cacheKey] = (failuresByKey[cacheKey] ?? 0) + 1;
  }

  @override
  Future<void> deleteByBook(String origin, String bookUrl) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

Book _book({bool bookshelf = false}) => Book(
  bookUrl: 'https://example.com/book/1',
  origin: 'https://source.example',
  name: 'Book',
  author: 'Author',
  isInBookshelf: bookshelf,
);

BookChapter _chapter(int index, String url) => BookChapter(
  title: 'c$index',
  index: index,
  url: url,
  bookUrl: 'https://example.com/book/1',
);

void main() {
  group('ReaderChapterContentCacheRepository', () {
    test('非書架網路書保存到 transient cache，不寫正式 chapters', () async {
      final chapterDao = _FakeChapterDao();
      final contentDao = _FakeChapterContentDao();
      final repository = ReaderChapterContentCacheRepository(
        chapterDao: chapterDao,
        contentDao: contentDao,
      );
      final book = _book();
      final chapter = _chapter(1, 'chapter-1');

      await repository.saveRawContent(
        book: book,
        chapter: chapter,
        content: 'raw content',
      );

      expect(chapterDao.insertedBatches, isEmpty);
      expect(
        await repository.getRawContent(book: book, chapter: chapter),
        'raw content',
      );
    });

    test('書架內網路書保存到持久章節內容 store', () async {
      final chapterDao = _FakeChapterDao();
      final contentDao = _FakeChapterContentDao();
      final repository = ReaderChapterContentCacheRepository(
        chapterDao: chapterDao,
        contentDao: contentDao,
      );
      final book = _book(bookshelf: true);
      final chapter = _chapter(2, 'chapter-2');

      await repository.saveRawContent(
        book: book,
        chapter: chapter,
        content: 'bookshelf raw',
      );

      expect(chapterDao.insertedBatches.single.single.url, 'chapter-2');
      expect(
        contentDao.contentByKey[ReaderChapterContentCacheRepository.cacheKeyFor(
          book: book,
          chapter: chapter,
        )],
        'bookshelf raw',
      );
    });

    test('加入書架時會提升 matching transient content', () async {
      final chapterDao = _FakeChapterDao();
      final contentDao = _FakeChapterContentDao();
      final repository = ReaderChapterContentCacheRepository(
        chapterDao: chapterDao,
        contentDao: contentDao,
      );
      final book = _book();
      final chapters = [_chapter(0, 'chapter-0'), _chapter(1, 'chapter-1')];

      await repository.saveRawContent(
        book: book,
        chapter: chapters[1],
        content: 'cached chapter',
      );
      book.isInBookshelf = true;
      await repository.promoteTransientCacheToBookshelf(
        book: book,
        chapters: chapters,
      );

      expect(chapterDao.insertedBatches.single.length, 2);
      expect(
        contentDao.contentByKey[ReaderChapterContentCacheRepository.cacheKeyFor(
          book: book,
          chapter: chapters[1],
        )],
        'cached chapter',
      );
      expect(
        contentDao.contentByKey.containsKey(
          ReaderChapterContentCacheRepository.cacheKeyFor(
            book: book,
            chapter: chapters[0],
          ),
        ),
        isFalse,
      );
    });

    test('不再讀取 chapter inline content，只讀 chapter content store', () async {
      final chapterDao = _FakeChapterDao();
      final contentDao = _FakeChapterContentDao();
      final repository = ReaderChapterContentCacheRepository(
        chapterDao: chapterDao,
        contentDao: contentDao,
      );
      final book = _book(bookshelf: true);
      final chapter = _chapter(
        3,
        'chapter-3',
      ).copyWith(content: 'legacy inline');

      final content = await repository.getRawContent(
        book: book,
        chapter: chapter,
      );

      expect(content, isNull);
      expect(
        contentDao.contentByKey.containsKey(
          ReaderChapterContentCacheRepository.cacheKeyFor(
            book: book,
            chapter: chapter,
          ),
        ),
        isFalse,
      );
    });
  });
}
