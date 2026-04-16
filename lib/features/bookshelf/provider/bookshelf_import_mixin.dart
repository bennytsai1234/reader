import 'package:inkpage_reader/core/services/app_log_service.dart';
import 'package:inkpage_reader/core/services/local_book_service.dart';
import 'bookshelf_provider_base.dart';

/// BookshelfProvider 的本地書籍匯入邏輯擴展
mixin BookshelfImportMixin on BookshelfProviderBase {
  Future<void> importLocalBookPath(String path) async {
    final bookUrl = 'local://$path';
    final existingBook = await bookDao.getByUrl(bookUrl);
    if (existingBook != null && existingBook.isInBookshelf) return;

    isLoading = true;
    notifyListeners();

    try {
      final result = await LocalBookService().importBook(path);
      if (result != null) {
        await bookDao.upsert(result.book);
        await chapterDao.insertChapters(result.chapters);
        loadBooks();
      }
    } catch (e) {
      AppLog.e('匯入本地書籍失敗: $e', error: e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
