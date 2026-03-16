import 'analyze_rule_base.dart';
import 'analyze_rule_element.dart';
import 'analyze_rule_string.dart';
import 'analyze_rule_regex_helper.dart';

export 'analyze_rule_element.dart';
export 'analyze_rule_string.dart';
export 'analyze_rule_regex_helper.dart';

/// AnalyzeRule 的核心解析擴展 (重構後)
/// 透過 Mixin 整合元素、字串與正則解析邏輯
mixin AnalyzeRuleCore on AnalyzeRuleBase, AnalyzeRuleRegexHelper, AnalyzeRuleElement, AnalyzeRuleString {}

