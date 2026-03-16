import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/replace_rule.dart';
import '../app_database.dart';

/// ReplaceRuleDao - SQLite 實作 (對標 Android ReplaceRuleDao.kt)
class ReplaceRuleDao extends BaseDao<ReplaceRule> {
  ReplaceRuleDao(AppDatabase appDatabase) : super(appDatabase, 'replace_rules');

  /// 獲取所有替換規則 (對標 Android: all)
  Future<List<ReplaceRule>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: '`order` ASC, name ASC',
    );
    return maps.map((m) => ReplaceRule.fromJson(m)).toList();
  }

  /// 獲取所有啟用的替換規則 (對標 Android: enabled)
  Future<List<ReplaceRule>> getEnabled() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'enabled = 1',
      orderBy: '`order` ASC',
    );
    return maps.map((m) => ReplaceRule.fromJson(m)).toList();
  }

  /// 單個插入 (UPSERT)
  Future<void> upsert(ReplaceRule rule) async {
    await insertOrUpdate(rule.toJson());
  }

  /// 批量插入
  Future<void> upsertAll(List<ReplaceRule> rules) async {
    if (rules.isEmpty) return;
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var rule in rules) {
        batch.insert(
          tableName,
          rule.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 根據 ID 刪除
  Future<void> deleteById(int id) async {
    await delete('id = ?', [id]);
  }

  /// 更新啟用狀態
  Future<void> updateEnabled(int id, bool enabled) async {
    final client = await db;
    await client.update(
      tableName,
      {'enabled': enabled ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 更新排序
  Future<void> updateOrder(int id, int order) async {
    final client = await db;
    await client.update(
      tableName,
      {'`order`': order},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
