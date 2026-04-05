import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/search_history_dao.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/features/search/search_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:legado_reader/core/database/app_database.dart';

// ---------------------------------------------------------------------------
// Fake DAOs
// ---------------------------------------------------------------------------

class _FakeSourceDao extends Fake implements BookSourceDao {
  List<BookSource> sources = [];

  @override
  Future<List<BookSource>> getAllPart() async => sources;

  @override
  Future<List<BookSource>> getEnabled() async =>
      sources.where((s) => s.enabled).toList();
}

class _FakeHistoryDao extends Fake implements SearchHistoryDao {
  final List<SearchHistoryRow> _rows = [];

  @override
  Future<List<SearchHistoryRow>> getRecent() async => _rows;

  @override
  Future<void> add(String keyword) async {
    _rows.insert(0, SearchHistoryRow(id: _rows.length, keyword: keyword, searchTime: 0));
  }

  @override
  Future<void> clearAll() async => _rows.clear();
}

// ---------------------------------------------------------------------------
// 測試
// ---------------------------------------------------------------------------

void main() {
  late _FakeSourceDao fakeSourceDao;
  late _FakeHistoryDao fakeHistoryDao;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    fakeSourceDao = _FakeSourceDao();
    fakeHistoryDao = _FakeHistoryDao();

    final getIt = GetIt.instance;
    getIt.registerLazySingleton<BookSourceDao>(() => fakeSourceDao);
    getIt.registerLazySingleton<SearchHistoryDao>(() => fakeHistoryDao);
  });

  tearDown(() async => GetIt.instance.reset());

  Future<SearchProvider> makeProvider() async {
    final p = SearchProvider();
    await Future.delayed(Duration.zero); // 等 constructor async 完成
    return p;
  }

  group('SearchProvider - 書源群組', () {
    test('無書源時 sourceGroups 只有「全部」', () async {
      final p = await makeProvider();
      expect(p.sourceGroups, ['全部']);
    });

    test('有群組的書源會加入 sourceGroups', () async {
      fakeSourceDao.sources = [
        BookSource(bookSourceUrl: 'http://a.com', bookSourceName: 'A', bookSourceGroup: '玄幻'),
        BookSource(bookSourceUrl: 'http://b.com', bookSourceName: 'B', bookSourceGroup: '都市'),
      ];
      final p = await makeProvider();
      expect(p.sourceGroups, containsAll(['全部', '玄幻', '都市']));
    });

    test('setGroup 更新 selectedGroup', () async {
      fakeSourceDao.sources = [
        BookSource(bookSourceUrl: 'http://a.com', bookSourceName: 'A', bookSourceGroup: '玄幻'),
      ];
      final p = await makeProvider();
      p.setGroup('玄幻');
      expect(p.selectedGroup, '玄幻');
    });
  });

  group('SearchProvider - 精準搜尋', () {
    test('初始 precisionSearch 為 false', () async {
      final p = await makeProvider();
      expect(p.precisionSearch, isFalse);
    });

    test('togglePrecisionSearch 切換狀態並寫入 prefs', () async {
      final p = await makeProvider();
      await p.togglePrecisionSearch();
      expect(p.precisionSearch, isTrue);
      await p.togglePrecisionSearch();
      expect(p.precisionSearch, isFalse);
    });
  });

  group('SearchProvider - 搜尋狀態', () {
    test('search 空字串不啟動搜尋', () async {
      final p = await makeProvider();
      await p.search('');
      expect(p.isSearching, isFalse);
      expect(p.lastSearchKey, isEmpty);
    });

    test('stopSearch 設定 isSearching = false', () async {
      final p = await makeProvider();
      // 直接呼叫 stopSearch，不實際觸發網路
      p.stopSearch();
      expect(p.isSearching, isFalse);
    });

    test('無啟用書源時 search 完成後 isSearching = false', () async {
      fakeSourceDao.sources = [];
      final p = await makeProvider();
      await p.search('測試');
      expect(p.isSearching, isFalse);
      expect(p.lastSearchKey, '測試');
    });
  });

  group('SearchProvider - 搜尋歷史', () {
    test('初始歷史為空', () async {
      final p = await makeProvider();
      expect(p.history, isEmpty);
    });

    test('搜尋後歷史更新', () async {
      fakeSourceDao.sources = [];
      final p = await makeProvider();
      await p.search('閱讀');
      expect(p.history, contains('閱讀'));
    });

    test('clearHistory 清空歷史', () async {
      fakeSourceDao.sources = [];
      final p = await makeProvider();
      await p.search('閱讀');
      await p.clearHistory();
      expect(p.history, isEmpty);
    });
  });

  group('SearchProvider - progress', () {
    test('無書源時 progress 為 0', () async {
      final p = await makeProvider();
      expect(p.progress, 0.0);
    });

    test('totalSources 初始為 0', () async {
      final p = await makeProvider();
      expect(p.totalSources, 0);
    });
  });
}
