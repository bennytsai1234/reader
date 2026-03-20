import 'package:drift/drift.dart';
import '../../models/search_keyword.dart';
import '../tables/app_tables.dart';
import '../app_database.dart';

part 'search_keyword_dao.g.dart';

@DriftAccessor(tables: [SearchKeywords])
class SearchKeywordDao extends DatabaseAccessor<AppDatabase> with _$SearchKeywordDaoMixin {
  SearchKeywordDao(super.db);

  Future<List<SearchKeyword>> getAll() {
    return (select(searchKeywords)
          ..orderBy([(t) => OrderingTerm(expression: t.usage, mode: OrderingMode.desc)]))
        .get();
  }

  Future<void> upsert(SearchKeyword keyword) =>
      into(searchKeywords).insertOnConflictUpdate(SearchKeywordToInsertable(keyword).toInsertable());

  Future<void> deleteByWord(String word) =>
      (delete(searchKeywords)..where((t) => t.word.equals(word))).go();

  Future<void> clearAll() => delete(searchKeywords).go();
}
