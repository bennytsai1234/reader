# Reader Recovery Option 2: Refactor Current Reader

## 建議採用

這是推薦方案。

目標不是小修小補，而是把目前 `ReaderRuntime` 主線收斂成穩定架構。舊版只作行為參考與測試來源，不把 `ReadBookController` 搬回來。

## 目標架構

長期真源：

```text
ReaderLocation(chapterIndex, charOffset)
```

精準恢復輔助：

```text
ReaderAnchor(
  location,
  pageIndexSnapshot?,
  localOffsetSnapshot?,
  contentHash?,
  layoutSignature?
)
```

主線責任：

```text
ReaderPage
  -> ReaderRuntime
     -> ChapterRepository
     -> PageResolver
     -> LayoutEngine
     -> ReaderProgressController
  -> EngineReaderScreen
     -> SlideReaderViewport / ScrollReaderViewport
```

原則：

- DB 只保存 durable progress 與可驗證 anchor。
- runtime 是唯一閱讀狀態真源。
- viewport 不直接持久化，不直接決定章節正文生命周期。
- 頁碼、PageView index、scroll offset 都是 runtime projection，不是 durable truth。
- placeholder/loading/error 不能被保存成閱讀進度。

## Phase 0: 凍結與基線

目的：避免邊分析邊污染主線。

工作：

- 保持 git worktree 乾淨。
- 建立 reader recovery 分支。
- 記錄目前能過的測試與不能過的測試。
- 保留 `reader-0.2.28` 作為行為對照，不直接覆蓋現有程式碼。

驗收：

- `git status --short` 乾淨。
- 已有基線測試輸出。

## Phase 1: 資料庫與進度欄位

這是最高優先級。

目前問題：

- 舊版 schemaVersion 是 10。
- 新版 schemaVersion 是 1。
- 舊版欄位是 `durChapterIndex/durChapterPos`。
- 新版欄位是 `chapterIndex/charOffset`。

推薦做法：

1. 把 schemaVersion 提升到 11 或更高，不允許降版。
2. `books` table 支援從舊欄位遷移：
   - 如果缺 `chapterIndex`，新增並從 `durChapterIndex` backfill。
   - 如果缺 `charOffset`，新增並從 `durChapterPos` backfill。
   - 如果舊欄位存在，可以暫時保留，不要急著 drop。
3. `beforeOpen` 做自我修復：
   - 檢查 `PRAGMA table_info(books)`。
   - 缺欄位時補欄位。
   - 新舊欄位互相 backfill。
4. backup/restore、book detail、bookshelf update、source switch 都統一讀寫新版欄位。
5. 加 migration test，使用模擬舊 schema 建庫後升級。

驗收：

- 0.2.28 資料庫升級後，`chapterIndex/charOffset` 等於舊 `durChapterIndex/durChapterPos`。
- 新資料庫建庫正常。
- 已經被目前 dev 版本建成 schemaVersion 1 的資料庫也能升到新版本。

## Phase 2: 進度寫入與 flush

目前 `ReaderProgressController` 太簡化，active write 期間的新 pending location 可能不會被 drain。

重構要求：

- 使用 latest-wins queue。
- `flush()` 必須 drain 到沒有 pending location。
- active flush 期間收到新 location，active 結束後要立即接著寫新 location。
- `dispose`、exit intent、app lifecycle 都要呼叫 drain flush。
- DB 寫失敗要記錄，但不能讓 in-memory state 假裝已 durable saved。

推薦流程：

```text
schedule(location)
  pending = normalized(location)
  debounce timer -> flush()

flush()
  if already flushing: mark drain requested and return same chain
  while pending exists:
    take latest pending
    write to DB
    remember saved location / anchor
```

測試必須覆蓋：

- debounce 只寫最後位置。
- active write 中 schedule 新位置，flush 結束後最後位置被寫出。
- `flush()` 被連續呼叫不重複寫同一位置。
- lifecycle flush 能寫出最後位置。
- placeholder page 不寫入。

## Phase 3: 恢復 `ReaderAnchor`，但不改 durable truth

`chapterIndex + charOffset` 仍是唯一 durable progress。`ReaderAnchor` 只用於精準 restore。

保留 anchor 的條件：

- `contentHash` 和 `layoutSignature` 匹配，才能使用 `localOffsetSnapshot` 或 `pageIndexSnapshot`。
- 不匹配時退回 `chapterIndex + charOffset` 重算。
- scroll restore 初期 layout 未完整時，可以暫用舊 snapshot，但完成 layout 後要用實際 line layout 校正。

要避免：

