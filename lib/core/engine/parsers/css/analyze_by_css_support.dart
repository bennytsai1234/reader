import 'package:html/dom.dart';

List<Element> querySelectorAllCompat(Element root, String selector) {
  final normalizedSelector = normalizeCssSelectorCompat(selector);
  try {
    return root.querySelectorAll(normalizedSelector);
  } on UnimplementedError {
    return _querySelectorAllUnsupportedCompat(root, normalizedSelector);
  } catch (_) {
    if (_needsCompatSelector(normalizedSelector)) {
      return _querySelectorAllUnsupportedCompat(root, normalizedSelector);
    }
    return [];
  }
}

bool matchesSelectorWithinParentCompat(Element temp, String selector) {
  final trimmed = selector.trim();
  if (trimmed.isEmpty || trimmed == '*') {
    final parent = temp.parent;
    if (parent == null) return false;
    try {
      return querySelectorAllCompat(parent, trimmed).contains(temp);
    } catch (_) {
      return false;
    }
  }
  try {
    return _querySelectorAllFromContainer(temp.parentNode, trimmed).contains(
      temp,
    );
  } catch (_) {
    return false;
  }
}

List<Element> _querySelectorAllUnsupportedCompat(
  Element root,
  String selector,
) {
  if (!_needsCompatSelector(selector)) {
    return [];
  }

  final matches = <Element>{};
  for (final group in _splitSelectorList(selector)) {
    final trimmed = group.trim();
    if (trimmed.isEmpty) continue;
    for (final element in _querySelectorGroupCompat(root, trimmed)) {
      matches.add(element);
    }
  }
  return root.querySelectorAll('*').where(matches.contains).toList();
}

bool _needsCompatSelector(String selector) {
  return selector.contains(':contains(') ||
      selector.contains(':containsOwn(') ||
      selector.contains(':has(');
}

List<Element> _querySelectorGroupCompat(Element root, String selector) {
  final segments = _parseSelectorSegments(selector);
  if (segments.isEmpty) return [];

  final tail = _parseCompoundSelector(segments.last.compound);
  final baseSelector = normalizeCssSelectorCompat(tail.baseSelector);

  List<Element> candidates;
  if (baseSelector.isEmpty || baseSelector == '*') {
    candidates = root.querySelectorAll('*');
  } else {
    try {
      candidates = root.querySelectorAll(baseSelector);
    } catch (_) {
      candidates =
          root
              .querySelectorAll('*')
              .where((element) => _matchesBaseSelector(element, baseSelector))
              .toList();
    }
  }

  return candidates.where(
    (element) => _matchesSelectorAgainstElement(element, selector),
  ).toList();
}

bool _matchesSelectorAgainstElement(Element element, String selector) {
  final segments = _parseSelectorSegments(selector);
  if (segments.isEmpty) return false;
  return _matchesSelectorPathFrom(element, segments, segments.length - 1);
}

bool _matchesSelectorPathFrom(
  Element element,
  List<_SelectorSegment> segments,
  int index,
) {
  if (!_matchesCompoundSelector(element, segments[index].compound)) {
    return false;
  }
  if (index == 0) return true;

  final combinator = segments[index].combinator ?? ' ';
  for (final previous in _relatedElementsForCombinator(element, combinator)) {
    if (_matchesSelectorPathFrom(previous, segments, index - 1)) {
      return true;
    }
  }
  return false;
}

Iterable<Element> _relatedElementsForCombinator(Element element, String combinator) sync* {
  switch (combinator) {
    case '>':
      final parent = element.parent;
      if (parent != null) yield parent;
      return;
    case '+':
      final sibling = element.previousElementSibling;
      if (sibling != null) yield sibling;
      return;
    case '~':
      var sibling = element.previousElementSibling;
      while (sibling != null) {
        yield sibling;
        sibling = sibling.previousElementSibling;
      }
      return;
    case ' ':
    default:
      var parent = element.parent;
      while (parent != null) {
        yield parent;
        parent = parent.parent;
      }
      return;
  }
}

