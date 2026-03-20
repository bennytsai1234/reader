# Flutter Reader Architecture (Current)

更新日期：2026-03-20  
範圍：目前 Flutter 文字閱讀器實作，聚焦本地書主鏈。  
目標：整理目前閱讀器在章節提供、分頁、`scroll/slide`、進度恢復、TTS、自動翻頁上的設計脈絡。

## 1. 一句話總結

目前閱讀器已收斂成接近 legado Android 的主鏈：

- 主控：`ReadBookController`
- 章節內容與分頁：`ReaderContentMixin -> ChapterContentManager -> ChapterProvider`
- 共用章節 runtime：`ReaderChapter`
- 顯示：`ReadViewRuntime -> ScrollModeDelegate / SlideModeDelegate`
- 朗讀：`ReadAloudController`

核心原則是：

- `scroll` / `slide` 共用同一套 chapter runtime
- 本地書 `scroll` 只維持 `prev/current/next` 三章 active runtime
- `scroll` 定位、TTS、高亮、自動翻頁都盡量改成同一套「章 -> 頁 -> 頁內 offset」模型

## 2. 主控架構

主控在 [read_book_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_book_controller.dart)。

它負責：

- 閱讀生命週期：`loading -> restoring -> ready`
- 當前閱讀狀態：章節、頁面、可見章節、可見 local offset
- 章節 runtime 快取：`_chapterRuntimeCache`
- `scroll` / `slide` 共用資料入口：`chapterAt()`、`pagesForChapter()`
- TTS / 自動翻頁 / restore / 進度保存的統一串接

目前 `ReadBookController` 對外提供的關鍵能力：

- `chapterAt(index)`：取得 `ReaderChapter`
- `pagesForChapter(index)`：取得共用 page 資料
- `pageFactory`：由 `prev/current/next` 三章組出 slide 模式頁鏈

## 3. 章節提供與內容處理

章節內容主鏈在 [reader_content_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_content_mixin.dart)。

流程如下：

1. `ReadBookController._init()` 建立 `ChapterContentManager`
2. `loadChapterWithPreloadRadius()` 載入目標章
3. `ChapterContentManager` 透過 `_fetchChapterData()` 取得正文
4. 正文經 `ContentProcessor.process(...)`
5. 再交給 `ChapterProvider` 做分頁
6. 分頁結果進 `chapterPagesCache`
7. `refreshChapterRuntime()` 把 pages 包成 `ReaderChapter`

正文來源：

- 本地書：`LocalBookService`
- 網路書：`BookSourceService`

正文處理在 [content_processor.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/engine/reader/content_processor.dart)：

- 去除重複標題
- replace rule 套用
- 簡繁轉換
- re-segment
- 段落縮排與清理

目前這段已經有用 `compute(...)` 把重 CPU 處理移到 isolate。

## 4. 分頁邏輯

分頁中心在 [chapter_provider.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_provider.dart)。

目前有兩條分頁路徑：

- `paginate(...)`：一次產出整章 `List<TextPage>`
- `paginateProgressive(...)`：逐步產出 pages

`paginateProgressive(...)` 是目前本地書 `scroll` 的重點設計：

- 不必等整章都分頁完才顯示
- 先把可見頁產出
- 後續頁面再繼續補

這讓本地書 `scroll` 更接近 legado 的「先能看，再補後續頁面」。

分頁輸出資料模型：

- `TextPage`
- `TextLine`

定位與 offset 換算在 [chapter_position_resolver.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_position_resolver.dart)。

它提供：

- `charOffset -> localOffset`
- `localOffset -> charOffset`
- `charOffset -> pageIndex`
- `localOffset -> pageIndex`

## 5. 快取設計

章節快取協調器在 [chapter_content_manager.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_content_manager.dart)。

目前有三層快取：

- `_contentCache`：正文內容快取
- `_paginatedCache`：記憶體中的分頁快取
- persisted cache：`reader_processed_v2_*` / `reader_paginated_v2_*`

作用：

- 同章重進時減少重新抓內容
- 分頁設定不變時直接還原 pages
- 降低 `paginate(...)` 重算次數

本地書 `scroll` 現在的窗口模型是：

- 只維持 `prev/current/next`
- 視窗外 pages 會被驅逐
- 不再做整本書 warmup

## 6. scroll / slide 共用 chapter runtime

