import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';

class ChapterListParser {
  static List<BookChapter> parse({
    required BookSource source,
    required Book book,
    required String body,
    required String baseUrl,
  }) {
    final rule = AnalyzeRule(source: source).setContent(body, baseUrl: baseUrl);
    final tocRule = source.ruleToc;
    if (tocRule == null) return [];

    final chapters = <BookChapter>[];
    final elements = rule.getElements(tocRule.chapterList ?? '');

    for (var i = 0; i < elements.length; i++) {
      final itemRule = AnalyzeRule(source: source).setContent(elements[i], baseUrl: baseUrl);
      final title = itemRule.getString(tocRule.chapterName ?? '');
      if (title.isEmpty) continue;

      chapters.add(BookChapter(
        index: i,
        title: title,
        url: itemRule.getString(tocRule.chapterUrl ?? '', isUrl: true),
        bookUrl: book.bookUrl,
      ));
    }

    return chapters;
  }
}

