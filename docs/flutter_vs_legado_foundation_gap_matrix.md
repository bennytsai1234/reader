# Flutter 底層能力 vs legado：保留 / 包裝 / 重寫矩陣

## 目的

這份文件只回答一個問題：

如果閱讀器要全面改成 legado 架構，Flutter 現有底層能力哪些可以直接沿用，哪些只能當底層工具，哪些必須重寫。

分類規則：

- `沿用`：能力與責任邊界已足夠，可直接留在新架構中
- `包裝後沿用`：能力可用，但責任位置不對，必須被新 runtime 包起來
- `重寫`：就算功能存在，也不適合作為 legado 架構下的主體

---

## 1. 結論總表

| 項目 | Flutter 現況 | 建議 |
|---|---|---|
| 書源正文抓取 | 已有 | 沿用 |
| 本地 TXT/EPUB 內容讀取 | 已有 | 沿用 |
| 章節內容快取 | 已有 | 沿用 |
| 分頁結果快取 | 已有 | 包裝後沿用 |
| 純分頁演算法 | 已有 | 包裝後沿用 |
| `TextPage` / `TextLine` 資料模型 | 已有 | 包裝後沿用 |
| 正文處理 `ContentProcessor` | 有，但簡化 | 重寫或深改 |
| 章內位置換算 `ChapterPositionResolver` | 有 | 暫時包裝後沿用，最終部分回收進 `ReaderChapter` |
| 閱讀主狀態 `ReaderProvider + mixin` | 有 | 重寫 |
| 閱讀主視圖 `ReaderViewBuilder` | 有 | 重寫 |
| `scroll/slide` 模式切換方式 | 兩套 widget tree | 重寫 |
| TTS 系統播放後端 | 有 | 沿用 |
| HTTP TTS 播放後端 | 有 | 包裝後沿用 |
| 朗讀主流程 | 有，但掛在 provider/mixin | 重寫 |

---

## 2. 可以直接沿用的底層能力

### 2.1 書源正文抓取

檔案：

- [book_source_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/book_source_service.dart)

原因：

- 它本質上是內容取得 service
- 與閱讀器主架構耦合不深
- 新的 `ReadBookController` 仍然需要這層能力

結論：

- 直接沿用

### 2.2 本地書內容讀取

檔案：

- [local_book_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/local_book_service.dart)

原因：

- 已有 TXT offset 讀取
- 已有 EPUB 內容讀取
- 這本來就屬於底層內容來源能力

結論：

- 直接沿用

### 2.3 DAO / 資料存取

檔案範圍：

- `ios/lib/core/database/dao/*`

原因：

- 新架構一樣要讀寫書籍、章節、內容、進度、TTS 設定
- 這層不需要跟著閱讀 runtime 重寫

結論：

- 直接沿用

### 2.4 系統 TTS 播放後端

檔案：

- [tts_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/tts_service.dart)

原因：

- 它可以作為播放後端存在
- 新架構仍然需要系統 TTS 能力

注意：

- 沿用的是「播放後端」角色
- 不是沿用它現在直接承載閱讀器朗讀流程的方式

結論：

- 直接沿用為底層播放器

---

## 3. 可以保留，但必須包裝後沿用

### 3.1 `ChapterContentManager`

檔案：

- [chapter_content_manager.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_content_manager.dart)

它現在提供的能力：

- 內容抓取協調
- 內容快取
- 分頁快取
- 預載 queue

問題：

- 它現在太靠近閱讀器主流程
- 在新架構下，它不應該決定閱讀器狀態，只應該提供內容與快取能力

結論：

- 保留
- 但要退到 `ReadBookController` 底下，變成基礎設施層

### 3.2 純分頁演算法 `ChapterProvider.paginate`

檔案：

- [chapter_provider.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_provider.dart)

它現在提供的能力：

- 依 view size / style / content 輸出 `TextPage`

問題：

- 它目前只是純函式分頁器
- legado 需要的是「閱讀 runtime 裡的 ChapterProvider」

結論：

- 保留裡面的排版演算法
- 外層要新增 `ReaderChapterProvider`
- 讓它成為新 chapter runtime 的一部分

### 3.3 `TextPage` / `TextLine`

檔案：

- [text_page.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/text_page.dart)

它現在提供的能力：

- 頁面與行資料模型
- 含 `chapterPosition`
- 含段落與圖片資訊

問題：

- 現在少了 `TextChapter` 這一層
- 單靠 `TextPage` / `TextLine` 不足以承接 legado 架構

結論：

- 保留
- 但要新增更高階的 `ReaderChapter`

### 3.4 `ChapterPositionResolver`

檔案：

