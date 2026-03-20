# Next Refactor Roadmap

更新日期：2026-03-20

目標：在目前閱讀器主鏈已完成第一輪收口後，進一步把閱讀 runtime 固化成穩定內核，降低後續功能擴展與維護成本。

## 1. 背景判斷

目前閱讀器已完成的核心收斂：

- `ReadBookController` 已成為閱讀器主控入口
- `scroll / slide` 已共享主要命令語義
- restore / progress / TTS / auto page 已開始走統一 command path
- `ReaderChapter` 已開始承接章內 runtime 能力
- `ReaderCommandGuard`、`ReaderAutoPageCoordinator` 已有第一版

目前仍然存在的核心問題：

- `ReadBookController` 職責仍然偏大
- `ReadViewRuntime` 仍持有較多 scroll execution 與 retry 細節
- `ReaderChapter` 還未達到 `TextChapter` 級別的 runtime 密度
- `ChapterContentManager` 仍偏 cache/preload manager，而不是 chapter lifecycle service
- integration tests 仍不足以完全保護 runtime 行為

因此下一輪重構的核心原則是：

1. 把 controller 再拆成明確子域
2. 把 chapter runtime 再補厚
3. 把 view runtime 再瘦身
4. 把內容管理層語義升級
5. 用 integration tests 鎖住主鏈

## 2. 重構總順序

下一輪建議依序完成：

1. `ReaderNavigationController`
2. `ReaderRestoreCoordinator`
3. `ReaderProgressStore`
4. `ReaderChapter` 強化
5. `ReadViewRuntime` 瘦身
6. `ChapterContentManager` 語義升級
7. integration tests
8. performance tracing

---

## Phase A: 拆 Controller 子域

### A1. 抽出 ReaderNavigationController

目標：

- 專門管理 jump / page change / chapter change / command dispatch
- 把 `ReadBookController` 內與 navigation 相關的方法抽離

候選來源檔案：

- [read_book_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_book_controller.dart)
- [reader_progress_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_progress_mixin.dart)

建議新增檔案：

- `lib/features/reader/runtime/reader_navigation_controller.dart`

第一批要搬的方法：

- `jumpToSlidePage(...)`
- `jumpToChapterLocalOffset(...)`
- `jumpToChapterCharOffset(...)`
- `handleSlidePageChanged(...)`
- `nextAutoScrollTarget(...)`
- `evaluateScrollAutoPageStep(...)`
- `shouldPersistForReason(...)`

驗收標準：

- `ReadBookController` 不再直接承擔大部分 navigation orchestration
- 所有跳轉語義仍只經過單一入口

目前進度：

- 已完成第一版落地
- 已新增 `lib/features/reader/runtime/reader_navigation_controller.dart`
- `ReadBookController` 已改為委派 jump reason / auto-scroll decision / progress-persist policy
- 已補 `reader_navigation_controller_test.dart`

### A2. 抽出 ReaderRestoreCoordinator

目標：

- 專門管理 restore lifecycle、pending restore token、restore target

候選來源檔案：

- [read_book_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_book_controller.dart)
- [read_view_runtime.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/read_view_runtime.dart)

建議新增檔案：

- `lib/features/reader/runtime/reader_restore_coordinator.dart`

第一批要搬的方法/狀態：

- `completeRestoreTransition()`
- `registerPendingScrollRestore(...)`
- `consumePendingScrollRestore()`
- `matchesPendingScrollRestore(...)`
- `_pendingScrollRestoreToken`
- `_pendingScrollRestoreChapterIndex`
- `_pendingScrollRestoreLocalOffset`

驗收標準：

- controller 不直接持有 restore token 細節
- view runtime 只拿 restore target 與執行命令

目前進度：

- 已完成第一版落地
- 已新增 `lib/features/reader/runtime/reader_restore_coordinator.dart`
- `ReadBookController` 已改為委派 restore token / target 狀態
- 已補 `reader_restore_coordinator_test.dart`

### A3. 抽出 ReaderProgressStore

目標：

- 專門管理 durable progress、visible progress sync、save policy

候選來源檔案：

- [reader_progress_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_progress_mixin.dart)
- [read_book_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_book_controller.dart)

建議新增檔案：

- `lib/features/reader/runtime/reader_progress_store.dart`

第一批要搬的方法：

- `persistCurrentProgress(...)`
- `persistChapterCharOffsetProgress(...)`
- `shouldPersistVisiblePosition()`
- scroll visible progress debounce 邏輯

驗收標準：

- progress 行為不再依賴 mixin 內隱狀態
- progress 可獨立測試

