import 'dart:async';
import 'package:legado_reader/core/models/rss_star.dart';
import '../app_database.dart';

/// RssStarDao - RSS 收藏文章操作 (對標 Android RssStarDao.kt)
class RssStarDao extends BaseDao<RssStar> {
  RssStarDao(AppDatabase appDatabase) : super(appDatabase, 'rss_stars');

  /// 獲取所有收藏 (對標 Android: all)
  Future<List<RssStar>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'starTime DESC',
    );
    return maps.map((m) => RssStar.fromJson(m)).toList();
  }

  /// 獲取所有分組
  Future<List<String>> getGroups() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['`group`'],
      distinct: true,
    );
    final groups = maps.map((m) => m['group'] as String).toList();
    groups.sort();
    return groups;
  }

  /// 根據分組獲取收藏 (對標 Android: getByGroup)
  Future<List<RssStar>> getByGroup(String group) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '`group` = ?',
      whereArgs: [group],
      orderBy: 'starTime DESC',
    );
    return maps.map((m) => RssStar.fromJson(m)).toList();
  }

  /// 根據來源與連結獲取 (對標 Android: get)
  Future<RssStar?> getByOriginAndLink(String origin, String link) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'origin = ? AND link = ?',
      whereArgs: [origin, link],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return RssStar.fromJson(maps.first);
  }

  /// 插入或更新收藏 (UPSERT)
  Future<void> upsert(RssStar star) async {
    await insertOrUpdate(star.toJson());
  }

  /// 插入別名，兼容舊代碼
  Future<void> insert(RssStar star) => upsert(star);

  /// 更新來源名稱 (對標 Android: updateOrigin)
  Future<void> updateOrigin(String newOrigin, String oldOrigin) async {
    final client = await db;
    await client.update(
      tableName,
      {'origin': newOrigin},
      where: 'origin = ?',
      whereArgs: [oldOrigin],
    );
  }

  /// 根據來源刪除 (對標 Android: deleteByOrigin)
  Future<void> deleteByOrigin(String origin) async {
    await delete('origin = ?', [origin]);
  }

  /// 根據來源與連結刪除 (對標 Android: delete)
  Future<void> deleteByLink(String origin, String link) async {
    await delete('origin = ? AND link = ?', [origin, link]);
  }

  /// 刪除指定分組的收藏
  Future<void> deleteByGroup(String group) async {
    await delete('`group` = ?', [group]);
  }

  /// 清空所有收藏
  Future<void> deleteAll() async {
    await clear();
  }
}
