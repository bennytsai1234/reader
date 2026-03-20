# legado Android 閱讀器 vs Flutter 閱讀器對照分析

## 目的

這份文件只聚焦你提的五條主線：

1. 章節提供
2. 分頁
3. `scroll` / `slide`
4. 進度
5. 朗讀

整理方式採用：

- `legado` 怎麼串
- Flutter 版目前怎麼串
- 兩者的核心差異
- 對我們 Flutter 版的實際含義

附註：

- 本文件內容以目前 repo 內可讀到的程式碼為準。
- 不引用 [reader_logic_chain_verification.md](/C:/Users/benny/Desktop/Folder/Project/reader/ios/doc/reader_logic_chain_verification.md) 的結論。
- 凡是屬於推估、傾向、設計判讀的地方，都會明確寫成「我對目前程式碼的判讀」，不當成既定事實。

---

## 1. 總體架構差異

### legado 的核心形狀

`legado` 的閱讀器主軸是「單一全域閱讀狀態 + 單一閱讀視圖」：

- `ReadBook` 持有當前閱讀的核心狀態，包含 `durChapterIndex`、`durChapterPos`、`prev/cur/nextTextChapter`，並負責切章、存進度、預載、朗讀接續。
- `ReadBookActivity` 是 UI 協調者，接 `ReadBook` callback，把資料推進 `ReadView`。
- `ReadView` 是單一閱讀容器，內部再透過不同 `PageDelegate` 切換 `scroll`、`slide`、模擬翻頁等模式。
- `ChapterProvider` + `TextChapterLayout` 負責把章節內容排版成 `TextChapter -> TextPage -> TextLine`。

也就是說，`legado` 是把「閱讀狀態機、章節生命週期、翻頁模式、朗讀」全部綁在同一套 runtime 裡。

### Flutter 版目前的核心形狀

Flutter 版改成「Provider + mixin + content manager + mode-specific UI」：

- `ReaderProvider` 是入口，初始化時串起設定、章節列表、來源、內容管理、TTS 與 auto page。
- `ReaderContentMixin` 負責章節載入、分頁、視窗預載與 `slidePages/chapterPagesCache` 組裝。
- `ChapterContentManager` 負責內容抓取、內容快取、分頁快取、預載佇列。
- `ReaderViewBuilder` 直接分成兩套 render path：
  - `PageView` 走 `slide`
  - `ScrollablePositionedList` 走 `scroll`
- `ReaderTtsMixin` 直接從已分頁的 `TextLine` 組出朗讀文字與 offset map，再驅動 `TTSService`。

Flutter 版把 `legado` 原本集中在 `ReadBook + ReadView` 的責任拆散了，模組化更好，但跨模組協調成本也比較高。

---

## 2. 章節提供

### legado 怎麼串

主線在 [ReadBook.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/model/ReadBook.kt) 與 [ChapterProvider.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/provider/ChapterProvider.kt)。

- `ReadBook.loadContent(resetPageOffset)` 會一次觸發「當前章、下一章、上一章」的內容載入。
- `ReadBook.loadContent(index, ...)` 先取章節內容；拿到 raw content 後再交給 `ChapterProvider.getTextChapterAsync(...)`。
- `getTextChapterAsync(...)` 不是同步整章做完才回傳，而是先建立 `TextChapter`，再由 `TextChapterLayout` 背景排版，透過 `LayoutProgressListener` 逐頁把排版結果回推 UI。
- `ReadBook` 永遠維持 `prevTextChapter / curTextChapter / nextTextChapter` 這三格窗口，切章時直接平移這三格，再補載下一格。

這代表 `legado` 的章節提供其實是「內容下載」和「章節排版」一起被包在閱讀狀態機裡。

### Flutter 版目前怎麼串

主線在 [reader_provider.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/reader_provider.dart)、[reader_content_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_content_mixin.dart)、[chapter_content_manager.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_content_manager.dart)。

- `ReaderProvider._init()` 會先載章節列表與來源，再 `initContentManager()`。
- `loadChapterWithPreloadRadius()` 會更新目前章節、要求 `ChapterContentManager` 更新 window，然後載入目標章，並靜默預載鄰章。
- `ChapterContentManager` 把「抓內容」、「內容快取」、「分頁快取」、「預載 queue」集中處理。
- `chapterPagesCache` 保存每章分頁結果，`slidePages` 再把前後章的頁面合併成橫向翻頁資料源。

### 核心差異

