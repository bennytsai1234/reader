import 'package:drift/drift.dart';
import '../../models/replace_rule.dart';
import '../tables/app_tables.dart';
import '../app_database.dart';

part 'replace_rule_dao.g.dart';

@DriftAccessor(tables: [ReplaceRules])
class ReplaceRuleDao extends DatabaseAccessor<AppDatabase> with _$ReplaceRuleDaoMixin {
  ReplaceRuleDao(super.db);

  Future<List<ReplaceRule>> getAll() {
    return (select(replaceRules)..orderBy([(t) => OrderingTerm(expression: t.order)])).get();
  }

  Stream<List<ReplaceRule>> watchAll() {
    return (select(replaceRules)..orderBy([(t) => OrderingTerm(expression: t.order)])).watch();
  }

  Future<void> upsert(ReplaceRule rule) => into(replaceRules).insertOnConflictUpdate(ReplaceRuleToInsertable(rule).toInsertable());

  Future<void> upsertAll(List<ReplaceRule> rules) async {
    await batch((b) => b.insertAllOnConflictUpdate(replaceRules, rules.map((e) => ReplaceRuleToInsertable(e).toInsertable()).toList()));
  }

  Future<void> deleteById(int id) =>
      (delete(replaceRules)..where((t) => t.id.equals(id))).go();

  Future<List<ReplaceRule>> getEnabled() {
    return (select(replaceRules)
          ..where((t) => t.isEnabled.equals(true))
          ..orderBy([(t) => OrderingTerm(expression: t.order)]))
        .get();
  }

  Future<void> updateEnabled(int id, bool enabled) {
    return (update(replaceRules)..where((t) => t.id.equals(id)))
        .write(ReplaceRulesCompanion(isEnabled: Value(enabled)));
  }

  Future<void> updateOrder(int id, int order) {
    return (update(replaceRules)..where((t) => t.id.equals(id)))
        .write(ReplaceRulesCompanion(order: Value(order)));
  }
}
