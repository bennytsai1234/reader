import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/features/reader/engine/chapter_position_resolver.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/features/reader/provider/reader_auto_page_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_progress_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
import 'package:legado_reader/features/reader/runtime/models/reader_chapter.dart';
import 'package:legado_reader/features/reader/runtime/read_aloud_controller.dart';
import 'package:legado_reader/features/reader/runtime/reader_chapter_provider.dart';
import 'package:legado_reader/features/reader/runtime/reader_page_factory.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadBookController extends ReaderProviderBase
    with
        ReaderSettingsMixin,
        ReaderContentMixin,
        ReaderProgressMixin,
        ReaderAutoPageMixin,
        WidgetsBindingObserver {
  List<String> _chapterDisplayTitles = const [];
  final Map<int, ReaderChapter> _chapterRuntimeCache = {};
  final ReaderChapterProvider _chapterProvider = const ReaderChapterProvider();
  late final ReadAloudController _readAloudController;
  int _ttsMode = 0;
  bool _initialSessionPrimed = false;
  DateTime? _ignoreViewportChangesUntil;

  ReadBookController({
    required Book book,
    int chapterIndex = 0,
    int chapterPos = 0,
  }) : super(book) {
    currentChapterIndex = chapterIndex;
    visibleChapterIndex = chapterIndex;
    initialCharOffset = chapterPos;
    _readAloudController = ReadAloudController(
      tts: TTSService(),
      nextChapter: nextChapter,
      prevChapter: ({bool fromEnd = true}) => prevChapter(fromEnd: fromEnd),
      nextPage: () async {
        if (currentPageIndex < slidePages.length - 1) {
          onPageChanged(currentPageIndex + 1);
        }
      },
      prevPage: () async {
        if (currentPageIndex > 0) {
          onPageChanged(currentPageIndex - 1);
        }
      },
      canMoveToNextPage: () => currentPageIndex >= 0 && currentPageIndex < slidePages.length - 1,
      canMoveToPrevPage: () => currentPageIndex > 0,
      requestJumpToPage: (pageIndex) {
        final chapterIndex =
            ttsChapterIndex >= 0 ? ttsChapterIndex : currentChapterIndex;
        final globalIndex = pageFactory.globalPageIndexFor(
          chapterIndex: chapterIndex,
          localPageIndex: pageIndex,
        );
        if (globalIndex != null && globalIndex >= 0) {
          requestJumpToPage(globalIndex);
        }
      },
      requestJumpToChapter: ({
        required int chapterIndex,
        required double alignment,
        required double localOffset,
      }) {
        requestJumpToChapter(
          chapterIndex: chapterIndex,
          alignment: alignment,
          localOffset: localOffset,
        );
      },
      chapterOf: chapterAt,
      currentChapterIndex: () => currentChapterIndex,
      visibleChapterIndex: () => visibleChapterIndex,
      currentCharOffset: () {
        if (pageTurnMode == PageAnim.scroll) {
          final pages = pagesForChapter(visibleChapterIndex);
          return ChapterPositionResolver.localOffsetToCharOffset(
            pages,
            visibleChapterLocalOffset,
          );
        }
        if (currentPageIndex >= 0 && currentPageIndex < slidePages.length) {
          final page = slidePages[currentPageIndex];
          final chapterPages = pagesForChapter(page.chapterIndex);
          return ChapterPositionResolver.getCharOffsetForPage(
            chapterPages,
            page.index,
          );
        }
        return book.durChapterPos;
      },
      visibleCharOffset: () {
        final pages = pagesForChapter(visibleChapterIndex);
        return ChapterPositionResolver.localOffsetToCharOffset(
          pages,
          visibleChapterLocalOffset,
        );
      },
      isScrollMode: () => pageTurnMode == PageAnim.scroll,
      onStateChanged: () {
        if (!isDisposed) notifyListeners();
      },
      updateMediaInfo: (title, author) {
        TTSService().updateMediaInfo(
          title: title.isEmpty ? book.name : title,
          author: author.isEmpty ? book.author : author,
        );
      },
    );
    _init();
  }

  ReaderChapter? chapterAt(int index) => _chapterRuntimeCache[index];
  ReaderChapter? get prevChapterRuntime => chapterAt(currentChapterIndex - 1);
  ReaderChapter? get curChapterRuntime => chapterAt(currentChapterIndex);
  ReaderChapter? get nextChapterRuntime => chapterAt(currentChapterIndex + 1);
  List<TextPage> pagesForChapter(int index) =>
      chapterAt(index)?.pages ?? chapterPagesCache[index] ?? const <TextPage>[];
  bool hasRuntimeChapter(int index) => chapterAt(index) != null;

  ReaderPageFactory get pageFactory => ReaderPageFactory(
        prevChapter: prevChapterRuntime,
        currentChapter: curChapterRuntime,
        nextChapter: nextChapterRuntime,
        chapterCharOffset: book.durChapterPos,
      );

  int get ttsStart => _readAloudController.ttsStart;
  int get ttsEnd => _readAloudController.ttsEnd;
  int get ttsChapterIndex => _readAloudController.ttsChapterIndex;
  bool get isTtsActive => _readAloudController.isActive;
  bool get stopAfterChapter => _readAloudController.stopAfterChapter;

  void refreshChapterRuntime(int index) {
    final pages = chapterPagesCache[index];
    if (pages == null || pages.isEmpty || index < 0 || index >= chapters.length) {
      _chapterRuntimeCache.remove(index);
      return;
    }
    _chapterRuntimeCache[index] = _chapterProvider.buildFromPages(
      chapter: chapters[index],
      chapterIndex: index,
      title: displayChapterTitleAt(index),
      pages: pages,
    );
  }

  void refreshAllChapterRuntime() {
    _chapterRuntimeCache.clear();
    for (final entry in chapterPagesCache.entries) {
      refreshChapterRuntime(entry.key);
    }
  }

  Future<void> _init() async {
    WidgetsBinding.instance.addObserver(this);
    lifecycle = ReaderLifecycle.loading;
    await Future.wait([
      loadSettings(),
      _loadReadAloudPreferences(),
      _loadChapters(),
      _loadSource(),
    ]);
    if (isDisposed) return;

    initContentManager();
    onSettingsChangedRepaginate = () {
      updatePaginationConfig();
      doPaginate();
    };

    lifecycle = ReaderLifecycle.restoring;
    pendingRestorePos = initialCharOffset;
    if (viewSize != null) {
      await _primeInitialWindow();
    }
    _startHeartbeat();
    _readAloudController.attach();
  }

  Timer? _heartbeatTimer;
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      batteryLevelNotifier.value =
          (batteryLevelNotifier.value - 1).clamp(0, 100);
    });
  }

  Future<void> _loadChapters() async {
    chapters = await chapterDao.getChapters(book.bookUrl);
    if (isDisposed) return;
    _chapterDisplayTitles = chapters.map((chapter) => chapter.title).toList();
    if (!isDisposed) notifyListeners();
  }

  Future<void> _loadSource() async {
    source = await sourceDao.getByUrl(book.origin);
  }

  Future<void> _loadReadAloudPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _ttsMode = prefs.getInt('reader_tts_mode') ?? 0;
  }

  double textPadding = 16.0;
  int get batteryLevel => batteryLevelNotifier.value;
  double get autoPageProgress => autoPageProgressNotifier.value;

  void setViewSize(Size size) {
    if (viewSize == null) {
      viewSize = size;
      if (!hasContentManager) return;
      updatePaginationConfig();
      if (!_initialSessionPrimed) {
        unawaited(_primeInitialWindow());
        return;
      }
      if (contentManager.getCachedContent(currentChapterIndex) != null &&
          (chapterPagesCache[currentChapterIndex]?.isEmpty ?? true)) {
        unawaited(doPaginate().then((_) => applyPendingRestore()));
      }
      return;
    }

    if (_shouldIgnoreViewSizeChange(size)) return;

    viewSize = size;
    if (hasContentManager &&
        contentManager.getCachedContent(currentChapterIndex) != null) {
      unawaited(doPaginate());
    }
  }

  @override
  void onPageChanged(int i) {
    if (pageTurnMode == PageAnim.scroll) return;
    if (i < 0 || i >= slidePages.length) return;

    super.onPageChanged(i);
    if (!isRestoring) {
      saveProgress(currentChapterIndex, i);
    }
    if (i >= slidePages.length - 2 && !isLoading) {
      triggerSilentPreload();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (isTtsActive) {
      saveTtsProgress();
    } else {
      saveProgress(currentChapterIndex, currentPageIndex);
    }
    scrollSaveTimer?.cancel();
    _heartbeatTimer?.cancel();
    autoPageTimer?.cancel();
    _readAloudController.detach();
    disposeContentManager();
    super.dispose();
  }

  void toggleControls() {
    _guardTransientViewportChanges();
    showControls = !showControls;
    if (showControls) {
      pauseAutoPage();
    } else {
      resumeAutoPage();
    }
    notifyListeners();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      if (!isDisposed) {
        if (isTtsActive) {
          saveTtsProgress();
        } else {
          saveProgress(currentChapterIndex, currentPageIndex);
        }
      }
    }
  }

  TextPage? get nextPageForAutoPage {
    if (!isAutoPaging || pageTurnMode == PageAnim.scroll) return null;
    final nextIdx = currentPageIndex + 1;
    if (nextIdx < slidePages.length) return slidePages[nextIdx];
    return null;
  }

  ReadingTheme get currentTheme => AppTheme.readingThemes[
      themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];

  String get currentChapterTitle => displayChapterTitleAt(currentChapterIndex);
  String get currentChapterUrl =>
      chapters.isNotEmpty ? chapters[currentChapterIndex].url : '';

  String displayChapterTitleAt(int index) {
    if (index < 0 || index >= chapters.length) return '';
    if (index < _chapterDisplayTitles.length &&
        _chapterDisplayTitles[index].isNotEmpty) {
      return _chapterDisplayTitles[index];
    }
    return chapters[index].title;
  }

  TTSService get tts => TTSService();

  double backgroundBlur = 0.0;
  void setBackgroundBlur(double v) {
    backgroundBlur = v;
    notifyListeners();
  }

  void setBackgroundImage(String? path) {
    currentTheme.backgroundImage = path;
    notifyListeners();
  }

  BookChapter? get currentChapter =>
      chapters.isNotEmpty && currentChapterIndex < chapters.length
          ? chapters[currentChapterIndex]
          : null;
  bool get isBookmarked => false;
  int get ttsMode => _ttsMode;
  double get rate => TTSService().rate;
  bool isScrubbing = false;
  int scrubIndex = 0;

  void onScrubStart() {
    isScrubbing = true;
    scrubIndex = currentChapterIndex;
    notifyListeners();
  }

  void onScrubbing(dynamic value) {
    final targetIndex = value is double
        ? (value * (chapters.length - 1)).round()
        : value as int;
    if (scrubIndex != targetIndex) {
      scrubIndex = targetIndex;
      notifyListeners();
    }
  }

  void onScrubEnd(dynamic value) {
    isScrubbing = false;
    final targetIndex = value is double
        ? (value * (chapters.length - 1)).round()
        : value as int;
    unawaited(jumpToChapter(targetIndex));
    notifyListeners();
  }

  void jumpToPage(int index) {
    if (index >= 0 && index < slidePages.length) {
      onPageChanged(index);
    }
  }

  Future<void> toggleBookmark() async {
    addBookmark();
  }

  void addBookmark({String? content}) {
    final bookmark = Bookmark(
      time: DateTime.now().millisecondsSinceEpoch,
      bookName: book.name,
      bookAuthor: book.author,
      bookUrl: book.bookUrl,
      chapterIndex: currentChapterIndex,
      chapterName: chapters[currentChapterIndex].title,
      chapterPos: currentPageIndex,
      bookText: content ?? '',
    );
    bookmarkDao.upsert(bookmark);
    notifyListeners();
  }

  void replaceChapterSource(int index, BookSource source, String content) {
    if (index >= 0 && index < chapters.length) {
      chapters[index].content = content;
      contentManager.putContent(index, content);
      chapterPagesCache.remove(index);
      _chapterRuntimeCache.remove(index);
      if (index == currentChapterIndex) {
        unawaited(loadChapter(index));
      }
      notifyListeners();
    }
  }

  Future<void> jumpToChapter(int index) async {
    if (index >= 0 && index < chapters.length) {
      book.durChapterPos = 0;
      await loadChapter(index);
    }
  }

  void setChineseConvert(int val) {
    chineseConvert = val;
    saveSetting('chinese_convert_v2', val);
    disposeContentManager();
    initContentManager();
    updatePaginationConfig();
    unawaited(loadChapter(currentChapterIndex));
  }

  void setTtsMode(int val) {
    _ttsMode = val;
    saveSetting('tts_mode', val);
    notifyListeners();
  }

  void setStopAfterChapter(bool val) {
    _readAloudController.setStopAfterChapter(val);
  }

  void setTtsRate(double val) {
    TTSService().setRate(val);
    saveSetting('tts_rate', val);
    notifyListeners();
  }

  void setTtsPitch(double val) {
    TTSService().setPitch(val);
    saveSetting('tts_pitch', val);
    notifyListeners();
  }

  void setTtsLanguage(String lang) {
    TTSService().setLanguage(lang);
    saveSetting('tts_language', lang);
    notifyListeners();
  }

  void setClickAction(int zone, int action) {
    clickActions[zone] = action;
    saveSetting('click_actions', clickActions.join(','));
    notifyListeners();
  }

  List<TextPage> buildSlideRuntimePages() {
    return pageFactory.windowPages;
  }

  @override
  Future<void> doPaginate({bool fromEnd = false}) async {
    await super.doPaginate(fromEnd: fromEnd);
    refreshAllChapterRuntime();
  }

  Future<void> _primeInitialWindow() async {
    if (_initialSessionPrimed || isDisposed || !hasContentManager || viewSize == null) {
      return;
    }
    _initialSessionPrimed = true;
    final initialPreloadRadius =
        pageTurnMode == PageAnim.scroll && book.origin == 'local' ? 1 : 0;
    await loadChapterWithPreloadRadius(
      currentChapterIndex,
      preloadRadius: pageTurnMode == PageAnim.scroll ? initialPreloadRadius : 1,
    );
    if (isDisposed) return;
    bootstrapChapterWindow(currentChapterIndex);
    applyPendingRestore();
    scheduleDeferredWindowWarmup(currentChapterIndex);
  }

  bool _shouldIgnoreViewSizeChange(Size size) {
    final currentSize = viewSize;
    if (currentSize == null) return false;
    final dw = (currentSize.width - size.width).abs();
    final dh = (currentSize.height - size.height).abs();
    if (dw < 12 && dh < 24) return true;
    if (dw < 1 && dh < 96) return true;
    final guardUntil = _ignoreViewportChangesUntil;
    if (guardUntil != null && DateTime.now().isBefore(guardUntil)) {
      return dw < 64 && dh < 180;
    }
    return false;
  }

  void _guardTransientViewportChanges() {
    _ignoreViewportChangesUntil = DateTime.now().add(
      const Duration(milliseconds: 500),
    );
  }

  void toggleTts() {
    if (isAutoPaging) stopAutoPage();
    _readAloudController.toggle();
  }

  void startTtsFromLine(int lineIndex) {
    if (isAutoPaging) stopAutoPage();
    _readAloudController.startFromLine(lineIndex);
  }

  void stopTts() {
    _readAloudController.stop();
  }

  Future<void> nextPageOrChapter() {
    return _readAloudController.nextPageOrChapter();
  }

  Future<void> prevPageOrChapter() {
    return _readAloudController.prevPageOrChapter();
  }

  void saveTtsProgress() {
    unawaited(_readAloudController.saveProgress(
      persist: (chapterIndex, charOffset) {
        book.durChapterIndex = chapterIndex;
        book.durChapterPos = charOffset;
        final title = chapters.isNotEmpty && chapterIndex < chapters.length
            ? chapters[chapterIndex].title
            : '';
        book.durChapterTitle = title;
        unawaited(bookDao.updateProgress(
          book.bookUrl,
          chapterIndex,
          title,
          charOffset,
        ));
      },
    ));
  }
}
