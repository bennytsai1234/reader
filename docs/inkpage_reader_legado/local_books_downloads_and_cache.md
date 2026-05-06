# 本地書、下載與快取

## 目前責任

- 匯入與閱讀本地 TXT、EPUB、UMD。
- 管理章節內容儲存、下載佇列、離線內容、封面/資源、快取大小與清理。

## 範圍

- 本地書：`lib/core/local_book/`、`lib/core/services/local_book_service.dart`、`lib/core/services/epub_service.dart`。
- 下載：`lib/core/services/download_service.dart`、`lib/core/services/download/`、`lib/features/cache_manager/download_manager_page.dart`。
- 內容儲存與快取：`ReaderChapterContentStore`、`ReaderChapterContentStorage`、`ChapterContentPreparationPipeline`、`ChapterContentScheduler`、`BookCoverStorageService`、`ResourceService`、`CacheManager`。
- 測試：`test/core/local_book/`、`test/core/services/epub_service_test.dart`、`test/download_executor_test.dart`、`test/local_txt_test.dart`。

## 依賴與影響

- 依賴 filesystem、encoding detection/GBK、archive/epub parsing、ReaderChapterContent DAO、Download DAO、Book/Chapter models。
- 下游影響 Reader V2、書籍詳情快取狀態、書架匯入、備份與儲存空間管理。
- 本地書和線上書共用閱讀器，但內容載入來源不同。

## 關鍵流程

- TXT 匯入會解析章節邊界與 charset，章節用 byte offset 讀取內容。
- EPUB 匯入讀 metadata、章節 href 與封面資源。
- UMD 匯入解析 title、author、chapters 與 cover，並保留小型解析快取。
- 下載服務排程章節，抓取內容後寫入 reader chapter content store。
- 書籍詳情可查內容與封面 cache 狀態，也可清除 content/cover/all。

## 常見修改起點

- TXT 亂碼、章節切分或 offset：先看 `TxtParser` 與 `LocalBookService`。
- EPUB metadata 或章節內容：先看 `EpubService`。
- UMD 支援：先看 `UmdParser` 與 `LocalBookService`。
- 背景下載、佇列、失敗重試：先看 `DownloadService` 與 `download/` mixins。
- 章節內容快取：先看 `ReaderChapterContentStore`、`ReaderChapterContentStorage` 與相關 DAO。
- 封面/資源：先看 `BookCoverStorageService` 與 `ResourceService`。

## 修改路線

- 改本地書解析時，同步 import result、chapter URL/index、Reader V2 content repository 與本地書 tests。
- 改下載時，同步 Download DAO、download manager UI、book detail cache status 與 reader content lookup。
- 改 cache key 時，同步線上內容、下載內容、本地內容與清理流程。

## 已知風險

- TXT 用 byte offset 讀取，charset 判斷或重編碼會影響章節定位。
- EPUB chapter href 與本地檔案路徑需保持一致，否則 reader 會找不到內容。
- UMD 解析快取依檔案 path、mtime、size key，檔案替換但 metadata 不變時需注意。
- 下載與 reader runtime 可能同時接觸章節內容 storage。

## 參考備註

- Legado 對應區域是 `model/localBook`、`ui/book/import/local`、`model/Download.kt`、`ui/book/cache`。
- 本專案支援 TXT、EPUB、UMD；Legado 的 Mobi/PDF 等本地格式不是目前對齊範圍。

## 不要做

- 不要為了 Legado 具備的本地格式新增未確認需求。
- 不要讓下載內容與 reader 即時抓取內容使用不同章節 key。
- 不要忽略本地書和線上書在 content loading path 上的差異。
