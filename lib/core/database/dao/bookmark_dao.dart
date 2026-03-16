import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/engine/app_event_bus.dart';
import '../app_database.dart';

/// BookmarkDao - SQLite 實作 (對標 Android BookmarkDao.kt)
class BookmarkDao extends BaseDao<Bookmark> {
  BookmarkDao(AppDatabase appDatabase) : super(appDatabase, 'bookmarks');

  /// 獲取所有書籤並依照書名、作者、章節與位置排序
  Future<List<Bookmark>> getAll() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      orderBy: 'bookName ASC, bookAuthor ASC, chapterIndex ASC, chapterPos ASC',
    );
    return maps.map((m) => Bookmark.fromJson(m)).toList();
  }

  /// 根據書名與作者獲取書籤 (對標 Android: getByBook)
  Future<List<Bookmark>> getByBook(String bookName, String bookAuthor) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookName = ? AND bookAuthor = ?',
      whereArgs: [bookName, bookAuthor],
      orderBy: 'chapterIndex ASC',
    );
    return maps.map((m) => Bookmark.fromJson(m)).toList();
  }

  /// 搜尋特定書籍的書籤
  Future<List<Bookmark>> searchInBook(
    String bookName,
    String bookAuthor,
    String key,
  ) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookName = ? AND bookAuthor = ? AND (chapterName LIKE ? OR content LIKE ?)',
      whereArgs: [bookName, bookAuthor, '%$key%', '%$key%'],
      orderBy: 'chapterIndex ASC',
    );
    return maps.map((m) => Bookmark.fromJson(m)).toList();
  }

  /// 新增書籤 (UPSERT)
  Future<void> upsert(Bookmark bookmark) async {
    await insertOrUpdate(bookmark.toJson());
    AppEventBus().fire('up_bookmark');
  }

  /// 刪除書籤
  Future<void> deleteBookmark(Bookmark bookmark) async {
    if (bookmark.id != null) {
      await delete('id = ?', [bookmark.id]);
      AppEventBus().fire('up_bookmark');
    }
  }

  /// 清除所有書籤
  Future<void> clearAll() async {
    final client = await db;
    await client.delete(tableName);
    AppEventBus().fire('up_bookmark');
  }

  /// 全域搜尋書籤（跨所有書籍）
  Future<List<Bookmark>> search(String key) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'chapterName LIKE ? OR content LIKE ?',
      whereArgs: ['%$key%', '%$key%'],
      orderBy: 'bookName ASC, bookAuthor ASC, chapterIndex ASC',
    );
    return maps.map((m) => Bookmark.fromJson(m)).toList();
  }
}
