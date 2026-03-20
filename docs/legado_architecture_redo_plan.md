# Flutter 閱讀器重做方向：全面對齊 legado 架構

## 決策

接下來的閱讀器重做，目標不再是「維持目前 Flutter 架構，局部參考 legado」，而是：

- 以 `legado` 的閱讀器架構作為主體
- Flutter 版只保留平台與語言差異需要的實作調整
- 現有 Flutter 模組若與 legado 主架構衝突，優先讓位給 legado 式結構

這代表後續設計應以這三個核心為中心：

1. 單一閱讀狀態機
2. 單一閱讀視圖 runtime
3. 章節/分頁/朗讀共用同一條資料鏈

---

## 目標架構

### 1. `ReadBookController` 取代現在的分散式 provider/mixin 主導

對齊 legado 的 `ReadBook`：

- 持有唯一閱讀進度真源：
  - `durChapterIndex`
  - `durChapterPos`
- 持有章節窗口：
  - `prevChapter`
  - `curChapter`
  - `nextChapter`
- 負責：
  - 開書初始化
  - 切章
  - 翻頁
  - 進度保存
  - 章節預載
  - 朗讀接續
  - 設定變更後重排版

不再讓這些責任散落在：

- `ReaderContentMixin`
- `ReaderProgressMixin`
- `ReaderTtsMixin`
- `ReaderAutoPageMixin`

這些可保留為過渡期實作來源，但不應再是最後架構。

### 2. `ReadViewRuntime` 取代現在 `ReaderViewBuilder` 的雙路徑主導

對齊 legado 的 `ReadView`：

- 閱讀器 UI 應該只有一個主 runtime
- `scroll` / `slide` / 其他翻頁模式，都由同一個 runtime 切換 delegate/controller
- 不能再讓 `scroll` 跟 `slide` 各自有一套主要資料流

Flutter 版的對應形式可以是：

- `ReadViewRuntime`：持有當前頁、前頁、後頁、可見範圍、jump 命令
- `PageModeDelegate`：
  - `ScrollModeDelegate`
  - `SlideModeDelegate`
  - 後續可擴充其他模式

重點不是 widget 長怎樣，而是：

- 狀態來源一致
- 翻頁模式只改「顯示與交互策略」
- 不改閱讀資料模型本身

### 3. `ChapterProvider` 回到閱讀 runtime 的中心

對齊 legado 的 `ChapterProvider + TextChapter + TextPageFactory`：

- `ChapterProvider` 不只是純函式 paginate
- 它要成為閱讀階段的 layout/config 中心
- 它要負責：
  - view size
  - padding
  - line metrics
  - 字體與樣式
  - 章節排版產物建立
  - 與閱讀模式相關的 page query

Flutter 版應新增：

- `ReaderChapterProvider`
- `ReaderChapter`
- `ReaderPageFactory`

其中：

- `ReaderChapter` 對應 legado 的 `TextChapter`
- `ReaderPageFactory` 對應 legado 的 `TextPageFactory`
- 現有 `ChapterPositionResolver` 的部分責任要回收到 `ReaderChapter`

### 4. 朗讀必須回到閱讀狀態機主鏈，不再只是 provider side-feature

對齊 legado 的 `ReadAloud` 使用方式：

- 朗讀起點由閱讀畫面當前位置決定
- 翻頁/切章後由閱讀狀態機決定如何接續
- 朗讀文字切段應來自章節 runtime，而不是零散從 page cache 拼

Flutter 版可以先不硬做成 Android service 的形狀，但架構上要做到：

- `ReadAloudController` 由 `ReadBookController` 驅動
- 朗讀段落來源取自 `ReaderChapter`
- TTS 後端只是播放器，不是閱讀邏輯持有者

---

## 現有 Flutter 模組如何處理

### 保留，但降級成底層工具

- `chapter_content_manager.dart`
  - 可保留為內容抓取與快取層
  - 不再作為閱讀器的主狀態中心

- `tts_service.dart`
  - 可保留為系統 TTS 播放後端
  - 不再直接承載閱讀器朗讀流程

- `chapter_provider.dart`
  - 其中純排版演算法可保留
  - 但應被包進新的 `ReaderChapterProvider`

### 需要被取代的主控結構

- `ReaderProvider`
- `ReaderContentMixin`
- `ReaderProgressMixin`
- `ReaderTtsMixin`
- `ReaderAutoPageMixin`
- `ReaderViewBuilder`

這些目前是可工作的，但不是 legado 型架構的終點。

