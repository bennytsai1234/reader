# Reader 全鏈路優化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修復閱讀器從開書到持續閱讀全鏈路中的 6 個確認 bug，涵蓋邊緣案例防護與性能加固。

**Architecture:** 所有修復均在現有檔案內進行，不新增模組。每個 Task 對應一個獨立 bug，修改範圍嚴格限定在相關檔案。每個 Task 採 TDD：先寫失敗測試，再修實作，再驗通過。

**Tech Stack:** Dart/Flutter, flutter_test, ChapterContentManager, ReaderProgressStore, ReadAloudController, ReadBookController

---

## 檔案修改清單

| 檔案 | 修改原因 |
|------|---------|
| `lib/features/reader/engine/chapter_content_manager.dart` | Task 1, Task 2 |
| `lib/features/reader/runtime/reader_progress_store.dart` | Task 3 |
| `lib/features/reader/runtime/read_book_controller.dart` | Task 4, Task 6 |
| `lib/features/reader/runtime/read_aloud_controller.dart` | Task 5 |
| `test/features/reader/chapter_content_manager_test.dart` | Task 1, Task 2 測試 |
| `test/features/reader/reader_progress_store_test.dart` | Task 3 測試 |
| `test/features/reader/read_aloud_controller_test.dart` | Task 5 測試 |

---

## Task 1 — N2: 空內容無限重試迴圈

**根因：** `_fetchAndPaginate` 在 content 為空字串時，`_doPaginate` 回傳 `[]`，觸發 `_paginatedCache.remove(index)`。下次呼叫 `getChapterPages(index)` 時，cache miss → 再次呼叫 `_fetchAndPaginate` → 同樣空內容 → 無限循環。

**Files:**
- Modify: `lib/features/reader/engine/chapter_content_manager.dart`
- Test: `test/features/reader/chapter_content_manager_test.dart`

- [ ] **Step 1: 寫入失敗測試**

在 `test/features/reader/chapter_content_manager_test.dart` 的 `group('ChapterContentManager')` 內新增：

```dart
test('空內容章節只抓取一次，不無限重試', () async {
  int fetchCount = 0;
  final manager = ChapterContentManager(
    fetchFn: (index) async {
      fetchCount++;
      return FetchResult(content: ''); // 空內容
    },
    chapters: makeChapters(3),
  );
  manager.updateConfig(makeConfig());

  final first = await manager.getChapterPages(0);
  final second = await manager.getChapterPages(0); // 不應再次抓取

  expect(first, isEmpty);
  expect(second, isEmpty);
  expect(fetchCount, 1, reason: '空內容應只抓取一次，不重試');

  manager.dispose();
});
```

- [ ] **Step 2: 確認測試失敗**

```bash
cd /home/benny/.openclaw/workspace/projects/reader
flutter test test/features/reader/chapter_content_manager_test.dart --name '空內容' -v
```

預期：FAIL（fetchCount 為 2，因為第二次呼叫觸發重試）

- [ ] **Step 3: 在 `chapter_content_manager.dart` 中新增 `_emptyContentChapters` Set**

在 `ChapterContentManager` 類別的欄位區（約第 79 行，`_silentLoadingChapters` 宣告之後）新增：

```dart
/// 已抓取但內容為空的章節集合（防止無限重試）
final Set<int> _emptyContentChapters = {};
```

- [ ] **Step 4: 在 `getChapterPages` 加入空內容早期返回**

在 `getChapterPages` 方法（第 127 行）的快取命中檢查（`if (cached != null && cached.isNotEmpty) return cached;`）之前，加入以下程式碼：

```dart
// 已知空內容章節，直接回傳空列表，不重試
if (_emptyContentChapters.contains(index)) return [];
```

也就是讓方法開頭變成：

```dart
Future<List<TextPage>> getChapterPages(int index) async {
  if (index < 0 || index >= _chapters.length) return [];
  if (_disposed) return [];

  // 已知空內容章節，直接回傳空列表，不重試
  if (_emptyContentChapters.contains(index)) return [];

  // 快取命中
  final cached = _paginatedCache[index];
  if (cached != null && cached.isNotEmpty) return cached;
  // ... 其餘不變
```

