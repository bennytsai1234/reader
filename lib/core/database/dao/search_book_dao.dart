import 'package:drift/drift.dart';
import '../../models/search_book.dart';
import '../tables/app_tables.dart';
import '../app_database.dart';

part 'search_book_dao.g.dart';

@DriftAccessor(tables: [SearchBooks, BookSources])
class SearchBookDao extends DatabaseAccessor<AppDatabase> with _$SearchBookDaoMixin {
  SearchBookDao(AppDatabase db) : super(db);

  Future<SearchBook?> getSearchBook(String bookUrl) {
    return (select(searchBooks)..where((t) => t.bookUrl.equals(bookUrl))).getSingleOrNull();
  }

  Future<SearchBook?> getFirstByNameAuthor(String name, String author) {
    return customSelect(
      'SELECT * FROM searchBooks WHERE name = ? AND author = ? AND origin IN (SELECT bookSourceUrl FROM book_sources) ORDER BY originOrder LIMIT 1',
      variables: [Variable.withString(name), Variable.withString(author)],
      readsFrom: {searchBooks, bookSources},
    ).map((row) => SearchBook.fromJson(row.data)).getSingleOrNull();
  }

  Future<List<SearchBook>> getByNameAuthor(String name, String author) {
    return (select(searchBooks)
          ..where((t) => t.name.equals(name) & t.author.equals(author)))
        .get();
  }

  Future<List<SearchBook>> changeSourceByGroup(String name, String author, String sourceGroup) {
    return customSelect(
      '''
      SELECT t1.*, t2.customOrder as originOrder
      FROM searchBooks as t1 INNER JOIN book_sources as t2 ON t1.origin = t2.bookSourceUrl
      WHERE t1.name = ? AND t1.author LIKE ?
      AND t2.enabled = 1 AND t2.bookSourceGroup LIKE ?
      ORDER BY t2.customOrder
      ''',
      variables: [
        Variable.withString(name),
        Variable.withString('%$author%'),
        Variable.withString('%$sourceGroup%')
      ],
      readsFrom: {searchBooks, bookSources},
    ).map((row) => SearchBook.fromJson(row.data)).get();
  }

  Future<List<SearchBook>> changeSourceSearch(String name, String author, String key, String sourceGroup) {
    return customSelect(
      '''
      SELECT t1.*, t2.customOrder as originOrder
      FROM searchBooks as t1 INNER JOIN book_sources as t2 ON t1.origin = t2.bookSourceUrl
      WHERE t1.name = ? AND t1.author LIKE ?
      AND t2.bookSourceGroup LIKE ?
      AND (t1.originName LIKE ? OR t1.latestChapterTitle LIKE ?)
      AND t2.enabled = 1
      ORDER BY t2.customOrder
      ''',
      variables: [
        Variable.withString(name),
        Variable.withString('%$author%'),
        Variable.withString('%$sourceGroup%'),
        Variable.withString('%$key%'),
        Variable.withString('%$key%')
      ],
      readsFrom: {searchBooks, bookSources},
    ).map((row) => SearchBook.fromJson(row.data)).get();
  }

  Future<List<SearchBook>> getEnabledHasCover(String name, String author) {
    return customSelect(
      '''
      SELECT t1.*, t2.customOrder as originOrder
      FROM searchBooks as t1 INNER JOIN book_sources as t2 ON t1.origin = t2.bookSourceUrl
      WHERE t1.name = ? AND t1.author = ? AND t1.coverUrl IS NOT NULL AND t1.coverUrl <> '' AND t2.enabled = 1
      ORDER BY t2.customOrder
      ''',
      variables: [Variable.withString(name), Variable.withString(author)],
      readsFrom: {searchBooks, bookSources},
    ).map((row) => SearchBook.fromJson(row.data)).get();
  }

  Future<void> upsert(SearchBook book) => into(searchBooks).insertOnConflictUpdate(SearchBookToInsertable(book).toInsertable());

  Future<void> insertList(List<SearchBook> books) async {
    await batch((b) => b.insertAllOnConflictUpdate(searchBooks, books.map((e) => SearchBookToInsertable(e).toInsertable()).toList()));
  }

  Future<void> deleteByUrl(String url) =>
      (delete(searchBooks)..where((t) => t.bookUrl.equals(url))).go();

  Future<void> clearAll() => delete(searchBooks).go();

  Future<void> clear(String name, String author) {
    return (delete(searchBooks)
          ..where((t) => t.name.equals(name) & t.author.equals(author)))
        .go();
  }

  Future<void> clearExpired(int time) {
    return (delete(searchBooks)..where((t) => t.addTime.isSmallerThanValue(time))).go();
  }

  Future<List<SearchBook>> getSearchBooks(String name, String author) =>
      getByNameAuthor(name, author);
}