- `legado` 是 `prev/cur/next TextChapter` 三槽模型。
- Flutter 是 `chapterPagesCache + slidePages` 的 cache/window 模型。
- `legado` 章節載入後可以邊排版邊可見。
- Flutter 目前大多是「該章分頁完成後，再放進 cache / UI」。

### 對 Flutter 版的含義

- Flutter 版的內容管線更乾淨，也比較容易測試。
- 但它不像 `legado` 那樣有「排版中的章節物件」這個中介層，所以少了漸進式排版回饋。
- 如果之後要追 legado 的閱讀手感，`scroll` 模式在大章節上的首屏等待、漸進排版、切章瞬間過渡，會是第一個差距點。

---

## 3. 分頁

### legado 怎麼串

主線在 [ChapterProvider.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/provider/ChapterProvider.kt)、[TextChapter.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/entities/TextChapter.kt)、[TextPageFactory.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/provider/TextPageFactory.kt)。

- `ChapterProvider` 是全域 layout/config 中心，持有 view size、padding、visible rect、paint、字型、double page 等資訊。
- `TextChapterLayout` 依這些全域 layout 參數把章節拆成 `TextPage` / `TextLine`。
- `TextChapter` 負責 `chapterPosition -> page index`、上一頁/下一頁位置、朗讀文字片段等查詢。
- `TextPageFactory` 再把目前閱讀位置包成 `curPage / prevPage / nextPage / nextPlusPage`，提供 `ReadView` 與動畫 delegate 使用。

也就是說，`legado` 的分頁不只是產生頁陣列，而是直接服務整個翻頁 runtime。

### Flutter 版目前怎麼串

主線在 [chapter_provider.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_provider.dart) 與 [chapter_content_manager.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_content_manager.dart)。

- Flutter 的 `ChapterProvider.paginate(...)` 是近乎純函式的分頁器。
- 它吃進 `content + viewSize + textStyle + paragraphSpacing + indent`，輸出 `List<TextPage>`。
- `ChapterContentManager._doPaginate()` 會先查分頁 cache，沒有才真正 paginate。
- 頁面位置換算另外交給 `ChapterPositionResolver`，而不是讓 `TextChapter` 自己承擔。

### 核心差異

- `legado` 的分頁器是整個閱讀 runtime 的一部分。
- Flutter 的分頁器更像「純運算元件」，頁面導航與位置換算分散到其他 class。

### 對 Flutter 版的含義

- 現在的 Flutter 分頁器更容易快取與重算，方向是對的。
- 但如果要完全對標 legado，還缺一層更強的「chapter runtime object」去承接：
  - 逐頁完成通知
  - page-level query
  - 朗讀切段
  - mode-specific lookup

目前這些責任分散在 `ChapterProvider`、`ChapterPositionResolver`、`ReaderTtsMixin` 幾個地方。

---

## 4. `scroll` / `slide`

### legado 怎麼串

主線在 [ReadView.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/ReadView.kt)、[ScrollPageDelegate.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/delegate/ScrollPageDelegate.kt)、[SlidePageDelegate.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/delegate/SlidePageDelegate.kt)。

- `ReadView.upPageAnim()` 依 `ReadBook.pageAnim()` 選擇 delegate。
- 不管是 `scroll` 還是 `slide`，都還是在同一個 `ReadView` 裡，只是互換 delegate。
- `TextPageFactory` 仍然提供相同的 `cur/prev/next` 頁資料。
- `scroll` 模式靠 `ScrollPageDelegate` 操作目前 `PageView` 內部的偏移。
- `slide` 模式靠 `HorizontalPageDelegate` 系列操作前後頁 recorder 與動畫。

這個設計的關鍵是：模式不同，但閱讀狀態與頁來源是同一套。

### Flutter 版目前怎麼串

主線在 [reader_view_builder.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/widgets/reader_view_builder.dart)。

- `slide` 走 `PageView.builder`，資料源是 `slidePages`。
- `scroll` 走 `ScrollablePositionedList.builder`，資料源是每章 `chapterPagesCache[chapterIndex]`。
- `ReaderViewBuilder` 監看 provider state，處理：
  - pending page jump
  - pending chapter jump
  - scroll mode 的可見章節回報
  - TTS 跟隨捲動
  - scroll auto page ticker

### 核心差異

- `legado` 是單一 view + 多 delegate。
- Flutter 是兩套不同 widget tree。

### 對 Flutter 版的含義

這是目前最明顯的架構差異。

優點：

- Flutter 寫起來比較符合框架習慣。
- `scroll` / `slide` 各自最佳化比較直覺。

代價：

