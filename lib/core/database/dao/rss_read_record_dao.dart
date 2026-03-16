import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/rss_read_record.dart';
import '../app_database.dart';

/// RssReadRecordDao - RSS 閱讀紀錄操作 (對標 Android RssReadRecordDao.kt)
class RssReadRecordDao extends BaseDao<RssReadRecord> {
  RssReadRecordDao(AppDatabase appDatabase) : super(appDatabase, 'rss_read_records');

  /// 插入單個紀錄 (對標 Android: insertRecord)
  Future<void> insertRecord(RssReadRecord record) async {
    final client = await db;
    // Android 使用 IGNORE 策略
    await client.insert(
      tableName,
      record.toJson(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  /// 批量插入紀錄 (對標 Android: insertRecords)
  Future<void> insertRecords(List<RssReadRecord> records) async {
    if (records.isEmpty) return;
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var record in records) {
        batch.insert(
          tableName,
          record.toJson(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 獲取所有紀錄 (對標 Android: getRecords)
  Future<List<RssReadRecord>> getRecords() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'readTime DESC',
    );
    return maps.map((m) => RssReadRecord.fromJson(m)).toList();
  }

  /// 獲取紀錄總數 (對標 Android: getCountRecords)
  Future<int> getCountRecords() async {
    final client = await db;
    return Sqflite.firstIntValue(await client.rawQuery('SELECT COUNT(*) FROM $tableName')) ?? 0;
  }

  /// 清空所有紀錄 (對標 Android: deleteAllRecord)
  Future<void> deleteAllRecord() async {
    await clear();
  }
}
