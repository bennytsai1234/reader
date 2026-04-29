# Reader Layout Boundary Repair Plan

日期：2026-04-29

## 目的

這份文件描述 reader 分頁、layout、runtime、viewport、painter 的邊界修復方案。

目前 reader 主幹已經能運作，但 layout 資料有過渡期留下的重疊表示：

```text
ChapterLayout.lines
TextPage.lines
LineLayout.fromPages(...)
PageCache.lines
```

這些資料彼此可以互相換算，但長期維護時會讓人不確定哪一份才是唯一真相。這份修復計劃的目標是把資料流收斂成：

```text
BookContent.displayText 是文字真相
ChapterLayout.lines 是 layout 真相
PageLayout / TextPage 只是 page 切片
Viewport 只做螢幕位移
Painter 只畫傳入的 lines
```

這不是 UI 重設計，也不是 DB 兼容修復。依目前 reader 開發政策，優先保證新安裝、新資料庫、目前 runtime 的閱讀正確性。

## 現況問題

目前分頁流程大致是：

```text
BookContent
  -> LayoutEngine 產生章節連續 lines
  -> _paginate() 把 lines 複製成 TextPage.lines，也就是頁內座標
  -> _chapterLocalLinesFromPages() 又從 TextPage.lines 重建 ChapterLayout.lines
  -> scroll viewport 用 LineLayout.fromPages() 再從 TextPage.pages 推回章節連續座標
  -> PageCache 再包一份 render tile 資料
```

這個流程能運作，但有三個維護風險：

1. 同一行文字同時存在「頁內座標」和「章節連續座標」兩種版本。
2. scroll、slide、TTS highlight、restore 都可能從不同模型查 line / page。
3. 未來修改分頁、段距、標題、padding、進度保存時，很容易只修到其中一條路徑。

修復方向不是把所有類別刪掉，而是先定義唯一真相，再逐步讓其它類別變薄。

## 目標資料流

整理後的資料流應該是：

```text
raw chapter text
  -> BookContent
  -> LayoutEngine
  -> ChapterLayout
  -> PageResolver
  -> ReaderRuntime
  -> ScrollReaderViewport / SlideReaderViewport
  -> ReaderTilePainter
  -> Canvas
```

每一層只做一件事：

```text
BookContent          文字正規化
LayoutEngine         斷行與分頁
ChapterLayout        layout 查詢真相
PageResolver         載入、快取、找前後頁
ReaderRuntime        閱讀狀態與進度
Viewport             手勢與螢幕位置
ReaderTilePainter    Canvas 繪製
```

## 邊界合約

### BookContent

職責：

```text
只管原始章節文字正規化，產生唯一 displayText。
```

輸入：

```text
chapterIndex
title
rawText
```

輸出：

```text
chapterIndex
title
paragraphs
plainText
displayText
bodyStartOffset
contentHash
```

規則：

- `displayText` 是唯一文字真相。
- 標題也在 `displayText` 裡。
- durable `charOffset` 永遠對應 `displayText`。
- `paragraphs` 可以服務排版，但不能成為第二份閱讀真相。

不得做：

- 不斷行。
- 不分頁。
- 不碰螢幕尺寸。
- 不碰進度保存。

### LayoutEngine

職責：

```text
唯一負責斷行與分頁，輸出唯一 ChapterLayout。
```

輸入：

```text
BookContent
LayoutSpec
chapterSize
```

輸出：

```text
ChapterLayout
```

要求：

- 先排出章節連續座標的 `TextLine`。
- 每一行都要在這裡切乾淨，包括標題、段落、offset、top/bottom/baseline。
- 分頁只應該把已排好的 lines 分組，不應該修改 line 的語意。
- layout cache key 應由 `contentHash + layoutSignature + chapterSize` 決定。

不得做：

- 不載入章節。
- 不保存 DB。
- 不處理 scroll / slide 手勢。
- 不為 scroll 和 slide 各生一份 layout truth。

### ChapterLayout

職責：

```text
唯一 layout truth。
```

資料：

