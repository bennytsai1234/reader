import 'dart:io';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/services/epub_service.dart';

/// LocalBookService - 本地書籍內容獲取服務
class LocalBookService {
  static final LocalBookService _instance = LocalBookService._internal();
  factory LocalBookService() => _instance;
  LocalBookService._internal();

  /// 獲取本地書籍章節內容
  Future<String> getContent(Book book, BookChapter chapter) async {
    final path = book.bookUrl.replaceFirst('local://', '');
    final file = File(path);
    if (!await file.exists()) return '檔案不存在: $path';

    final ext = path.split('.').last.toLowerCase();
    if (ext == 'txt') {
      // 對於 TXT 來說，分章節時已經可能存儲了內容，或者需要重新解析
      // 這裡簡單處理：如果是 TXT 且沒有存儲在內容庫中，嘗試重新讀取
      // (實際開發中 TXT 通常在匯入時就 insertContents 了)
      return '本地 TXT 內容缺失，請重新匯入';
    } else if (ext == 'epub') {
      return await EpubService().getChapterContent(file, chapter.url);
    }
    return '不支援的本地格式: $ext';
  }
}