- [ ] **Step 5: 在 `_fetchAndPaginate` 的 `try` 區塊中，fetch 完後加入空內容攔截**

找到 `_fetchAndPaginate` 方法（約第 462 行），在 `_saveContentCache(index, result.content);` 之前插入：

```dart
try {
  final result = await _fetchFn(index);
  if (_disposed) return;

  // 空內容攔截：記錄並早期返回，避免無限重試
  if (result.content.trim().isEmpty) {
    AppLog.w('ChapterContentManager: Chapter $index returned empty content, marking as empty');
    _emptyContentChapters.add(index);
    return;
  }

  _saveContentCache(index, result.content);
  // ... 其餘不變
```

- [ ] **Step 6: 在 `_preloadChapterSilently` 的 `try` 區塊做相同處理**

找到 `_preloadChapterSilently` 方法（約第 693 行），在 `_saveContentCache(index, result.content);` 之前插入：

```dart
try {
  final result = await _fetchFn(index);
  if (_disposed) return;

  // 空內容攔截
  if (result.content.trim().isEmpty) {
    AppLog.w('ChapterContentManager: Silent preload chapter $index empty content');
    _emptyContentChapters.add(index);
    return;
  }

  _saveContentCache(index, result.content);
  // ... 其餘不變
```

- [ ] **Step 7: 在 `dispose()` 清除 `_emptyContentChapters`**

在 `dispose()` 方法（約第 453 行）加入：

```dart
void dispose() {
  _disposed = true;
  _onChapterReadyController.close();
  _preloadQueue.clear();
  _loadCompleters.clear();
  _emptyContentChapters.clear(); // 新增
}
```

- [ ] **Step 8: 執行測試，確認通過**

```bash
flutter test test/features/reader/chapter_content_manager_test.dart -v
```

預期：全部 PASS

- [ ] **Step 9: 靜態分析**

```bash
flutter analyze lib/features/reader/engine/chapter_content_manager.dart
```

預期：No issues found

- [ ] **Step 10: Commit**