- [chapter_position_resolver.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_position_resolver.dart)

它現在提供的能力：

- `charOffset <-> localOffset`
- `charOffset <-> pageIndex`
- page height / chapter height 計算

問題：

- 在 legado 架構裡，這些查詢很多會長在 `TextChapter`
- 現在是因為缺少 chapter runtime 才拆成獨立 resolver

結論：

- 過渡期可以保留
- 但最終應把一部分能力回收到 `ReaderChapter`

### 3.5 `HttpTtsService`

檔案：

- [http_tts_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/http_tts_service.dart)

它現在提供的能力：

- HTTP TTS 音訊下載
- 快取
- 播放列表串接

問題：

- 它現在是獨立 service
- 還沒有像 legado 一樣被閱讀器朗讀主鏈統一調度

結論：

- 保留作為 HTTP TTS 播放後端
- 外層必須新增 `ReadAloudController` / engine selector 統一調用

---

## 4. 必須重寫的部分

### 4.1 `ReaderProvider + mixin` 主控架構

檔案：

- [reader_provider.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/reader_provider.dart)
- [reader_content_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_content_mixin.dart)
- [reader_progress_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_progress_mixin.dart)
- [reader_tts_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_tts_mixin.dart)
- [reader_auto_page_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_auto_page_mixin.dart)

原因：

- 它們把閱讀器核心責任切得太散
- 與 legado 的單一狀態機方向相反
- 越繼續補，之後越難收回到單一 runtime

結論：

- 不保留為主架構
- 直接重寫成 `ReadBookController`

### 4.2 `ReaderViewBuilder`

檔案：

- [reader_view_builder.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/widgets/reader_view_builder.dart)

原因：

- 它現在直接分裂成 `PageView` 與 `ScrollablePositionedList` 兩條主要資料流
- 與 legado 的「單一閱讀視圖 runtime + delegate 切模式」方向衝突

結論：

- 重寫成新的 `ReadViewRuntime`

### 4.3 `scroll/slide` 模式切換方式

原因：

- 現在不是只切交互策略，而是切整條 render/data path
- 這會讓進度、朗讀、restore、auto page 長期需要雙份維護

結論：

- 必須重寫
- 改成單一 runtime 下的 delegate

### 4.4 朗讀主流程

目前主線：

- `ReaderTtsMixin` 直接收集頁面文字
- 直接驅動 `TTSService`

原因：

- 這不是 legado 那種由閱讀狀態機統一控制的朗讀鏈
- 缺少 engine selector、統一入口、章節 runtime 切段

結論：

- 重寫
- 新建 `ReadAloudController`

### 4.5 `ContentProcessor`

檔案：

- [content_processor.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/engine/reader/content_processor.dart)

和 legado 對照檔案：

- [ContentProcessor.kt](/C:/Users/benny/Desktop/Folder/Project/reader/legado/app/src/main/java/io/legado/app/help/book/ContentProcessor.kt)

原因：

- Flutter 版目前是簡化實作
- 規則作用域、替換行為、處理流程、快取觀念都比 legado 薄

結論：

- 不建議原樣沿用
- 要嘛重寫，要嘛至少依 legado 行為深改

---

## 5. 實際開工時的保留清單

這些檔案我建議當成「可留」：

- [book_source_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/book_source_service.dart)
- [local_book_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/local_book_service.dart)
- [chapter_content_manager.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_content_manager.dart)
- [chapter_provider.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_provider.dart)
- [text_page.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/text_page.dart)
- [chapter_position_resolver.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/engine/chapter_position_resolver.dart)
- [tts_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/tts_service.dart)
- [http_tts_service.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/core/services/http_tts_service.dart)

---

## 6. 實際開工時的淘汰清單

這些檔案我建議不要當成新架構主體延續：

- [reader_provider.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/reader_provider.dart)
- [reader_content_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_content_mixin.dart)
- [reader_progress_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_progress_mixin.dart)
- [reader_tts_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_tts_mixin.dart)
- [reader_auto_page_mixin.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/provider/reader_auto_page_mixin.dart)
- [reader_view_builder.dart](/C:/Users/benny/Desktop/Folder/Project/reader/ios/lib/features/reader/widgets/reader_view_builder.dart)

---

## 7. 最後結論

如果以 legado 架構為目標：

- Flutter 並不是「底層能力都沒有」
- 但也不是「底層能力已經等同 legado」

比較準確的判斷是：

- 內容來源、快取、基本分頁資料模型、TTS 播放後端，已經有可沿用基礎
- 閱讀器主狀態、主視圖 runtime、章節 runtime、朗讀主鏈，仍然需要按 legado 方向重建
