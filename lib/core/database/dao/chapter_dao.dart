import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/chapter.dart';
import '../app_database.dart';

/// ChapterDao - SQLite 實作 (對標 Android Room ChapterDao)
class ChapterDao extends BaseDao<BookChapter> {
  ChapterDao(AppDatabase appDatabase) : super(appDatabase, 'chapters');

  /// 獲取指定書籍的所有章節 (對標 Android: getChapters)
  Future<List<BookChapter>> getByBookUrl(String bookUrl) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
      orderBy: '`index` ASC',
    );
    return maps.map((m) => BookChapter.fromJson(m)).toList();
  }

  /// getByBookUrl 的別名，兼容舊代碼
  Future<List<BookChapter>> getChapters(String bookUrl) => getByBookUrl(bookUrl);

  /// 根據 URL 和索引獲取章節 (對標 Android: getChapter)
  Future<BookChapter?> getChapterByIndex(String bookUrl, int index) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookUrl = ? AND `index` = ?',
      whereArgs: [bookUrl, index],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookChapter.fromJson(maps.first);
  }

  /// 根據 URL 獲取單一章節
  Future<BookChapter?> getByUrl(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return BookChapter.fromJson(maps.first);
  }

  /// 儲存章節內容 (對標 Android: saveContent)
  Future<void> saveContent(String url, String content) async {
    final client = await db;
    await client.update(
      tableName,
      {'content': content},
      where: 'url = ?',
      whereArgs: [url],
    );
  }

  /// 獲取章節內容 (對標 Android: getContent)
  Future<String?> getContent(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['content'],
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['content'] as String?;
  }

  /// 插入單個章節
  Future<void> upsert(BookChapter chapter) async {
    await insertOrUpdate(chapter.toJson());
  }

  /// 批量插入章節 (對標 Android: insertAll)
  Future<void> insertChapters(List<BookChapter> chapters) async {
    if (chapters.isEmpty) return;
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var chapter in chapters) {
        batch.insert(
          tableName,
          chapter.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 刪除書籍的所有章節 (對標 Android: deleteByBook)
  Future<void> deleteByBookUrl(String bookUrl) async {
    await delete('bookUrl = ?', [bookUrl]);
  }

  /// 別名相容
  Future<void> deleteByBook(String bookUrl) => deleteByBookUrl(bookUrl);

  /// 檢查章節內容是否已存在
  Future<bool> hasContent(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['content'],
      where: 'url = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return false;
    final content = maps.first['content'] as String?;
    return content != null && content.isNotEmpty;
  }

  /// 根據書籍 URL 刪除所有章節的內容 (對標 Android: deleteContentByBook)
  Future<void> deleteContentByBook(String bookUrl) async {
    final client = await db;
    await client.update(
      tableName,
      {'content': null},
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );
  }

  /// 清空所有章節的內容 (對標 Android: clearAllContent)
  Future<void> clearAllContent() async {
    final client = await db;
    await client.update(
      tableName,
      {'content': null},
    );
  }

  /// 獲取所有章節內容的總大小估算 (單位: byte)
  Future<int> getTotalContentSize() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.rawQuery(
      'SELECT SUM(LENGTH(content)) as total FROM $tableName'
    );
    if (maps.isEmpty || maps.first['total'] == null) return 0;
    return maps.first['total'] as int;
  }
}
