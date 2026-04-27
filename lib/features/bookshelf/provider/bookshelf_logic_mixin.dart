import 'package:shared_preferences/shared_preferences.dart';
import 'package:inkpage_reader/core/constant/prefer_key.dart';
import 'package:inkpage_reader/core/services/book_storage_service.dart';
import 'bookshelf_provider_base.dart';

/// BookshelfProvider 的 UI 狀態與分組邏輯擴展
mixin BookshelfLogicMixin on BookshelfProviderBase {
  Future<void> loadUiPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    isGridView = prefs.getBool('bookshelf_is_grid') ?? isGridView;
    showLastUpdate =
        prefs.getBool('bookshelf_show_last_update') ?? showLastUpdate;
    final savedSort = prefs.getInt(PreferKey.bookshelfSort);
    if (savedSort != null &&
        savedSort >= 0 &&
        savedSort < BookshelfSortMode.values.length) {
      sortMode = BookshelfSortMode.values[savedSort];
    }
    notifyListeners();
  }

  void toggleViewMode() {
    isGridView = !isGridView;
    SharedPreferences.getInstance().then(
      (p) => p.setBool('bookshelf_is_grid', isGridView),
    );
    notifyListeners();
  }

  void setGridView(bool value) {
    if (isGridView == value) return;
    isGridView = value;
    SharedPreferences.getInstance().then(
      (p) => p.setBool('bookshelf_is_grid', isGridView),
    );
    notifyListeners();
  }

  void toggleShowLastUpdate() {
    showLastUpdate = !showLastUpdate;
    SharedPreferences.getInstance().then(
      (p) => p.setBool('bookshelf_show_last_update', showLastUpdate),
    );
    notifyListeners();
  }

  Future<void> setSortMode(BookshelfSortMode value) async {
    if (sortMode == value) return;
    sortMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PreferKey.bookshelfSort, value.index);
    await loadBooks();
  }

  Future<void> reorderBooks(int oldIndex, int newIndex) async {
    if (sortMode != BookshelfSortMode.custom) return;
    if (newIndex > oldIndex) newIndex -= 1;
    if (oldIndex < 0 ||
        oldIndex >= books.length ||
        newIndex < 0 ||
        newIndex > books.length) {
      return;
    }
    final item = books.removeAt(oldIndex);
    books.insert(newIndex, item);
    for (var i = 0; i < books.length; i++) {
      books[i].order = i;
      await bookDao.upsert(books[i]);
    }
    notifyListeners();
  }

  void toggleBatchMode({String? initialSelectedUrl}) {
    isBatchMode = !isBatchMode;
    selectedBookUrls.clear();
    if (isBatchMode && initialSelectedUrl != null) {
      selectedBookUrls.add(initialSelectedUrl);
    }
    notifyListeners();
  }

  void toggleSelect(String url) {
    selectedBookUrls.contains(url)
        ? selectedBookUrls.remove(url)
        : selectedBookUrls.add(url);
    notifyListeners();
  }

  void selectAll() {
    selectedBookUrls.length == books.length
        ? selectedBookUrls.clear()
        : selectedBookUrls.addAll(books.map((b) => b.bookUrl));
    notifyListeners();
  }

  Future<void> deleteSelected() async {
    for (var url in selectedBookUrls) {
      final book = await bookDao.getByUrl(url);
      if (book != null) {
        await BookStorageService().discardBook(book);
      } else {
        await bookDao.deleteByUrl(url);
        await chapterDao.deleteByBook(url);
      }
    }
    isBatchMode = false;
    selectedBookUrls.clear();
    loadBooks();
  }
}
