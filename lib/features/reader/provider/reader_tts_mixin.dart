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
  List<({int ttsOffset, int chapterOffset})> _ttsTextOffsetMap = [];

  // 預取下一頁內容，消除銜接停頓
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

  StreamSubscription? audioEventSub;

  void initTtsListener() {
    TTSService().addListener(_onTtsProgressUpdate);
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
        final pageEnd = page.lines.last.chapterPosition + page.lines.last.text.length;
        if (chapterBase >= pageEnd) continue; // 目標在更後面的頁面
        
        final pageStart = page.lines.first.chapterPosition;
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

    if (_ttsStart != hlStart || _ttsEnd != hlEnd) {
      _ttsStart = hlStart;
      _ttsEnd = hlEnd;
      notifyListeners();
    }
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

    final (text, map) = prepareTtsData(nextPage.lines);
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

    final (text, map) = prepareTtsData(firstPage.lines);
    _prefetchedChapterTtsText = text;
    _prefetchedChapterOffsetMap = map;
    _prefetchedChapterBaseOffset = visibleLines.first.chapterPosition;
  }

  void _onTtsComplete() {
    if (_ttsCancelled) return; // 使用者已按停止，不繼續推進頁面
    if (currentPageIndex < pages.length - 1) {
      final nextIdx = currentPageIndex + 1;
      currentPageIndex = nextIdx;

      // 【Phase 1 修復】分頁模式需要跳轉 UI
      if (pageTurnMode != PageAnim.scroll) {
        jumpPageController.add(nextIdx);
      }
      // 【Phase 1 修復】滾動模式：主動通知高亮變化，觸發 _scrollToTtsHighlight

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
    // TTS 與自動翻頁互斥（透過 stopAutoPage callback）
    onTtsStartCallback?.call();

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

    final (text, map) = prepareTtsData(linesToRead);
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
