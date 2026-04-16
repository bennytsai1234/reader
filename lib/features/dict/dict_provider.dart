import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/models/dict_rule.dart';
import 'package:inkpage_reader/core/services/dict_service.dart';

class DictProvider with ChangeNotifier {
  final DictService _service = DictService();
  
  List<DictRule> _rules = [];
  List<DictRule> get rules => _rules;
  
  List<DictRule> _allRules = [];
  List<DictRule> get allRules => _allRules;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String _result = '';
  String get result => _result;

  DictRule? _selectedRule;
  DictRule? get selectedRule => _selectedRule;

  Future<void> loadRules() async {
    _allRules = await _service.getAllRules();
    _rules = _allRules.where((r) => r.enabled).toList();
    if (_rules.isNotEmpty && _selectedRule == null) {
      _selectedRule = _rules.first;
    }
    notifyListeners();
  }

  void selectRule(DictRule rule) {
    _selectedRule = rule;
    notifyListeners();
  }

  Future<void> search(String word, {DictRule? rule}) async {
    if (_rules.isEmpty) await loadRules();
    if (_rules.isEmpty) return;

    final targetRule = rule ?? _selectedRule ?? _rules.first;
    _selectedRule = targetRule;

    _isLoading = true;
    _result = '';
    notifyListeners();

    try {
      _result = await _service.search(targetRule, word);
    } catch (e) {
      _result = '搜索失敗: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleRule(DictRule rule) async {
    rule.enabled = !rule.enabled;
    await _service.saveRule(rule);
    await loadRules();
  }

  Future<void> saveRule(DictRule rule) async {
    await _service.saveRule(rule);
    await loadRules();
  }

  Future<void> deleteRule(DictRule rule) async {
    await _service.deleteRule(rule.name);
    await loadRules();
  }
}

