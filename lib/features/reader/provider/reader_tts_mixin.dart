import 'dart:async';
import 'package:flutter/material.dart';
import 'package:legado_reader/core/constant/page_anim.dart';
import 'package:legado_reader/core/services/tts_service.dart';
import 'package:legado_reader/features/reader/engine/text_page.dart';
import 'reader_provider_base.dart';
import 'reader_settings_mixin.dart';
import 'reader_content_mixin.dart';
import 'reader_progress_mixin.dart';

/// ReaderProvider 的 TTS 朗讀擴展
/// 負責：TTS 控制、高亮追蹤、預取機制、章節邊界銜接
mixin ReaderTtsMixin on ReaderProviderBase, ReaderSettingsMixin, ReaderContentMixin, ReaderProgressMixin {
  int _currentTtsBaseOffset = 0; // 當前朗讀塊在章節中的起始偏移量
  bool stopAfterChapter = false;
  /// 取消旗標：stopTts() 後設為 true，防止 pending 的 nextChapter().then() 繼續執行
  bool _ttsCancelled = false;
  /// 防止 iOS flutter_tts 重複 didFinish 導致 _onTtsComplete 重入
  bool _ttsCompleteProcessing = false;
  List<({int ttsOffset, int chapterOffset})> _ttsTextOffsetMap = [];

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

  StreamSubscription? audioEventSub;

  /// TTS 絕對錨點：記住「目前讀到哪個章節的哪個字元之後」
  /// 完全不依賴 currentPageIndex，使用者滑動頁面不會影響這兩個值
  int _ttsAnchorChapterIdx = -1;
  int _ttsAnchorEndCharPos = 0;

  /// 預取下一章節的錨點資訊
  int _prefetchedChapterAnchorChapterIdx = -1;
  int _prefetchedChapterAnchorEndCharPos = 0;

  void initTtsListener() {
    TTSService().addListener(_onTtsProgressUpdate);
  }

  /// 移除 TTS 進度監聽（dispose 時呼叫），與 initTtsListener 成對
  void disposeTtsListener() {
    TTSService().removeListener(_onTtsProgressUpdate);
  }

  void listenAudioEvents() {
    audioEventSub?.cancel();
    audioEventSub = TTSService().audioEvents.listen((event) {
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

  void _onTtsProgressUpdate() {
    if (!TTSService().isPlaying || _ttsTextOffsetMap.isEmpty) return;

    final rawStart = TTSService().currentWordStart;
    if (rawStart < 0) return; // speak() 剛呼叫，進度尚未初始化，跳過避免用舊值計算

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
      
      // Phase 1：頁面級 Skip (O(N) 降維優化)
      if (page.lines.isNotEmpty) {
        final lastTextLine = page.lines.lastWhere((l) => l.image == null, orElse: () => page.lines.last);
        final pageEnd = lastTextLine.chapterPosition + lastTextLine.text.length;
        if (chapterBase >= pageEnd) continue; // 目標在更後面的頁面

        final firstTextLine = page.lines.firstWhere((l) => l.image == null, orElse: () => page.lines.first);
        final pageStart = firstTextLine.chapterPosition;
        if (chapterBase < pageStart) break; // 已超過目標，安全跳出迴圈
      }

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

    bool needsNotify = false;
    if (_ttsStart != hlStart || _ttsEnd != hlEnd) {
      _ttsStart = hlStart;
      _ttsEnd = hlEnd;
      needsNotify = true;
    }

    // 整章朗讀：根據進度自動翻頁（平移/覆蓋模式）
    // 捲動模式由 _scrollToTtsHighlight 處理，不需要這裡翻頁
    if (pageTurnMode != PageAnim.scroll) {
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        if (page.chapterIndex != _ttsChapterIndex) continue;
        if (page.lines.isEmpty) continue;
        final firstTextLine = page.lines.firstWhere(
            (l) => l.image == null, orElse: () => page.lines.first);
        final lastTextLine = page.lines.lastWhere(
            (l) => l.image == null, orElse: () => page.lines.last);
        final pageStart = firstTextLine.chapterPosition;
        final pageEnd = lastTextLine.chapterPosition + lastTextLine.text.length;
        if (chapterBase >= pageStart && chapterBase < pageEnd) {
          if (currentPageIndex != i) {
            currentPageIndex = i;
            jumpPageController.add(i);
            needsNotify = true;
          }
          break;
        }
      }
    }

    if (needsNotify) notifyListeners();
  }

  /// 抽取文本與偏移映射建構邏輯，供 start 與 prefetch 共用
  (String, List<({int ttsOffset, int chapterOffset})>) prepareTtsData(List<TextLine> lines) {
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

  /// 預取下一章節的完整 TTS 文本，消除章節切換時的停頓
  void _prefetchNextChapterTts() {
    final anchorChapter = _ttsAnchorChapterIdx >= 0 ? _ttsAnchorChapterIdx : _ttsChapterIndex;
    final nextChapterIdx = anchorChapter + 1;
    if (nextChapterIdx >= chapters.length) return;

    final nextPages = chapterCache[nextChapterIdx];
    if (nextPages == null || nextPages.isEmpty) return;

    // 收集下一章節所有頁面的全部行
    final List<TextLine> allLines = [];
    for (final page in nextPages) {
      allLines.addAll(page.lines);
    }
    final visibleLines = allLines.where((l) => l.image == null).toList();
    if (visibleLines.isEmpty) return;

    final (text, map) = prepareTtsData(allLines);
    _prefetchedChapterTtsText = text;
    _prefetchedChapterOffsetMap = map;
    _prefetchedChapterBaseOffset = visibleLines.first.chapterPosition;
    _prefetchedChapterAnchorChapterIdx = nextChapterIdx;
    _prefetchedChapterAnchorEndCharPos = visibleLines.last.chapterPosition + visibleLines.last.text.length;
  }

  /// 根據當前 TTS 進度位置，找到正在朗讀的頁面索引
  int _findCurrentTtsPageIdx() {
    if (_ttsChapterIndex < 0) return currentPageIndex;
    final currentCharPos = _lastTtsHighlightStart >= 0 ? _lastTtsHighlightStart : _currentTtsBaseOffset;
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      if (page.chapterIndex != _ttsChapterIndex) continue;
      if (page.lines.isEmpty) continue;
      final firstTextLine = page.lines.firstWhere(
          (l) => l.image == null, orElse: () => page.lines.first);
      final lastTextLine = page.lines.lastWhere(
          (l) => l.image == null, orElse: () => page.lines.last);
      if (currentCharPos >= firstTextLine.chapterPosition &&
          currentCharPos < lastTextLine.chapterPosition + lastTextLine.text.length) {
        return i;
      }
    }
    return currentPageIndex;
  }

  /// 整章朗讀完成：只在章節邊界觸發，處理章節切換
  void _onTtsComplete() {
    if (_ttsCancelled) return;
    if (_ttsCompleteProcessing) return;
    _ttsCompleteProcessing = true;

    try {
      _lastTtsHighlightStart = -1;
      _lastTtsHighlightEnd = -1;
      _ttsStart = -1;
      _ttsEnd = -1;

      // 取出章節預取數據（在 nextChapter 之前，避免被覆蓋）
      final chapterPrefetchText = _prefetchedChapterTtsText;
      final chapterPrefetchMap = _prefetchedChapterOffsetMap;
      final chapterPrefetchBase = _prefetchedChapterBaseOffset;
      final chapterPrefetchAnchorChapterIdx = _prefetchedChapterAnchorChapterIdx;
      final chapterPrefetchAnchorEndCharPos = _prefetchedChapterAnchorEndCharPos;
      _prefetchedChapterTtsText = null;
      _prefetchedChapterOffsetMap = null;
      _prefetchedChapterAnchorChapterIdx = -1;
      _prefetchedChapterAnchorEndCharPos = 0;

      nextChapter().then((_) {
        if (_ttsCancelled) {
          _ttsCompleteProcessing = false;
          return;
        }
        if (stopAfterChapter) {
          stopAfterChapter = false;
          TTSService().stop();
          _ttsCompleteProcessing = false;
        } else {
          _lastTtsHighlightStart = -1;
          _lastTtsHighlightEnd = -1;
          if (pageTurnMode != PageAnim.scroll) {
            jumpPageController.add(currentPageIndex);
          }
          if (chapterPrefetchText != null && chapterPrefetchMap != null &&
              chapterPrefetchAnchorChapterIdx >= 0) {
            _currentTtsBaseOffset = chapterPrefetchBase;
            _ttsTextOffsetMap = chapterPrefetchMap;
            _ttsChapterIndex = chapterPrefetchAnchorChapterIdx;
            _ttsAnchorChapterIdx = chapterPrefetchAnchorChapterIdx;
            _ttsAnchorEndCharPos = chapterPrefetchAnchorEndCharPos;
            TTSService().speak(chapterPrefetchText);
            _prefetchNextChapterTts();
          } else {
            _startTts();
          }
          _ttsCompleteProcessing = false;
          notifyListeners();
        }
      }).catchError((e) {
        // 異常時也需重置旗標，否則 TTS 永遠無法繼續
        _ttsCompleteProcessing = false;
        debugPrint('TTS: nextChapter failed in _onTtsComplete: $e');
      });
    } finally {
      // 不在此處重置 _ttsCompleteProcessing：
      // nextChapter() 是異步的，finally 會在 .then() 之前執行，
      // 導致防重入旗標過早失效。已移至 .then()/.catchError() 內部。
    }
  }

  // --- TTS 跳轉與功能核心 ---
  void nextPageOrChapter() {
    _ttsCancelled = false;
    _prefetchedChapterTtsText = null;
    _prefetchedChapterOffsetMap = null;
    _prefetchedChapterAnchorChapterIdx = -1;
    _prefetchedChapterAnchorEndCharPos = 0;
    TTSService().stop();

    final curIdx = _findCurrentTtsPageIdx();
    if (curIdx >= 0 && curIdx < pages.length - 1) {
      onPageChanged(curIdx + 1);
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
    _prefetchedChapterTtsText = null;
    _prefetchedChapterOffsetMap = null;
    _prefetchedChapterAnchorChapterIdx = -1;
    _prefetchedChapterAnchorEndCharPos = 0;
    TTSService().stop();

    final curIdx = _findCurrentTtsPageIdx();
    if (curIdx > 0) {
      onPageChanged(curIdx - 1);
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
    _ttsCancelled = true;
    _ttsCompleteProcessing = false;
    TTSService().stop();
    _ttsStart = -1;
    _ttsEnd = -1;
    _ttsChapterIndex = -1;
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    _prefetchedChapterTtsText = null;
    _prefetchedChapterOffsetMap = null;
    _ttsAnchorChapterIdx = -1;
    _ttsAnchorEndCharPos = 0;
    _prefetchedChapterAnchorChapterIdx = -1;
    _prefetchedChapterAnchorEndCharPos = 0;
    notifyListeners();
  }

  void startTtsFromLine(int lineIndex) {
    _ttsCancelled = false;
    _ttsCompleteProcessing = false;
    TTSService().stop();
    _ttsStart = -1;
    _ttsEnd = -1;
    _ttsChapterIndex = -1;
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    _prefetchedChapterTtsText = null;
    _prefetchedChapterOffsetMap = null;
    _prefetchedChapterAnchorChapterIdx = -1;
    _prefetchedChapterAnchorEndCharPos = 0;
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

  /// 整章朗讀：從起始位置收集到章節末尾的全部文字，一次 speak() 完成
  void _startTts({int startLineIndex = -1}) async {
    if (_ttsCancelled) return;
    if (pages.isEmpty) return;
    onTtsStartCallback?.call();

    // 決定起始頁與起始行
    int pageIdx = currentPageIndex.clamp(0, pages.length - 1);
    int lineIdx = startLineIndex >= 0 ? startLineIndex : 0;

    // 捲動模式且未指定特定行：從視口頂端可見行開始
    if (pageTurnMode == PageAnim.scroll && startLineIndex < 0) {
      (pageIdx, lineIdx) = _getScrollModeTtsStart();
    }

    if (pageIdx >= pages.length) return;
    final startPage = pages[pageIdx];
    if (startPage.lines.isEmpty) return;
    final targetChapterIndex = startPage.chapterIndex;

    // 取得起始字元位置
    final startLines = startPage.lines.sublist(lineIdx);
    final textLines = startLines.where((l) => l.image == null);
    if (textLines.isEmpty) {
      // 純圖片頁面：跳到下一頁重試
      if (currentPageIndex < pages.length - 1) {
        currentPageIndex++;
        _startTts();
      }
      return;
    }
    final int startCharPos = textLines.first.chapterPosition;

    // 從 chapterCache 取得完整章節頁面，收集從 startCharPos 到章末的所有行
    final allChapterPages = chapterCache[targetChapterIndex] ??
        pages.where((p) => p.chapterIndex == targetChapterIndex).toList();

    final List<TextLine> linesToRead = [];
    for (final page in allChapterPages) {
      for (final line in page.lines) {
        if (line.image != null) continue;
        if (line.chapterPosition >= startCharPos) {
          linesToRead.add(line);
        }
      }
    }

    if (linesToRead.isEmpty) return;

    final (text, map) = prepareTtsData(linesToRead);
    if (text.trim().isEmpty) return;

    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
    _ttsChapterIndex = targetChapterIndex;
    _currentTtsBaseOffset = linesToRead.first.chapterPosition;
    _ttsTextOffsetMap = map;
    // 錨點設為整章末尾
    _ttsAnchorChapterIdx = targetChapterIndex;
    _ttsAnchorEndCharPos = linesToRead.last.chapterPosition + linesToRead.last.text.length;

    await TTSService().speak(text);
    TTSService().updateMediaInfo(title: book.name, author: book.author);
    _prefetchNextChapterTts();
    notifyListeners();
  }

  /// 捲動模式：從目前視口頂端可見行開始 TTS，而非從當前「頁」的第一行
  (int pageIdx, int lineIdx) _getScrollModeTtsStart() {
    if (pages.isEmpty) return (0, 0);
    final headOffset = scrollHeadOffset;
    double cumHeight = 0;
    for (int i = 0; i < pages.length; i++) {
      final page = pages[i];
      final double pageHeight = page.lines.isEmpty ? 0 : page.lines.last.lineBottom;
      for (int j = 0; j < page.lines.length; j++) {
        final line = page.lines[j];
        if (line.image != null) continue;
        final lineAbsBottom = headOffset + cumHeight + line.lineBottom;
        if (lineAbsBottom > lastScrollY) return (i, j);
      }
      cumHeight += pageHeight;
    }
    return (currentPageIndex.clamp(0, pages.length - 1), 0);
  }

  /// TTS 啟動時的回調，供 ReaderProvider 注入自動翻頁停止邏輯
  VoidCallback? onTtsStartCallback;

  /// 重置 TTS 高亮快取（重新分頁後呼叫）
  void resetTtsHighlightCache() {
    _lastTtsHighlightStart = -1;
    _lastTtsHighlightEnd = -1;
  }

  /// 儲存 TTS 進度（退出時使用）
  void saveTtsProgress() {
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
        saveProgress(currentChapterIndex, currentPageIndex);
      }
    }
  }

  /// TTS 是否正在運作（播放中或有高亮）
  bool get isTtsActive => TTSService().isPlaying || _ttsStart >= 0;
}
