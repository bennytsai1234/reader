import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/core/models/book_source.dart';
import 'package:inkpage_reader/core/models/search_book.dart';
import 'package:inkpage_reader/core/engine/web_book/web_book_service.dart';
import 'package:inkpage_reader/core/services/app_log_service.dart';

/// ExploreShowProvider - 探索結果列表的狀態管理
/// (對標 Android ExploreShowViewModel)
///
/// 管理單個分類的書籍列表、分頁載入、書架狀態。
class ExploreShowProvider extends ChangeNotifier {
  final String sourceUrl;
  final String exploreUrl;
  final String exploreName;

  final BookSourceDao _sourceDao = getIt<BookSourceDao>();
  CancelToken? _cancelToken;

  BookSource? _bookSource;
  List<SearchBook> _books = [];
  int _page = 1;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;

  // --- 書架狀態 (對標 Android ExploreShowViewModel.bookshelf) ---
  final Set<String> _bookshelfKeys = {};

  // --- Getters ---
  List<SearchBook> get books => _books;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _books.isEmpty && !_isLoading;

  ExploreShowProvider({
    required this.sourceUrl,
    required this.exploreUrl,
    required this.exploreName,
  }) {
    _init();
  }

  Future<void> _init() async {
    _bookSource = await _sourceDao.getByUrl(sourceUrl);
    if (_bookSource == null) {
      _errorMessage = '找不到書源';
      notifyListeners();
      return;
    }
    await _loadBookshelfState();
    await _loadData();
  }

  /// 載入書架狀態 (對標 Android ExploreShowViewModel.init bookshelf flow)
  Future<void> _loadBookshelfState() async {
    // TODO: 當 bookDao 可用時，從書架載入狀態
    // 目前先跳過，等待後續整合
  }

  /// 判斷書籍是否在書架中 (對標 Android isInBookShelf)
  bool isInBookshelf(SearchBook book) {
    final key = book.author != null && book.author!.isNotEmpty
        ? '${book.name}-${book.author}'
        : book.name;
    return _bookshelfKeys.contains(key) || _bookshelfKeys.contains(book.bookUrl);
  }

  /// 載入數據
  Future<void> _loadData() async {
    if (_bookSource == null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _cancelToken = CancelToken();

    try {
      final results = await WebBook.exploreBookAwait(
        _bookSource!,
        exploreUrl,
        page: _page,
      );

      if (_cancelToken?.isCancelled ?? false) return;

      if (results.isEmpty) {
        _hasMore = false;
      } else {
        _books.addAll(results);
        _page++;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) return;
      AppLog.e('探索載入失敗', error: e);
      _errorMessage = e.message ?? '載入失敗';
      _hasMore = false;
    } catch (e) {
      AppLog.e('探索載入失敗', error: e);
      _errorMessage = e.toString();
      _hasMore = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 載入更多 (對標 Android scrollToBottom)
  Future<void> loadMore() async {
    if (!_hasMore || _isLoading) return;
    await _loadData();
  }

  /// 重新載入
  Future<void> refresh() async {
    _cancelToken?.cancel('refresh');
    _page = 1;
    _books = [];
    _hasMore = true;
    _errorMessage = null;
    await _loadData();
  }

  @override
  void dispose() {
    _cancelToken?.cancel('ExploreShowProvider disposed');
    super.dispose();
  }
}
