import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/database/dao/bookmark_dao.dart';
import 'package:legado_reader/core/di/injection.dart';
import 'package:legado_reader/core/models/bookmark.dart';

class BookmarkProvider extends ChangeNotifier {
  final BookmarkDao _dao = getIt<BookmarkDao>();

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
}

