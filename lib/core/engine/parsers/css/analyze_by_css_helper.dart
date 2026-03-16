import 'package:html/dom.dart';
import 'analyze_by_css_base.dart';
import 'analyze_by_css_support.dart';

/// AnalyzeByCss 的私有輔助邏輯擴展
extension AnalyzeByCssHelper on AnalyzeByCssBase {
  List<Element> getElementsSingle(Element temp, String rule) {
    final single = ElementsSingle();
    return single.getElementsSingle(temp, rule);
  }

  List<String> getResultLast(List<Element> elements, String lastRule) {
    final textS = <String>[];
    switch (lastRule) {
      case 'text':
        for (final el in elements) {
          final t = el.text.replaceAll(RegExp(r'\s+'), ' ').trim();
          if (t.isNotEmpty) textS.add(t);
        }
        break;
      case 'textNodes':
        for (final el in elements) {
          final nodes = el.nodes
              .where((n) => n.nodeType == Node.TEXT_NODE)
              .map((n) => n.text?.trim() ?? '')
              .where((t) => t.isNotEmpty)
              .join('\n');
          if (nodes.isNotEmpty) textS.add(nodes);
        }
        break;
      case 'ownText':
        for (final el in elements) {
          final t = el.nodes
              .where((n) => n.nodeType == Node.TEXT_NODE)
              .map((n) => n.text?.trim() ?? '')
              .where((t) => t.isNotEmpty)
              .join(' ');
          if (t.isNotEmpty) textS.add(t);
        }
        break;
      case 'html':
      case 'outerHtml':
        for (final el in elements) {
          el.querySelectorAll('script').forEach((s) => s.remove());
          el.querySelectorAll('style').forEach((s) => s.remove());
          final h = el.outerHtml;
          if (h.isNotEmpty) textS.add(h);
        }
        break;
      case 'all':
        for (final el in elements) {
          textS.add(el.outerHtml);
        }
        break;
      case 'src':
        for (final el in elements) {
          final s = el.attributes['src']?.trim();
          if (s != null && s.isNotEmpty) textS.add(s);
        }
        break;
      case 'href':
        for (final el in elements) {
          final h = el.attributes['href']?.trim();
          if (h != null && h.isNotEmpty) textS.add(h);
        }
        break;
      default:
        for (final el in elements) {
          final attr = el.attributes[lastRule]?.trim();
          if (attr != null && attr.isNotEmpty) {
            textS.add(attr);
          }
        }
    }
    return textS;
  }
}

