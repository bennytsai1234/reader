import 'package:drift/drift.dart';
import '../../models/read_record.dart';
import '../tables/app_tables.dart';
import '../app_database.dart';

part 'read_record_dao.g.dart';

@DriftAccessor(tables: [ReadRecords])
class ReadRecordDao extends DatabaseAccessor<AppDatabase> with _$ReadRecordDaoMixin {
  ReadRecordDao(AppDatabase db) : super(db);

  Future<List<ReadRecord>> getAll() => select(readRecords).get();

  Future<void> upsert(ReadRecord record) => into(readRecords).insertOnConflictUpdate(ReadRecordToInsertable(record).toInsertable());

  Future<void> clearAll() => delete(readRecords).go();

  Future<List<ReadRecord>> getAllTime() => getAll();

  Future<List<ReadRecord>> getAllShow() {
    return (select(readRecords)
          ..orderBy([(t) => OrderingTerm(expression: t.lastRead, mode: OrderingMode.desc)]))
        .get();
  }

  Future<List<ReadRecord>> search(String key) {
    return (select(readRecords)..where((t) => t.bookName.like('%$key%'))).get();
  }

  Future<void> deleteByName(String bookName) =>
      (delete(readRecords)..where((t) => t.bookName.equals(bookName))).go();
}