bool _matchesCompoundSelector(Element element, String compound) {
  final parsed = _parseCompoundSelector(compound);
  if (!_matchesBaseSelector(element, parsed.baseSelector)) {
    return false;
  }

  final text = element.text;
  final ownText =
      element.nodes
          .where((node) => node.nodeType == Node.TEXT_NODE)
          .map((node) => node.text ?? '')
          .join();
  if (!parsed.containsValues.every(text.contains)) {
    return false;
  }
  if (!parsed.containsOwnValues.every(ownText.contains)) {
    return false;
  }
  for (final hasSelector in parsed.hasSelectors) {
    if (hasSelector.trim().isEmpty) return false;
    if (querySelectorAllCompat(element, hasSelector).isEmpty) {
      return false;
    }
  }
  for (final notSelector in parsed.notSelectors) {
    final groups = _splitSelectorList(notSelector);
    if (groups.any(
      (group) =>
          group.trim().isNotEmpty &&
          _matchesSelectorAgainstElement(element, group.trim()),
    )) {
      return false;
    }
  }
  return true;
}

bool _matchesBaseSelector(Element element, String selector) {
  final trimmed = selector.trim();
  if (trimmed.isEmpty || trimmed == '*') {
    return true;
  }
  final parentNode = element.parentNode;
  if (parentNode == null) {
    return false;
  }
  try {
    return _querySelectorAllFromContainer(parentNode, trimmed).contains(
      element,
    );
  } catch (_) {
    return false;
  }
}

List<Element> _querySelectorAllFromContainer(Node? container, String selector) {
  if (container is Element) {
    return querySelectorAllCompat(container, selector);
  }
  if (container is Document) {
    final normalizedSelector = normalizeCssSelectorCompat(selector);
    try {
      return container.querySelectorAll(normalizedSelector);
    } on UnimplementedError {
      return _querySelectorAllUnsupportedCompat(
        container.documentElement!,
        normalizedSelector,
      );
    } catch (_) {
      if (_needsCompatSelector(normalizedSelector)) {
        return _querySelectorAllUnsupportedCompat(
          container.documentElement!,
          normalizedSelector,
        );
      }
      return [];
    }
  }
  return [];
}

List<String> _splitSelectorList(String selector) {
  return _splitSelectorAtTopLevel(selector, ',');
}

List<_SelectorSegment> _parseSelectorSegments(String selector) {
  final segments = <_SelectorSegment>[];
  final current = StringBuffer();
  String? combinator;
  var parenDepth = 0;
  var bracketDepth = 0;
  String? quote;

  void flushCurrent() {
    final compound = current.toString().trim();
    if (compound.isEmpty) return;
    segments.add(_SelectorSegment(compound: compound, combinator: combinator));
    current.clear();
    combinator = null;
  }

  for (var i = 0; i < selector.length; i++) {
    final char = selector[i];
    if (quote != null) {
      current.write(char);
      if (char == quote && !_isEscaped(selector, i)) {
        quote = null;
      }
      continue;
    }
    if (char == '"' || char == "'") {
      quote = char;
      current.write(char);
      continue;
    }
    if (char == '[') {
      bracketDepth++;
      current.write(char);
      continue;
    }
    if (char == ']') {
      if (bracketDepth > 0) bracketDepth--;
      current.write(char);
      continue;
    }
    if (char == '(') {
      parenDepth++;
      current.write(char);
      continue;
    }
    if (char == ')') {
      if (parenDepth > 0) parenDepth--;
      current.write(char);
      continue;
    }
    if (parenDepth == 0 && bracketDepth == 0) {
      if (char == '>' || char == '+' || char == '~') {
        flushCurrent();
        combinator = char;
        continue;
      }
      if (_isWhitespace(char)) {
        final nextNonWhitespace = _findNextNonWhitespace(selector, i + 1);
        if (current.isNotEmpty &&
            nextNonWhitespace != null &&
            !'>+~'.contains(nextNonWhitespace)) {
          flushCurrent();
          combinator = ' ';
        }
        continue;
      }
    }
    current.write(char);
  }

  flushCurrent();
  return segments;
}

_ParsedCompoundSelector _parseCompoundSelector(String compound) {
  final base = StringBuffer();
  final containsValues = <String>[];
  final containsOwnValues = <String>[];
  final hasSelectors = <String>[];
  final notSelectors = <String>[];

  for (var i = 0; i < compound.length; i++) {
    final pseudo =
        _matchPseudo(compound, i, ':containsOwn(') ??
        _matchPseudo(compound, i, ':contains(') ??
        _matchPseudo(compound, i, ':has(') ??
        _matchPseudo(compound, i, ':not(');
    if (pseudo == null) {
      base.write(compound[i]);
      continue;
    }

    if (pseudo.name == ':contains') {
      final value = _normalizeContainsNeedle(pseudo.argument);
      if (value.isNotEmpty) containsValues.add(value);
    } else if (pseudo.name == ':containsOwn') {
      final value = _normalizeContainsNeedle(pseudo.argument);
      if (value.isNotEmpty) containsOwnValues.add(value);
    } else if (pseudo.name == ':has') {
      if (pseudo.argument.trim().isNotEmpty) {
        hasSelectors.add(pseudo.argument.trim());
      }
    } else if (pseudo.name == ':not') {
      if (pseudo.argument.trim().isNotEmpty) {
        notSelectors.add(pseudo.argument.trim());
      }
    }
    i = pseudo.endIndex;
  }

  return _ParsedCompoundSelector(
    baseSelector: base.toString().trim(),
    containsValues: containsValues,
    containsOwnValues: containsOwnValues,
    hasSelectors: hasSelectors,
    notSelectors: notSelectors,
  );
}

