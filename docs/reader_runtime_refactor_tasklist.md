# Reader Runtime Refactor Task List

更新日期：2026-03-20

目標：完成閱讀器主鏈重構收口，降低 `mixin`、controller、view delegate 之間的時序耦合。

## Phase 1: Command API 收口

### Task 1.1

為閱讀器跳轉與保存行為定義統一命令語義：

- `ReaderCommandReason`
- `jumpToChapterCharOffset(...)`
- `jumpToChapterLocalOffset(...)`
- `jumpToSlidePage(...)`
- `persistCurrentProgress(...)`

驗收標準：

- restore / TTS / auto page / user action 不再直接散用 `requestJumpToPage`、`requestJumpToChapter`
- 所有跳轉命令都帶有 reason

狀態：

- 已完成第一版
- `ReadBookController` 已新增統一 jump / persist API
- `ReaderCommandReason` 已串到 pending jump、page jump、chapter jump、auto page、TTS

### Task 1.2

把 `ReaderProgressMixin` 改成只做 position resolve，不直接擁有跳轉出口。

驗收標準：

- `applyPendingRestore()`、scroll visible update、save progress 都改走 controller 統一入口

狀態：

- 已完成第一版
- `ReaderProgressMixin` 已改走 controller 統一入口
- 已加入 programmatic jump 的 viewport progress suppress

### Task 1.3

把 `ReaderContentMixin` 的章節載入後跳轉改走統一命令 API。

驗收標準：

- `loadChapterWithPreloadRadius()`、`doPaginate()` 不再直接呼叫底層 pending jump API

狀態：

- 已完成第一版
- `ReaderContentMixin` 的主要章節載入與 repaginate 跳轉已接到 controller command API

## Phase 2: Progress / Restore 收口

### Task 2.1

將 restore 狀態切換與 pending restore token 的來源集中到 controller。

驗收標準：

- restore 的生命週期切換只由 controller 決定

狀態：

- 已完成
- restore jump 已經收斂進 controller command API
- `ReadViewRuntime` / `SlideModeDelegate` 的 restore ready 切換已回收到 controller
- scroll restore token / pending target 也已回收到 controller

### Task 2.2

把 progress persistence 明確拆成：

- visible progress sync
- durable progress persistence

驗收標準：

- UI 層不直接回寫 `book.durChapterPos`

狀態：

- 已完成第二階段範圍
- page jump 與 scroll visible progress 已開始走 command 語義
- TTS persist 已回收到 controller

## Phase 3: TTS / Auto Page 去耦合

### Task 3.1

讓 `ReadAloudController` 只產出語義位置，不直接決定 mode-specific jump。

驗收標準：

- TTS 透過 controller command API 發送跳轉意圖

狀態：

- 已完成
- `ReadAloudController` 的 jump 已改走 controller command API
- 章內定位已優先改走 `ReaderChapter`

### Task 3.2

把 auto page 改成 coordinator，只經由 controller navigation API 前進。

驗收標準：

- `scroll` / `slide` 自動翻頁不再各自持有保存/跳轉規則

狀態：

- 已完成
- auto page 已有獨立 reason，並改走 controller 翻頁入口
- 已新增 `ReaderAutoPageCoordinator` 管理 auto page timer 與狀態
- scroll 模式的 view ticker 仍存在，但「下一步動作決策」已回收到 controller

## Phase 4: Chapter Runtime 補強

### Task 4.1

將高頻章內查詢回收到 `ReaderChapter`：

- `charOffset -> pageIndex`
- `charOffset -> localOffset`
- `pageIndex -> firstCharOffset`

驗收標準：

- controller 對 `ChapterPositionResolver` 的直接依賴顯著下降

狀態：

- 已完成
- `ReaderChapter` 已補章內 offset/alignment/pageIndex helper
- controller / progress / view runtime 已開始優先依賴 chapter runtime helper

## Phase 5: View Runtime / Delegate 清邊界

### Task 5.1

讓 `ReadViewRuntime` 只做 command dispatch 與 widget coordination。

狀態：

- 已完成第二階段重構範圍
- restore lifecycle / scroll auto-page step 決策已回收到 controller
- `ReadViewRuntime` 主要保留 widget coordination 與 scroll execution

### Task 5.2

讓 `ScrollModeDelegate` / `SlideModeDelegate` 只做 mode-specific render 與 interaction bridge。

驗收標準：

- delegate 不再決定 restore / preload / save progress

狀態：

- 已完成
- `SlideModeDelegate` 已改走 controller 的 `handleSlidePageChanged(...)`
- `ScrollModeDelegate` 已改用 chapter runtime helper，不再直接依賴底層 resolver

## Phase 6: Command Guard 與測試

### Task 6.1

新增簡單 command guard：

- restore
- user
- tts
- autoPage
- repaginate

狀態：

- 已完成
- 已新增 `ReaderCommandGuard`
- controller jump / persist 入口已接入 guard

### Task 6.2

補 controller-level integration tests：

- restore to scroll offset
- restore to slide page
- TTS progress 不重複跳轉
- repaginate 後 progress 不漂移
- user scroll 與 programmatic scroll 不互相污染

驗收標準：

- 能穩定覆蓋本次重構新增的 command path

狀態：

- 已完成第一版
- 已補 `ReaderCommandGuard` 測試
- 已補 `ReaderChapter` runtime helper 測試
