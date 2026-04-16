import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/database/dao/bookmark_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/bookmark.dart';
import 'package:inkpage_reader/core/models/book.dart';

class BookmarkProvider extends ChangeNotifier {
  final BookmarkDao _dao = getIt<BookmarkDao>();
  final BookDao _bookDao = getIt<BookDao>();

  List<Bookmark> _bookmarks = [];
  List<Bookmark> get bookmarks => _bookmarks;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _searchKey = '';

  BookmarkProvider() {
    loadBookmarks();
  }

  Future<void> loadBookmarks() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_searchKey.isEmpty) {
        _bookmarks = await _dao.getAll();
      } else {
        _bookmarks = await _dao.search(_searchKey);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void search(String key) {
    _searchKey = key;
    loadBookmarks();
  }

  Future<void> deleteBookmark(Bookmark bookmark) async {
    await _dao.deleteBookmark(bookmark);
    await loadBookmarks();
  }

  Future<void> clearAll() async {
    await _dao.clearAll();
    await loadBookmarks();
  }

  Future<Book?> lookupBook(String bookUrl) => _bookDao.getByUrl(bookUrl);
}

