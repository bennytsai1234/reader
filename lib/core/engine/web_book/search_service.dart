import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/search_book.dart';
import 'package:legado_reader/core/engine/web_book/web_book_service.dart';
import 'package:legado_reader/core/database/dao/search_book_dao.dart';
import 'package:legado_reader/core/di/injection.dart';

/// SearchService - 多書源並行搜尋服務 (原 Android model/webBook/SearchModel.kt)
class SearchService {
  final WebBookService _webBookService = WebBookService();
  final List<SearchBook> _searchBooks = [];
  StreamController<List<SearchBook>>? _controller;
  
  bool _isSearching = false;
  String _searchKey = '';

  Stream<List<SearchBook>> get searchStream => _controller?.stream ?? const Stream.empty();

  Future<void> search(List<BookSource> sources, String key, {int page = 1}) async {
    if (_isSearching && page == 1) {
      await stopSearch();
    }

    _searchKey = key;
    _isSearching = true;

    if (page == 1) {
      _searchBooks.clear();
      _controller?.close();
      _controller = StreamController<List<SearchBook>>.broadcast();
    }

    final tasks = <Future>[];
    // 控制並發數，這裡簡單處理，未來可加入更細緻的執行緒控制
    for (final source in sources) {
      tasks.add(_searchSingleSource(source, key, page));
    }

    Future.wait(tasks).then((_) {
      _isSearching = false;
      // 全部完成後的處理
    });
  }

  Future<void> _searchSingleSource(BookSource source, String key, int page) async {
    try {
      final results = await _webBookService.searchBook(
        source, 
        key, 
        page: page,
      );

      if (results.isNotEmpty) {
        _mergeResults(results);
        _controller?.add(List.from(_searchBooks));
        
        // 存入資料庫快取
        await getIt<SearchBookDao>().insertList(results);
      }
    } catch (e) {
      debugPrint('Search failed for ${source.bookSourceName}: $e');
    }
  }

  void _mergeResults(List<SearchBook> newResults) {
    for (var newBook in newResults) {
      // 檢查是否已存在 (相同書名與作者)
      final index = _searchBooks.indexWhere((b) => b.name == newBook.name && b.author == newBook.author);
      if (index != -1) {
        // 合併來源
        _searchBooks[index].addOrigin(newBook.origin);
      } else {
        _searchBooks.add(newBook);
      }
    }
    
    // 排序邏輯 ((原 Android 優先完全匹配，其次包含匹配，最後按來源數排序))
    _searchBooks.sort((a, b) {
      final aEqual = a.name == _searchKey || a.author == _searchKey;
      final bEqual = b.name == _searchKey || b.author == _searchKey;
      if (aEqual && !bEqual) return -1;
      if (!aEqual && bEqual) return 1;
      
      return b.origins.length.compareTo(a.origins.length);
    });
  }

  Future<void> stopSearch() async {
    _isSearching = false;
    // 取消尚未完成的任務 (Isolate 取消較複雜，目前先標記狀態)
  }

  void dispose() {
    _controller?.close();
  }
}