這是目前架構最重要的設計點。

共用的是：

- `ReaderChapter`
- `pagesForChapter(index)`
- `charOffset / localOffset`
- restore / TTS / highlight / 自動翻頁的定位模型

不同的是顯示方式：

### `scroll`

在 [scroll_mode_delegate.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/delegate/scroll_mode_delegate.dart)。

特性：

- 用 `ScrollablePositionedList`
- 每個 chapter item 直接渲染 `ReaderChapter.pages`
- 長卷式閱讀
- 進度依賴 `visibleChapterIndex + visibleChapterLocalOffset`

### `slide`

在 [slide_mode_delegate.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/delegate/slide_mode_delegate.dart)。

特性：

- 用 `PageView`
- 透過 [reader_page_factory.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/reader_page_factory.dart) 從三章 runtime 組成 `slidePages`
- 頁面切換是 page-based

結論：

- `scroll` / `slide` 已不是兩套內容鏈
- 現在是同一套 chapter runtime，不同 delegate 呈現

## 7. 開書與 restore

主 restore 邏輯在 [read_view_runtime.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/read_view_runtime.dart) 和 [reader_progress_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_progress_mixin.dart)。

目前開書流程：

1. `loading`
2. 初始化設定、章節、書源、內容管理器
3. 進入 `restoring`
4. 先確保目標章 pages 可用
5. `scroll` 模式做「章 -> 頁 -> 頁內 offset」定位
6. 定位完成後才切到 `ready`

這代表目前不是：

- 先顯示內容
- 再跳一下到正確位置

而是：

- 先定位
- 再顯示

目前進度保存/恢復也已改成走 `pagesForChapter(...)`，不再直接綁舊的 `chapterPagesCache[...]`。

## 8. TTS / Read Aloud

朗讀主鏈在 [read_aloud_controller.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/runtime/read_aloud_controller.dart)。

現在它已經接到新的 chapter runtime：

- 起點來自 `ReaderChapter.buildReadAloudData()`
- 使用 `offsetMap` 把 TTS 位置映射回章內 offset
- 高亮使用 `ttsStart / ttsEnd`

目前 `scroll` / `slide` 的朗讀行為：

- `slide`：先頁內前後移動，再跨章
- `scroll`：也已跟上，會先在章內 page 前後移動，再跨章

`scroll` 下的高亮定位：

- 會把句子滾到視窗內
- 上方保留一段閱讀緩衝
- 句子大致落在第 2、3 行附近，不再總是貼第一行

## 9. 自動翻頁

自動翻頁基礎在 [reader_auto_page_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_auto_page_mixin.dart)。

目前：

- `slide`：按時間推進 page-based 翻頁
- `scroll`：按時間推進 `localOffset`

真正把 `scroll` 自動翻頁落地的是 [read_view_runtime.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/view/read_view_runtime.dart)：

- 先計算下一個 `localOffset`
- 再用共用 helper 做「章 -> 頁 -> 頁內 offset」滾動
- 不再只是頁首對齊

所以現在：

- restore
- TTS
- 自動翻頁

三者在 `scroll` 模式下，已盡量統一成同一套定位模型。

## 10. 目前的設計重點

目前這版閱讀器可以這樣理解：

- `ReadBookController` 是閱讀器狀態機
- `ChapterContentManager` 是內容/分頁/快取協調器
- `ReaderChapter` 是共用 chapter runtime
- `ReadViewRuntime` 是共用 view runtime
- `scroll` / `slide` 只是不同 delegate
- `ReadAloudController`、restore、自動翻頁都盡量共用同一套章內定位邏輯

## 11. 目前仍需持續關注的點

目前仍可能存在的性能與體感風險：

- 新章進入時，`paginateProgressive(...)` 雖已改善，但仍可能有輕微主執行緒壓力
- 本地書跨章時，鄰章補載仍可能在某些時機造成微卡
- `scroll` restore 已大幅改善，但若要做到更穩的句子級恢復，未來仍可考慮加入更完整 snapshot

整體來說，目前已完成的方向是：

- 從多條資料鏈，收斂成單一 chapter runtime
- 從整章 ready，往頁級漸進顯示靠攏
- 從 page-based scroll restore，收斂成章內 offset restore
- 讓 `scroll` / `slide` / TTS / 自動翻頁逐步使用同一套閱讀位置語言
