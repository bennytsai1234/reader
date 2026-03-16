import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

class BookInfoParser {
  static Book parse({
    required BookSource source,
    required Book book,
    required String body,
    required String baseUrl,
  }) {
    final rule = AnalyzeRule(source: source).setContent(body, baseUrl: baseUrl);
    final infoRule = source.ruleBookInfo;
    if (infoRule == null) return book;

    return book.copyWith(
      name: _format(rule.getString(infoRule.name ?? '')).isEmpty ? book.name : _format(rule.getString(infoRule.name ?? '')),
      author: _format(rule.getString(infoRule.author ?? '')).isEmpty ? book.author : _format(rule.getString(infoRule.author ?? '')),
      kind: rule.getStringList(infoRule.kind ?? '').join(','),
      coverUrl: rule.getString(infoRule.coverUrl ?? '', isUrl: true),
      intro: rule.getString(infoRule.intro ?? ''),
      latestChapterTitle: rule.getString(infoRule.lastChapter ?? ''),
      tocUrl: rule.getString(infoRule.tocUrl ?? '', isUrl: true),
    );
  }

  static String _format(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');
}

