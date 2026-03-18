import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/models/book.dart';
import 'package:legado_reader/core/models/chapter.dart';
import 'package:legado_reader/core/models/book_source.dart';
import 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
import 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
import 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';
import 'package:legado_reader/shared/theme/app_theme.dart';
import 'package:legado_reader/core/models/bookmark.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'package:legado_reader/core/constant/page_anim.dart';

export 'package:legado_reader/features/reader/provider/reader_provider_base.dart';
export 'package:legado_reader/features/reader/provider/reader_settings_mixin.dart';
export 'package:legado_reader/features/reader/provider/reader_content_mixin.dart';

/// ReaderProvider - 閱讀器狀態管理 (效能優化版)
class ReaderProvider extends ReaderProviderBase with ReaderSettingsMixin, ReaderContentMixin {
  /// 儲存從資料庫讀取的初始字元偏移量
  int _initialCharOffset = 0;

  ReaderProvider({required Book book, int chapterIndex = 0, int chapterPos = 0}) : super(book) {
    currentChapterIndex = chapterIndex;
    _initialCharOffset = chapterPos;
    // 初始頁碼設為 0，直到恢復邏輯計算出真正的頁碼
    currentPageIndex = 0;
    _init();
  }

  Future<void> _init() async {
    await loadSettings();
    await _loadChapters();
    await _loadSource();

    if (isDisposed) return;

    // 標記正在恢復進度
    isRestoring = true;
    _pendingRestorePos = _initialCharOffset;

    // 關鍵優復：延後 200ms 啟動首章載入，避開 App 啟動時的 CPU 尖峰，解決 Skipped frames 問題
    await Future.delayed(const Duration(milliseconds: 200));
    if (isDisposed) return;

    await loadChapter(currentChapterIndex);

    if (isDisposed) return;
    
    // loadChapter 完成後會自動觸發 _applyPendingRestore
    _applyPendingRestore();

    _listenAudioEvents();
    _startHeartbeat();
    _initTtsListener();
  }

  // --- 捲動模式：追蹤精確滾動位置（供 dispose 時精確儲存進度）---
  double _lastScrollY = 0.0;
  Timer? _scrollSaveTimer;

  /// 延遲恢復的閱讀位置（charOffset）：_init 時 viewSize 尚未就緒，需等 doPaginate 後再恢復
  int? _pendingRestorePos;

  /// 由 ReaderViewBuilder 在每次捲動時呼叫，記錄最新 scroll offset
  void updateScrollOffset(double scrollY) {
    if (_lastScrollY == scrollY) return;
    _lastScrollY = scrollY;
    
    // 滾動時自動儲存進度（Debounce 500ms），確保「記得讀到哪一個句子」
    if (!isRestoring && !isLoading) {
      _scrollSaveTimer?.cancel();
      _scrollSaveTimer = Timer(const Duration(milliseconds: 500), () {
        if (!isDisposed) _saveProgress(currentChapterIndex, currentPageIndex);
      });
    }
  }

  /// showHead 時，ListView 頂部有 2px head
  double get _scrollHeadOffset =>
      (pages.isNotEmpty && pages.first.chapterIndex > 0) ? 2.0 : 0.0;

  // --- TTS 朗讀優化版 (流式長文本 + 精準高亮) ---
  int _currentTtsBaseOffset = 0; // 當前朗讀塊在章節中的起始偏移量
  bool stopAfterChapter = false;
  /// 取消旗標：stopTts() 後設為 true，防止 pending 的 nextChapter().then() 繼續執行
  bool _ttsCancelled = false;
  List<({int ttsOffset, int chapterOffset})> _ttsTextOffsetMap = [];
  
  // 預取下一頁內容，消除銜接停頓 (問題 5)
  String? _prefetchedTtsText;
  List<({int ttsOffset, int chapterOffset})>? _prefetchedOffsetMap;
  int _prefetchedBaseOffset = 0;

  int _ttsStart = -1;
  int _ttsEnd = -1;
  int get ttsStart => _ttsStart;
  int get ttsEnd => _ttsEnd;

  /// TTS 正在朗讀的章節索引：用於跨章節滾動模式中過濾高亮，防止多章節重複高亮
  int _ttsChapterIndex = -1;
  int get ttsChapterIndex => _ttsChapterIndex;

