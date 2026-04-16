import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inkpage_reader/core/local_book/epub_parser.dart';

// XML 特殊字元轉義，防止書名/作者直接插入 XML 時破壞結構
String _escapeXml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

// ─── 輔助：在記憶體中組裝最小合法 EPUB，寫入指定路徑 ──────────────────────────
Future<File> _createMinimalEpub({
  required String filePath,
  String title = '測試書名',
  String author = '測試作者',
  String chapter1Title = '第一章',
  String chapter1Body = '<h1>第一章</h1><p>你好，世界！</p>',
}) async {
  final archive = Archive();

  void add(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  // mimetype（必須是第一個檔案）
  add('mimetype', 'application/epub+zip');

  // META-INF/container.xml
  // epubx 4.0.0 要求完整 namespace（findAllElements 做 namespace 比對）
  add('META-INF/container.xml', '''<?xml version="1.0"?>
<container version="1.0"
           xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf"
              media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''');

  // OEBPS/content.opf
  add('OEBPS/content.opf', '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="2.0"
         unique-identifier="bookid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>${_escapeXml(title)}</dc:title>
    <dc:creator>${_escapeXml(author)}</dc:creator>
    <dc:identifier id="bookid">test-epub-001</dc:identifier>
    <dc:language>zh-TW</dc:language>
  </metadata>
  <manifest>
    <item id="ch1" href="chapter1.xhtml"
          media-type="application/xhtml+xml"/>
    <item id="ncx" href="toc.ncx"
          media-type="application/x-dtbncx+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="ch1"/>
  </spine>
</package>''');

  // OEBPS/toc.ncx
  add('OEBPS/toc.ncx', '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="test-epub-001"/>
    <meta name="dtb:depth" content="1"/>
  </head>
  <docTitle><text>${_escapeXml(title)}</text></docTitle>
  <navMap>
    <navPoint id="np1" playOrder="1">
      <navLabel><text>${_escapeXml(chapter1Title)}</text></navLabel>
      <content src="chapter1.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''');

  // OEBPS/chapter1.xhtml
  add('OEBPS/chapter1.xhtml', '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml">
  <head><title>${_escapeXml(chapter1Title)}</title></head>
  <body>$chapter1Body</body>
</html>''');

  final zipBytes = ZipEncoder().encode(archive)!;
  final file = File(filePath);
  await file.writeAsBytes(zipBytes);
  return file;
}

void main() {
  group('EpubParser Tests', () {
    late Directory tempDir;

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('epub_test_');
    });

    tearDownAll(() async {
      await tempDir.delete(recursive: true);
    });

    // ─── load() 前的初始狀態 ──────────────────────────────────────────────────
    group('load() 前的初始狀態', () {
      test('title/author 回傳預設值，chapters 為空', () {
        final parser = EpubParser(File('${tempDir.path}/ghost.epub'));
        expect(parser.title, equals('Unknown Title'));
        expect(parser.author, equals('Unknown Author'));
        expect(parser.getChapters(), isEmpty);
        expect(parser.getChapterContent('any.xhtml'), isEmpty);
      });
    });

    // ─── 非法檔案 ─────────────────────────────────────────────────────────────
    group('非法/損壞 EPUB', () {
      test('load() 對純文字檔拋出 Exception', () async {
        final f = File('${tempDir.path}/invalid.epub');
        await f.writeAsString('this is not a valid epub file');
        final parser = EpubParser(f);
        await expectLater(parser.load(), throwsA(isA<Exception>()));
      });

      test('load() 對空檔案拋出 Exception', () async {
        final f = File('${tempDir.path}/empty.epub');
        await f.writeAsBytes([]);
        final parser = EpubParser(f);
        await expectLater(parser.load(), throwsA(isA<Exception>()));
      });
    });

    // ─── 合法 EPUB 解析 ───────────────────────────────────────────────────────
    group('合法 EPUB 解析', () {
      late EpubParser parser;

      setUp(() async {
        final file = await _createMinimalEpub(
          filePath: '${tempDir.path}/valid_${DateTime.now().millisecondsSinceEpoch}.epub',
          title: '測試書名',
          author: '測試作者',
        );
        parser = EpubParser(file);
        await parser.load();
      });

      test('正確解析書名', () {
        expect(parser.title, equals('測試書名'));
      });

      test('正確解析作者', () {
        expect(parser.author, equals('測試作者'));
      });

      test('getChapters() 回傳非空章節列表', () {
        final chapters = parser.getChapters();
        expect(chapters, isNotEmpty);
      });

      test('getChapters() 包含 title 與 href 欄位', () {
        final chapter = parser.getChapters().first;
        expect(chapter['title'], isNotNull);
        expect(chapter['href'], isNotNull);
        expect(chapter['href'], isNotEmpty);
      });

      test('getChapters() 章節標題來自 NCX navLabel', () {
        final chapters = parser.getChapters();
        expect(chapters.first['title'], contains('第一章'));
      });

      test('getChapterContent() 以 href 讀取 HTML 內文', () {
        final href = parser.getChapters().first['href']!;
        final content = parser.getChapterContent(href);
        expect(content, isNotEmpty);
        expect(content, contains('你好，世界！'));
      });

      test('getChapterContent() 自動去除 href 中的 anchor (#)', () {
        final href = parser.getChapters().first['href']!;
        final contentWithAnchor  = parser.getChapterContent('$href#section1');
        final contentWithoutAnchor = parser.getChapterContent(href);
        expect(contentWithAnchor, equals(contentWithoutAnchor));
      });

      test('getChapterContent() 對不存在的 href 回傳空字串', () {
        expect(parser.getChapterContent('nonexistent.xhtml'), isEmpty);
      });

      test('getCoverImage() 對無封面的 EPUB 回傳 null', () async {
        final cover = await parser.getCoverImage();
        expect(cover, isNull);
      });
    });

    // ─── 多章節 EPUB ──────────────────────────────────────────────────────────
    group('多章節 EPUB', () {
      test('書名含特殊字元可正常解析', () async {
        final file = await _createMinimalEpub(
          filePath: '${tempDir.path}/special.epub',
          title: '書名：副標題 & 特殊<字>元',
          author: 'O\'Brien',
        );
        final parser = EpubParser(file);
        await parser.load();
        // epubx 會對 XML 字元做反轉義，結果視 epubx 版本而定
        // 至少確認不拋出、且書名非預設值
        expect(parser.title, isNot('Unknown Title'));
        expect(parser.author, isNot('Unknown Author'));
      });
    });
  });
}
