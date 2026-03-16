import 'package:flutter/services.dart';
import 'web_service_base.dart';

/// WebService 的具體業務邏輯擴展
extension WebServiceControllers on WebServiceBase {
  /// 重新整理目錄
  Future<List<Map<String, dynamic>>> refreshToc(String bookUrl) async {
    final book = await bookDao.getByUrl(bookUrl);
    if (book == null) throw Exception('書籍不存在');
    
    final source = await sourceDao.getByUrl(book.origin);
    if (source == null) throw Exception('書源不存在');

    final chapters = await sourceService.getChapterList(source, book);
    await chapterDao.deleteByBook(bookUrl);
    await chapterDao.insertChapters(chapters);
    
    book.totalChapterNum = chapters.length;
    await bookDao.upsert(book);

    return chapters.map((c) => c.toJson()).toList();
  }

  /// 獲取章節內容
  Future<String> getBookContent(String bookUrl, int index) async {
    final chapter = await chapterDao.getChapterByIndex(bookUrl, index);
    if (chapter == null) throw Exception('章節不存在');

    var content = await chapterDao.getContent(chapter.url);
    if (content != null) return content;

    final book = await bookDao.getByUrl(bookUrl);
    if (book == null) throw Exception('書籍不存在');

    final source = await sourceDao.getByUrl(book.origin);
    if (source == null) throw Exception('書源不存在');

    content = await sourceService.getContent(source, book, chapter);
    await chapterDao.saveContent(chapter.url, content);
    return content;
  }

  /// 處理靜態檔案
  Future<dynamic> handleStaticFile(String fileName) async {
    try {
      final path = 'assets/web/$fileName';
      return await rootBundle.loadString(path);
    } catch (e) {
      return '<html><body><h1>Web Interface Source Not Found</h1></body></html>';
    }
  }
}