_PseudoMatch? _matchPseudo(String input, int index, String prefix) {
  if (!input.startsWith(prefix, index)) return null;
  final openParenIndex = index + prefix.length - 1;
  final closeParenIndex = _findMatchingParen(input, openParenIndex);
  if (closeParenIndex == -1) return null;
  return _PseudoMatch(
    name: prefix.substring(0, prefix.length - 1),
    argument: input.substring(openParenIndex + 1, closeParenIndex),
    endIndex: closeParenIndex,
  );
}

int _findMatchingParen(String input, int openParenIndex) {
  var depth = 1;
  String? quote;
  for (var i = openParenIndex + 1; i < input.length; i++) {
    final char = input[i];
    if (quote != null) {
      if (char == quote && !_isEscaped(input, i)) {
        quote = null;
      }
      continue;
    }
    if (char == '"' || char == "'") {
      quote = char;
      continue;
    }
    if (char == '(') {
      depth++;
    } else if (char == ')') {
      depth--;
      if (depth == 0) return i;
    }
  }
  return -1;
}

List<String> _splitSelectorAtTopLevel(String input, String delimiter) {
  final parts = <String>[];
  final current = StringBuffer();
  var parenDepth = 0;
  var bracketDepth = 0;
  String? quote;

  for (var i = 0; i < input.length; i++) {
    final char = input[i];
    if (quote != null) {
      current.write(char);
      if (char == quote && !_isEscaped(input, i)) {
        quote = null;
      }
      continue;
    }
    if (char == '"' || char == "'") {
      quote = char;
      current.write(char);
      continue;
    }
    if (char == '[') {
      bracketDepth++;
      current.write(char);
      continue;
    }
    if (char == ']') {
      if (bracketDepth > 0) bracketDepth--;
      current.write(char);
      continue;
    }
    if (char == '(') {
      parenDepth++;
      current.write(char);
      continue;
    }
    if (char == ')') {
      if (parenDepth > 0) parenDepth--;
      current.write(char);
      continue;
    }
    if (parenDepth == 0 &&
        bracketDepth == 0 &&
        input.startsWith(delimiter, i)) {
      parts.add(current.toString());
      current.clear();
      i += delimiter.length - 1;
      continue;
    }
    current.write(char);
  }

  parts.add(current.toString());
  return parts;
}

String? _findNextNonWhitespace(String input, int start) {
  for (var i = start; i < input.length; i++) {
    if (!_isWhitespace(input[i])) return input[i];
  }
  return null;
}

bool _isWhitespace(String char) => char.trim().isEmpty;

bool _isEscaped(String input, int index) {
  var backslashes = 0;
  for (var i = index - 1; i >= 0 && input[i] == r'\'; i--) {
    backslashes++;
  }
  return backslashes.isOdd;
}

String normalizeCssSelectorCompat(String selector) {
  return selector.replaceAllMapped(RegExp(r'\[([^\]=~\^\$\*\|]+)=([^\]]+)\]'), (
    match,
  ) {
    final attr = match.group(1)!.trim();
    final value = match.group(2)!.trim();
    if (value.startsWith('"') || value.startsWith("'")) {
      return match.group(0)!;
    }
    return '[$attr="$value"]';
  });
}

