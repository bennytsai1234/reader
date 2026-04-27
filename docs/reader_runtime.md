# 閱讀器 Runtime

這份文件描述目前接進 `ReaderPage` 的閱讀器主線。`features/reader/runtime/` 內仍有一些已測試但未完全接進頁面入口的旁支，不能把它們視為目前使用中的主流程。

## 主線入口

- 頁面組裝：`lib/features/reader/reader_page.dart`
- 依賴組裝：`lib/features/reader/controllers/reader_dependencies.dart`
- 核心 runtime：`lib/features/reader/runtime/reader_runtime.dart`
- 章節 repository：`lib/features/reader/engine/chapter_repository.dart`
- 分頁 resolver：`lib/features/reader/engine/page_resolver.dart`
- viewport 分派：`lib/features/reader/viewport/reader_screen.dart`
- slide viewport：`lib/features/reader/viewport/slide_reader_viewport.dart`
- scroll viewport：`lib/features/reader/viewport/scroll_reader_viewport.dart`

`ReaderPage` 在第一次取得 viewport size 後建立 `ReaderRuntime`、`ReaderProgressController`、`ReaderTtsController`、`ReaderAutoPageController`、`ReaderBookmarkController`，並在 post-frame 呼叫 `runtime.openBook()`。

## Durable Location

目前閱讀位置的長期真源是：

```text
ReaderLocation(chapterIndex, charOffset)
```

來源順序：

1. `ReaderOpenTarget.location`
2. `Book.chapterIndex` + `Book.charOffset`

頁碼、PageView index、scroll offset 都是執行期投影，不是 durable progress。

## Runtime State

`ReaderRuntime` 持有 `ReaderState`，主要欄位：

- `mode`：`slide` 或 `scroll`
- `phase`：`cold`、`loading`、`layingOut`、`ready`、`switchingMode`、`error`
- `committedLocation`
- `visibleLocation`
- `layoutSpec`
- `layoutGeneration`
- `pageWindow`
- `currentSlidePage`

`openBook()` 會先 `ChapterRepository.ensureChapters()`，再把初始 location normalize，最後 `jumpToLocation(..., immediateSave: false)`。

## 章節與正文

`ChapterRepository.ensureChapters()` 的順序：

1. 使用 `ReaderPage.initialChapters`
2. 從 `ChapterDao.getByBook()` 讀取
3. 透過 `BookSourceService.getChapterList()` 從書源抓取並寫入 `ChapterDao`

`ChapterRepository.loadContent()` 有 memory cache 與 in-flight 去重。正文載入優先走 `ReaderChapterContentLoader`：

1. `ReaderChapterContentStorage.read()` 取得 raw content。
2. 套用替換規則。
3. 重新分段與標題處理。
4. 依閱讀設定做繁簡轉換。
5. 回傳 `FetchResult`。

若 content DAO 或 replace DAO 不可用，才 fallback 到章節物件上的 `chapter.content`。

## 分頁與 PageWindow

`PageResolver.ensureLayout()` 會：

1. 載入 `BookContent`
2. 呼叫 `LayoutEngine.layout(content, spec)`
3. 依 `layoutSignature` 快取 `ChapterLayout`

`pageForLocation()` 把 `charOffset` 投影成 `TextPage`。`buildWindowAround()` 建立：

```text
PageWindow(prev, current, next)
```

當鄰頁尚未 ready 時，resolver 會產生 loading 或 error placeholder page，viewport 不直接自行補資料。

## 翻頁與 Viewport

### Slide

`SlideReaderViewport` 使用三頁 `PageView`，中心頁固定為 index `1`。使用者翻到 `0` 或 `2` 時：

1. 呼叫 `runtime.moveToPrevPage()` 或 `runtime.moveToNextPage()`
2. runtime 更新 `PageWindow`、`currentSlidePage`、`visibleLocation`
3. viewport 跳回中心頁

### Scroll

`ScrollReaderViewport` 自行維護 `_pageOffset` 與 fling。offset 跨過目前頁高度時，呼叫 runtime 推進或回退 `PageWindow`。拖曳或慣性結束後：

