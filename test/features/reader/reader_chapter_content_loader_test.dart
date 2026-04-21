import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/replace_rule_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/models/replace_rule.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_loader.dart';

class _FakeChapterDao implements ChapterDao {
  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeReplaceRuleDao implements ReplaceRuleDao {
  @override
  Future<List<ReplaceRule>> getEnabled() async => const <ReplaceRule>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class _FakeBookSourceDao implements BookSourceDao {
  @override
  Future<BookSource?> getByUrl(String url) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  group('ReaderChapterContentLoader', () {
    test('load 不會把 displayTitle 再拼回正文內容', () async {
      final chapter = BookChapter(
        title: '第二章 測試章節',
        index: 1,
        url: 'chapter-1',
        bookUrl: 'book-1',
        content: '正文第一行\n正文第二行',
      );
      final loader = ReaderChapterContentLoader(
        book: Book(
          bookUrl: 'book-1',
          name: 'Book',
          author: 'Author',
          origin: 'remote',
        ),
        chapterDao: _FakeChapterDao(),
        replaceDao: _FakeReplaceRuleDao(),
        sourceDao: _FakeBookSourceDao(),
        service: BookSourceService(),
        currentChineseConvert: () => 0,
        getSource: () => null,
        setSource: (_) {},
      );

      final result = await loader.load(1, chapter);

      expect(result.displayTitle, '第二章 測試章節');
      expect(result.content.startsWith('第二章 測試章節\n'), isFalse);
      expect(result.content, contains('正文第一行'));
      expect(result.content, contains('正文第二行'));
    });
  });
}
