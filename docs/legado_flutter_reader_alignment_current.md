# Legado Android vs Flutter Reader Alignment

更新日期：2026-03-20  
範圍：只對照目前 repo 內的 Android legado 實作與目前 Flutter 閱讀器程式碼。  
備註：本分析不引用舊的 `reader_logic_chain_verification.md`。

## 一句話結論

目前 Flutter 閱讀器已經明顯往 legado 的主鏈靠攏，核心形狀可以描述成：

- legado：`ReadBook -> ChapterProvider/TextChapter -> ReadView(delegate) -> ReadAloud`
- Flutter：`ReadBookController -> ChapterContentManager/ReaderChapter -> ReadViewRuntime(delegate) -> ReadAloudController`

但兩者仍不是完全同構：

- Flutter 已對齊主控入口、scroll/slide delegate、章節 runtime、進度/朗讀與閱讀狀態的串接
- Flutter 尚未完全對齊 legado 的 `TextChapter` runtime 深度、`ChapterProvider` 單體責任範圍、以及 foreground read aloud service abstraction

## 1. 章節提供怎麼串

### legado Android

主控在 `ReadBook`：

- `ReadBook` 持有 `prevTextChapter / curTextChapter / nextTextChapter`
- 閱讀進度核心是 `durChapterIndex / durChapterPos`
- `resetData()`、`upData()`、`setProgress()` 會清掉 chapter runtime，再重新 `loadContent`

章節內容來源：

- 本地書走 `TextFile`
- 網路書走 `WebBook`
- 正文先經過 `ContentProcessor`
- 再交給 `ChapterProvider.getTextChapter(...)` 產生 `TextChapter`

這代表 legado 的章節提供不是單純「拿文字」，而是：

1. 取章節內容
2. 做正文處理
3. 轉成 `TextChapter`
4. 同時準備前/當/後章 runtime

### Flutter

主控現在在 `ReadBookController`：

- 持有 `_chapterRuntimeCache`
- 對外提供 `chapterAt()`、`prevChapterRuntime`、`curChapterRuntime`、`nextChapterRuntime`
- 初始化流程是 `loadSettings -> load chapters/source -> initContentManager -> loadChapterWithPreloadRadius`

章節內容來源：

- `ReaderContentMixin` 用 `ChapterContentManager(fetchFn: _fetchChapterData, chapters: chapters)`
- `_fetchChapterData()` 會做：
  - local 書走 `LocalBookService`
  - 網路書走 `BookSourceService`
  - 正文經 `ContentProcessor.process(...)`
- `ChapterContentManager` 完成分頁後，把 `TextPage` 存進 `chapterPagesCache`
- `ReadBookController.refreshChapterRuntime()` 再把 cache 包成 `ReaderChapter`

### 對照判讀

- Flutter 已對齊 legado 的「主控持有章節 runtime」這個大方向
- 目前 Flutter 的 runtime 單位是 `ReaderChapter(pages)`，而不是 legado 的 `TextChapter`
- legado 的章節 runtime 比較厚，Flutter 目前還是「內容抓取/正文處理/分頁」與「runtime 包裝」分層較明顯

結論：

- 架構方向：已對齊
- runtime 深度：Flutter 仍較薄

## 2. 分頁怎麼串

### legado Android

`ChapterProvider` 同時負責：

- 讀取 `ReadBookConfig`
- 準備 `titlePaint / contentPaint`
- 計算 view size / padding / visible rect
- 把處理後正文切成 `TextLine`
- 產出 `TextPage`
- 最終組成 `TextChapter`

也就是說，legado 的分頁不是獨立小函式，而是閱讀 runtime 的核心組件。

### Flutter

Flutter 現在分成兩層：

- `ChapterContentManager`
  - 管內容快取
  - 管 window preload
  - 管 repaginate / getChapterPages
- `ChapterProvider.paginate(...)`
  - 真正做純分頁運算