```text
chapterIndex
displayText
contentHash
layoutSignature
lines
pages
contentHeight
```

`lines` 必須是章節連續座標：

```text
TextLine.top / bottom = chapter localY
```

`pages` 應逐步收斂成 page 切片：

```text
pageIndex
pageCount
startLineIndex
endLineIndexExclusive
startCharOffset
endCharOffset
localStartY
localEndY
viewportHeight
```

查詢 API：

```text
pageForCharOffset(charOffset)
lineForCharOffset(charOffset)
linesForPage(pageIndex)
lineAtLocalY(chapterLocalY)
pageForLocalY(chapterLocalY)
linesForRange(startCharOffset, endCharOffset)
```

規則：

- `ChapterLayout.lines` 是 anchor、restore、TTS highlight、scroll mapping、slide mapping 的共同真源。
- 如果 painter 需要頁內座標，只在輸出給 painter 時轉換：

```text
pageLocalY = line.top - page.localStartY
```

不得做：

- 不重新排版。
- 不載入資料。
- 不更新 runtime state。
- 不保存進度。

### PageResolver

職責：

```text
只管載入章節、快取 layout、找目前頁 / 前頁 / 後頁。
```

輸入：

```text
chapterIndex
ReaderLocation
current page
LayoutSpec
```

依賴：

```text
ChapterRepository
LayoutEngine
```

輸出：

```text
ensureLayout(chapterIndex) -> ChapterLayout
pageForLocation(location) -> page
buildWindowAround(location) -> PageWindow
nextPage(page) -> page?
prevPage(page) -> page?
cachedLayout(chapterIndex) -> ChapterLayout?
```

不得做：

- 不決定閱讀模式。
- 不處理手勢。
- 不保存進度。
- 不把頁面畫上螢幕。
- 不產生 scroll 專用或 slide 專用 layout。

### ReaderRuntime

職責：

```text
只管閱讀 session 狀態、進度、模式切換。
```

輸入：

```text
Book
ReaderLocation
LayoutSpec
ReaderMode
PageResolver result
viewport capture callback
```

輸出：

```text
ReaderState
jumpToLocation(location)
jumpToChapter(chapterIndex)
applyPresentation(spec, mode)
moveToNextPage()
moveToPrevPage()
saveProgress()
flushProgress()
```

規則：

- Runtime 不重新推 layout。
- Runtime 不知道 scroll Y 或 slide X 如何實作。
- Runtime 只接受 viewport 回報的 `ReaderLocation`。
- durable progress 只保存：

```text
chapterIndex
charOffset
visualOffsetPx
```

不得做：

- 不斷行。
- 不分頁。
- 不從 page lines 反推 layout truth。
- 不直接處理 widget 手勢位移。

### ScrollReaderViewport / SlideReaderViewport

職責：

```text
只管手勢、位移、把 page 放到螢幕座標。
```

共同輸入：

```text
ReaderState
ChapterLayout / PageWindow
ReadStyle
viewport size
gesture events
```

共同輸出：

```text
visible page placements
visible location capture callback
restore callback
ReaderTilePainter input
```

scroll 模式核心：

```text
virtualScrollY = runtime-only
screenY = pageVirtualTop - virtualScrollY
```

slide 模式核心：

```text
prev slot    = -1
current slot = 0
next slot    = 1
screenX = width * slot + dragDx
```

不得做：

- 不重新斷行。
- 不重新分頁。
- 不修改 `TextLine`。
- 不保存 DB，最多通知 runtime 保存。
- 不維護第二份 page / line truth。

### ReaderTilePainter

職責：

```text
只把傳進來的 lines 畫上 Canvas。
```

輸入：

```text
page
lines
ReadStyle
backgroundColor
textColor
Size
```

繪製公式：

```text
lineYOnPage = line.top - page.localStartY
screenX = style.paddingLeft
screenY = style.paddingTop + lineYOnPage
```

不得做：

- 不查章節。
- 不查 runtime。
- 不找前後頁。
- 不計算閱讀進度。
- 不改 `charOffset`。
- 不斷行、不分頁。