- 兩種模式的進度同步、TTS 跟隨、auto page、restore、預載邏輯，現在都要分情境處理。
- 只要某個 feature 只補了一邊，就很容易出現 mode parity 問題。

換句話說，`legado` 的優勢是模式共用同一套狀態面；Flutter 版現在的風險是「功能一致性要靠人維護」。

---

## 5. 進度

### legado 怎麼串

主線在 [ReadBook.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/model/ReadBook.kt)。

- 閱讀進度的單一真源是 `ReadBook.durChapterIndex + durChapterPos`。
- 翻頁、切章、跳頁後都會回寫 `saveRead(...)`。
- `saveRead(...)` 會把目前章索引、章內位置、章標題更新回資料庫。
- `TextChapter.getPageIndexByCharIndex(...)` 讓進度核心仍然維持在「章內字元位移」，頁碼只是展示/導航用。

`legado` 的本質是以 `char offset` 當 canonical progress，但由 `ReadBook` 這個 singleton 集中持有。

### Flutter 版目前怎麼串

主線在 [reader_progress_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_progress_mixin.dart) 與 [reader_content_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_content_mixin.dart)。

- Flutter 版也把 `book.durChapterIndex + book.durChapterPos` 當 canonical progress。
- `slide` 模式下，`onPageChanged()` 會把頁索引換算回該頁在章內的 char offset 再存檔。
- `scroll` 模式下，`updateVisibleChapterPosition()` 會把 `localOffset` 經 `ChapterPositionResolver.localOffsetToCharOffset()` 換回 char offset，再做 debounce 儲存。
- `jumpToPosition()` 也統一以 `charOffset` 作入口，依模式換算成 page jump 或 chapter/local offset jump。

### 核心差異

- 兩邊都以 `char offset` 為最終進度語意。
- `legado` 把它綁在 `ReadBook` 與 `TextChapter`。
- Flutter 把它拆成 `ReaderProgressMixin + ChapterPositionResolver`。

### 對 Flutter 版的含義

從目前程式碼看，Flutter 版在「不同模式都統一回到 char offset」這件事上，落點是清楚的。

目前需要注意的不是模型本身，而是 mode parity：

- `scroll` 的 visible chapter / local offset 更新時機
- `slide` 的跨章合併頁索引
- TTS 存回進度時要不要以 highlight start 為準

這些在現有設計裡都已經有明確落點，但很依賴 listener 與 jump 命令不要打架。

---

## 6. 朗讀

### legado 怎麼串

主線在 [ReadBook.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/model/ReadBook.kt)、[ReadBookActivity.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/ReadBookActivity.kt)、[TextChapter.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/entities/TextChapter.kt)、[ReadAloud.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/model/ReadAloud.kt)。

- `ReadBookActivity.onClickReadAloud()` 是 UI 入口。
- 在 `scroll` 模式下，它會先從 `ReadView.getReadAloudPos()` 取出目前可見朗讀起點；必要時先切到對應章，再用該行位置啟動朗讀。
- `ReadBook.readAloud()` 再轉交給 `ReadAloud.play(...)`。
- `ReadAloud` 不直接唸文字，而是啟動 foreground service（系統 TTS 或 HTTP TTS）。
- 服務端再依目前頁/段落、`TextChapter.getNeedReadAloud(...)`、段落跳轉命令持續往下唸。
- `ReadBook.curPageChanged()` 還會在翻頁/切章後跟朗讀狀態互動，確保自動接續。

這表示 `legado` 的朗讀是「獨立服務 + 閱讀器配合服務」，不是 widget 內部播放器。

### Flutter 版目前怎麼串

主線在 [reader_tts_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_tts_mixin.dart)、[tts_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/tts_service.dart)、[reader_view_builder.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/widgets/reader_view_builder.dart)。

- `ReaderProvider.toggleTts()` 是主要入口。
- `_startTts()` 直接從目前章節的 `TextPage/TextLine` 收集 `linesToRead`。
- `prepareTtsData()` 會把朗讀文字與 `ttsOffset -> chapterOffset` 對照表一起建出來。
- `TTSService` 播放時會持續回報 `currentWordStart/currentWordEnd`。
- `_onTtsProgressUpdate()` 再把 TTS offset 映射回章內位置，更新 highlight，並在：
  - `slide` 模式時跳到對應頁
  - `scroll` 模式時捲到對應位置
- `_onTtsComplete()` 會切到下一章並自動接續，且會預抓下一章的 TTS session。

### 核心差異

- `legado`：朗讀核心在 service，閱讀器主要負責提供起點、同步視圖、接服務命令。
- Flutter：朗讀核心在 `ReaderTtsMixin`，直接依賴已分頁的 page/line 結果。

