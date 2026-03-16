import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/database/dao/txt_toc_rule_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/models/txt_toc_rule.dart';

class TxtTocRuleProvider extends ChangeNotifier {
  final TxtTocRuleDao _dao = getIt<TxtTocRuleDao>();

  List<TxtTocRule> _rules = [];
  List<TxtTocRule> get rules => _rules;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  TxtTocRuleProvider() {
    loadRules();
  }

  Future<void> loadRules() async {
    _isLoading = true;
    notifyListeners();
    try {
      _rules = await _dao.getAll();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleEnable(TxtTocRule rule) async {
    rule.enable = !rule.enable;
    await _dao.upsert(rule);
    notifyListeners();
  }

  Future<void> deleteRule(TxtTocRule rule) async {
    await _dao.deleteById(rule.id);
      await loadRules();
  }

  Future<void> saveRule(TxtTocRule rule) async {
    await _dao.upsert(rule);
    await loadRules();
  }
}