## 修復原則

### 1. 不做大爆炸重寫

`TextPage`、`PageCache`、`LineLayout` 目前被多處測試和 viewport 使用。修復時應採取兼容式收斂：

```text
先補 ChapterLayout API
再讓 viewport 改用 ChapterLayout 查詢
再把 TextPage / PageCache 降級成 view model
最後移除不再使用的反推工具
```

### 2. 先保進度語意

所有階段都必須維持：

```text
ReaderLocation(chapterIndex, charOffset, visualOffsetPx)
```

不允許重新引入 durable pageIndex、scroll offset、virtualScrollY。

### 3. 先保新安裝正確性

這次修復不以舊開發 DB schema 或舊 reader layout 快取兼容為阻塞項。只要目前 Drift schema、model、runtime、fresh install 行為一致即可。

### 4. 每一步都能測

每個階段都應能跑：

```bash
flutter test test/features/reader
flutter analyze
```

如果階段太大，至少先跑相關測試：

```bash
flutter test test/features/reader/page_cache_test.dart test/features/reader/line_layout_test.dart test/features/reader/reader_tile_viewport_test.dart
```

## 建議實作順序

### Phase 0：建立現況保護

目的：在改模型前先鎖住行為。

工作：

- 補測試確認 `displayText` 包含標題，且 `charOffset` 對應最終 display text。
- 補測試確認 `TextLine` 的 `isTitle`、`paragraphNum`、`startCharOffset/endCharOffset` 正確。
- 補測試確認 scroll capture / restore 使用同一個 anchor 規則。
- 補測試確認 slide 翻頁 settle 不保存 placeholder page。

驗收：

- 目前 reader 測試全過。
- 測試名稱能直接描述 invariant。

### Phase 1：補齊 ChapterLayout 查詢 API

目的：讓使用者不用再靠 `LineLayout.fromPages()` 反推座標。

工作：

- 增加 `linesForPage(pageIndex)`。
- 增加 `pageForLine(line)` 或等價查詢。
- 確認 `lineForCharOffset()`、`lineAtOrNearLocalY()`、`linesForRange()` 全部基於 `ChapterLayout.lines`。
- 讓 TTS highlight / scroll capture 優先走 `ChapterLayout` 查詢。

驗收：

- 新增查詢測試。
- `LineLayout.fromPages()` 的新使用點不再增加。

### Phase 2：引入 PageLayout 概念或讓 TextPage 變薄

目的：把 page 從「持有另一份 lines」改成「描述章節 lines 的切片」。

可選做法：

```text
方案 A：新增 PageLayout，逐步取代 TextPage。
方案 B：保留 TextPage 類名，但讓它內部只存 line range，lines 由 ChapterLayout 查詢產生。
```

建議先用方案 A，因為語意比較清楚；若改動面太大，可以先用方案 B 過渡。

PageLayout 應包含：

```text
chapterIndex
pageIndex
pageSize
startLineIndex
endLineIndexExclusive
startCharOffset
endCharOffset
localStartY
localEndY
contentHeight
viewportHeight
isChapterStart
isChapterEnd
```

驗收：

- page 不再是另一份 line truth。
- page 的 `startCharOffset/endCharOffset` 由 line range 推出。
- layout test 能證明頁切片與 lines 一致。

### Phase 3：整理 LayoutEngine

目的：`LayoutEngine` 只產生一份章節連續 lines，分頁只產生切片。

工作：

- `_layoutBlock()` 保持唯一斷行入口。
- `_paginate()` 不再複製頁內 `TextLine`。
- 刪除或改寫 `_chapterLocalLinesFromPages()`。
- 所有 line 的 `top/bottom/baseline` 都保持章節連續座標。

驗收：

- `ChapterLayout.lines` 不需要從 pages 重建。
- `ChapterLayout.pages` 與 `ChapterLayout.lines` 的 line range 完全一致。

### Phase 4：整理 PageResolver / PageWindow

目的：resolver 只傳 page 切片，不傳第二份 page line truth。

工作：