- 把舊 localOffset 當成永久真源。
- 內容變了還相信舊 page snapshot。
- restore 期間 visible 暫態被 debounce 寫成正式進度。

## Phase 4: 排版與位置映射收斂

所有位置映射都應由 `LineLayout` / `ChapterLayout` 提供。

要求：

- `TextLine` 明確保存 `startCharOffset/endCharOffset`。
- `ChapterLayout.pageForCharOffset()` 使用頁面範圍，不只看 page start。
- title-only page 不應成為 durable restore target。
- `charOffset -> page/localOffset` 與 `localOffset -> charOffset` 同源。
- `LayoutSpec.layoutSignature` 必須包含所有影響排版的設定。

測試：

- title-only page restore。
- page boundary：上一頁 end 與下一頁 start 的邊界。
- 字級、行距、padding、段距變更後位置保持。
- 繁簡轉換或替換規則改變後，content hash 改變，anchor snapshot 失效。

## Phase 5: scroll viewport 重構

目前 scroll viewport 同時有自己的 chapter loading、estimated extent、global offset 計算，容易跟 runtime 競爭。

推薦方向：

1. runtime 產生 scroll presentation：
   - current anchor chapter
   - loaded chapter window
   - estimated/actual extent
   - layout generation
2. viewport 只渲染 presentation，回報：
   - `onVisibleAnchorChanged(ReaderLocation or localOffset)`
   - `onUserScrollSettled`
   - `onRequestLoadAround`
3. chapter load 完成後，runtime 計算 anchor compensation，viewport 只執行 scroll command。
4. 保留舊版「restore pending token」概念：
   - restore 未完成前阻止 auto page / TTS follow / user scroll 寫進度。
   - restore 完成後才允許正常 visible progress commit。

是否使用 `ListView`、`CustomScrollView` 或 `ScrollablePositionedList` 不是核心。核心是責任邊界要清楚。

驗收：

- scroll 初始 restore 到非 0 charOffset。
- scroll 中章節從 estimated height 換成 actual height，不產生明顯跳動。
- 快速滑動後退出，重開到最後可視位置。
- 跨章 scroll 保存正確章節。
- 模式切換後位置不漂移。

## Phase 6: slide viewport 重構

slide 可以保留目前 `PageWindow(prev/current/next)` 方向。

要求：

- center/current 永遠由 runtime 決定。
- 翻頁 animation 結束後只 commit 一次 progress。
- 跨章鄰頁 loading 時不可保存 placeholder。
- layout generation 改變時取消動畫並重建 presentation。
- chapter jump、bookmark jump、settings repaginate 都走同一個 `jumpToLocation`。

驗收：

- 章尾下一頁進下一章章首。
- 章首上一頁回上一章章末。
- 快速連翻不丟 pending progress。
- 字級變更後仍在同一 charOffset 對應頁。

## Phase 7: 章節內容接入

保留目前 `ChapterRepository` 方向，但補齊契約：

- 章節目錄來源順序：initial chapters -> DB -> source fetch。
- 正文來源順序：materialized content -> source/local materialize -> chapter fallback。
- 失敗狀態要可區分 loading/error/empty，不把錯誤文字當正常正文。
- content cache key 要包含 source/book/chapter/content settings。
- replace rule、reSegment、Chinese convert 改變時，content/layout cache 要正確失效。

驗收：

- 本地 TXT 可開。
- 已快取章節可離線開。
- 遠端正文失敗顯示 error，不保存 error placeholder 為閱讀進度。
- 換源後 reload content 並保留 `chapterIndex + charOffset` 語義。

## Phase 8: 清理旁支

目前 runtime 目錄中仍有一些測試或候選架構，但不一定接主線。

處理方式：

- 真正接主線的保留並補文檔。
- 未接主線但有價值的移到 `legacy` 或加明確註記。
- 無價值或誤導的測試刪掉或改成主線測試。
- `docs/reader_runtime.md` 必須只描述真實入口。

## 最終驗證清單

自動測試：

```bash
flutter analyze
flutter test test/features/reader
flutter test test/core test/features/book_detail test/features/bookshelf
```

人工測試：

- 舊資料庫升級。
- 空資料庫第一次開書。
- 本地 TXT。
- 遠端書源。
- slide 連翻。
- scroll 快速滑動與退出。
- 切換字級、行距、padding。
- slide/scroll 反覆切換。
- background/foreground。
- 單章換源與整書 fallback 換源。

## 最終判斷

這條路能最大化保留新版的正確方向，同時拿回舊版已經證明重要的 restore/anchor/flush 經驗。它的成本比退回高，但比完全重做低，而且會把 reader 的核心問題一次性收斂。

