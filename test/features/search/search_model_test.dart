import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/features/search/search_model.dart';

void main() {
  group('matchesPrecisionSearch', () {
    SearchBook buildBook({required String name, String? author}) {
      return SearchBook(
        bookUrl: 'https://example.com/book',
        name: name,
        author: author,
        origin: 'https://example.com',
        originName: '測試書源',
      );
    }

    test('matches when title contains keyword', () {
      final book = buildBook(name: '我的徒弟都是大反派', author: '貓膩');

      expect(matchesPrecisionSearch(book, '我的徒弟'), isTrue);
    });

    test('matches when author contains keyword', () {
      final book = buildBook(name: '雪中悍刀行', author: '烽火戲諸侯');

      expect(matchesPrecisionSearch(book, '烽火'), isTrue);
    });

    test('does not require exact equality but rejects blank keywords', () {
      final book = buildBook(name: '大奉打更人', author: '賣報小郎君');

      expect(matchesPrecisionSearch(book, '大奉'), isTrue);
      expect(matchesPrecisionSearch(book, '   '), isFalse);
    });
  });
}
