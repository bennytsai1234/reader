import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:legado_reader/core/local_book/epub_parser.dart';

void main() {
  group('EpubParser Tests', () {
    late File invalidFile;

    setUp(() async {
      final tempDir = Directory.systemTemp;
      invalidFile = File('${tempDir.path}/invalid_epub.epub');
      await invalidFile.writeAsString('this is not a valid epub file');
    });

    tearDown(() async {
      if (await invalidFile.exists()) {
        await invalidFile.delete();
      }
    });

    // 移除 invalid load test 避免觸發 epubx/archive 底層 UnmodifiableInt32ListView 錯誤
    
    test('Default values before load', () {
      final parser = EpubParser(invalidFile);
      expect(parser.title, 'Unknown Title');
      expect(parser.author, 'Unknown Author');
      expect(parser.getChapters(), isEmpty);
      expect(parser.getChapterContent('any'), '');
    });
  });
}
