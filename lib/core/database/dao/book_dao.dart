import 'package:sqflite/sqflite.dart';
import 'package:legado_reader/core/models/book.dart';
import '../app_database.dart';

/// BookDao - SQLite 實作 (對標 Android BookDao.kt)
class BookDao extends BaseDao<Book> {
  BookDao(AppDatabase appDatabase) : super(appDatabase, 'books');

  /// 獲取所有書籍 (對標 Android: all)
  Future<List<Book>> getAll() async {
    final List<Map<String, dynamic>> maps = await queryAll();
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// 獲取所有書架上的書籍 (對標 Android: flowAll)
  Future<List<Book>> getInBookshelf() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'isInBookshelf = 1',
      orderBy: 'durChapterTime DESC, `order` ASC',
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// getInBookshelf 的別名，兼容舊代碼呼叫
  Future<List<Book>> getAllInBookshelf() => getInBookshelf();

  /// 獲取最後閱讀的書籍 (對標 Android: lastReadBook)
  Future<Book?> getLastReadBook() async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'isInBookshelf = 1',
      orderBy: 'durChapterTime DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Book.fromJson(maps.first);
  }

  /// 根據 URL 獲取單一書籍 (對標 Android: getBook)
  Future<Book?> getByUrl(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'bookUrl = ?',
      whereArgs: [url],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Book.fromJson(maps.first);
  }

  /// 搜尋書籍 (對標 Android: flowSearch)
  Future<List<Book>> search(String key) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '(name LIKE ? OR author LIKE ?) AND isInBookshelf = 1',
      whereArgs: ['%$key%', '%$key%'],
      orderBy: 'durChapterTime DESC',
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// 根據書名與作者獲取書籍
  Future<Book?> getByNameAndAuthor(String name, String author) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: 'name = ? AND author = ?',
      whereArgs: [name, author],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return Book.fromJson(maps.first);
  }

  /// 檢查是否存在 (對標 Android: has)
  Future<bool> has(String url) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      columns: ['bookUrl'],
      where: 'bookUrl = ?',
      whereArgs: [url],
      limit: 1,
    );
    return maps.isNotEmpty;
  }

  /// 插入或更新書籍 (UPSERT)
  Future<void> upsert(Book book) async {
    await insertOrUpdate(book.toJson());
  }

  /// 批量更新
  Future<void> upsertAll(List<Book> books) async {
    final client = await db;
    await client.transaction((txn) async {
      final batch = txn.batch();
      for (var book in books) {
        batch.insert(
          tableName,
          book.toJson(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  /// 更新進度 (對標 Android: upProgress)
  Future<void> updateProgress(String bookUrl, int pos) async {
    final client = await db;
    await client.update(
      tableName,
      {'durChapterPos': pos, 'durChapterTime': DateTime.now().millisecondsSinceEpoch},
      where: 'bookUrl = ?',
      whereArgs: [bookUrl],
    );
  }

  /// 根據 URL 刪除書籍
  Future<void> deleteByUrl(String url) async {
    final client = await db;
    await client.delete(
      tableName,
      where: 'bookUrl = ?',
      whereArgs: [url],
    );
  }

  /// 獲取指定分組的書籍 (對標 Android: flowByUserGroup)
  /// 支持位運算分組過濾
  Future<List<Book>> getByGroup(int groupMask) async {
    final client = await db;
    final List<Map<String, dynamic>> maps = await client.query(
      tableName,
      where: '(`group` & ?) > 0 AND isInBookshelf = 1',
      whereArgs: [groupMask],
      orderBy: 'durChapterTime DESC',
    );
    return maps.map((m) => Book.fromJson(m)).toList();
  }

  /// getByGroup 的別名，支持位運算
  Future<List<Book>> getBooksInGroup(int groupMask) => getByGroup(groupMask);
}
