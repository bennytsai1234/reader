import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/services/book_source_service.dart';
import 'package:legado_reader/core/database/dao/book_source_dao.dart';
import 'package:legado_reader/core/database/dao/search_book_dao.dart';
import 'package:legado_reader/core/di/injection.dart';

/// ChangeSourceProvider - 換源業務邏輯
class ChangeSourceProvider extends ChangeNotifier {
  final Book book;
  final BookSourceService service = BookSourceService();
  final BookSourceDao sourceDao = getIt<BookSourceDao>();
  final SearchBookDao searchBookDao = getIt<SearchBookDao>();

  List<SearchBook> allResults = [];
  List<SearchBook> filteredResults = [];
  List<String> groups = ['全部'];
  String selectedGroup = '全部';
  bool isSearching = false;
  String status = '正在初始化...';
  bool checkAuthor = true;

  ChangeSourceProvider(this.book) {
    loadGroups();
    startSearch();
  }

  Future<void> loadGroups() async {
    final sources = await sourceDao.getEnabled();
    final groupSet = <String>{'全部'};
    for (var s in sources) {
      if (s.bookSourceGroup != null && s.bookSourceGroup!.isNotEmpty) {
        groupSet.addAll(s.bookSourceGroup!.split(',').map((e) => e.trim()));
      }
    }
    groups = groupSet.toList()..sort();
    notifyListeners();
  }

  void applyFilter(String key) {
    if (key.isEmpty) {
      filteredResults = allResults;
    } else {
      final query = key.toLowerCase();
      filteredResults = allResults.where((r) =>
        (r.originName ?? '').toLowerCase().contains(query) ||
        (r.latestChapterTitle ?? '').toLowerCase().contains(query)
      ).toList();
    }
    notifyListeners();
  }

  Future<void> startSearch() async {
    final cached = await searchBookDao.getSearchBooks(book.name, book.author);
    if (cached.isNotEmpty) {
      allResults = cached;
      filteredResults = cached;
      status = '載入快取來源... 正在同步更新...';
      notifyListeners();
    }

    isSearching = true;
    if (allResults.isEmpty) status = '正在搜尋可用書源...';
    notifyListeners();

    try {
      var enabledSources = await sourceDao.getEnabled();
      if (selectedGroup != '全部') {
        enabledSources = enabledSources.where((s) => (s.bookSourceGroup ?? '').split(',').map((e) => e.trim()).contains(selectedGroup)).toList();
      }

      final searchTasks = enabledSources.map((source) => 
        service.preciseSearch(source, book.name, checkAuthor ? book.author : '')
      ).toList();
      
      final resultsList = await Future.wait(searchTasks);
      final results = resultsList.expand((x) => x).toList();

      results.sort((a, b) {
        final cmp = a.originOrder.compareTo(b.originOrder);
        if (cmp != 0) return cmp;
        return (b.latestChapterTitle?.length ?? 0).compareTo(a.latestChapterTitle?.length ?? 0);
      });

      allResults = results;
      filteredResults = results;
      isSearching = false;
      status = results.isEmpty ? '未找到備用書源' : '搜尋完成 (已自動優選)';
      notifyListeners();
    } catch (e) {
      isSearching = false;
      status = '搜尋出錯: $e';
      notifyListeners();
    }
  }

  void toggleCheckAuthor() {
    checkAuthor = !checkAuthor;
    startSearch();
  }

  void updateSelectedGroup(String g) {
    selectedGroup = g;
    startSearch();
  }
}