### 建議保留的資料模型

- `TextPage`
- `TextLine`
- `Book`
- `BookChapter`

但要補一個更高階的 `ReaderChapter` runtime 物件。

---

## 重做後的建議模組骨架

### 核心層

- `ios/lib/features/reader/runtime/read_book_controller.dart`
- `ios/lib/features/reader/runtime/read_book_state.dart`
- `ios/lib/features/reader/runtime/read_aloud_controller.dart`
- `ios/lib/features/reader/runtime/reader_page_factory.dart`
- `ios/lib/features/reader/runtime/reader_chapter_provider.dart`
- `ios/lib/features/reader/runtime/models/reader_chapter.dart`

### 視圖層

- `ios/lib/features/reader/view/read_view_runtime.dart`
- `ios/lib/features/reader/view/delegate/page_mode_delegate.dart`
- `ios/lib/features/reader/view/delegate/scroll_mode_delegate.dart`
- `ios/lib/features/reader/view/delegate/slide_mode_delegate.dart`

### 基礎服務層

- `ChapterContentManager`
- `TTSService`
- source/content fetch service
- DAO

---

## 資料流目標

### 開書

`ReaderPage`
-> `ReadBookController.open(book, chapterIndex, chapterPos)`
-> 載入當前章
-> 同步預載前後章
-> 建立 `prev/cur/next ReaderChapter`
-> `ReadViewRuntime` 刷新顯示

### 翻頁

`ReadViewRuntime`
-> delegate 判定是上一頁/下一頁
-> `ReaderPageFactory.moveToPrev/moveToNext`
-> `ReadBookController` 更新 `durChapterPos`
-> 必要時切章
-> 保存進度
-> 通知朗讀狀態

### 朗讀

`ReadViewRuntime`
-> 取得目前可朗讀位置
-> `ReadBookController.startReadAloud(startPos)`
-> `ReadAloudController` 從 `ReaderChapter` 取得待讀文字
-> `TTSService` 播放
-> progress callback 回寫到 `ReadBookController`
-> 更新高亮與必要的頁面/章節切換

---

## 實作原則

1. 不再新增新的 mixin 來補閱讀器主鏈。
2. `scroll` / `slide` 共用同一套閱讀狀態與頁來源。
3. 章節 runtime 必須是一級概念，不可只靠 `List<TextPage>` 代替。
4. 朗讀與進度都必須掛在同一個閱讀狀態機上。
5. 現有模組若能重用，重用的是「演算法與服務」，不是現在的責任切分。

---

## 分階段重做建議

### Phase 1：先立新骨架，不急著功能全搬

先建立：

- `ReadBookController`
- `ReaderChapter`
- `ReaderChapterProvider`
- `ReaderPageFactory`

先只支援：

- 開書
- 當前章載入
- `slide` 模式翻頁
- 基本進度保存

目標是把核心鏈先跑通：

`open -> load chapter -> paginate -> move page -> save progress`

### Phase 2：補前後章窗口與切章

加入：

- `prev/cur/next` 章節窗口
- 切章與預載
- `PageFactory` 跨章頁面查詢

目標是追上 legado 的基礎閱讀狀態機。

### Phase 3：補 `scroll` delegate

把 `scroll` 從現在獨立 UI 路徑，改成同一個 runtime 下的模式 delegate。

### Phase 4：補朗讀主鏈

建立：

- `ReadAloudController`
- 從 `ReaderChapter` 取朗讀段落
- 跟翻頁/切章/進度正式整合

### Phase 5：再搬 auto page、更多模式與細節行為

---

## 我建議的第一刀

如果真的要全面採用 legado 架構，第一刀不要再修現有 `ReaderViewBuilder`。

第一刀應該是：

1. 新建 `ReadBookController`
2. 新建 `ReaderChapter`
3. 新建 `ReaderPageFactory`
4. 讓 `ReaderPage` 可以切到新的 controller + slide-only runtime

原因很簡單：

- 這樣才是真的換主架構
- 如果還是在舊的 provider/mixin 上補功能，只會越補越難拔

---

## 結論

如果方向是「全面採用 legado 架構」，那就不應該再把目前 Flutter 閱讀器當主體去修補。

正確方向應該是：

- 用 legado 的閱讀器結構重建 Flutter 版主鏈
- 現有 Flutter 代碼只保留可重用的底層能力
- 先建立新的閱讀狀態機與章節 runtime，再逐步把 UI 和功能掛上去

這會是一次真正的重做，不是局部重構。