  // TTS 高亮快取：避免 progressUpdate 每次觸發都重新遍歷所有頁面行
  int _lastTtsHighlightStart = -1;
  int _lastTtsHighlightEnd = -1;

  // TTS 章節邊界預取：消除章節切換時的銜接停頓
  String? _prefetchedChapterTtsText;
  List<({int ttsOffset, int chapterOffset})>? _prefetchedChapterOffsetMap;
  int _prefetchedChapterBaseOffset = 0;

  void _initTtsListener() {
    TTSService().addListener(_onTtsProgressUpdate);
  }

  void _onTtsProgressUpdate() {
    if (!TTSService().isPlaying || _ttsTextOffsetMap.isEmpty) return;

    final rawStart = TTSService().currentWordStart;

    // 查表：將 TTS 字串位置映射到章節字元位置
    int chapterBase = _currentTtsBaseOffset;
    for (final entry in _ttsTextOffsetMap.reversed) {
      if (rawStart >= entry.ttsOffset) {
        chapterBase = entry.chapterOffset + (rawStart - entry.ttsOffset);
        break;
      }
    }

    // 快取命中：chapterBase 仍在上次高亮段落範圍內，跳過全頁掃描
    if (_lastTtsHighlightStart >= 0 &&
        chapterBase >= _lastTtsHighlightStart &&
        chapterBase < _lastTtsHighlightEnd) {
      return;
    }

    // 以段落為單位高亮（對標 Android upPageAloudSpan：整段一起標記）
    // 只掃描屬於目前 TTS 章節的頁面，避免跨章節時重複高亮相同 chapterPosition
    int hlStart = chapterBase;
    int hlEnd = chapterBase + 1;
    for (final page in pages) {
      if (_ttsChapterIndex >= 0 && page.chapterIndex != _ttsChapterIndex) continue;
      int? targetParagraphNum;
      for (final line in page.lines) {
        if (line.image != null) continue;
        final lEnd = line.chapterPosition + line.text.length;
        if (chapterBase >= line.chapterPosition && chapterBase < lEnd) {
          targetParagraphNum = line.paragraphNum;
          break;
        }
      }
      if (targetParagraphNum != null) {
        final paraLines = page.lines
            .where((l) => l.paragraphNum == targetParagraphNum && l.image == null)
            .toList();
        if (paraLines.isNotEmpty) {
          hlStart = paraLines.first.chapterPosition;
          hlEnd = paraLines.last.chapterPosition + paraLines.last.text.length;
        }
        break;
      }
    }

    _lastTtsHighlightStart = hlStart;
    _lastTtsHighlightEnd = hlEnd;

    if (_ttsStart != hlStart || _ttsEnd != hlEnd) {
      _ttsStart = hlStart;
      _ttsEnd = hlEnd;
      notifyListeners();
    }
  }

  /// 抽取文本與偏移映射建構邏輯，供 start 與 prefetch 共用
  (String, List<({int ttsOffset, int chapterOffset})>) _prepareTtsData(List<TextLine> lines) {
    final buffer = StringBuffer();
    final map = <({int ttsOffset, int chapterOffset})>[];
    int ttsPos = 0;
    int lastParagraphNum = -1;

    final List<TextLine> filteredLines = lines.where((l) => l.image == null).toList();

    for (final line in filteredLines) {
      if (lastParagraphNum != -1 && line.paragraphNum != lastParagraphNum) {
        buffer.write('\n');
        ttsPos += 1;
      }
      map.add((ttsOffset: ttsPos, chapterOffset: line.chapterPosition));
      buffer.write(line.text);
      ttsPos += line.text.length;
      lastParagraphNum = line.paragraphNum;
    }
    return (buffer.toString(), map);
  }

  void _prefetchNextPage() {
    final nextIdx = currentPageIndex + 1;
    if (nextIdx >= pages.length) {
      _prefetchedTtsText = null;
      // 已到最後一頁：嘗試預取下一章節第一頁的 TTS 文本
      _prefetchNextChapterTts();
      return;
    }
    final nextPage = pages[nextIdx];
    if (nextPage.lines.isEmpty) return;

    final (text, map) = _prepareTtsData(nextPage.lines);
    _prefetchedTtsText = text;
    _prefetchedOffsetMap = map;
    _prefetchedBaseOffset = nextPage.lines.first.chapterPosition;
  }

