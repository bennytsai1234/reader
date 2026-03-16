import 'dart:convert';
import 'rule_data_interface.dart';

/// RuleData - 規則數據封裝實作
/// (原 Android model/analyzeRule/RuleData.kt)
class RuleData implements RuleDataInterface {
  @override
  final Map<String, String> variableMap = {};

  @override
  void putVariable(String key, String? value) {
    if (value == null) {
      variableMap.remove(key);
    } else {
      variableMap[key] = value;
    }
  }

  @override
  String getVariable(String key) {
    return variableMap[key] ?? '';
  }

  /// 獲取序列化後的變量字串 (原 Android getVariable)
  String? getVariableJson() {
    if (variableMap.isEmpty) return null;
    return jsonEncode(variableMap);
  }
}
// AI_PORT: GAP-ANALYZE-02 derived from RuleData.kt