1. `runtime.resolveVisibleLocation(pageOffset, viewportHeight)`
2. `runtime.updateVisibleLocation(location)`
3. `ReaderProgressController.schedule(location)`

## 進度儲存

`ReaderProgressController` 是目前主線進度寫入器：

- `schedule()`：400ms debounce
- `saveImmediately()`：立即 flush
- `flush()`：寫入 pending location

寫入時會更新：

- `book.chapterIndex`
- `book.charOffset`
- `book.durChapterTitle`
- `book.readerAnchorJson = null`

然後呼叫 `BookDao.updateProgress()`。

會觸發 flush 的時機：

- chapter jump / location jump 的 immediate save
- 翻頁或 scroll settle 的 debounce save
- `ReaderPage.dispose()`
- exit intent
- app lifecycle 進入 inactive / paused / detached

## 設定同步

`ReaderSettingsController` 從 `ReaderPrefsRepository` 載入閱讀器設定。`ReaderPage._syncRuntimeConfiguration()` 監控：

- `LayoutSpec.layoutSignature`
- page turn mode
- content settings generation

字級、行距、段距、縮排、letter spacing、padding 等排版設定改變時，呼叫 `runtime.updateLayoutSpec()`，並以目前 `visibleLocation` 重新投影頁面。

繁簡轉換等會改變正文內容的設定改變時，呼叫 `runtime.reloadContentPreservingLocation()`。

## TTS、自動翻頁、書籤

目前接進頁面的控制器在 `lib/features/reader/controllers/`：

- `ReaderTtsController`
- `ReaderAutoPageController`
- `ReaderBookmarkController`
- `ReaderMenuController`
- `ReaderSettingsController`

TTS 主線包裝全域 `TTSService`。開始朗讀時從 `runtime.state.visibleLocation` 讀取章節內容，從 `charOffset` 切出剩餘正文後呼叫 speak。highlight location 由 `speechStartLocation + currentWordStart` 推回，但目前主線不承諾自動 viewport follow。

自動翻頁目前是簡單 timer，預設每 8 秒呼叫一次 `runtime.moveToNextPage()`；若無法前進就停止。

書籤由 `ReaderBookmarkController.addVisibleLocationBookmark()` 讀取目前 visible location 後寫入 `BookmarkDao`。

## 換源

目前可見 UI 流程分兩種：

- 單章換源：`change_chapter_source_sheet.dart`
  - 找候選 source
  - 抓書籍資訊與目錄
  - 以章節標題或原 index 找目標章節
  - 抓正文並寫入 `ReaderChapterContentStore.saveRawContent()`
  - caller reload content

- 整書 fallback 換源：`reader_source_fallback_sheet.dart`
  - 找候選 source
  - 抓書籍與目錄
  - `book.migrateTo(...)`
  - `Navigator.pushReplacement(ReaderPage(... openTarget: resume))`

`ReaderSourceSwitchFacade`、`ReaderSourceSwitchRuntime`、`ReaderSessionFacade.applySourceSwitchResolution()` 仍在 runtime 目錄中，但不是目前 `ReaderPage` 主線入口。

## 未接進主線的 runtime 旁支

以下檔案或子域有測試或候選架構價值，但不能在文件中描述成現行頁面主流程：

- `read_aloud_controller.dart`
- `reader_tts_engine_factory.dart`
- `http_tts_engine.dart`
- `system_tts_engine.dart`
- `switchable_tts_engine.dart`
- `reader_session_facade.dart`
- `reader_source_switch_facade.dart`
- `reader_source_switch_runtime.dart`
- 舊 coordinator / facade 類型的部分 runtime 檔案

後續若要把它們接回主線，應先更新 `ReaderPage` 接線與測試，再更新本文件。

## 對應測試

閱讀器相關測試集中在 `test/features/reader/`，目前覆蓋：

- 章節 repository / content loader / content store
- layout、line、text page serialization
- reader runtime controller / navigation / progress / restore / session
- viewport mailbox / lifecycle / page viewport bridge
- TTS source / engine factory / HTTP TTS / switchable engine
- auto page、bookmark、source switch facade/runtime

最低本地驗證：

```bash
flutter analyze
flutter test test/features/reader
```
