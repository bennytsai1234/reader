import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// AnalyzeByCss 的基礎類別
/// (原 Android model/analyzeRule/AnalyzeByJSoup.kt)
abstract class AnalyzeByCssBase {
  late Element element;

  void setContent(dynamic doc) {
    if (doc is Element) {
      element = doc;
    } else if (doc is String) {
      final document = html_parser.parse(doc);
      element = document.documentElement!;
    } else {
      element = html_parser.parse(doc.toString()).documentElement!;
    }
  }
}

