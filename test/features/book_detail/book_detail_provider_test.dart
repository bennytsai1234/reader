import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:legado_reader/core/database/dao/book_dao.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/database/dao/chapter_dao.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/features/book_detail/book_detail_provider.dart';

// ---------------------------------------------------------------------------
// Fake DAOs
// ---------------------------------------------------------------------------

class _FakeBookDao extends Fake implements BookDao {
  final Map<String, Book> _store = {};

  @override
  Future<Book?> getByUrl(String url) async => _store[url];

  @override
  Future<void> upsert(Book book) async => _store[book.bookUrl] = book;

  @override
  Future<void> deleteByUrl(String url) async => _store.remove(url);
}

class _FakeChapterDao extends Fake implements ChapterDao {
  final Map<String, List<BookChapter>> _store = {};

  @override
  Future<List<BookChapter>> getChapters(String bookUrl) async =>
      _store[bookUrl] ?? [];

  @override
  Future<void> insertChapters(List<BookChapter> chapters) async {
    if (chapters.isEmpty) return;
    _store[chapters.first.bookUrl] = chapters;
  }

  @override
  Future<void> deleteContentByBook(String bookUrl) async {}
}

class _FakeSourceDao extends Fake implements BookSourceDao {
  @override
  Future<BookSource?> getByUrl(String url) async => null;
}

// ---------------------------------------------------------------------------
// 測試輔助
// ---------------------------------------------------------------------------

AggregatedSearchBook _makeSearchBook({String url = 'http://book.com'}) {
  final sb = SearchBook(
    bookUrl: url,
    name: '測試書',
    author: '作者',
    origin: 'origin',
    originName: '書源',
  );
  return AggregatedSearchBook(book: sb, sources: ['書源']);
}

List<BookChapter> _makeChapters(int n) => List.generate(
      n,
      (i) => BookChapter(
        url: 'chapter_$i',
        title: '第 $i 章',
        bookUrl: 'http://book.com',
        index: i,
      ),
    );

// ---------------------------------------------------------------------------
// 測試
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    GetIt.instance.registerLazySingleton<BookDao>(() => _FakeBookDao());
    GetIt.instance.registerLazySingleton<ChapterDao>(() => _FakeChapterDao());
    GetIt.instance.registerLazySingleton<BookSourceDao>(() => _FakeSourceDao());
  });

  tearDown(() async => GetIt.instance.reset());

  Future<BookDetailProvider> makeProvider({
    String url = 'http://book.com',
    List<BookChapter> chapters = const [],
  }) async {
    final chapterDao = GetIt.instance<ChapterDao>() as _FakeChapterDao;
    if (chapters.isNotEmpty) {
      await chapterDao.insertChapters(chapters);
    }
    final p = BookDetailProvider(_makeSearchBook(url: url));
    await Future.delayed(Duration.zero); // 等 _init() async 完成
    return p;
  }

  group('BookDetailProvider - 初始狀態', () {
    test('未在書架時 isInBookshelf 為 false', () async {
      final p = await makeProvider();
      expect(p.isInBookshelf, isFalse);
      expect(p.isLoading, isFalse);
    });

    test('DAO 中已有該書時 isInBookshelf 為 true', () async {
      final bookDao = GetIt.instance<BookDao>() as _FakeBookDao;
      final book = Book(
        bookUrl: 'http://book.com',
        name: '存在的書',
        author: '作者',
        origin: 'o',
        originName: 'on',
        isInBookshelf: true,
      );
      await bookDao.upsert(book);

      final p = await makeProvider();
      expect(p.isInBookshelf, isTrue);
    });
  });

  group('BookDetailProvider - 章節篩選', () {
    test('setSearchQuery 篩選章節', () async {
      final chapters = _makeChapters(5);
      chapters[2] = BookChapter(
        url: 'chapter_2',
        title: '特殊章節',
        bookUrl: 'http://book.com',
        index: 2,
      );
      final p = await makeProvider(chapters: chapters);

      p.setSearchQuery('特殊');
      await Future.delayed(const Duration(milliseconds: 350)); // debounce
      expect(p.filteredChapters, hasLength(1));
      expect(p.filteredChapters.first.title, '特殊章節');
    });

    test('清空 searchQuery 恢復全部章節', () async {
      final p = await makeProvider(chapters: _makeChapters(5));

      p.setSearchQuery('不存在');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(p.filteredChapters, isEmpty);

      p.setSearchQuery('');
      await Future.delayed(const Duration(milliseconds: 350));
      expect(p.filteredChapters, hasLength(5));
    });

    test('toggleSort 反轉章節順序', () async {
      final p = await makeProvider(chapters: _makeChapters(3));
      expect(p.filteredChapters.first.index, 0);

      p.toggleSort();
      expect(p.isReversed, isTrue);
      expect(p.filteredChapters.first.index, 2);

      p.toggleSort();
      expect(p.filteredChapters.first.index, 0);
    });

    test('totalChapterCount 正確回傳數量', () async {
      final p = await makeProvider(chapters: _makeChapters(7));
      expect(p.totalChapterCount, 7);
    });
  });
}
