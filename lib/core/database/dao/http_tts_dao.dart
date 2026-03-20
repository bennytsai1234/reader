import 'package:drift/drift.dart';
import '../../models/http_tts.dart';
import '../tables/app_tables.dart';
import '../app_database.dart';

part 'http_tts_dao.g.dart';

@DriftAccessor(tables: [HttpTtsTable])
class HttpTtsDao extends DatabaseAccessor<AppDatabase> with _$HttpTtsDaoMixin {
  HttpTtsDao(super.db);

  Future<List<HttpTTS>> getAll() => select(httpTtsTable).get();

  Stream<List<HttpTTS>> watchAll() => select(httpTtsTable).watch();

  Future<void> upsert(HttpTTS tts) => into(httpTtsTable).insertOnConflictUpdate(HttpTTSToInsertable(tts).toInsertable());

  Future<void> deleteById(int id) =>
      (delete(httpTtsTable)..where((t) => t.id.equals(id))).go();

  Future<void> insertOrUpdateAll(List<HttpTTS> engines) async {
    await batch((b) => b.insertAllOnConflictUpdate(httpTtsTable, engines.map((e) => HttpTTSToInsertable(e).toInsertable()).toList()));
  }
}