目前進度：

- 已完成第一版落地
- 已新增 `lib/features/reader/runtime/reader_progress_store.dart`
- `ReadBookController` / `ReaderProgressMixin` 已改為委派 durable progress persist 與 save policy
- 已補 `reader_progress_store_test.dart`

---

## Phase B: 補厚 ReaderChapter

### B1. 補 paragraph / page query API

目標：

- 讓外部更少直接碰 `pages`

目標檔案：

- [reader_chapter.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/models/reader_chapter.dart)

建議新增能力：

- `lineAtCharOffset(...)`
- `paragraphAtCharOffset(...)`
- `pageAtLocalOffset(...)`
- `nextPageStartCharOffset(...)`
- `prevPageStartCharOffset(...)`
- `isCharOffsetVisibleInPage(...)`

驗收標準：

- `ReadAloudController`
- `ReadViewRuntime`
- `ReaderProgressMixin` / 後續 progress store

對 `pages` 的直接掃描顯著減少

目前進度：

- 已完成第一版落地
- `ReaderChapter` 已新增 line / paragraph / page / prev-next page helper
- `ReadAloudController` 已改為優先依賴 chapter runtime 的 highlight 與頁跳轉定位
- `ReadViewRuntime` 已改為使用 `resolveRestoreTarget(...)` / `resolveScrollAnchor(...)`
- 已擴充 `reader_chapter_runtime_test.dart`

### B2. 補 restore / highlight snapshot helper

目標：

- 讓 restore / TTS / scroll follow 使用同一套章內語義

建議新增能力：

- `resolveHighlightRange(...)`
- `resolveRestoreTarget(...)`
- `resolveScrollAnchor(...)`

驗收標準：

- TTS highlight 與 restore 共享更多 chapter runtime API

目前進度：

- 已完成第一版落地
- `ReaderChapter` 已新增：
  - `resolveHighlightRange(...)`
  - `resolveRestoreTarget(...)`
  - `resolveScrollAnchor(...)`
- TTS highlight / scroll follow / restore page anchor 已開始共享同一套章內語義

---

## Phase C: 瘦身 ReadViewRuntime

### C1. 拆出 ScrollExecutionAdapter

目標：

- 把 scroll jump / ensureVisible / pixel adjust 細節隔離

候選來源檔案：

- [read_view_runtime.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/read_view_runtime.dart)

建議新增檔案：

- `lib/features/reader/view/scroll_execution_adapter.dart`

第一批要搬的方法：

- `_scrollToPageKey(...)`
- `_scrollToChapterLocalOffset(...)`
- `_jumpScrollPosition(...)`

驗收標準：

- `ReadViewRuntime` 不再直接持有大段 scroll execution 細節

目前進度：

- 已完成第一版落地
- 已新增 `lib/features/reader/view/scroll_execution_adapter.dart`
- `_scrollToChapterLocalOffset(...)` 已從 `ReadViewRuntime` 抽到 adapter
- `ReadViewRuntime` 保留 restore / follow / coordination，本身不再直接持有主要的 scroll pixel 計算

### C2. 把 restore retry policy 抽成小協調器

目標：

- 讓 `ReadViewRuntime` 不再自己管理 restore retry 次數與重試條件

候選來源檔案：

- [read_view_runtime.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/read_view_runtime.dart)

建議新增檔案：

- `lib/features/reader/view/scroll_restore_runner.dart`

驗收標準：

- `ReadViewRuntime` 只發起 restore，runner 負責 retry

目前進度：

- 已完成第一版落地
- 已新增 `lib/features/reader/view/scroll_restore_runner.dart`
- `ReadViewRuntime` 已改為委派 restore retry / reload / retry exhaustion 前的重試流程

### C3. 把可見項回報策略上收

目標：

- 將 visible chapter -> preload / visible progress 的策略轉到 controller/coordinator

候選來源檔案：

- [read_view_runtime.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/read_view_runtime.dart)

驗收標準：

- `ReadViewRuntime` 只回報 raw visible positions
- 策略判斷由 controller 或 coordinator 完成

目前進度：

- 已完成第一版落地
- 已新增 `lib/features/reader/runtime/reader_scroll_visibility_coordinator.dart`
- `ReadViewRuntime` 現在只回報 top visible chapter / localOffset / visible chapters
- visible preload / visible chapter ensure / 去重請求 已移到 controller/coordinator

---

## Phase D: 升級 ChapterContentManager 語義

### D1. 對外 API 改成 lifecycle-oriented

目標：

- 從 cache/preload manager 改為 chapter lifecycle service

