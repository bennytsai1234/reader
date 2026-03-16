import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/book_source.dart';
import '../app_database.dart';

/// BookSourceDao - SQLite 實作 (對標 Android BookSourceDao.kt)
class BookSourceDao extends BaseDao<BookSource> {
  BookSourceDao(AppDatabase appDatabase) : super(appDatabase, 'book_sources');

  /// 獲取所有書源 (對標 Android: all)
  Future<List<BookSource>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'customOrder ASC, weight DESC',
    );
    return maps.map((m) => BookSource.fromJson(m)).toList();
  }

  /// 獲取所有書源簡略信息 (用於搜尋列表中過濾)
  Future<List<BookSource>> getAllPart() => getAll();

  /// 獲取所有書源完整信息
  Future<List<BookSource>> getAllFull() => getAll();

  /// 獲取所有啟用的書源 (對標 Android: enabled)
  Future<List<BookSource>> getEnabled() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'enabled = 1',
      orderBy: 'customOrder ASC, weight DESC',
    );
    return maps.map((m) => BookSource.fromJson(m)).toList();
  }

  /// 根據 URL 獲取單一書源 (對標 Android: getSource)
  Future<BookSource?> getByUrl(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookSourceUrl = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookSource.fromJson(maps.first);
  }

  /// 單個插入
  Future<void> insert(BookSource source) async {
    await insertOrUpdate(source.toJson());
  }

  /// 插入或更新 (UPSERT)
  Future<void> upsert(BookSource source) async {
    await insertOrUpdate(source.toJson());
  }

  /// 批量更新自定義排序
  Future<void> updateCustomOrder(List<BookSource> sources) async {
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var s in sources) {
        batch.update(
          tableName,
          {'customOrder': s.customOrder},
          where: 'bookSourceUrl = ?',
          whereArgs: [s.bookSourceUrl],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 單個更新
  Future<void> update(BookSource source) async {
    await insertOrUpdate(source.toJson());
  }

  /// 批量更新書源 (對標 Android: insertOrReplace)
  Future<void> upsertAll(List<BookSource> sources) async {
    if (sources.isEmpty) return;
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var source in sources) {
        batch.insert(
          tableName,
          source.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 插入或更新列表別名
  Future<void> insertOrUpdateAll(List<BookSource> sources) => upsertAll(sources);

  /// 根據 URL 刪除 (對標 Android: delete)
  Future<void> deleteByUrl(String url) async {
    final client = await db;
    await client.delete(
      tableName,
      where: 'bookSourceUrl = ?',
      whereArgs: [url],
    );
  }

  /// 批量刪除 URL (輔助方法)
  Future<void> deleteByUrls(List<String> urls) async {
    if (urls.isEmpty) return;
    final client = await db;
    await client.delete(
      tableName,
      where: 'bookSourceUrl IN (${List.filled(urls.length, '?').join(',')})',
      whereArgs: urls,
    );
  }

  /// 批量刪除
  Future<void> deleteSources(List<BookSource> sources) async {
    final urls = sources.map((s) => s.bookSourceUrl).toList();
    await deleteByUrls(urls);
  }

  /// 調整排序號碼 (對標 Android: adjustSortNumber)
  Future<void> adjustSortNumbers() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['bookSourceUrl'],
      orderBy: 'customOrder ASC, bookSourceName ASC',
    );
    
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var i = 0; i < maps.length; i++) {
        batch.update(
          tableName,
          {'customOrder': i},
          where: 'bookSourceUrl = ?',
          whereArgs: [maps[i]['bookSourceUrl']],
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 搜尋書源 (對標 Android: searchSource)
  Future<List<BookSource>> search(String keyword) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookSourceName LIKE ? OR bookSourceGroup LIKE ?',
      whereArgs: ['%$keyword%', '%$keyword%'],
      orderBy: 'customOrder ASC',
    );
    return maps.map((m) => BookSource.fromJson(m)).toList();
  }

  /// 重新命名分組 (對標 Android: renameGroup)
  Future<void> renameGroup(String oldName, String newName) async {
    final client = await db;
    await client.update(
      tableName,
      {'bookSourceGroup': newName},
      where: 'bookSourceGroup = ?',
      whereArgs: [oldName],
    );
  }

  /// 移除分組標籤 (對標 Android: removeGroupLabel)
  Future<void> removeGroupLabel(String groupLabel) async {
    final client = await db;
    // 將分組標籤從逗號分隔的字符串中移除 (簡化處理：目前直接清空包含該標籤的分組)
    await client.update(
      tableName,
      {'bookSourceGroup': null},
      where: 'bookSourceGroup = ?',
      whereArgs: [groupLabel],
    );
  }
}
