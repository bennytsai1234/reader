import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/rss_article.dart';
import '../app_database.dart';

/// RssArticleDao - SQLite 實作 (對標 Android Room RssArticleDao.kt)
class RssArticleDao extends BaseDao<RssArticle> {
  RssArticleDao(AppDatabase appDatabase) : super(appDatabase, 'rss_articles');

  /// 獲取所有文章
  Future<List<RssArticle>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'pubDate DESC',
    );
    return maps.map((m) => RssArticle.fromJson(m)).toList();
  }

  /// 獲取指定源的文章 (對標 Android: getByOrigin)
  Future<List<RssArticle>> getByOrigin(String origin) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'origin = ?',
      whereArgs: [origin],
      orderBy: 'pubDate DESC',
    );
    return maps.map((m) => RssArticle.fromJson(m)).toList();
  }

  /// 插入或更新單個文章 (UPSERT)
  Future<void> upsert(RssArticle article) async {
    await insertOrUpdate(article.toJson());
  }

  /// 批量插入文章 (對標 Android: insertAll)
  Future<void> insertAll(List<RssArticle> articles) async {
    if (articles.isEmpty) return;
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var article in articles) {
        batch.insert(
          tableName,
          article.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 根據連結刪除文章
  Future<void> deleteByLink(String link) async {
    await delete('link = ?', [link]);
  }

  /// 清空指定源的文章 (對標 Android: clearByOrigin)
  Future<void> clearByOrigin(String origin) async {
    await delete('origin = ?', [origin]);
  }

  /// 清空所有文章
  Future<void> clearAll() async {
    await clear();
  }
}
