import 'rule_analyzer_base.dart';
import 'rule_analyzer_match.dart';

/// RuleAnalyzer 的規則切分邏輯擴展
mixin RuleAnalyzerSplit on RuleAnalyzerBase, RuleAnalyzerMatch {
  List<String> splitRule(List<String> split) {
    ruleList = [];
    start = pos;
    startX = pos;

    while (true) {
      if (!consumeToAny(split)) {
        ruleList.add(queue.substring(startX));
        return ruleList;
      }

      final end = pos;
      pos = start;

      var skipMatch = false;
      while (end > pos) {
        final st = findToAny(['[', '(']);
        if (st == -1 || st > end) {
          break;
        }

        pos = st;
        final next = queue[pos] == '[' ? ']' : ')';
        if (!chompBalanced(queue[pos], next)) {
          return [queue];
        }

        if (end <= pos) {
          skipMatch = true;
          break;
        }
      }

      if (!skipMatch) {
        ruleList.add(queue.substring(startX, end));
        elementsType = queue.substring(end, end + step);
        pos = end + step;
        startX = pos;
        start = pos;
        return splitRuleSingle();
      }

      start = pos;
      pos = start;
    }
  }

  List<String> splitRuleSingle() {
    step = elementsType.length;
    while (true) {
      if (!consumeTo(elementsType)) {
        ruleList.add(queue.substring(startX));
        return ruleList;
      }

      final end = pos;
      pos = start;

      var skipMatch = false;
      while (end > pos) {
        final st = findToAny(['[', '(']);
        if (st == -1 || st > end) {
          break;
        }

        pos = st;
        final next = queue[pos] == '[' ? ']' : ')';
        if (!chompBalanced(queue[pos], next)) {
          break;
        }

        if (end <= pos) {
          skipMatch = true;
          break;
        }
      }

      if (!skipMatch) {
        ruleList.add(queue.substring(startX, end));
        pos = end + step;
        startX = pos;
        start = pos;
      } else {
        start = pos;
      }
    }
  }
}

