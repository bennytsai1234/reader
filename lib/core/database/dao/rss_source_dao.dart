import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/rss_source.dart';
import '../app_database.dart';

/// RssSourceDao - SQLite 實作 (對標 Android Room RssSourceDao.kt)
class RssSourceDao extends BaseDao<RssSource> {
  RssSourceDao(AppDatabase appDatabase) : super(appDatabase, 'rss_sources');

  /// 獲取所有 RSS 源 (對標 Android: all)
  Future<List<RssSource>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'customOrder ASC, sourceName ASC',
    );
    return maps.map((m) => RssSource.fromJson(m)).toList();
  }

  /// 獲取所有啟用的 RSS 源 (對標 Android: enabled)
  Future<List<RssSource>> getEnabled() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'enabled = 1',
      orderBy: 'customOrder ASC, sourceName ASC',
    );
    return maps.map((m) => RssSource.fromJson(m)).toList();
  }

  /// 根據 URL 獲取單一 RSS 源 (對標 Android: getSource)
  Future<RssSource?> getByUrl(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'sourceUrl = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RssSource.fromJson(maps.first);
  }

  /// 插入或更新單個 RSS 源 (UPSERT)
  Future<void> upsert(RssSource source) async {
    await insertOrUpdate(source.toJson());
  }

  /// 批量更新 RSS 源
  Future<void> insertOrUpdateAll(List<RssSource> sources) async {
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

  /// 更新啟用狀態 (對標 Android: updateEnabled)
  Future<void> updateEnabled(String url, bool enabled) async {
    final client = await db;
    await client.update(
      tableName,
      {'enabled': enabled ? 1 : 0},
      where: 'sourceUrl = ?',
      whereArgs: [url],
    );
  }

  /// 獲取所有分組 (對標 Android: allGroups)
  Future<List<String>> getAllGroups() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['sourceGroup'],
      distinct: true,
    );
    return maps
        .map((m) => m['sourceGroup'] as String?)
        .where((g) => g != null && g.isNotEmpty)
        .cast<String>()
        .toList();
  }

  /// 根據 URL 刪除 (對標 Android: delete)
  Future<void> deleteByUrl(String url) async {
    await delete('sourceUrl = ?', [url]);
  }
}
