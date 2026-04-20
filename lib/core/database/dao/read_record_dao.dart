import 'package:drift/drift.dart';
import '../../models/read_record.dart';
import '../tables/app_tables.dart';
import '../app_database.dart';

part 'read_record_dao.g.dart';

@DriftAccessor(tables: [ReadRecords])
class ReadRecordDao extends DatabaseAccessor<AppDatabase>
    with _$ReadRecordDaoMixin {
  ReadRecordDao(super.db);

  Future<List<ReadRecord>> getAll() => select(readRecords).get();

  Future<void> upsert(ReadRecord record) => into(
    readRecords,
  ).insertOnConflictUpdate(ReadRecordToInsertable(record).toInsertable());

  Future<ReadRecord?> getByBookName(String bookName) {
    return (select(readRecords)
      ..where((t) => t.bookName.equals(bookName))).getSingleOrNull();
  }

  Future<void> incrementReadTime({
    required String bookName,
    required int seconds,
    required int lastRead,
    String deviceId = '',
  }) async {
    if (seconds <= 0) return;
    final existing = await getByBookName(bookName);
    if (existing == null) {
      await into(readRecords).insert(
        ReadRecord(
          bookName: bookName,
          deviceId: deviceId,
          readTime: seconds,
          lastRead: lastRead,
        ).toInsertable(),
      );
      return;
    }
    await (update(readRecords)..where((t) => t.id.equals(existing.id))).write(
      ReadRecordsCompanion(
        readTime: Value(existing.readTime + seconds),
        lastRead: Value(lastRead),
      ),
    );
  }

  Future<void> clearAll() => delete(readRecords).go();

  Future<List<ReadRecord>> getAllTime() => getAll();

  Future<List<ReadRecord>> getAllShow() {
    return (select(readRecords)..orderBy([
      (t) => OrderingTerm(expression: t.lastRead, mode: OrderingMode.desc),
    ])).get();
  }

  Future<List<ReadRecord>> search(String key) {
    return (select(readRecords)
          ..where((t) => t.bookName.like('%$key%'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.lastRead, mode: OrderingMode.desc),
          ]))
        .get();
  }

  Future<void> deleteByName(String bookName) =>
      (delete(readRecords)..where((t) => t.bookName.equals(bookName))).go();
}
