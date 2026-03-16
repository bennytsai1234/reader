import 'dart:isolate';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/engine/analyze_url.dart';
import 'package:legado_reader/core/engine/analyze_rule.dart';
import 'package:legado_reader/core/engine/web_book/book_list_parser.dart';
import 'package:legado_reader/core/engine/web_book/book_info_parser.dart';
import 'package:legado_reader/core/engine/web_book/chapter_list_parser.dart';
import 'package:legado_reader/core/engine/web_book/content_parser.dart';
import 'package:legado_reader/core/services/book_source_service.dart';

/// WebBookService - 書源抓取業務調度服務 (原 Android model/webBook/WebBook.kt)
class WebBookService {
  final BookSourceService _sourceService = BookSourceService();

  Future<List<SearchBook>> searchBook(
    BookSource source,
    String key, {
    int page = 1,
    bool Function(String name, String author)? filter,
  }) async {
    if (source.searchUrl == null || source.searchUrl!.isEmpty) {
      throw Exception('搜尋 URL 不能為空');
    }

    if (_sourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final analyzeUrl = AnalyzeUrl(
      source.searchUrl!,
      source: source,
      key: key,
      page: page,
    );

    // 執行登入檢查 JS Hook
    final rule = AnalyzeRule(source: source);
    await rule.checkLogin();

    final body = await analyzeUrl.getResponseBody();
    
    // 解析
    final results = await Isolate.run(() => BookListParser.parse(
      source: source,
      body: body,
      baseUrl: analyzeUrl.url,
      isSearch: true,
    ));

    // 過濾
    if (filter != null) {
      return results.where((b) => filter(b.name, b.author ?? '')).toList();
    }
    return results;
  }

  Future<List<SearchBook>> exploreBook(
    BookSource source,
    String url, {
    int page = 1,
  }) async {
    if (_sourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final analyzeUrl = AnalyzeUrl(url, source: source, page: page);
    final rule = AnalyzeRule(source: source);
    await rule.checkLogin();

    final body = await analyzeUrl.getResponseBody();

    return Isolate.run(() => BookListParser.parse(
      source: source,
      body: body,
      baseUrl: analyzeUrl.url,
      isSearch: false,
    ));
  }

  Future<Book> getBookInfo(BookSource source, Book book) async {
    if (_sourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final analyzeUrl = AnalyzeUrl(book.bookUrl, source: source);
    final rule = AnalyzeRule(source: source, ruleData: book);
    await rule.checkLogin();

    final body = await analyzeUrl.getResponseBody();

    return Isolate.run(() => BookInfoParser.parse(
      source: source,
      book: book,
      body: body,
      baseUrl: analyzeUrl.url,
    ));
  }

  Future<List<BookChapter>> getChapterList(BookSource source, Book book) async {
    if (_sourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final analyzeUrl = AnalyzeUrl(book.tocUrl, source: source);
    final rule = AnalyzeRule(source: source, ruleData: book);
    await rule.checkLogin();
    await rule.preUpdateToc();

    final body = await analyzeUrl.getResponseBody();

    return Isolate.run(() => ChapterListParser.parse(
      source: source,
      book: book,
      body: body,
      baseUrl: analyzeUrl.url,
    ));
  }

  Future<String> getContent(
    BookSource source,
    Book book,
    BookChapter chapter, {
    String? nextChapterUrl,
  }) async {
    if (_sourceService.is18Plus(source.bookSourceUrl)) {
      throw Exception('該網址為 18+ 網站，禁止訪問。');
    }

    final analyzeUrl = AnalyzeUrl(chapter.url, source: source, ruleData: book);
    final rule = AnalyzeRule(source: source, ruleData: book);
    await rule.checkLogin();

    final body = await analyzeUrl.getResponseBody();

    return Isolate.run(() => ContentParser.parse(
      source: source,
      body: body,
      baseUrl: analyzeUrl.url,
      nextChapterUrl: nextChapterUrl,
    ));
  }
}