### 對 Flutter 版的含義

Flutter 版目前的朗讀優點是：

- highlight 與畫面同步比較直接
- offset map 做得很清楚
- 章節接續已經有 session / prefetch 概念

但和 legado 比，還有幾個明顯差距：

1. 目前實際串進閱讀器的是 `TTSService`，不是 legado 那種可切換 service abstraction。
2. `HttpTtsService`、`readAloudByPage`、per-book `ttsEngine` 這些設定雖然專案裡有，但閱讀主鏈還沒有像 legado 那樣真正接上。
3. 現在朗讀是建立在「分頁結果已存在」上；如果未來要支援更接近 legado 的 service 化朗讀，最好把朗讀文本來源從 page cache 再抽象一層。

---

## 7. 對照總表

| 主題 | legado Android | Flutter 目前 | 評語 |
|---|---|---|---|
| 章節提供 | `ReadBook` 三槽章節窗口 + 漸進式排版 | `ReaderProvider` + `ChapterContentManager` + cache/window | Flutter 模組化較好，但少了漸進排版 runtime |
| 分頁 | `ChapterProvider` 是全域 layout 中心 | `ChapterProvider.paginate()` 偏純函式 | Flutter 較乾淨，但 chapter runtime 能力較薄 |
| `scroll` / `slide` | 同一個 `ReadView` 換 delegate | 兩套 widget tree | Flutter 最容易出 mode parity 問題的地方 |
| 進度 | `ReadBook` 集中保存 `durChapterPos` | `ReaderProgressMixin` + resolver 轉換 | 這塊 Flutter 已經很接近甚至更清楚 |
| 朗讀 | foreground service 驅動 | provider/mixin 直接驅動 `TTSService` | Flutter 的 highlight 更直，但 service 化能力還不足 |

---

## 8. 我對目前 Flutter 版的判讀

如果只根據目前程式碼來看，不做百分比評分，我會這樣下判斷：

- 章節提供：Flutter 已經有獨立的內容管線與預載視窗，但沒有 `legado` 那種「排版中的 TextChapter runtime」。
- 分頁：Flutter 已經能穩定輸出 `TextPage` 並配合快取重用，但 page query 與 chapter query 的責任是分散的。
- `scroll/slide`：兩種模式都已實作，但共享的是 provider 狀態，不是同一個閱讀 view runtime。
- 進度：兩邊都以 `durChapterPos` 這種章內偏移為核心語意；Flutter 這塊結構相對直接。
- 朗讀：Flutter 已有朗讀高亮、跨章接續、TTS offset 映射，但還不是 `legado` 那種 service 主導的朗讀架構。

---

## 9. 如果接下來要更貼 legado，我會優先看三件事

1. 補一層「chapter runtime / progressive layout」抽象。
   讓 Flutter 版不只是拿到 `List<TextPage>`，而是有機會像 legado 一樣支援逐頁完成、查詢、朗讀切段。

2. 把 `scroll` / `slide` 的共通行為往 provider 或 controller 再收斂。
   目前這兩條 UI path 分得太早，導致 restore、TTS 跟隨、auto page 都要各自處理。

3. 把 TTS 來源與播放後端分開。
   讓 `ReaderTtsMixin` 不直接綁死 `TTSService`，之後才比較容易把 HTTP TTS、per-book engine、read-aloud-by-page 接回來。

---

## 10. 這次對照用到的主要檔案

Android legado:

- [ReadBook.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/model/ReadBook.kt)
- [ReadAloud.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/model/ReadAloud.kt)
- [ReadBookActivity.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/ReadBookActivity.kt)
- [ReadView.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/ReadView.kt)
- [TextPageFactory.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/provider/TextPageFactory.kt)
- [ChapterProvider.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/provider/ChapterProvider.kt)
- [TextChapter.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/entities/TextChapter.kt)
- [ScrollPageDelegate.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/delegate/ScrollPageDelegate.kt)
- [SlidePageDelegate.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/ui/book/read/page/delegate/SlidePageDelegate.kt)

Flutter:

- [reader_provider.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/reader_provider.dart)
- [reader_provider_base.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_provider_base.dart)
- [reader_content_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_content_mixin.dart)
- [reader_progress_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_progress_mixin.dart)
- [reader_tts_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_tts_mixin.dart)
- [reader_view_builder.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/widgets/reader_view_builder.dart)
- [chapter_content_manager.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_content_manager.dart)
- [chapter_provider.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_provider.dart)
- [tts_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/tts_service.dart)
