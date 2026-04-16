import 'package:flutter/foundation.dart';
import 'package:inkpage_reader/core/database/dao/book_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_group_dao.dart';
import 'package:inkpage_reader/core/database/dao/book_source_dao.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/book_group.dart';
import 'package:inkpage_reader/core/services/book_source_service.dart';
import 'package:inkpage_reader/core/di/injection.dart';

/// BookshelfProvider 的基礎狀態與 DAO 定義
abstract class BookshelfProviderBase extends ChangeNotifier {
  Future<void> loadBooks();

  final BookDao bookDao = getIt<BookDao>();
  final BookGroupDao groupDao = getIt<BookGroupDao>();
  final BookSourceDao sourceDao = getIt<BookSourceDao>();
  final BookSourceService service = BookSourceService();
  final ChapterDao chapterDao = getIt<ChapterDao>();

  List<Book> books = [];
  List<BookGroup> groups = [];
  int currentGroupId = -1; // -1: 全部
  bool isLoading = false;
  bool isBatchMode = false;
  final Set<String> selectedBookUrls = {};
  
  bool isGridView = true;
  bool showUnread = true;
  bool showLastUpdate = false;
  int sortMode = 0; // 0:手動, 1:最後閱讀, 2:最晚更新, 3:書名, 4:作者
  int updatingCount = 0;

  BookshelfProviderBase();
}