目標檔案：

- [chapter_content_manager.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_content_manager.dart)

建議改造方向：

- `ensureChapterReady(index)`
- `warmChaptersAround(index, radius)`
- `repaginateVisibleWindow(indexes)`
- `evictOutside(indexes)`
- `prioritize(indexes)`

驗收標準：

- `ReaderContentMixin` 或後續 content domain 不再大量操縱 queue/window 細節

目前進度：

- 已完成第一版落地
- `ChapterContentManager` 已新增：
  - `ensureChapterReady(index)`
  - `warmChaptersAround(index, radius)`
  - `repaginateVisibleWindow(indexes)`
  - `evictOutside(indexes)`
  - `prioritize(indexes, centerIndex)`
- `ReaderContentMixin` 已開始改用新的 lifecycle-oriented API

### D2. 弱化 targetWindow 作為對外語義

目標：

- 外部不要直接依賴 `_targetWindow` / `targetWindow`

驗收標準：

- `targetWindow` 逐漸退回 manager 內部細節

目前進度：

- 已開始落地
- `ReaderContentMixin` 在 window 同步與 repaginate 路徑已減少直接操作 queue/preload 細節
- `targetWindow` 仍保留於少數快取同步路徑，後續可再往 `visibleWindow` / `lifecycle window` 語義收斂

---

## Phase E: Integration Tests

### E1. 新增 reader runtime integration tests

建議新增檔案：

- `test/features/reader/read_book_controller_runtime_test.dart`
- `test/features/reader/read_restore_flow_test.dart`
- `test/features/reader/read_aloud_runtime_test.dart`

第一批場景：

1. restore 到 scroll 指定 offset
2. restore 到 slide 指定 page
3. TTS progress 不重複觸發 jump storm
4. auto page 被 user scroll 打斷後不錯亂
5. repaginate 後 progress 不漂移
6. command guard 能正確擋下低優先級命令

驗收標準：

- 新一輪重構不再只靠 widget/人工驗證

目前進度：

- 已完成第一版落地
- 已新增：
  - `test/features/reader/chapter_content_manager_lifecycle_test.dart`
  - `test/features/reader/reader_runtime_flow_test.dart`
- 目前先覆蓋 restore/navigation/visibility/content lifecycle 的 integration-style flow
- `ReadBookController` / `ReadAloudController` 的 full runtime integration test 可在下一輪補強

### E2. 保留並擴充 runtime helper tests

目標：

- 延續現有：
  - `reader_command_guard_test.dart`
  - `reader_chapter_runtime_test.dart`

新增：

- restore target helper test
- highlight range helper test
- page navigation helper test

目前進度：

- 已完成第一版落地
- 既有 helper tests 已擴充至：
  - restore target
  - highlight range
  - page navigation
  - scroll visibility coordinator

---

## Phase F: Performance Trace

### F1. 為關鍵路徑加時間埋點

目標檔案：

- [chapter_content_manager.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_content_manager.dart)
- [read_book_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_book_controller.dart)
- [read_aloud_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_aloud_controller.dart)

建議觀測點：

- 首章 ready
- restore ready
- repaginate cost
- next chapter preload ready
- TTS chapter handoff

驗收標準：

- 能分辨卡頓來自 fetch / process / paginate / scroll execution

目前進度：

- 已完成第一版落地
- `ReaderPerfTrace` 已新增：
  - `mark(...)`
  - `measureSync(...)`
- 已接入觀測點：
  - `prime initial window`
  - `restore ready`
  - `tts speak`
  - `tts prefetched next chapter`
  - `tts chapter handoff nextChapter`
  - `tts handoff speak`

---

## 3. 建議執行節奏

如果按兩到三輪提交來做，建議這樣拆：

### Round 1

- Phase A
- Phase B1

輸出：

- controller 子域初步拆分
- `ReaderChapter` 補強一批 API

### Round 2

- Phase C
- Phase D

輸出：

- view runtime 明顯變薄
- chapter content manager 對外語義升級

### Round 3

- Phase E
- Phase F

輸出：

- runtime 行為有測試保護
- 性能優化有觀測基礎

---

## 4. 結論

下一輪重構的重點不是再“做更多功能”，而是把閱讀器模組正式定型成：

- 內核：navigation / restore / progress / chapter runtime
- 中層：chapter lifecycle / read aloud / auto page
- 外層：view runtime / mode delegates

只要這一輪做完，後面要加：

- 更強 TTS
- 更多翻頁動畫
- 更穩的 restore
- 更複雜的 preload

都不需要再去碰整條主鏈。
