# 資料庫

這份文件描述目前 `lib/core/database/` 的 Drift / SQLite 結構。

## 基本資訊

- 入口：`lib/core/database/app_database.dart`
- 資料庫類別：`AppDatabase`
- 連線：singleton `AppDatabase` + `LazyDatabase`
- SQLite driver：`NativeDatabase.createInBackground`
- schema version：`1`
- 檔案位置：`<ApplicationSupportDirectory>/databases/inkpage_reader.db`

## 存取原則

- UI 不直接碰 SQLite。
- 正式查詢與寫入經由 `lib/core/database/dao/`。
- table 與 converter 定義在 `lib/core/database/tables/app_tables.dart`。
- 變更 Drift table、DAO 或 `AppDatabase` 後要重新生成：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Migration

目前資料庫已重置為新架構的初始 schema：

- `schemaVersion => 1`
- `MigrationStrategy` 只有 `onCreate: (m) => m.createAll()`
- 沒有 `onUpgrade`
- 不保留舊 schema 的欄位修補或逐版 migration path

備份 manifest 的 `schemaVersion` 直接使用 `AppDatabase().schemaVersion`。還原時只接受 manifest 存在且 `schemaVersion <= AppDatabase().schemaVersion` 的備份。

## Type Converters

- `EmptyStringConverter`：SQL `NULL` 讀成空字串，空字串寫回 `NULL`。
- `ReadConfigConverter`：`ReadConfig?` 與 JSON string。
- 書源規則 converters：`SearchRule`、`ExploreRule`、`BookInfoRule`、`TocRule`、`ContentRule`、`ReviewRule` 與 JSON string。

## Tables 與 DAOs

目前 `AppDatabase` 宣告 21 張表與對應 DAO：

| Table | DAO | 用途 |
| --- | --- | --- |
| `books` | `BookDao` | 書架書籍、書籍資訊、閱讀進度 |
| `chapters` | `ChapterDao` | 章節目錄 |
| `reader_chapter_contents` | `ReaderChapterContentDao` | materialized 章節正文 |
| `book_sources` | `BookSourceDao` | 書源規則、登入、搜尋/探索/目錄/正文 rule |
| `book_groups` | `BookGroupDao` | 書架分組 |
| `search_history_table` | `SearchHistoryDao` | 搜尋歷史 |
| `replace_rules` | `ReplaceRuleDao` | 內容替換規則 |
| `bookmarks` | `BookmarkDao` | 書籤 |
| `cookies` | `CookieDao` | 站點 cookie |
| `dict_rules` | `DictRuleDao` | 字典規則 |
| `http_tts_table` | `HttpTtsDao` | HTTP TTS 引擎設定 |
| `read_records` | `ReadRecordDao` | 閱讀時長紀錄 |
| `servers` | `ServerDao` | 伺服器設定 |
| `txt_toc_rules` | `TxtTocRuleDao` | TXT 目錄規則 |
| `cache_table` | `CacheDao` | 通用 key-value cache 與 deadline |
| `keyboard_assists` | `KeyboardAssistDao` | 鍵盤輔助 |
| `rule_subs` | `RuleSubDao` | 規則訂閱 |
| `source_subscriptions` | `SourceSubscriptionDao` | 書源訂閱 |
| `search_books` | `SearchBookDao` | 搜尋結果與換源候選快取 |
| `download_tasks` | `DownloadDao` | 下載任務 |
| `search_keywords` | `SearchKeywordDao` | 搜尋關鍵字統計 |

## 主要資料分組

### 書籍與閱讀

- `books`
- `chapters`
- `reader_chapter_contents`
- `bookmarks`
- `read_records`
- `download_tasks`

閱讀器 durable progress 存在 `books`：

- `chapterIndex`
- `charOffset`
- `durChapterTitle`
- `durChapterTime`
- `readerAnchorJson`
- `readConfig`

目前有效 durable 座標是 `chapterIndex + charOffset`。`readerAnchorJson` 欄位仍存在，但主線寫進度時會清成 `null`。

### 書源與規則

- `book_sources`
- `cookies`
- `rule_subs`
- `source_subscriptions`
- `replace_rules`
- `dict_rules`
- `http_tts_table`
- `txt_toc_rules`
- `servers`

`book_sources` 是書源規則主表，包含啟用狀態、分組、登入、headers、JS lib、探索/搜尋 URL，以及搜尋、探索、詳情、目錄、正文、評論規則。

### 搜尋、分組與輔助

- `search_history_table`
- `search_books`
- `search_keywords`
- `keyboard_assists`
- `book_groups`
- `cache_table`

這組資料支援搜尋 UI、搜尋結果快取、書架分組、輸入輔助與通用快取清理。

## 章節正文儲存

`reader_chapter_contents` 是閱讀器 materialized content store：

- 主鍵：`contentKey`
- 定位：`origin`、`bookUrl`、`chapterUrl`、`chapterIndex`
- 內容：`content`
- 狀態：`status`、`failureMessage`
- 更新時間：`updatedAt`

閱讀器會優先透過 `ReaderChapterContentLoader` / `ReaderChapterContentStore` 讀取正文。缺內容時再依書源或章節資料 materialize，並寫回這張表。

## 備份與還原

備份入口是 `BackupService.createBackupZip()`。

ZIP 內容：

- `manifest.json`：`appVersion`、`schemaVersion`、`timestamp`
- `bookshelf.json`
- `bookSource.json`
- `replaceRule.json`
- `bookmark.json`
- `readRecord.json`
- `txtTocRule.json`
- `bookGroup.json`
- `dictRule.json`
- `httpTts.json`
- `downloadTask.json`
- `config.json`

`config.json` 來自 `SharedPreferences.getKeys()`，逐項寫入。ZIP 檔名為 `backup-yyyy-MM-dd.zip`，先寫 `.tmp` 再 rename。

還原入口是 `RestoreService.restoreFromZip()`：

- 必須有相容 manifest。
- list JSON 逐筆 `fromJson` 後 upsert。
- 支援部分新舊檔名 alias，例如 `books.json` / `bookshelf.json`、`bookSources.json` / `bookSource.json`。
- `config.json` 會還原 String、int、bool、double、StringList 到 `SharedPreferences`。

## 維護規則

- schema version 或 table 變更時同步更新本文件。
- 變更 table / DAO 後跑 build runner。
- 不在 UI 層加入 SQL 或直接依賴 Drift generated table。
- 若未來恢復 migration path，必須在這份文件列出每個 schema version 的升級責任。