String _normalizeContainsNeedle(String value) {
  final trimmed = value.trim();
  if (trimmed.length >= 2 &&
      ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
          (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
    return trimmed.substring(1, trimmed.length - 1);
  }
  return trimmed;
}

class _SelectorSegment {
  final String compound;
  final String? combinator;

  const _SelectorSegment({required this.compound, required this.combinator});
}

class _ParsedCompoundSelector {
  final String baseSelector;
  final List<String> containsValues;
  final List<String> containsOwnValues;
  final List<String> hasSelectors;
  final List<String> notSelectors;

  const _ParsedCompoundSelector({
    required this.baseSelector,
    required this.containsValues,
    required this.containsOwnValues,
    required this.hasSelectors,
    required this.notSelectors,
  });
}

class _PseudoMatch {
  final String name;
  final String argument;
  final int endIndex;

  const _PseudoMatch({
    required this.name,
    required this.argument,
    required this.endIndex,
  });
}

class SourceRule {
  bool isCss = false;
  late String elementsRule;

  SourceRule(String ruleStr) {
    if (ruleStr.toUpperCase().startsWith('@CSS:')) {
      isCss = true;
      elementsRule = ruleStr.substring(5).trim();
    } else {
      elementsRule = ruleStr;
    }
  }
}

class ElementsSingle {
  String split = '.';
  String beforeRule = '';
  final List<int> indexDefault = [];
  final List<dynamic> indexes = [];

  List<Element> getElementsSingle(Element temp, String rule) {
    split = '.';
    beforeRule = '';
    indexDefault.clear();
    indexes.clear();
    findIndexSet(rule);

    List<Element> elements;
    if (beforeRule.isEmpty) {
      elements = temp.children;
    } else {
      final rules = beforeRule.split('.');
      if (rules[0] == ':root' || rules[0] == 'root') {
        elements = [temp];
      } else if (rules[0] == 'children') {
        elements = temp.children;
      } else if (rules[0] == 'class' && rules.length > 1) {
        final selector = '.${rules.sublist(1).join('.')}';
        elements = _withSelfIf(
          temp,
          descendants:
              selector.contains(':') || selector.contains('[')
                  ? querySelectorAllCompat(temp, selector)
                  : temp.getElementsByClassName(rules[1]),
          selfMatches:
              selector.contains(':') || selector.contains('[')
                  ? matchesSelectorWithinParentCompat(temp, selector)
                  : temp.classes.contains(rules[1]),
        );
      } else if (rules[0] == 'tag' && rules.length > 1) {
        final selector = rules.sublist(1).join('.');
        elements = _withSelfIf(
          temp,
          descendants:
              selector.contains(':') || selector.contains('[')
                  ? querySelectorAllCompat(temp, selector)
                  : temp.getElementsByTagName(rules[1]),
          selfMatches:
              selector.contains(':') || selector.contains('[')
                  ? matchesSelectorWithinParentCompat(temp, selector)
                  : temp.localName == rules[1],
        );
      } else if (rules[0] == 'id' && rules.length > 1) {
        final el = temp.querySelector('#${rules[1]}');
        elements = temp.id == rules[1] ? [temp] : (el != null ? [el] : []);
      } else if (rules[0] == 'text' && rules.length > 1) {
        final descendants =
            temp.querySelectorAll('*').where((el) {
              return el.nodes.any(
                (n) =>
                    n.nodeType == Node.TEXT_NODE && n.text!.contains(rules[1]),
              );
            }).toList();
        final selfMatches = temp.nodes.any(
          (n) =>
              n.nodeType == Node.TEXT_NODE && (n.text ?? '').contains(rules[1]),
        );
        elements = _withSelfIf(
          temp,
          descendants: descendants,
          selfMatches: selfMatches,
        );
      } else {
        try {
          elements = _withSelfIf(
            temp,
            descendants: querySelectorAllCompat(temp, beforeRule),
            selfMatches: matchesSelectorWithinParentCompat(temp, beforeRule),
          );
        } catch (e) {
          elements = [];
        }
      }
    }

    final len = elements.length;
    if (len == 0) return [];

    final lastIndexes =
        indexDefault.isNotEmpty ? indexDefault.length - 1 : indexes.length - 1;
    final indexSet = <int>{};

    if (indexes.isEmpty) {
      for (var i = lastIndexes; i >= 0; i--) {
        final it = indexDefault[i];
        if (it >= 0 && it < len) {
          indexSet.add(it);
        } else if (it < 0 && len >= -it) {
          indexSet.add(it + len);
        }
      }
    } else {
      for (var i = lastIndexes; i >= 0; i--) {
        final idx = indexes[i];
        if (idx is Triple) {
          var start = idx.first ?? 0;
          if (start < 0) start += len;
          var end = idx.second ?? (len - 1);
          if (end < 0) end += len;

          if ((start < 0 && end < 0) || (start >= len && end >= len)) continue;

          start = start.clamp(0, len - 1);
          end = end.clamp(0, len - 1);

          var step = idx.third;
          if (step == 0) step = 1;
          if (step < 0 && -step < len) step += len;
          if (step <= 0) step = 1;

          if (start <= end) {
            for (var j = start; j <= end; j += step) {
              indexSet.add(j);
            }
          } else {
            for (var j = start; j >= end; j -= step) {
              indexSet.add(j);
            }
          }
        } else if (idx is int) {
          final it = idx;
          if (it >= 0 && it < len) {
            indexSet.add(it);
          } else if (it < 0 && len >= -it) {
            indexSet.add(it + len);
          }
        }
      }
    }

    if (split == '!') {
      final result = <Element>[];
      for (var i = 0; i < len; i++) {
        if (!indexSet.contains(i)) {
          result.add(elements[i]);
        }
      }
      return result;
    } else if (split == '.') {
      final result = <Element>[];
      for (final idx in indexSet) {
        result.add(elements[idx]);
      }
      return result;
    } else {
      return elements;
    }
  }

  List<Element> _withSelfIf(
    Element temp, {
    required Iterable<Element> descendants,
    required bool selfMatches,
  }) {
    final results = <Element>[];
    if (selfMatches) {
      results.add(temp);
    }
    results.addAll(descendants);
    return results;
  }

  void findIndexSet(String rule) {
    final rus = rule.trim();
    final bracketMatch = RegExp(r'^(.*)\[(!?)([-\d:,\s]+)\]$').firstMatch(rus);
    if (bracketMatch != null) {
      beforeRule = bracketMatch.group(1)!.trim();
      split = bracketMatch.group(2) == '!' ? '!' : '.';
      final segments = bracketMatch.group(3)!.split(',');
      for (final rawSegment in segments) {
        final segment = rawSegment.trim();
        if (segment.isEmpty) {
          continue;
        }
        if (segment.contains(':')) {
          final parts = segment.split(':').map((e) => e.trim()).toList();
          int? parsePart(int index) =>
              index < parts.length && parts[index].isNotEmpty
                  ? int.tryParse(parts[index])
                  : null;
          indexes.add(
            Triple(
              parsePart(0),
              parsePart(1),
              parts.length > 2 ? (parsePart(2) ?? 1) : 1,
            ),
          );
        } else {
          final value = int.tryParse(segment);
          if (value != null) {
            indexes.add(value);
          }
        }
      }
      return;
    }

    var len = rus.length;
    var curMinus = false;
    final curList = <int?>[];
    var l = '';

    var head = rus.endsWith(']');

    if (head) {
      len--;
      while (len >= 0) {
        final rl = rus[len];
        if (rl == ' ' || rl == ']') {
          len--;
          continue;
        }

        if (_isDigit(rl)) {
          l = rl + l;
        } else if (rl == '-') {
          curMinus = true;
        } else {
          final curInt = l.isEmpty ? null : int.tryParse(curMinus ? '-$l' : l);
          if (rl == ':') {
            curList.add(curInt);
          } else {
            if (curList.isEmpty) {
              if (curInt == null && rl != '[') break;
              if (curInt != null) indexes.add(curInt);
            } else {
              indexes.add(
                Triple(
                  curInt,
                  curList.last,
                  curList.length == 2 ? (curList.first ?? 1) : 1,
                ),
              );
              curList.clear();
            }

            if (rl == '!') {
              split = '!';
              while (len > 0 && rus[len - 1] == ' ') {
                len--;
              }
            }

            if (rl == '[') {
              beforeRule = rus.substring(0, len);
              return;
            }

            if (rl != ',') break;
          }
          l = '';
          curMinus = false;
          head = false; // reset head if rule is complex
        }
        len--;
      }
    } else {
      while (len > 0) {
        len--;
        final rl = rus[len];
        if (rl == ' ') continue;

        if (_isDigit(rl)) {
          l = rl + l;
        } else if (rl == '-') {
          curMinus = true;
        } else {
          if (rl == '!' || rl == '.' || rl == ':') {
            final val = int.tryParse(curMinus ? '-$l' : l);
            if (val == null) {
              len++;
              break;
            }
            indexDefault.add(val);
            if (rl != ':') {
              split = rl;
              beforeRule = rus.substring(0, len);
              return;
            }
          } else {
            break;
          }
          l = '';
          curMinus = false;
        }
      }
    }
    split = ' ';
    beforeRule = rus;
  }

  bool _isDigit(String s) => RegExp(r'^\d$').hasMatch(s);
}

class Triple {
  final int? first;
  final int? second;
  final int third;
  Triple(this.first, this.second, this.third);
}