```bash
cd /home/benny/.openclaw/workspace/projects/reader
git add lib/features/reader/engine/chapter_content_manager.dart \
        test/features/reader/chapter_content_manager_test.dart
git commit -m "fix(N2): guard empty content chapters against infinite retry loop

Empty content from fetch was causing _paginatedCache.remove(),
which caused subsequent getChapterPages() calls to re-fetch
indefinitely. Now tracked in _emptyContentChapters Set.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 2 — N3: 分頁設定變更時舊設定結果覆寫快取

**根因：** `updateConfig` 清除 `_paginatedCache`，但正在進行中的 `_fetchAndPaginate` 仍可能在清除後將使用舊設定分頁的結果寫入快取，導致字體變更後部分章節顯示舊佈局。

**Files:**
- Modify: `lib/features/reader/engine/chapter_content_manager.dart`
- Test: `test/features/reader/chapter_content_manager_test.dart`

- [ ] **Step 1: 寫入失敗測試**

在 `test/features/reader/chapter_content_manager_test.dart` 的 group 內新增：

```dart
test('updateConfig 清除快取後，舊分頁結果不應覆蓋新設定', () async {
  final completer = Completer<void>();
  int paginateCallCount = 0;

  PaginationConfig makeConfig({double fontSize = 16}) {
    final style = TextStyle(fontSize: fontSize, height: 1.5);
    return PaginationConfig(
      viewSize: const Size(1000, 1200),
      titleStyle: style,
      contentStyle: style,
      textIndent: 0,
    );
  }

  final manager = ChapterContentManager(
    fetchFn: (index) async {
      // 第一次抓取時暫停，讓 updateConfig 插入
      if (paginateCallCount == 0) await completer.future;
      paginateCallCount++;
      return FetchResult(content: 'content-$index');
    },
    chapters: makeChapters(3),
  );
  manager.updateConfig(makeConfig(fontSize: 16));

  // 觸發載入（不等待）
  final fetchFuture = manager.getChapterPages(0);

  // 在 fetch 等待期間更新設定
  manager.updateConfig(makeConfig(fontSize: 24));

  // 完成 fetch
  completer.complete();
  await fetchFuture;

  // 再次取得，應為空（新設定未完成重新分頁）或需要重新分頁
  // 關鍵：updateConfig 之後，舊分頁結果不應留存
  expect(manager.getCachedPages(0), isNull,
      reason: 'updateConfig 後快取應被清除，不應有舊設定的分頁結果');

  manager.dispose();
});
```

- [ ] **Step 2: 確認測試失敗**

```bash
flutter test test/features/reader/chapter_content_manager_test.dart --name 'updateConfig 清除快取' -v
```

預期：FAIL（getCachedPages(0) 非 null，因為舊分頁結果在 updateConfig 清除後被寫回）

- [ ] **Step 3: 在 `ChapterContentManager` 新增 `_configVersion` 計數器**

在 `_config` 欄位（約第 88 行）下方新增：

```dart
/// 當前分頁設定版本，每次 updateConfig 遞增，用於丟棄過期的分頁結果
int _configVersion = 0;
```

- [ ] **Step 4: 在 `updateConfig` 方法中遞增版本號**

將 `updateConfig` 方法（約第 208 行）改為：

```dart
void updateConfig(PaginationConfig config) {
  _config = config;
  _configVersion++;       // 遞增版本號，使所有進行中的分頁作廢
  _paginatedCache.clear();
}
```

- [ ] **Step 5: 在 `_fetchAndPaginate` 中捕捉版本號，並在寫入前驗證**

在 `_fetchAndPaginate` 方法（約第 462 行）的 try 區塊開頭，在 `await _fetchFn(index)` 之前加入：

```dart
Future<void> _fetchAndPaginate(int index) async {
  final completer = Completer<void>();
  _loadCompleters[index] = completer;
  final capturedConfigVersion = _configVersion; // 捕捉開始時的版本號
  final trace = Stopwatch()..start();
  // ... 其餘不變
```

然後在 `_progressivePaginationEnabled` 判斷（約第 476 行）前，以及在寫入 `_paginatedCache` 之前，加入版本驗證：

```dart
      // 版本驗證：若分頁設定在抓取期間被更新，丟棄此次結果
      if (_configVersion != capturedConfigVersion) {
        AppLog.d('ChapterContentManager: Chapter $index pagination discarded (config changed)');
        return;
      }

      if (_progressivePaginationEnabled) {
```

- [ ] **Step 6: 執行測試，確認通過**

```bash
flutter test test/features/reader/chapter_content_manager_test.dart -v
```

預期：全部 PASS

- [ ] **Step 7: 靜態分析**

```bash
flutter analyze lib/features/reader/engine/chapter_content_manager.dart
```

預期：No issues found

- [ ] **Step 8: Commit**

```bash
git add lib/features/reader/engine/chapter_content_manager.dart \
        test/features/reader/chapter_content_manager_test.dart
git commit -m "fix(N3): discard stale pagination results after config update

Added _configVersion counter incremented by updateConfig().
_fetchAndPaginate() now captures version before the async fetch
and discards results if config changed during loading.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 3 — N6: 進度寫入失敗靜默吞噬

**根因：** `ReaderProgressStore.persistCharOffset` 直接 `await write(...)` 不包裝 try-catch。呼叫端使用 `unawaited()`，導致 DAO 寫入失敗（如 SQLite 錯誤）完全靜默，無法診斷。

**Files:**
- Modify: `lib/features/reader/runtime/reader_progress_store.dart`
- Test: `test/features/reader/reader_progress_store_test.dart`

- [ ] **Step 1: 寫入失敗測試**

在 `test/features/reader/reader_progress_store_test.dart` 的 `group('ReaderProgressStore')` 內新增：

```dart
test('persistCharOffset 寫入失敗時不拋出例外（並靜默記錄）', () async {
  final store = ReaderProgressStore();
  final book = Book(name: 'book', author: 'author', bookUrl: 'url');
  final chapters = [BookChapter(title: 'c0', index: 0)];

  // write 函數拋出例外
  Future<void> failingWrite(int ci, String title, int charOffset) async {
    throw Exception('DB write failed');
  }

  // 確認 persistCharOffset 本身不拋出例外
  await expectLater(
    store.persistCharOffset(
      write: failingWrite,
      book: book,
      chapters: chapters,
      chapterIndex: 0,
      charOffset: 100,
    ),
    completes, // 不應拋出
  );

  // book 狀態應已更新（寫入失敗只影響持久化，不影響記憶體狀態）
  expect(book.durChapterPos, 100);
});
```

- [ ] **Step 2: 確認測試失敗**

```bash
flutter test test/features/reader/reader_progress_store_test.dart --name '寫入失敗' -v
```

預期：FAIL（拋出 `Exception: DB write failed`）

- [ ] **Step 3: 修改 `persistCharOffset` 加入 try-catch**

在 `reader_progress_store.dart` 中，在檔案頂部加入 import（如果尚未有）：

```dart
import 'package:legado_reader/core/services/app_log_service.dart';
```

然後將 `persistCharOffset` 方法的 `await write(...)` 改為：

```dart
Future<void> persistCharOffset({
  required Future<void> Function(int chapterIndex, String title, int charOffset)
      write,
  required Book book,
  required List<BookChapter> chapters,
  required int chapterIndex,
  required int charOffset,
}) async {
  final title = chapters.isNotEmpty && chapterIndex < chapters.length
      ? chapters[chapterIndex].title
      : '';
  updateBookProgress(
    book: book,
    chapterIndex: chapterIndex,
    charOffset: charOffset,
    title: title,
  );
  _lastSavedCharOffset = charOffset;
  try {
    await write(chapterIndex, title, charOffset);
  } catch (e, stack) {
    AppLog.e(
      'ReaderProgressStore: persist failed ch=$chapterIndex pos=$charOffset: $e',
      error: e,
      stackTrace: stack,
    );
  }
}
```

- [ ] **Step 4: 執行測試，確認通過**

```bash
flutter test test/features/reader/reader_progress_store_test.dart -v
```

預期：全部 PASS

- [ ] **Step 5: 靜態分析**

```bash
flutter analyze lib/features/reader/runtime/reader_progress_store.dart
```

預期：No issues found

- [ ] **Step 6: Commit**

```bash
git add lib/features/reader/runtime/reader_progress_store.dart \
        test/features/reader/reader_progress_store_test.dart
git commit -m "fix(N6): catch and log progress write failures instead of propagating

DAO write errors are now caught with try-catch in persistCharOffset.
In-memory book state is still updated; only the durable write fails.
Errors are logged via AppLog.e for diagnostics.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 4 — N1: initialCharOffset 恢復後未清零

**根因：** `ReadBookController.initialCharOffset` 是公開欄位，在 `_init()` 使用後從未清零。若外部程式碼（或未來的初始化路徑）讀取此欄位，會得到過期的初始偏移量，可能導致意外的二次跳轉。

**Files:**
- Modify: `lib/features/reader/runtime/read_book_controller.dart`

**注意：** `ReadBookController` 依賴 Flutter widget 生命週期，無法在純 Dart 單元測試中完整測試 `_init()`。此 Task 為防禦性程式碼改動，驗證以靜態分析為主。

- [ ] **Step 1: 在 `_init()` 中清零 `initialCharOffset`**

找到 `_init()` 方法中使用 `initialCharOffset` 的區塊（約第 484-493 行）：

```dart
batchUpdate(() {
  bootstrapChapterWindow(currentChapterIndex);
  if (initialCharOffset > 0) {
    jumpToChapterCharOffset(
      chapterIndex: currentChapterIndex,
      charOffset: initialCharOffset,
      reason: ReaderCommandReason.restore,
      isRestoringJump: false,
    );
  }
  lifecycle = ReaderLifecycle.ready;
});
```

改為：

```dart
batchUpdate(() {
  bootstrapChapterWindow(currentChapterIndex);
  if (initialCharOffset > 0) {
    jumpToChapterCharOffset(
      chapterIndex: currentChapterIndex,
      charOffset: initialCharOffset,
      reason: ReaderCommandReason.restore,
      isRestoringJump: false,
    );
    initialCharOffset = 0; // 使用後清零，防止外部讀取到過期值
  }
  lifecycle = ReaderLifecycle.ready;
});
```

- [ ] **Step 2: 靜態分析**

```bash
flutter analyze lib/features/reader/runtime/read_book_controller.dart
```

預期：No issues found

- [ ] **Step 3: 執行全套測試**

```bash
flutter test test/features/reader/read_book_controller_test.dart -v
```

預期：全部 PASS（無回歸）

- [ ] **Step 4: Commit**

```bash
git add lib/features/reader/runtime/read_book_controller.dart
git commit -m "fix(N1): clear initialCharOffset after restore jump in _init()

The public field was never zeroed after use, leaving stale data
accessible externally. Now cleared immediately after the restore
jump executes, or unconditionally within the batchUpdate block.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 5 — N7: TTS 章節銜接時高亮殘留

**根因：** `ReadAloudController._onComplete()` 在清除高亮狀態（`_ttsStart = -1` 等）後，要等待 `nextChapter()` 完整執行完才呼叫 `notifyController()`。`nextChapter()` 是網路操作，可能耗時數百毫秒，期間舊章節高亮仍顯示在畫面上。

**Files:**
- Modify: `lib/features/reader/runtime/read_aloud_controller.dart`
- Test: `test/features/reader/read_aloud_controller_test.dart`

- [ ] **Step 1: 讀取現有測試結構**

```bash
head -80 /home/benny/.openclaw/workspace/projects/reader/test/features/reader/read_aloud_controller_test.dart
```

- [ ] **Step 2: 確認現有回歸覆蓋**

```bash
flutter test test/features/reader/read_aloud_controller_test.dart -v 2>&1 | head -40
```

`_onComplete` 是私有方法且透過 `TTSService` 觸發，無法在純 Dart 單元測試中直接呼叫。此 Task 的驗證策略：
- **程式碼審查**：確認 `notifyController()` 插入位置正確（Step 3）
- **靜態分析**：確保無語法/型別錯誤（Step 4）
- **回歸測試**：確保現有 TTS 測試無失敗（Step 5）

- [ ] **Step 3: 修改 `_onComplete` — 在清除高亮後立即 `notifyController()`**

找到 `_onComplete()` 方法（約第 364 行），在清除高亮狀態之後、呼叫 `nextChapter()` 之前，插入 `notifyController()` 呼叫：

```dart
Future<void> _onComplete() async {
  if (_state != ReadAloudState.speaking) return;
  final version = _opVersion;
  _state = ReadAloudState.transitioning;
  try {
    _ttsStart = -1;
    _ttsEnd = -1;
    _lastHighlightStart = -1;
    _lastHighlightEnd = -1;
    notifyController(); // ← 新增：立即清除畫面上的高亮，不等 nextChapter
    final prefetched = _session?.prefetchedNext;
    await ReaderPerfTrace.measureAsync(
      'tts chapter handoff nextChapter',
      () => nextChapter(),
    );
    // ... 其餘不變
```

- [ ] **Step 4: 靜態分析**

```bash
flutter analyze lib/features/reader/runtime/read_aloud_controller.dart
```

預期：No issues found

- [ ] **Step 5: 執行 TTS 相關測試**

```bash
flutter test test/features/reader/read_aloud_controller_test.dart -v
```

預期：全部 PASS（無回歸）

- [ ] **Step 6: Commit**

```bash
git add lib/features/reader/runtime/read_aloud_controller.dart \
        test/features/reader/read_aloud_controller_test.dart
git commit -m "fix(N7): clear TTS highlight immediately on chapter completion

Previously _onComplete() only called notifyController() after
nextChapter() resolved, leaving the old chapter highlight visible
for the full duration of the chapter handoff (potentially 100-500ms).
Now notifies immediately after clearing _ttsStart/_ttsEnd.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Task 6 — N7: TTS follow localOffset 未限制在章節高度內

**根因：** `ReadBookController.evaluateTtsFollowTarget()` 計算 `targetLocalOffset` 時，若 `ttsStart` 位於章節末尾的圖片行之後，`charOffsetToLocalOffset` 回傳 `chapterHeight`，減去 `anchorPadding` 後仍可能超出實際滾動範圍。傳遞未 clamp 的 offset 給 `_ttsFollow.evaluate()` 會產生無效的滾動目標。

**Files:**
- Modify: `lib/features/reader/runtime/read_book_controller.dart`

- [ ] **Step 1: 找到 `evaluateTtsFollowTarget` 方法位置**

確認方法在 `read_book_controller.dart` 約第 279-302 行。

- [ ] **Step 2: 修改 `evaluateTtsFollowTarget` — 加入 localOffset 上界限制**

將 `evaluateTtsFollowTarget` 方法改為：

```dart
ReaderTtsFollowTarget? evaluateTtsFollowTarget({
  required double viewportHeight,
}) {
  final chapterIndex =
      ttsChapterIndex >= 0 ? ttsChapterIndex : currentChapterIndex;
  final runtimeChapter = chapterAt(chapterIndex);
  final pages = pagesForChapter(chapterIndex);
  if (((runtimeChapter == null && pages.isEmpty) ||
          (runtimeChapter != null && runtimeChapter.isEmpty)) ||
      ttsStart < 0) {
    return null;
  }
  final rawLocalOffset =
      runtimeChapter != null
          ? runtimeChapter.resolveScrollAnchor(ttsStart).localOffset
          : ChapterPositionResolver.charOffsetToLocalOffset(pages, ttsStart);

  // 限制 localOffset 不超過章節實際高度，防止圖片結尾章節產生超界滾動目標
  final chapterHeight = runtimeChapter?.chapterHeight
      ?? ChapterPositionResolver.chapterHeight(pages);
  final targetLocalOffset =
      chapterHeight > 0 ? rawLocalOffset.clamp(0.0, chapterHeight) : rawLocalOffset;

  return _ttsFollow.evaluate(
    chapterIndex: chapterIndex,
    visibleChapterIndex: visibleChapterIndex,
    targetLocalOffset: targetLocalOffset,
    visibleChapterLocalOffset: visibleChapterLocalOffset,
    viewportHeight: viewportHeight,
  );
}
```

- [ ] **Step 3: 靜態分析**

```bash
flutter analyze lib/features/reader/runtime/read_book_controller.dart
```

預期：No issues found

- [ ] **Step 4: 執行 TTS follow 相關測試**

```bash
flutter test test/features/reader/reader_tts_follow_coordinator_test.dart \
             test/features/reader/read_book_controller_test.dart -v
```

預期：全部 PASS

- [ ] **Step 5: Commit**

```bash
git add lib/features/reader/runtime/read_book_controller.dart
git commit -m "fix(N7): clamp TTS follow localOffset to chapter height

Chapters ending with images return chapterHeight from
charOffsetToLocalOffset, which could produce scroll targets
beyond the chapter's actual scrollable extent. Now clamped
to [0, chapterHeight] before passing to TtsFollowCoordinator.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## 最終驗證

- [ ] **執行全套測試**

```bash
cd /home/benny/.openclaw/workspace/projects/reader
flutter test -v 2>&1 | tail -30
```

預期：全部 PASS，無新增失敗。

- [ ] **全專案靜態分析**

```bash
flutter analyze
```

預期：No issues found

- [ ] **確認所有 commit 完整**

```bash
git log --oneline -8
```

---

## Bug 修復摘要

| Task | 節點 | 檔案 | Bug | 修復 |
|------|------|------|-----|------|
| 1 | N2 | chapter_content_manager.dart | 空內容 → 無限重試 | `_emptyContentChapters` Set 防護 |
| 2 | N3 | chapter_content_manager.dart | 設定更新後舊分頁覆蓋快取 | `_configVersion` 計數器 |
| 3 | N6 | reader_progress_store.dart | 寫入失敗靜默吞噬 | try-catch + AppLog.e |
| 4 | N1 | read_book_controller.dart | `initialCharOffset` 未清零 | 使用後立即清零 |
| 5 | N7 | read_aloud_controller.dart | TTS 切章高亮殘留 | 清除後立即 notifyController |
| 6 | N7 | read_book_controller.dart | TTS follow offset 未限界 | clamp 到 chapterHeight |