分頁結果再被：

- `chapterPagesCache`
- `ReaderChapterProvider.buildFromPages(...)`
- `ReadBookController.refreshChapterRuntime()`

接回新的 runtime。

### 對照判讀

- Flutter 分頁結構比 legado 更分層，也更容易替換與測試
- legado 的優勢是 `ChapterProvider` 與閱讀 runtime 是一體的，context 很完整
- Flutter 現在雖然已接回 `ReaderChapter`，但 `TextChapter` 等級的章節內運行資訊仍偏少

結論：

- 分頁可用性：Flutter 已足夠
- 與 legado 的結構同構度：中高
- 與 legado 的 runtime 密合度：中

## 3. scroll / slide 怎麼串

### legado Android

`ReadView` 是唯一閱讀視圖：

- 持有 `pageFactory`
- 持有 `pageDelegate`
- 透過 `upPageAnim()` 切換 `ScrollPageDelegate / SlidePageDelegate / SimulationPageDelegate ...`

也就是：

- 同一個 `ReadView`
- 同一份資料來源
- 不同 delegate 決定互動與繪製方式

### Flutter

現在主視圖是 `ReadViewRuntime`：

- `ReadViewRuntime` 監聽 `ReadBookController`
- 依 `pageTurnMode` 切到：
  - `ScrollModeDelegate`
  - `SlideModeDelegate`

scroll 模式：

- 使用 `ScrollablePositionedList`
- 每個 chapter 底下渲染該章 `TextPage`
- 透過 `visibleChapterIndex + visibleChapterLocalOffset` 回寫閱讀位置

slide 模式：

- 使用單一 `PageView`
- `slidePages` 由 `ReadBookController.buildSlideRuntimePages()` 根據 `prev/current/next ReaderChapter` 組合

舊的 `ReaderViewBuilder` 已退成薄 wrapper，實際上只轉呼叫 `ReadViewRuntime`。

### 對照判讀

- 這一塊是目前 Flutter 和 legado 最接近的部分之一
- 現在已不是兩套完全分離的 widget tree 思維，而是單一 runtime 外層 + delegate 切模式
- 差異在於：
  - legado 的 `ReadView` 更像單一 view 物件加多 page layer
  - Flutter 仍然是 declarative widget tree，但控制面已經對齊 legado

結論：

- 架構方向：高對齊
- 實作型態：語言/框架差異導致不同，但不再是本質分裂

## 4. 進度怎麼串

### legado Android

核心進度永遠是：

- `durChapterIndex`
- `durChapterPos`

不論 UI 是 scroll 還是 slide，最後都回到「章索引 + 章內字元位置」。

`ReadBook.setProgress()` 會：

- 更新 `durChapterIndex / durChapterPos`
- `saveRead()`
- 清 chapter runtime
- 重新載入內容

### Flutter

核心進度也是：

- `book.durChapterIndex`
- `book.durChapterPos`

`ReaderContentMixin` 和 `ReadBookController` 透過 `ChapterPositionResolver` 在不同模式間做轉換：

- scroll：`localOffset <-> charOffset`
- slide：`pageIndex <-> charOffset`

保存時：

- 一般閱讀走 `saveProgress(...)`
- 朗讀狀態走 `saveTtsProgress()`

### 對照判讀

- 這塊 Flutter 已經和 legado 非常接近
- 兩邊都把真正的閱讀位置收斂到 chapter char offset
- Flutter 還額外明確拆出 `visibleChapterIndex / visibleChapterLocalOffset`，對 scroll 模式更清楚

結論：

- 核心概念：高對齊
- Flutter 在位置換算顯性化方面甚至更清楚

## 5. 朗讀怎麼串

### legado Android

主控在 `ReadAloud`：

- 先依 `book.getTtsEngine()` / `AppConfig.ttsEngine` 決定 service 類型
- 可能走 `TTSReadAloudService`
- 也可能走 `HttpReadAloudService`
- 操作方式是對 foreground service 發 intent