  /// 預取下一章節第一頁的 TTS 文本，消除章節切換時的停頓
  void _prefetchNextChapterTts() {
    final nextChapterIdx = currentChapterIndex + 1;
    if (nextChapterIdx >= chapters.length) return;

    final nextPages = chapterCache[nextChapterIdx];
    if (nextPages == null || nextPages.isEmpty) return;

    final firstPage = nextPages.first;
    final visibleLines = firstPage.lines.where((l) => l.image == null).toList();
    if (visibleLines.isEmpty) return;

    final (text, map) = _prepareTtsData(firstPage.lines);
    _prefetchedChapterTtsText = text;
    _prefetchedChapterOffsetMap = map;
    _prefetchedChapterBaseOffset = visibleLines.first.chapterPosition;
  }

  // --- 效能優化：精準更新屬性 ---
  bool isAutoPaging = false;
  double autoPageSpeed = 30.0; // 單位：秒/頁
  double textPadding = 16.0;
  
  int get batteryLevel => batteryLevelNotifier.value;
  double get autoPageProgress => autoPageProgressNotifier.value;

  Timer? _heartbeatTimer;
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      // 這裡可以透過插件獲取真實電量，目前先模擬
      batteryLevelNotifier.value = (batteryLevelNotifier.value - 1).clamp(0, 100);
    });
  }

  StreamSubscription? _audioEventSub;
  void _listenAudioEvents() {
    _audioEventSub?.cancel();
    _audioEventSub = TTSService().audioEvents.listen((event) {
      switch (event) {
        case 'onPlay':
          if (!TTSService().isPlaying) toggleTts();
          break;
        case 'onPause':
          if (TTSService().isPlaying) TTSService().pause();
          break;
        case 'onStop':
          _ttsStart = -1;
          _ttsEnd = -1;
          notifyListeners();
          break;
        case 'onSkipToNext':
          nextPageOrChapter();
          break;
        case 'onSkipToPrevious':
          prevPageOrChapter();
          break;
        case 'onComplete':
          _onTtsComplete();
          break;
      }
    });
  }

  void _onTtsComplete() {
    if (_ttsCancelled) return; // 使用者已按停止，不繼續推進頁面
    if (currentPageIndex < pages.length - 1) {
      final nextIdx = currentPageIndex + 1;
      // 直接更新索引，不呼叫 onPageChanged 避免雙重存進度
      // 分頁模式由 PageView 回呼負責 onPageChanged；捲動模式由 _scrollToTtsHighlight 處理
      currentPageIndex = nextIdx;
      if (pageTurnMode != PageAnim.scroll) jumpPageController.add(nextIdx);
      // 使用預取好的數據，消除銜接停頓；同時重置高亮快取
      _lastTtsHighlightStart = -1;
      _lastTtsHighlightEnd = -1;
      if (_prefetchedTtsText != null && _prefetchedOffsetMap != null) {
        _currentTtsBaseOffset = _prefetchedBaseOffset;
        _ttsTextOffsetMap = _prefetchedOffsetMap!;
        // 更新 TTS 章節索引（下一頁可能已跨章，例如滾動模式）
        if (nextIdx < pages.length) _ttsChapterIndex = pages[nextIdx].chapterIndex;
        TTSService().speak(_prefetchedTtsText!);
        _prefetchNextPage();
      } else {
        _startTts();
      }
    } else {
      // 最後一頁：優先使用章節邊界預取文本，減少停頓
      final chapterPrefetchText = _prefetchedChapterTtsText;
      final chapterPrefetchMap = _prefetchedChapterOffsetMap;
      final chapterPrefetchBase = _prefetchedChapterBaseOffset;
      _prefetchedChapterTtsText = null;
      _prefetchedChapterOffsetMap = null;

      nextChapter().then((_) {
        if (_ttsCancelled) return; // 使用者在章節載入途中按了停止，放棄繼續播放
        if (stopAfterChapter) {
          stopAfterChapter = false;
          TTSService().stop();
        } else {
          _lastTtsHighlightStart = -1;
          _lastTtsHighlightEnd = -1;
          if (chapterPrefetchText != null && chapterPrefetchMap != null) {
            _currentTtsBaseOffset = chapterPrefetchBase;
            _ttsTextOffsetMap = chapterPrefetchMap;
            if (pages.isNotEmpty && currentPageIndex < pages.length) {
              _ttsChapterIndex = pages[currentPageIndex].chapterIndex;
            }
            TTSService().speak(chapterPrefetchText);
            _prefetchNextPage();
          } else {
            _startTts();
          }
        }
      });
    }
  }

  Future<void> _loadChapters() async {
    chapters = await chapterDao.getChapters(book.bookUrl);
    notifyListeners();
  }

  Future<void> _loadSource() async {
    source = await sourceDao.getByUrl(book.origin);
  }

  /// 捲動模式：由 ReaderViewBuilder 在捲動時輕量更新當前可見頁（不寫 DB、不 notify）
  void updateScrollPageIndex(int i) {
    if (i < 0 || i >= pages.length) return;
    currentPageIndex = i;
    final pageChapterIndex = pages[i].chapterIndex;
    if (currentChapterIndex != pageChapterIndex) {
      currentChapterIndex = pageChapterIndex;
    }
  }

  void setViewSize(Size size) {
    if (viewSize == null) {
      viewSize = size;
      if (chapterContentCache.containsKey(currentChapterIndex)) {
        doPaginate().then((_) => _applyPendingRestore());
      } else if (pages.isEmpty && !isLoading && chapters.isNotEmpty) {
        loadChapter(currentChapterIndex);
      }
      return;
    }

    // 關鍵修復：如果尺寸變化非常小（例如 < 20 像素），忽略它。
    // 這通常是由於選單顯示/隱藏導致的微小佈局擠壓，不應觸發重新分頁。
    final double dw = (viewSize!.width - size.width).abs();
    final double dh = (viewSize!.height - size.height).abs();
    if (dw < 10 && dh < 20) return;

    if (viewSize != size) {
      viewSize = size;
      // 重新分頁，doPaginate 內部現在會自動嘗試恢復到先前的 charOffset
      if (chapterContentCache.containsKey(currentChapterIndex)) {
        doPaginate();
      }
    }
  }

  /// 統一跳轉定位邏輯 (核心方法)
  /// 無論是開書恢復、目錄跳轉、還是 TTS 追蹤，都經由此處
  void _jumpToPosition({int? charOffset, int? pageIndex, bool isRestoringJump = false}) {
    if (pages.isEmpty) return;
    
    if (isRestoringJump) isRestoring = true;

    if (pageTurnMode == PageAnim.scroll) {
      // 捲動模式：優先使用 charOffset 計算精確像素
      double targetPixels = 0.0;
      if (charOffset != null && charOffset > 0) {
        targetPixels = _calcScrollOffsetForCharOffset(charOffset);
      } else if (pageIndex != null) {
        targetPixels = _calcScrollOffsetForPageIndex(pageIndex);
      }
      
      scrollOffsetController.add(targetPixels);
      // 捲動模式跳轉後，ListView 會觸發監聽，進而更新 currentPageIndex
    } else {
      // 分頁模式：將 charOffset 轉換為頁碼
      int targetPage = 0;
      if (charOffset != null && charOffset > 0) {
        targetPage = _findPageIndexByCharOffset(charOffset);
      } else if (pageIndex != null) {
        targetPage = pageIndex.clamp(0, pages.length - 1);
      }
      
      currentPageIndex = targetPage;
      jumpPageController.add(targetPage);
      // 分頁模式跳轉後，由 ReaderViewBuilder 負責將 isRestoring 設為 false
    }
    
    if (pageTurnMode != PageAnim.scroll && !isRestoringJump) notifyListeners();
  }

  /// 根據頁碼計算捲動像素 (用於目錄跳轉等場景)
  double _calcScrollOffsetForPageIndex(int pageIndex) {
    if (pages.isEmpty || pageIndex <= 0) return 0.0;
    final headOffset = _scrollHeadOffset;
    double cumHeight = 0;
    for (int i = 0; i < pageIndex.clamp(0, pages.length - 1); i++) {
      final page = pages[i];
      cumHeight += page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
    }
    return headOffset + cumHeight;
  }

  /// 根據字元偏移量尋找對應頁碼
  int _findPageIndexByCharOffset(int charOffset) {
    int targetPage = 0;
    for (int i = 0; i < pages.length; i++) {
      final firstLineOffset = _getCharOffsetForPage(i);
      if (firstLineOffset <= charOffset) {
        targetPage = i;
      } else {
        break;
      }
    }
    return targetPage;
  }

  /// 延遲恢復閱讀位置：在 doPaginate() 完成後呼叫
  void _applyPendingRestore() {
    if (_pendingRestorePos == null || pages.isEmpty) return;
    final pos = _pendingRestorePos!;
    _pendingRestorePos = null;
    
    _jumpToPosition(charOffset: pos, isRestoringJump: true);
  }

  @override
  void onPageChanged(int i) {
    if (currentPageIndex != i) {
      currentPageIndex = i;
      notifyListeners();

      // 進度恢復期間不執行主動儲存，避免跳轉中的中間狀態覆蓋正確進度
      if (!isRestoring) {
        _saveProgress(currentChapterIndex, i);
      }

      // 積極預載入：剩餘 2 頁時即開始加載下一章，消除等待感
      if (i >= pages.length - 2 && !isLoading) {
        final lastPage = pages.lastOrNull;
        if (lastPage != null && lastPage.chapterIndex < chapters.length - 1) {
          // 靜默預載入下一章
          unawaited(_preloadChapterSilently(lastPage.chapterIndex + 1));
        }
      }
    }
  }

  /// 靜默預載入章節，供 onPageChanged 調用
  Future<void> _preloadChapterSilently(int chapterIndex) async {
    // 這裡直接調用 Mixin 提供的邏輯（如果有的話，或是手動實現）
    // 實際上 ReaderContentMixin 已經有 _preloadChapterSilently
    // 這裡我們確保它被正確觸發
    if (chapterIndex < 0 || chapterIndex >= chapters.length) return;
    if (chapterCache.containsKey(chapterIndex) || silentLoadingChapters.contains(chapterIndex)) return;
    
    // 調用 mixin 中的方法
    await (this as ReaderContentMixin).loadChapter(chapterIndex);
  }

  /// 統一進度儲存：同時更新 DB 與 in-memory book 物件
  /// durChapterPos 儲存字元偏移量（TextLine.chapterPosition），對標 Android Legado 行為
  /// 捲動模式：精確儲存視窗頂端可見行，而非頁首行（修正「向下移半個窗口」問題）
  void _saveProgress(int chapterIndex, int pageIndex) {
    final title = chapters.isNotEmpty && chapterIndex < chapters.length
        ? chapters[chapterIndex].title
        : null;
    final charOffset = (pageTurnMode == PageAnim.scroll)
        ? _getCharOffsetForScrollY(_lastScrollY)
        : _getCharOffsetForPage(pageIndex);
    book.durChapterIndex = chapterIndex;
    book.durChapterPos = charOffset;
    book.durChapterTitle = title;
    unawaited(bookDao.updateProgress(book.bookUrl, chapterIndex, title ?? '', charOffset));
  }

  /// 返回 [pageIndex] 頁第一個文字行的 chapterPosition（字元偏移量）
  int _getCharOffsetForPage(int pageIndex) {
    if (pages.isEmpty || pageIndex < 0 || pageIndex >= pages.length) return 0;
    for (final line in pages[pageIndex].lines) {
      if (line.image == null) return line.chapterPosition;
    }
    return 0;
  }

  /// 計算捲動模式下 charOffset 對應的像素 Y 位置（用於開書恢復捲動位置）
  /// 包含 showHead 的 2px 偏移
  double _calcScrollOffsetForCharOffset(int charOffset) {
    final headOffset = _scrollHeadOffset;
    double cumHeight = 0;
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
      for (final line in page.lines) {
        if (line.image == null && line.chapterPosition >= charOffset) {
          return (headOffset + cumHeight + line.lineTop).clamp(0.0, double.infinity);
        }
      }
      cumHeight += pageHeight;
    }
    return headOffset + cumHeight;
  }

  /// 捲動模式：由實際 scroll offset 反算視窗頂端第一個可見行的 chapterPosition
  /// 修正「向下移半個窗口」問題：儲存視窗頂端行而非頁首行
  int _getCharOffsetForScrollY(double scrollY) {
    if (pages.isEmpty) return 0;
    final headOffset = _scrollHeadOffset;
    double cumHeight = 0;
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
      for (final line in page.lines) {
        if (line.image != null) continue;
        // 行的底部絕對 Y（包含 headOffset）
        final lineAbsBottom = headOffset + cumHeight + line.lineBottom;
        if (lineAbsBottom > scrollY) {
          return line.chapterPosition;
        }
      }
      cumHeight += pageHeight;
    }
    return _getCharOffsetForPage(0);
  }

  @override
  void dispose() {
    // 退出閱讀器時確保當前進度已儲存
    // 若 TTS 正在播放，保存朗讀位置而非頁面/捲動位置
    if (TTSService().isPlaying || _ttsStart >= 0) {
      TTSService().stop();
      if (_ttsStart >= 0) {
        book.durChapterIndex = currentChapterIndex;
        book.durChapterPos = _ttsStart;
        final title = chapters.isNotEmpty && currentChapterIndex < chapters.length
            ? chapters[currentChapterIndex].title : '';
        book.durChapterTitle = title;
        unawaited(bookDao.updateProgress(book.bookUrl, currentChapterIndex, title, _ttsStart));
      } else {
        _saveProgress(currentChapterIndex, currentPageIndex);
      }
    } else {
      _saveProgress(currentChapterIndex, currentPageIndex);
    }
    _scrollSaveTimer?.cancel();
    _heartbeatTimer?.cancel();
    _autoPageTimer?.cancel();
    _audioEventSub?.cancel();
    TTSService().removeListener(_onTtsProgressUpdate);
    super.dispose();
  }

  void toggleControls() {
    showControls = !showControls;
    // 菜單彈出時暫停自動翻頁，收起時恢復（對標 Android onMenuShow）
    if (showControls) {
      pauseAutoPage();
    } else {
      resumeAutoPage();
    }
    notifyListeners();
  }

  /// 取得下一頁資料，用於分頁模式掃描線效果
  TextPage? get nextPageForAutoPage {
    if (!isAutoPaging || pageTurnMode == PageAnim.scroll) return null;
    final nextIdx = currentPageIndex + 1;
    if (nextIdx < pages.length) return pages[nextIdx];
    return null;
  }

  ReadingTheme get currentTheme => AppTheme.readingThemes[themeIndex.clamp(0, AppTheme.readingThemes.length - 1)];

  String get currentChapterTitle => chapters.isNotEmpty ? chapters[currentChapterIndex].title : '';
  String get currentChapterUrl => chapters.isNotEmpty ? chapters[currentChapterIndex].url : '';

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

  BookChapter? get currentChapter => chapters.isNotEmpty && currentChapterIndex < chapters.length ? chapters[currentChapterIndex] : null;
  bool get isBookmarked => false; // 這裡可以進一步實作查詢
  int get ttsMode => 0; 
  double get rate => TTSService().rate;

  Stream<int> get jumpPageStream => jumpPageController.stream;

  // --- 進度條拖動邏輯 ---
  bool isScrubbing = false;
  int scrubIndex = 0;

  void onScrubStart() {
    isScrubbing = true;
    scrubIndex = currentChapterIndex;
    notifyListeners();
  }

  void onScrubbing(dynamic value) {
    int targetIndex;
    if (value is double) {
      targetIndex = (value * (chapters.length - 1)).round();
    } else {
      targetIndex = value;
    }
    if (scrubIndex != targetIndex) {
      scrubIndex = targetIndex;
      notifyListeners();
    }
  }

  void onScrubEnd(dynamic value) {
    isScrubbing = false;
    int targetIndex;
    if (value is double) {
      targetIndex = (value * (chapters.length - 1)).round();
    } else {
      targetIndex = value;
    }
    loadChapter(targetIndex);
    notifyListeners();
  }

  void jumpToPage(int index) {
    if (index >= 0 && index < pages.length) {
      onPageChanged(index);
    }
  }

  Future<void> toggleBookmark() async {
    // Simple toggle: check if bookmark exists at current chapter and pos
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
      chapterContentCache[index] = content;
      notifyListeners();
    }
  }

  Future<void> jumpToChapter(int index) async {
    if (index >= 0 && index < chapters.length) {
      await loadChapter(index);
    }
  }

  void setChineseConvert(int val) {
    chineseConvert = val;
    saveSetting('chinese_convert_v2', val);
    clearReaderCache();
    loadChapter(currentChapterIndex);
  }

  void setTtsMode(int val) {
    saveSetting('tts_mode', val);
    notifyListeners();
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

  // --- TTS 跳轉與功能核心 ---
  void nextPageOrChapter() {
    _ttsCancelled = false;
    if (currentPageIndex < pages.length - 1) {
      onPageChanged(currentPageIndex + 1);
      _startTts();
    } else {
      nextChapter().then((_) {
        if (!_ttsCancelled) _startTts();
      });
    }
    notifyListeners();
  }

  void prevPageOrChapter() {
    _ttsCancelled = false;
    if (currentPageIndex > 0) {
      onPageChanged(currentPageIndex - 1);
      _startTts();
    } else {
      prevChapter().then((_) {
        if (!_ttsCancelled) _startTts();
      });
    }
    notifyListeners();
  }

  void setStopAfterChapter(bool val) {
    stopAfterChapter = val;
    notifyListeners();
  }

  void stopTts() {
    _ttsCancelled = true; // 取消所有 pending 的 nextChapter().then() 回調
    TTSService().stop();
    _ttsStart = -1;
    _ttsEnd = -1;
    _ttsChapterIndex = -1;
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    _prefetchedTtsText = null;
    _prefetchedOffsetMap = null;
    _prefetchedChapterTtsText = null;
    _prefetchedChapterOffsetMap = null;
    notifyListeners();
  }

  void startTtsFromLine(int lineIndex) {
    _ttsCancelled = false; // 重置取消旗標
    TTSService().stop(); // 切換行時需徹底重新建構塊
    _ttsStart = -1;
    _ttsEnd = -1;
    _ttsChapterIndex = -1;
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    _startTts(startLineIndex: lineIndex);
    notifyListeners();
  }

  void toggleTts() {
    if (TTSService().isPlaying) {
      TTSService().pause();
    } else if (_ttsStart >= 0) {
      TTSService().resume(); // 恢復
    } else {
      if (pages.isEmpty || isLoading) return; // 頁面未就緒時不啟動
      _ttsCancelled = false; // 重置取消旗標，開始新一輪朗讀
      _startTts();
    }
    notifyListeners();
  }

  void _startTts({int startLineIndex = -1}) async {
    if (_ttsCancelled) return; // 取消旗標已設，不啟動新朗讀
    if (pages.isEmpty) return;
    if (isAutoPaging) stopAutoPage(); // TTS 與自動翻頁互斥

    // 決定起始頁與起始行
    int pageIdx = currentPageIndex.clamp(0, pages.length - 1);
    int lineIdx = startLineIndex >= 0 ? startLineIndex : 0;

    // 捲動模式且未指定特定行：從視口頂端可見行開始，而非頁首
    if (pageTurnMode == PageAnim.scroll && startLineIndex < 0) {
      (pageIdx, lineIdx) = _getScrollModeTtsStart();
    }

    if (pageIdx >= pages.length) return;
    final page = pages[pageIdx];
    if (page.lines.isEmpty) return;

    final linesToRead = page.lines.sublist(lineIdx).where((l) => l.image == null).toList();
    if (linesToRead.isEmpty) {
      // 純圖片頁面：自動跳到下一頁重試
      if (currentPageIndex < pages.length - 1) {
        currentPageIndex++;
        _startTts();
      }
      return;
    }

    final (text, map) = _prepareTtsData(linesToRead);
    if (text.trim().isEmpty) return;

    // 重置高亮快取，確保新一輪朗讀正確高亮第一段；設定朗讀章節以防跨章多重高亮
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    _ttsChapterIndex = page.chapterIndex;
    _currentTtsBaseOffset = linesToRead.first.chapterPosition;
    _ttsTextOffsetMap = map;

    await TTSService().speak(text);
    TTSService().updateMediaInfo(title: book.name, author: book.author);
    _prefetchNextPage(); // 開始朗讀當前頁後，立即預取下一頁（含跨章節邊界）
    notifyListeners();
  }

  /// 捲動模式：從目前視口頂端可見行開始 TTS，而非從當前「頁」的第一行
  (int pageIdx, int lineIdx) _getScrollModeTtsStart() {
    if (pages.isEmpty) return (0, 0);
    final headOffset = _scrollHeadOffset;
    double cumHeight = 0;
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
      for (int j = 0; j < page.lines.length; j++) {
        final line = page.lines[j];
        if (line.image != null) continue;
        final lineAbsBottom = headOffset + cumHeight + line.lineBottom;
        if (lineAbsBottom > _lastScrollY) return (i, j);
      }
      cumHeight += pageHeight;
    }
    return (currentPageIndex.clamp(0, pages.length - 1), 0);
  }

  // --- 自動翻頁穩定版 (對標 Android AutoPager) ---
  Timer? _autoPageTimer;
  bool _isAutoPagePaused = false;
  
  bool get isAutoPagePaused => _isAutoPagePaused;

  void toggleAutoPage() {
    isAutoPaging = !isAutoPaging;
    if (isAutoPaging) {
      // 自動翻頁與 TTS 互斥
      if (TTSService().isPlaying || _ttsStart >= 0) stopTts();
      _isAutoPagePaused = false;
      _startAutoPage();
      // 這裡可以呼叫 WakelockPlus 保持螢幕常亮
    } else {
      stopAutoPage();
    }
    notifyListeners();
  }

  /// 手動操作時暫停 (對標 Android onMenuShow/onTouch)
  void pauseAutoPage() {
    if (isAutoPaging && !_isAutoPagePaused) {
      _isAutoPagePaused = true;
      notifyListeners();
    }
  }

  /// 手動操作結束後恢復
  void resumeAutoPage() {
    if (isAutoPaging && _isAutoPagePaused) {
      _isAutoPagePaused = false;
      notifyListeners();
    }
  }

  void _startAutoPage() {
    _autoPageTimer?.cancel();
    autoPageProgressNotifier.value = 0.0;
    
    // 採用 16ms (約 60fps) 的高頻 tick 以支援像素級平滑捲動，同時兼容分頁模式
    _autoPageTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_isAutoPagePaused || !isAutoPaging) return;
      if (TTSService().isPlaying) return; // TTS 播放中不自動翻頁

      // 如果是分頁模式 (pageTurnMode != PageAnim.scroll)，則按時間進度翻頁
      if (pageTurnMode != PageAnim.scroll) {
        final double delta = 0.016 / autoPageSpeed.clamp(1.0, 600.0);
        autoPageProgressNotifier.value += delta;

        if (autoPageProgressNotifier.value >= 1.0) {
          autoPageProgressNotifier.value = 0.0;
          nextPage();
        }
      } else {
        // 捲動模式由 ReaderViewBuilder 根據 isAutoPaging 狀態自行處理像素累加
        // 這裡僅更新進度條（假設一頁高度為基準）
        final double delta = 0.016 / autoPageSpeed.clamp(1.0, 600.0);
        autoPageProgressNotifier.value = (autoPageProgressNotifier.value + delta) % 1.0;
      }
    });
  }

  void setAutoPageSpeed(double speed) {
    autoPageSpeed = speed;
    if (isAutoPaging) _startAutoPage();
    notifyListeners();
  }

  void stopAutoPage() {
    isAutoPaging = false;
    _isAutoPagePaused = false;
    _autoPageTimer?.cancel();
    _autoPageTimer = null;
    autoPageProgressNotifier.value = 0.0;
    notifyListeners();
  }

  void setClickAction(int zone, int action) {
    clickActions[zone] = action;
    saveSetting('click_actions', clickActions.join(','));
    notifyListeners();
  }

  @override
  Future<void> doPaginate({bool fromEnd = false}) async {
    await super.doPaginate(fromEnd: fromEnd);
    // 重新分頁後重置 TTS 高亮快取，確保下次進度更新重新掃描新的頁面佈局
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
  }
}
