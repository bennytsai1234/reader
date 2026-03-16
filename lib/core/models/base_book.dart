import 'dart:convert';
import 'rule_data_interface.dart';

/// BaseBook - 書籍基礎介面
/// (原 Android data/entities/BaseBook.kt)
abstract class BaseBook implements RuleDataInterface {
  String get name;
  set name(String value);

  String get author;
  set author(String value);

  String get bookUrl;
  set bookUrl(String value);

  String? get kind;
  set kind(String? value);

  String? get wordCount;
  set wordCount(String? value);

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