這代表 legado 的朗讀鏈是：

1. 閱讀狀態提供 page / progress
2. `ReadAloud` 選 service
3. service 負責播放、媒體控制、前景通知、續讀

### Flutter

現在主控在 `ReadAloudController`：

- 掛在 `ReadBookController`
- 使用 `TTSService`
- 直接監聽 `audioEvents`
- 讀取 `ReaderChapter.pages`
- 生成 `(text, offsetMap)`
- 根據 `ttsStart / ttsEnd` 高亮
- 根據模式：
  - scroll：`requestJumpToChapter(...)`
  - slide：`requestJumpToPage(...)`

跨章與模式切換：

- `nextPageOrChapter()` / `prevPageOrChapter()`
- slide 模式會先試頁內前後移動，再跨章
- `_prefetchNextChapter()` 會先準備下一章朗讀 session

### 對照判讀

- Flutter 已經把朗讀接回閱讀主鏈，這點比之前成熟很多
- 目前缺的不是「能不能朗讀」，而是還沒有 legado 那種 service abstraction：
  - 沒有 `ReadAloud -> BaseReadAloudService -> concrete service` 這種層次
  - 目前是 controller 直接駕馭 `TTSService`
- 先前的 `HttpTtsService` 已移除，因此目前 Flutter 明確是單一路徑系統 TTS

結論：

- 閱讀位置、高亮、跨章接續：已大致對齊 legado 能力
- service abstraction：尚未對齊
- 多引擎架構：目前刻意不做

## 五條主鏈對照表

| 主題 | legado Android | Flutter 現況 | 對齊度 |
|---|---|---|---|
| 章節提供 | `ReadBook` 持有前/中/後 `TextChapter`，取文後直接生成 runtime | `ReadBookController` 持有 `ReaderChapter` cache，內容由 `ChapterContentManager` 驅動後再包裝 runtime | 中高 |
| 分頁 | `ChapterProvider` 是 runtime 核心 | `ChapterContentManager + ChapterProvider.paginate + ReaderChapterProvider` 分層組裝 | 中高 |
| scroll / slide | `ReadView + PageDelegate` 單一視圖切模式 | `ReadViewRuntime + Scroll/SlideModeDelegate` 單一 runtime 切模式 | 高 |
| 進度 | `durChapterIndex + durChapterPos` | `book.durChapterIndex + book.durChapterPos`，並有 `ChapterPositionResolver` | 高 |
| 朗讀 | `ReadAloud + foreground service` | `ReadAloudController + TTSService` | 中 |

## 最後判讀

如果只看你指定的五塊：

- 章節提供：Flutter 已接回 legado 式主控，但章內 runtime 還比 legado 薄
- 分頁：Flutter 已可支撐 legado 式閱讀器，但責任分層較散
- scroll/slide：目前已經是高相似度
- 進度：目前是高相似度
- 朗讀：功能鏈已接上，但還沒有 service 化

因此目前最準確的描述不是「Flutter 已完全等同 legado」，而是：

> Flutter 閱讀器的核心控制鏈已經大致對上 legado，尤其是閱讀主控、模式切換、進度和朗讀高亮；  
> 但章節 runtime 深度與朗讀 service abstraction 仍比 legado 簡化。

## 之後如果要繼續追 legado，最值得補的兩塊

1. 把 `ReaderChapter` 再往 `TextChapter` 等級補強  
讓章節 runtime 不只是 `pages` 容器，而是直接承擔更多章內定位、前後頁能力與 layout state。

2. 把朗讀再抽成 service layer  
如果未來真的要把 HTTP TTS 放回來，建議不要再直接接 controller，而是回到 legado 那種：

- `ReadAloudController`
- `BaseReadAloudService`
- `SystemTtsReadAloudService`
- `HttpReadAloudService`

這樣才不會再把多引擎責任混回閱讀主控。
