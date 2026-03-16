import 'rule_analyzer_base.dart';
import 'rule_analyzer_match.dart';

/// RuleAnalyzer 的範圍提取邏輯擴展
mixin RuleAnalyzerRange on RuleAnalyzerBase, RuleAnalyzerMatch {
  String innerRuleRange(String startStr, String endStr, {required String? Function(String) fr}) {
    final st = StringBuffer();
    while (consumeTo(startStr)) {
      final posPre = pos;
      pos += startStr.length;
      var balanced = false;
      
      if (startStr.contains('{')) {
        final nextBrace = queue.indexOf('{', posPre);
        if (nextBrace != -1) {
          pos = nextBrace;
          balanced = chompCodeBalanced('{', '}');
        }
      } else if (startStr.contains('[')) {
        final nextBracket = queue.indexOf('[', posPre);
        if (nextBracket != -1) {
          pos = nextBracket;
          balanced = chompCodeBalanced('[', ']');
        }
      } else {
        balanced = consumeTo(endStr);
        if (balanced) {
          pos += endStr.length;
        }
      }

      if (balanced) {
        final content = queue.substring(posPre + startStr.length, pos - endStr.length);
        final frv = fr(content);
        if (frv != null) {
          st.write(queue.substring(startX, posPre));
          st.write(frv);
          startX = pos;
          continue;
        }
      }
      pos = posPre + startStr.length;
    }
    
    if (startX == 0) {
      return queue;
    }
    st.write(queue.substring(startX));
    return st.toString();
  }

  String innerRule(String startStr, {required String? Function(String) fr}) {
    var endStr = '}';
    if (startStr.startsWith('{{')) {
      endStr = '}}';
    } else if (startStr.startsWith('[')) {
      endStr = ']';
    }
    return innerRuleRange(startStr, endStr, fr: fr);
  }
}

