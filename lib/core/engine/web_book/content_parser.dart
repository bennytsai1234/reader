import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

class ContentParser {
  static String parse({
    required BookSource source,
    required String body,
    required String baseUrl,
    String? nextChapterUrl,
  }) {
    final rule = AnalyzeRule(source: source)
        .setContent(body, baseUrl: baseUrl)
        .setNextChapterUrl(nextChapterUrl);
    final contentRule = source.ruleContent;
    if (contentRule == null) return body;

    // 取得正文內容
    final content = rule.getString(contentRule.content ?? '');
    
    return content;
  }
}

