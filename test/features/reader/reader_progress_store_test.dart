import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/features/reader/runtime/reader_progress_store.dart';

void main() {
  group('ReaderProgressStore', () {
    test('shouldSaveImmediately 會根據距離與章節變化決定', () {
      final store = ReaderProgressStore();

      expect(
        store.shouldSaveImmediately(
          currentCharOffset: 10,
          currentChapterIndex: 0,
          targetChapterIndex: 0,
        ),
        isTrue,
      );
    });

    test('persistCharOffset 會更新 book 並寫入資料層', () async {
      final store = ReaderProgressStore();
      final book = Book(name: 'book', author: 'author', bookUrl: 'url');
      final chapters = [
        BookChapter(title: 'c0', index: 0),
        BookChapter(title: 'c1', index: 1),
      ];

      int? savedChapter;
      String? savedTitle;
      int? savedOffset;

      await store.persistCharOffset(
        write: (chapterIndex, title, charOffset) async {
          savedChapter = chapterIndex;
          savedTitle = title;
          savedOffset = charOffset;
        },
        book: book,
        chapters: chapters,
        chapterIndex: 1,
        charOffset: 345,
      );

      expect(book.durChapterIndex, 1);
      expect(book.durChapterPos, 345);
      expect(book.durChapterTitle, 'c1');
      expect(savedChapter, 1);
      expect(savedTitle, 'c1');
      expect(savedOffset, 345);
    });
  });
}
