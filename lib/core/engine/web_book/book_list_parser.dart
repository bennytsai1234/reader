import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

class BookListParser {
  static List<SearchBook> parse({
    required BookSource source,
    required String body,
    required String baseUrl,
    required bool isSearch,
  }) {
    // 1. 偵測 bookUrlPattern (原 Android 邏輯)
    if (isSearch && source.bookUrlPattern?.isNotEmpty == true) {
      try {
        if (RegExp(source.bookUrlPattern!).hasMatch(baseUrl)) {
          // 這裡未來應實作直接按詳情頁解析並封裝
        }
      } catch (_) {}
    }

    final rule = AnalyzeRule(source: source).setContent(body, baseUrl: baseUrl);
    final dynamic listRule = isSearch ? source.ruleSearch : source.ruleExplore;
    if (listRule == null) return [];

    String ruleList = listRule.bookList ?? '';
    var isReverse = false;
    if (ruleList.startsWith('-')) {
      isReverse = true;
      ruleList = ruleList.substring(1);
    }

    final elements = rule.getElements(ruleList);
    final books = <SearchBook>[];

    for (final element in elements) {
      final itemRule = AnalyzeRule(source: source).setContent(element, baseUrl: baseUrl);
      final name = _format(itemRule.getString(listRule.name ?? ''));
      if (name.isEmpty) continue;

      books.add(SearchBook(
        bookUrl: itemRule.getString(listRule.bookUrl ?? '', isUrl: true),
        name: name,
        author: _format(itemRule.getString(listRule.author ?? '')),
        kind: itemRule.getStringList(listRule.kind ?? '').join(','),
        coverUrl: itemRule.getString(listRule.coverUrl ?? '', isUrl: true),
        intro: itemRule.getString(listRule.intro ?? ''),
        latestChapterTitle: itemRule.getString(listRule.lastChapter ?? ''),
        wordCount: _formatWordCount(itemRule.getString(listRule.wordCount ?? '')),
        origin: source.bookSourceUrl,
        originName: source.bookSourceName,
      ));
    }

    return isReverse ? books.reversed.toList() : books;
  }

  static String _format(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

  static String _formatWordCount(String count) {
    if (count.isEmpty) return '';
    final numStr = count.replaceAll(RegExp(r'[^0-9.]'), '');
    final val = double.tryParse(numStr);
    if (val == null) return count;
    if (count.contains('萬')) return '${val.toStringAsFixed(1)}萬字';
    if (val > 10000) return '${(val / 10000).toStringAsFixed(1)}萬字';
    return '${val.toInt()}字';
  }
}

