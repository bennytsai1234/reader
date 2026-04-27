# 專案架構

這份文件描述目前 `main` 上實際存在的架構。不要用這份文件保存未落地設計或已完成的重構計畫。

## 技術棧

- App：Flutter / Dart，`MaterialApp`
- 狀態管理：`provider` + `ChangeNotifier`
- DI：`get_it`
- 資料庫：Drift / SQLite，schema version `1`
- 路由：`Navigator` + `MaterialPageRoute`
- 網路：Dio、CookieJar、interceptors
- 書源 JS：`flutter_js`
- 背景任務：`workmanager`

目前專案沒有 Riverpod、GoRouter 或 route table。

## 啟動流程

1. `lib/main.dart` 初始化 Flutter binding、全域錯誤處理與 DI。
2. `configureDependencies()` 註冊 `AppDatabase`、所有 DAO、`NetworkService`、`TTSService` 與 logger。
3. `MultiProvider` 掛上 `AppProviders.providers`。
4. `LegadoReaderApp` 由 `SettingsProvider` 驅動 theme mode 與 locale。
5. `SplashPage` 執行 `DefaultData.initEssential()` 後進入 `MainPage`。
6. 第一幀後執行 deferred startup：匯入預設書源、TXT 目錄規則、HTTP TTS、字典規則，並做快取與搜尋歷史維護。

`Workmanager` 的 background isolate 會重新呼叫 `configureDependencies()`，再透過 DAO 讀取書架資料。

## 目錄邊界

```text
lib/
  main.dart
  app_providers.dart
  core/
    database/    Drift tables, DAOs, AppDatabase
    di/          get_it registration
    engine/      書源解析、JS bridge、規則 parser、WebBook
    local_book/  TXT / EPUB / UMD parser
    models/      跨 feature domain model
    network/     Dio API 與 interceptors
    services/    書源、備份、還原、TTS、下載、更新等業務服務
    storage/     app-owned filesystem paths
    utils/       純工具
    widgets/     domain-aware 共用 widget
  features/
    bookshelf/
    book_detail/
    search/
    explore/
    reader/
    source_manager/
    settings/
    ...
  shared/
    theme/
    widgets/
```

## `core/` 的責任

`core/database`

- `AppDatabase` 是 Drift singleton。
- DAO 是正式資料庫讀寫入口。
- schema version 目前是 `1`，只保留 clean create path。

`core/engine`

- `AnalyzeUrl` 負責 URL 規則、headers、charset、WebView 與請求建構。
- `AnalyzeRule` 與 `parsers/` 負責 CSS、XPath、JSONPath、regex、JS 規則解析。
- `web_book/` 封裝搜尋、詳情、目錄與正文抓取。
- `js/` 透過 `flutter_js` 提供同步與 async rule JS 執行。

`core/services`

- 不是純工具層，而是跨 feature 的業務 facade。
- 代表服務包含 `BookSourceService`、`BackupService`、`RestoreService`、`TTSService`、`DownloadService`、`CheckSourceService`、`SourceSwitchService`。

`core/storage`

- 集中管理 app-owned paths，例如備份暫存、書籍資產、字型、rule data、image cache。

## `features/` 的責任

`features` 是 UI、feature state 與 feature orchestration 層。大多數 feature 透過 Provider / ChangeNotifier 管 UI state，透過 `getIt<Dao>()` 與 `core/services` 讀寫資料。

- `bookshelf`：書架、分組、匯入與更新。
- `search`：搜尋 UI state、搜尋歷史與搜尋範圍；搜尋執行委派給 `SearchModel`。
- `book_detail`：搜尋結果轉書籍、補詳情、補目錄、寫入 `BookDao` / `ChapterDao`。
- `explore`：書源探索頁與探索結果展示。
- `reader`：閱讀器主系統，包含 runtime、排版、內容載入、viewport、TTS、自動翻頁、書籤控制。
- `source_manager`：書源 CRUD、匯入、分組、篩選、批次檢查與除錯。
- `settings`：全域設定、備份還原、TTS、外觀與閱讀設定入口。

`shared/` 只放跨 feature 的主題與通用 UI。若 widget 帶明顯 domain 語意，通常放在 `core/widgets` 或對應 feature 內。

## 主要資料流

### 搜尋

1. `SearchProvider.search()` 儲存關鍵字到 `SearchKeywordDao`。
2. `SearchModel.search()` 依 `SearchScope` 取得啟用書源。
3. 多來源並行呼叫 `WebBook.searchBookAwait()`。
4. `AnalyzeUrl` 發請求，`BookListParser` 解析結果。
5. 結果寫入 `SearchBookDao`，provider 通知 UI。

### 書籍詳情與目錄

1. `BookDetailProvider` 將 `SearchBook` 轉成 `Book`。
2. 讀寫 `BookDao`，並透過 `BookSourceDao` 找來源。
3. `BookSourceService.getBookInfo()` 補書籍資訊。
4. `BookSourceService.getChapterList()` 補目錄。
5. 書籍與章節分別持久化到 `books` / `chapters`。

### 閱讀

1. `ReaderPage` 建立 `ReaderDependencies` 與 `ChapterRepository`。
2. 第一次取得 viewport size 後建立 `ReaderRuntime`。
3. `ReaderRuntime.openBook()` 確保目錄，依 `ReaderLocation(chapterIndex, charOffset)` 開書。
4. `ChapterRepository` 讀取或 materialize 正文。
5. `PageResolver` + `LayoutEngine` 把正文投影成 `TextPage` 與 `PageWindow`。
6. `EngineReaderScreen` 依 mode 分派 `SlideReaderViewport` 或 `ScrollReaderViewport`。
7. `ReaderProgressController` 將 durable progress 寫回 `books.chapterIndex` / `books.charOffset`。

## 書源 JS 與 QuickJS 測試

正式依賴是 `flutter_js`。`JsEngine` 會建立 `JavascriptRuntime`、注入 `JsExtensions`，並提供：

- `evaluate()`：同步 JS fast path
- `evaluateAsync()`：透過 async rewriter 與 Promise bridge 等待 `java.*` / `cache.*` / `source.*` 類呼叫

本地測試若需要 Linux QuickJS shared library，可透過 `tool/flutter_test_with_quickjs.sh` 包裝 `flutter test`。CI 目前直接執行 `flutter test --reporter compact`。

## 邊界規則

- UI 不直接開 SQLite，也不手寫 SQL；資料庫讀寫走 DAO。
- 新的書源解析能力放在 `core/engine`，不要塞進 UI provider。
- 跨 feature 業務流程放 service / repository，feature provider 只做 UI 狀態與 orchestration。
- 閱讀器位置長期真源是 `chapterIndex + charOffset`，不是頁碼或 scroll offset。
- 文件只描述已存在的實作；階段性執行稿完成後應刪除。
