import 'dart:convert';
import 'rule_data_interface.dart';

/// BaseRssArticle - RSS 文章基礎介面
/// (原 Android data/entities/BaseRssArticle.kt)
abstract class BaseRssArticle implements RuleDataInterface {
  String get origin;
  set origin(String value);

  String get link;
  set link(String value);

  String? get variable;
  set variable(String? value);

  @override
  void putVariable(String key, String? value) {
    if (value != null) {
      variableMap[key] = value;
    } else {
      variableMap.remove(key);
    }
    variable = jsonEncode(variableMap);
  }

  @override
  String getVariable(String key) {
    return variableMap[key] ?? '';
  }
}