- `pageForLocation()` 回傳 page 切片。
- `nextPage()` / `prevPage()` 以 layout pages 為準。
- `PageWindow` 保持 prev/current/next，但 page 不應持有第二份 lines。

驗收：

- 跨章上一頁 / 下一頁行為不變。
- placeholder page 仍不會 settle 成 durable progress。

### Phase 5：整理 Viewport

目的：viewport 只做螢幕位移與 anchor capture。

scroll 工作：

- page placement 使用 `ChapterLayout.pages`。
- anchor capture 使用 `ChapterLayout.lineAtLocalY()`。
- 不再用 `LineLayout.fromPages()` 反推章節 localY。

slide 工作：

- 三頁槽位邏輯維持不變。
- capture current page 時，從 `ChapterLayout.linesForPage()` 找 anchor line。
- TTS ensure visible 透過 `ChapterLayout.pageForCharOffset()` 判斷是否要跳頁。

驗收：

- scroll 上下滑動、跨章滑動、恢復位置一致。
- slide 左右翻頁、跨章翻頁、恢復位置一致。
- TTS highlight 跟隨仍正常。

### Phase 6：整理 Render Tile

目的：`PageCache` 變成薄 render view model，或直接由 painter 接 `page + lines`。

工作：

- `PageCache.lines` 由 `ChapterLayout.linesForPage(pageIndex)` 生成，不作為 truth。
- `ReaderTilePainter` 接近純函式：page、lines、style、colors、size -> canvas。
- 移除不必要的 `PageCache.fullLineRectsForRange()` 或改成委託 `ChapterLayout`。

驗收：

- scroll / slide 共用同一套 painter。
- TTS highlight rect 仍能從同一套 lines 算出。
- repaint key 仍能反映 layout generation、chapter、page、offset。

### Phase 7：刪除過渡層

目的：移除已失去必要性的舊轉換。

候選：

```text
LineLayout.fromPages()
_chapterLocalLinesFromPages()
TextPage.lines 作為 truth 的用法
PageCache 作為獨立 truth 的用法
```

驗收：

- 搜尋不到 viewport 直接從 page lines 反推章節 localY。
- 文件與程式碼都只描述一套 layout truth。
- `docs/reader_current_state.md` 同步更新。

## 驗收標準

修復完成後，必須符合：

- `BookContent.displayText` 是唯一文字真相。
- `ChapterLayout.lines` 是唯一 layout 真相。
- `TextLine` 在分頁時已切乾淨：標題、段落、offset、top/bottom/baseline 都完整。
- `PageLayout` / `TextPage` 不再保存第二份 line truth。
- `LineLayout.fromPages()` 不再是 runtime 必要路徑。
- scroll / slide 使用同一份 `ChapterLayout` 查詢 API。
- painter 不查 runtime，不算進度，不分頁。
- durable progress 仍然只有 `ReaderLocation(chapterIndex, charOffset, visualOffsetPx)`。

## 風險與注意事項

### 最大風險：座標系轉換

目前 painter 使用頁內座標，目標 layout truth 使用章節連續座標。修復時最容易出錯的是：

```text
line.top
page.localStartY
style.paddingTop
screenY
```

所有轉換都要明確寫成：

```text
pageLocalY = line.top - page.localStartY
screenY = style.paddingTop + pageLocalY
```

### 第二風險：跨章 window

scroll 模式會同時保留前後章，且 `_virtualScrollY` 是 runtime-only。整理時不能把 `_virtualScrollY` 保存進 DB，也不能讓章節 virtual top 變成 durable truth。

### 第三風險：placeholder

loading / error / placeholder page 可以顯示，但不能產生正式閱讀位置，也不能被 settle 成 durable progress。

## 文件同步

修復完成後要同步更新：

```text
docs/reader_current_state.md
docs/reader_mobile_test_plan.md   如果手機測試項目有變
AGENTS.md / CLAUDE.md             如果 reader invariant 有變
```

這份文件在修復完成後應移到歷史文件狀態，避免後續誤以為仍有未完成任務。
