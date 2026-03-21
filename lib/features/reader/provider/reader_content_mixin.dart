import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/engine/reader/content_processor.dart' as engine;
import 'package:legado_reader/core/models/book/book_content.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/services/cache_manager.dart';
import 'package:legado_reader/core/services/local_book_service.dart';
import 'package:legado_reader/features/reader/engine/chapter_content_manager.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/reader_perf_trace.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';

import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';

mixin ReaderContentMixin on ReaderProviderBase, ReaderSettingsMixin {
  static const int _scrollPreloadRadius = 1;
  ChapterContentManager? _contentManager;
  ChapterContentManager get contentManager => _contentManager!;
  bool get hasContentManager => _contentManager != null;
  bool get isWholeBookPreloadEnabled =>
      hasContentManager && contentManager.wholeBookPreloadEnabled;

  StreamSubscription<int>? _chapterReadySub;
  Timer? _deferredWindowWarmupTimer;
  Timer? _extendedWindowWarmupTimer;
  Timer? _localAdjacentLoadTimer;

  List<Map<String, dynamic>>? _cachedRulesJson;
  String? _cachedRulesSignature;
  bool _isPaginating = false;
  int _lastVisibleScrollChapter = -1;

  List<TextPage> get currentChapterPages =>
      chapterPagesCache[currentChapterIndex] ?? const <TextPage>[];

  bool get _isLocalScrollMode =>
      pageTurnMode == PageAnim.scroll && book.origin == 'local';
  bool get _isLocalBook => book.origin == 'local';

  void initContentManager() {
    _chapterReadySub?.cancel();
    _deferredWindowWarmupTimer?.cancel();
    _extendedWindowWarmupTimer?.cancel();
    _localAdjacentLoadTimer?.cancel();
    _contentManager?.dispose();
    chapterPagesCache.clear();
    slidePages = [];
    _contentManager = ChapterContentManager(
      fetchFn: _fetchChapterData,
      chapters: chapters,
    );
    _contentManager!.setProgressivePaginationEnabled(_isLocalScrollMode);
    _chapterReadySub = contentManager.onChapterReady.listen((chapterIndex) {
      if (isDisposed) return;
      final pages = contentManager.getCachedPages(chapterIndex);
      if (pages != null && pages.isNotEmpty) {
        chapterPagesCache[chapterIndex] = pages;
        (this as dynamic).refreshChapterRuntime?.call(chapterIndex);
        if (pageTurnMode == PageAnim.scroll) {
          _syncScrollWindowCache();
        }
      }
      if (pageTurnMode != PageAnim.scroll) {
        _refreshSlidePages();
      } else if (_shouldNotifyChapterReady(chapterIndex)) {
        notifyListeners();
      }
    });
  }

  void updatePaginationConfig() {
    if (viewSize == null || !hasContentManager) return;
    final currentTheme = AppTheme.readingThemes[
        themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];
    final titleStyle = TextStyle(
      fontSize: fontSize + 4,
      fontWeight: FontWeight.bold,
      color: currentTheme.textColor,
      letterSpacing: letterSpacing,
    );
    final contentStyle = TextStyle(
      fontSize: fontSize,
      height: lineHeight,
      color: currentTheme.textColor,
      letterSpacing: letterSpacing,
    );
    contentManager.updateConfig(
      PaginationConfig(
        viewSize: viewSize!,
        titleStyle: titleStyle,
        contentStyle: contentStyle,
        paragraphSpacing: paragraphSpacing,
        textIndent: textIndent,
        textFullJustify: textFullJustify,
      ),
    );
  }

  Future<void> doPaginate({bool fromEnd = false}) async {
    if (_isPaginating || !hasContentManager || viewSize == null) return;
    final targetChapter = currentChapterIndex;
    _isPaginating = true;
    loadingChapters.add(targetChapter);
    notifyListeners();
    try {
      updatePaginationConfig();
      chapterPagesCache.clear();
      slidePages = [];
      final repaginateTargets = pageTurnMode == PageAnim.scroll
          ? _scrollWindowIndices(targetChapter)
          : contentManager.targetWindow;
      if (pageTurnMode == PageAnim.scroll) {
        await contentManager.repaginateVisibleWindow(repaginateTargets);
      } else {
        await contentManager.repaginateAll();
      }
      for (final entry in repaginateTargets) {
        final pages = contentManager.getCachedPages(entry);
        if (pages != null && pages.isNotEmpty) {
          chapterPagesCache[entry] = pages;
          (this as dynamic).refreshChapterRuntime?.call(entry);
        }
      }
      final currentPages = contentManager.getCachedPages(targetChapter);
      if (currentPages != null && currentPages.isNotEmpty) {
        chapterPagesCache[targetChapter] = currentPages;
        (this as dynamic).refreshChapterRuntime?.call(targetChapter);
      }
      _refreshSlidePages();
      if (pageTurnMode == PageAnim.scroll) {
        final pages = chapterPagesCache[targetChapter] ?? const <TextPage>[];
        final charOffset = fromEnd && pages.isNotEmpty
            ? ChapterPositionResolver.getCharOffsetForPage(
                pages,
                pages.length - 1,
              )
            : book.durChapterPos;
        (this as dynamic).jumpToChapterCharOffset(
          chapterIndex: targetChapter,
          charOffset: charOffset,
          reason: isRestoring
              ? ReaderCommandReason.restore
              : ReaderCommandReason.settingsRepaginate,
          isRestoringJump: isRestoring,
        );
      } else {
        currentPageIndex = _findSlidePageIndexByCharOffset(
          chapterIndex: targetChapter,
          charOffset: book.durChapterPos,
          fromEnd: fromEnd,
        );
        (this as dynamic).jumpToSlidePage(
          currentPageIndex,
          reason: isRestoring
              ? ReaderCommandReason.restore
              : ReaderCommandReason.settingsRepaginate,
        );
      }
    } finally {
      loadingChapters.remove(targetChapter);
      _isPaginating = false;
      if (!isDisposed) notifyListeners();
    }
  }

  Future<void> loadChapter(
    int index, {
    bool fromEnd = false,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
  }) async {
    return loadChapterWithPreloadRadius(
      index,
      fromEnd: fromEnd,
      reason: reason,
    );
  }

  Future<void> loadChapterWithPreloadRadius(
    int index, {
    bool fromEnd = false,
    int preloadRadius = 2,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
  }) async {
    if (index < 0 || index >= chapters.length || !hasContentManager) return;
    updatePaginationConfig();
    currentChapterIndex = index;
    visibleChapterIndex = index;
    final effectivePreloadRadius = _isLocalBook
        ? 1
        : (pageTurnMode == PageAnim.scroll
            ? preloadRadius.clamp(0, _scrollPreloadRadius).toInt()
            : preloadRadius);
    contentManager.updateWindow(
      index,
      preloadRadius: effectivePreloadRadius,
      preload: !_isLocalScrollMode,
    );
    if (pageTurnMode == PageAnim.scroll) {
      _syncScrollWindowCache();
    }

    final pages = await _loadAndCacheChapter(index);
    if (pages.isEmpty || isDisposed) return;

    if (pageTurnMode != PageAnim.scroll) {
      for (final neighbor in [index - 1, index + 1]) {
        if (effectivePreloadRadius > 0 &&
            neighbor >= 0 &&
            neighbor < chapters.length) {
          unawaited(_loadAndCacheChapter(neighbor, silent: true));
        }
      }
    }
    if (_isLocalScrollMode && effectivePreloadRadius > 0) {
      _scheduleAdjacentScrollLoad(index, immediate: true);
    } else if (pageTurnMode == PageAnim.scroll && effectivePreloadRadius > 0) {
      scheduleDeferredWindowWarmup(
        index,
        delay: const Duration(milliseconds: 900),
      );
    }
    if (pageTurnMode != PageAnim.scroll && effectivePreloadRadius > 0) {
      contentManager.warmChaptersAround(
        index,
        radius: effectivePreloadRadius,
      );
    }

    if (pageTurnMode == PageAnim.scroll) {
      final targetOffset = fromEnd && pages.isNotEmpty
          ? ChapterPositionResolver.charOffsetToLocalOffset(
              pages,
              ChapterPositionResolver.getCharOffsetForPage(pages, pages.length - 1),
            )
          : ChapterPositionResolver.charOffsetToLocalOffset(
              pages,
              book.durChapterPos,
            );
      (this as dynamic).jumpToChapterLocalOffset(
        chapterIndex: index,
        localOffset: targetOffset,
        alignment: 0.0,
        reason: reason,
      );
    } else {
      _refreshSlidePages();
      currentPageIndex = _findSlidePageIndexByCharOffset(
        chapterIndex: index,
        charOffset: book.durChapterPos,
        fromEnd: fromEnd,
      );
      (this as dynamic).jumpToSlidePage(
        currentPageIndex,
        reason: reason,
      );
    }
    if (!isDisposed) notifyListeners();
  }

  Future<List<TextPage>> _loadAndCacheChapter(
    int index, {
    bool silent = false,
  }) async {
    if (index < 0 || index >= chapters.length || !hasContentManager) return [];
    final cached = chapterPagesCache[index];
    if (cached != null && cached.isNotEmpty) return cached;

    if (!silent) {
      loadingChapters.add(index);
      if (!isDisposed) notifyListeners();
    }
    try {
      final pages = await contentManager.ensureChapterReady(index);
      if (pages.isNotEmpty) {
        chapterPagesCache[index] = pages;
        (this as dynamic).refreshChapterRuntime?.call(index);
      }
      return pages;
    } finally {
      if (!silent) {
        loadingChapters.remove(index);
        if (!isDisposed) notifyListeners();
      }
    }
  }

  Future<List<TextPage>> ensureChapterCached(
    int index, {
    bool silent = true,
    bool prioritize = false,
    int preloadRadius = 1,
  }) {
    if (hasContentManager && pageTurnMode == PageAnim.scroll) {
      contentManager.updateWindow(
        index,
        preloadRadius: _scrollPreloadRadius,
        preload: !_isLocalScrollMode,
      );
      _syncScrollWindowCache();
      if (prioritize && !_isLocalScrollMode) {
        contentManager.prioritize([index], centerIndex: index);
      }
    }
    return _loadAndCacheChapter(index, silent: silent);
  }

  void _refreshSlidePages() {
    final previousPage =
        currentPageIndex >= 0 && currentPageIndex < slidePages.length
            ? slidePages[currentPageIndex]
            : null;
    final runtimePages = (this as dynamic).buildSlideRuntimePages?.call();
    if (runtimePages is List<TextPage>) {
      slidePages = runtimePages;
      if (slidePages.isEmpty) {
        currentPageIndex = 0;
        return;
      }
      final remappedIndex = previousPage != null
          ? slidePages.indexWhere(
              (page) =>
                  page.chapterIndex == previousPage.chapterIndex &&
                  page.index == previousPage.index,
            )
          : -1;
      final targetIndex = remappedIndex >= 0
          ? remappedIndex
          : _findSlidePageIndexByCharOffset(
              chapterIndex: currentChapterIndex,
              charOffset: book.durChapterPos,
            );
      final clampedIndex = targetIndex.clamp(0, slidePages.length - 1);
      final indexChanged = clampedIndex != currentPageIndex;
      currentPageIndex = clampedIndex;
      if (indexChanged) {
        requestJumpToPage(
          currentPageIndex,
          reason: ReaderCommandReason.system,
        );
      }
      return;
    }

    final merged = <TextPage>[];
    final chapterIndexes = <int>[
      if (currentChapterIndex > 0) currentChapterIndex - 1,
      currentChapterIndex,
      if (currentChapterIndex < chapters.length - 1) currentChapterIndex + 1,
    ];
    for (final chapterIndex in chapterIndexes) {
      final pages = chapterPagesCache[chapterIndex];
      if (pages != null && pages.isNotEmpty) {
        merged.addAll(pages);
      }
    }
    slidePages = merged;
    if (slidePages.isEmpty) {
      currentPageIndex = 0;
      return;
    }
    final remappedIndex = previousPage != null
        ? slidePages.indexWhere(
            (page) =>
                page.chapterIndex == previousPage.chapterIndex &&
                page.index == previousPage.index,
          )
        : -1;
    final targetIndex = remappedIndex >= 0
        ? remappedIndex
        : _findSlidePageIndexByCharOffset(
            chapterIndex: currentChapterIndex,
            charOffset: book.durChapterPos,
          );
    final clampedIndex = targetIndex.clamp(0, slidePages.length - 1);
    final indexChanged = clampedIndex != currentPageIndex;
    currentPageIndex = clampedIndex;
    if (indexChanged) {
      requestJumpToPage(
        currentPageIndex,
        reason: ReaderCommandReason.system,
      );
    }
  }

  int _findSlidePageIndexByCharOffset({
    required int chapterIndex,
    required int charOffset,
    bool fromEnd = false,
  }) {
    if (slidePages.isEmpty) return 0;
    if (fromEnd) {
      for (var i = slidePages.length - 1; i >= 0; i--) {
        if (slidePages[i].chapterIndex == chapterIndex) return i;
      }
      return slidePages.length - 1;
    }
    final localPageIndex = ChapterPositionResolver.findPageIndexByCharOffset(
      chapterPagesCache[chapterIndex] ?? const <TextPage>[],
      charOffset,
    );
    final globalIndex = slidePages.indexWhere(
      (page) => page.chapterIndex == chapterIndex && page.index == localPageIndex,
    );
    return globalIndex >= 0 ? globalIndex : 0;
  }

  void bootstrapChapterWindow(int centerIndex) {
    if (!hasContentManager) return;
    contentManager.updateWindow(
      centerIndex,
      preloadRadius: pageTurnMode == PageAnim.scroll ? _scrollPreloadRadius : 1,
      preload: !_isLocalScrollMode,
    );
    if (pageTurnMode == PageAnim.scroll) {
      _syncScrollWindowCache();
    }
  }

  void scheduleDeferredWindowWarmup(
    int centerIndex, {
    Duration delay = const Duration(milliseconds: 1500),
  }) {
    if (_isLocalScrollMode) return;
    _deferredWindowWarmupTimer?.cancel();
    _extendedWindowWarmupTimer?.cancel();
    _deferredWindowWarmupTimer = Timer(delay, () {
      if (!isDisposed && hasContentManager) {
        if (pageTurnMode == PageAnim.scroll &&
            contentManager.userInteractionActive) {
          scheduleDeferredWindowWarmup(
            visibleChapterIndex,
            delay: const Duration(milliseconds: 900),
          );
          return;
        }
        final warmupCenter =
            pageTurnMode == PageAnim.scroll ? visibleChapterIndex : centerIndex;
        if (pageTurnMode == PageAnim.scroll) {
          contentManager.warmupWindow(
            warmupCenter,
            preloadRadius: _scrollPreloadRadius,
          );
          if (_isLocalScrollMode) {
            unawaited(_loadAdjacentScrollChapters(warmupCenter));
          }
          return;
        }
        contentManager.warmChaptersAround(
            warmupCenter,
            radius: _isLocalBook ? 1 : 2,
        );
      }
    });
  }

  void triggerSilentPreload() {
    if (!hasContentManager) return;
    if (pageTurnMode == PageAnim.scroll) {
      if (_isLocalScrollMode) return;
      scheduleDeferredWindowWarmup(
        visibleChapterIndex,
        delay: const Duration(milliseconds: 900),
      );
      return;
    }
    final center = pageTurnMode == PageAnim.scroll
        ? visibleChapterIndex
        : currentChapterIndex;
    contentManager.updateWindow(
      center,
      preloadRadius: pageTurnMode == PageAnim.scroll
          ? _scrollPreloadRadius
          : (_isLocalBook ? 1 : 2),
    );
    contentManager.warmChaptersAround(
      center,
      radius: pageTurnMode == PageAnim.scroll
          ? _scrollPreloadRadius
          : (_isLocalBook ? 1 : 2),
    );
  }

  void updateScrollPreloadForVisibleChapter(int visibleChapter) {
    if (!hasContentManager || pageTurnMode != PageAnim.scroll) return;
    contentManager.updateWindow(
      visibleChapter,
      preloadRadius: _scrollPreloadRadius,
      preload: !_isLocalScrollMode,
    );
    _syncScrollWindowCache();
    final visiblePages = chapterPagesCache[visibleChapter];
    if ((visiblePages == null || visiblePages.isEmpty) &&
        !loadingChapters.contains(visibleChapter)) {
      unawaited(
        ensureChapterCached(
          visibleChapter,
          silent: false,
          prioritize: true,
          preloadRadius: 1,
        ),
      );
    }
    if (_isLocalScrollMode) {
      _scheduleAdjacentScrollLoad(visibleChapter, immediate: true);
    }
  }

  void setScrollInteractionActive(bool active) {
    if (!hasContentManager || pageTurnMode != PageAnim.scroll) return;
    contentManager.setUserInteractionActive(active);
    if (_isLocalScrollMode) return;
    if (!active) {
      scheduleDeferredWindowWarmup(
        visibleChapterIndex,
        delay: const Duration(milliseconds: 700),
      );
    }
  }

  void onPageChanged(int i) {
    if (i < 0 || i >= slidePages.length) return;
    currentPageIndex = i;
    final page = slidePages[i];
    currentChapterIndex = page.chapterIndex;
    visibleChapterIndex = page.chapterIndex;
    visibleChapterLocalOffset = ChapterPositionResolver.charOffsetToLocalOffset(
      chapterPagesCache[page.chapterIndex] ?? const <TextPage>[],
      ChapterPositionResolver.getCharOffsetForPage(
        chapterPagesCache[page.chapterIndex] ?? const <TextPage>[],
        page.index,
      ),
    );
    _refreshSlidePages();
    notifyListeners();
    final title = chapters.isNotEmpty ? chapters[currentChapterIndex].title : '';
    unawaited(
      bookDao.updateProgress(
        book.bookUrl,
        page.chapterIndex,
        title,
        ChapterPositionResolver.getCharOffsetForPage(
          chapterPagesCache[page.chapterIndex] ?? const <TextPage>[],
          page.index,
        ),
      ),
    );
  }

  void nextPage({
    ReaderCommandReason reason = ReaderCommandReason.user,
  }) {
    if (pageTurnMode == PageAnim.scroll) {
      final target = (visibleChapterIndex + 1).clamp(0, chapters.length - 1);
      if (target != visibleChapterIndex) {
        unawaited(nextChapter(reason: reason));
      }
      return;
    }
    if (currentPageIndex < slidePages.length - 1) {
      currentPageIndex++;
      (this as dynamic).jumpToSlidePage(
        currentPageIndex,
        reason: reason,
      );
      notifyListeners();
    } else {
      unawaited(nextChapter(reason: reason));
    }
  }

  void prevPage({
    ReaderCommandReason reason = ReaderCommandReason.user,
  }) {
    if (pageTurnMode == PageAnim.scroll) {
      final target = (visibleChapterIndex - 1).clamp(0, chapters.length - 1);
      if (target != visibleChapterIndex) {
        unawaited(prevChapter(reason: reason));
      }
      return;
    }
    if (currentPageIndex > 0) {
      currentPageIndex--;
      (this as dynamic).jumpToSlidePage(
        currentPageIndex,
        reason: reason,
      );
      notifyListeners();
    } else {
      unawaited(prevChapter(reason: reason));
    }
  }

  Future<void> nextChapter({
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
  }) async {
    final target = currentChapterIndex + 1;
    if (target < chapters.length) {
      book.durChapterPos = 0;
      await loadChapter(target, reason: reason);
    }
  }

  Future<void> prevChapter({
    bool fromEnd = true,
    ReaderCommandReason reason = ReaderCommandReason.chapterChange,
  }) async {
    final target = currentChapterIndex - 1;
    if (target >= 0) {
      if (!fromEnd) {
        book.durChapterPos = 0;
      }
      await loadChapter(target, fromEnd: fromEnd, reason: reason);
    }
  }

  Future<FetchResult> _fetchChapterData(int i) async {
    final chapter = chapters[i];
    debugPrint('Reader: Fetching content for chapter $i: ${chapter.title}');
    var raw = await ReaderPerfTrace.measureAsync(
      'fetch raw chapter $i',
      () => chapterDao.getContent(chapter.url),
    );
    if (raw == null) {
      if (book.origin == 'local') {
        raw = await ReaderPerfTrace.measureAsync(
          'local content chapter $i',
          () => LocalBookService().getContent(book, chapter),
        );
      } else {
        source ??= await sourceDao.getByUrl(book.origin);
        try {
          raw = await ReaderPerfTrace.measureAsync(
            'remote content chapter $i',
            () => service.getContent(source!, book, chapter),
          );
          if (raw?.isNotEmpty ?? false) {
            await chapterDao.saveContent(chapter.url, raw!);
          } else {
            raw = '章節內容為空 (可能解析規則有誤)';
          }
        } catch (e) {
          raw = '加載章節失敗: $e';
        }
      }
    }
    raw ??= '';

    _cachedRulesJson ??=
        (await replaceDao.getEnabled()).map((r) => r.toJson()).toList().cast<Map<String, dynamic>>();
    final rulesJson = _cachedRulesJson!;
    _cachedRulesSignature ??=
        sha1.convert(utf8.encode(jsonEncode(rulesJson))).toString();

    final processedCacheKey = _buildProcessedContentCacheKey(
      chapter: chapter,
      rawContent: raw,
      rulesSignature: _cachedRulesSignature!,
    );
    final cacheManager = _tryGetCacheManager();
    if (cacheManager != null) {
      final processedContent = await cacheManager.get(processedCacheKey);
      if (processedContent?.isNotEmpty ?? false) {
        return FetchResult(content: processedContent!);
      }
    }

    final BookContent bookContent = await ReaderPerfTrace.measureAsync(
      'process content chapter $i',
      () => engine.ContentProcessor.process(
        book: book,
        chapter: chapter,
        rawContent: raw!,
        rulesJson: rulesJson,
        chineseConvertType: chineseConvert,
        reSegmentEnabled: true,
      ),
    );

    if (cacheManager != null) {
      unawaited(
        cacheManager.put(
          processedCacheKey,
          bookContent.content,
          saveTimeSeconds: 60 * 60 * 24 * 30,
        ),
      );
    }
    return FetchResult(content: bookContent.content);
  }

  String _buildProcessedContentCacheKey({
    required BookChapter chapter,
    required String rawContent,
    required String rulesSignature,
  }) {
    final rawHash = sha1.convert(utf8.encode(rawContent)).toString();
    final titleHash = sha1.convert(utf8.encode(chapter.title)).toString();
    final digest = sha1
        .convert(
          utf8.encode(
            [
              book.bookUrl,
              chapter.url,
              chapter.index.toString(),
              chineseConvert.toString(),
              rulesSignature,
              titleHash,
              rawHash,
            ].join('|'),
          ),
        )
        .toString();
    return 'reader_processed_v2_$digest';
  }

  CacheManager? _tryGetCacheManager() {
    try {
      return CacheManager();
    } catch (_) {
      return null;
    }
  }

  void jumpToPosition({
    int? chapterIndex,
    int? charOffset,
    int? pageIndex,
    bool isRestoringJump = false,
  });

  void disposeContentManager() {
    _chapterReadySub?.cancel();
    _deferredWindowWarmupTimer?.cancel();
    _extendedWindowWarmupTimer?.cancel();
    _cachedRulesSignature = null;
    _localAdjacentLoadTimer?.cancel();
    chapterPagesCache.clear();
    slidePages = [];
    _contentManager?.dispose();
    _contentManager = null;
  }

  Set<int> _scrollWindowIndices(int centerChapterIndex) {
    if (chapters.isEmpty) return {};
    final start =
        (centerChapterIndex - _scrollPreloadRadius).clamp(0, chapters.length - 1).toInt();
    final end =
        (centerChapterIndex + _scrollPreloadRadius).clamp(0, chapters.length - 1).toInt();
    return {
      for (int i = start; i <= end; i++) i,
    };
  }

  bool _shouldNotifyChapterReady(int chapterIndex) {
    if (loadingChapters.contains(chapterIndex)) return true;
    final center = visibleChapterIndex;
    return (chapterIndex - center).abs() <= _scrollPreloadRadius ||
        (chapterIndex - currentChapterIndex).abs() <= _scrollPreloadRadius;
  }

  void _scheduleAdjacentScrollLoad(
    int centerIndex, {
    bool immediate = false,
  }) {
    _localAdjacentLoadTimer?.cancel();
    final delay = immediate ? Duration.zero : const Duration(milliseconds: 280);
    _localAdjacentLoadTimer = Timer(delay, () {
      if (isDisposed || !_isLocalScrollMode) return;
      unawaited(_loadAdjacentScrollChapters(centerIndex));
    });
  }

  Future<void> _loadAdjacentScrollChapters(int centerIndex) async {
    final direction = _lastVisibleScrollChapter == -1
        ? 1
        : (centerIndex - _lastVisibleScrollChapter).sign;
    _lastVisibleScrollChapter = centerIndex;
    final neighbors = <int>[
      if (direction >= 0) centerIndex + 1,
      if (direction <= 0) centerIndex - 1,
      if (direction >= 0) centerIndex - 1,
      if (direction <= 0) centerIndex + 1,
    ];

    for (final neighbor in neighbors.toSet()) {
      if (neighbor < 0 || neighbor >= chapters.length) continue;
      if (chapterPagesCache[neighbor]?.isNotEmpty ?? false) continue;
      if (loadingChapters.contains(neighbor)) continue;
      await _loadAndCacheChapter(neighbor, silent: true);
      break;
    }
  }

  void _syncScrollWindowCache() {
    if (!hasContentManager || pageTurnMode != PageAnim.scroll) return;
    final keep = contentManager.targetWindow;
    final evicted = contentManager.evictOutside(keep);
    for (final index in chapterPagesCache.keys.toList()) {
      if (evicted.contains(index)) {
        chapterPagesCache.remove(index);
      }
    }
    for (final index in evicted) {
      (this as dynamic).refreshChapterRuntime?.call(index);
    }
  }
}
