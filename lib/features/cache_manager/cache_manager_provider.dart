import 'package:flutter/material.dart';
import 'package:inkpage_reader/core/models/book.dart';
import 'package:inkpage_reader/core/models/chapter.dart';
import 'package:inkpage_reader/core/database/dao/chapter_dao.dart';
import 'package:inkpage_reader/core/database/dao/reader_chapter_content_dao.dart';
import 'package:inkpage_reader/core/services/download_service.dart';
import 'package:inkpage_reader/core/di/injection.dart';
import 'package:inkpage_reader/features/reader/engine/reader_chapter_content_cache_repository.dart';

class CacheManagerProvider extends ChangeNotifier {
  final Book book;
  final ChapterDao _chapterDao = getIt<ChapterDao>();
  final ReaderChapterContentDao? _chapterContentDao =
      getIt.isRegistered<ReaderChapterContentDao>()
          ? getIt<ReaderChapterContentDao>()
          : null;
  final DownloadService downloadService = DownloadService();

  List<BookChapter> _chapters = [];
  final Set<int> _cachedIndices = {};
  bool _isLoading = false;

  List<BookChapter> get chapters => _chapters;
  Set<int> get cachedIndices => _cachedIndices;
  bool get isLoading => _isLoading;

  CacheManagerProvider(this.book) {
    loadStatus();
    downloadService.addListener(notifyListeners);
  }

  @override
  void dispose() {
    downloadService.removeListener(notifyListeners);
    super.dispose();
  }

  Future<void> loadStatus() async {
    _isLoading = true;
    notifyListeners();

    _chapters = await _chapterDao.getChapters(book.bookUrl);
    final chapterContentDao = _chapterContentDao;
    final cachedIndices =
        chapterContentDao == null
            ? <int>{}
            : await ReaderChapterContentCacheRepository(
              chapterDao: _chapterDao,
              contentDao: chapterContentDao,
            ).cachedChapterIndices(book: book);
    _cachedIndices
      ..clear()
      ..addAll(cachedIndices);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> downloadChapters(int start, int end) async {
    final toDownload = _chapters.sublist(
      start.clamp(0, _chapters.length),
      end.clamp(0, _chapters.length),
    );
    await downloadService.addDownloadTask(book, toDownload);
  }

  Future<void> downloadUncached() async {
    final uncached =
        _chapters.where((ch) => !_cachedIndices.contains(ch.index)).toList();
    if (uncached.isNotEmpty) {
      await downloadService.addDownloadTask(book, uncached);
    }
  }

  Future<void> clearCache() async {
    final chapterContentDao = _chapterContentDao;
    if (chapterContentDao != null) {
      await ReaderChapterContentCacheRepository(
        chapterDao: _chapterDao,
        contentDao: chapterContentDao,
      ).deleteCachedContentForBook(book: book);
    }
    await loadStatus();
  }
}
