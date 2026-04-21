# 資料庫

這份文件描述 `lib/core/database/` 目前真實存在的 Drift 結構。

## 基本資訊

- 入口：`lib/core/database/app_database.dart`
- 資料庫類別：`AppDatabase`
- 連線模式：singleton
- schema version：`8`
- 檔案路徑：`<ApplicationSupportDirectory>/databases/inkpage_reader.db`

## 存取原則

- UI 不直接碰 SQLite
- 所有正式查詢 / 寫入都應經過 DAO
- table 定義在 `lib/core/database/tables/app_tables.dart`
- 變更 table / dao 後必須重新跑：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## 資料表分組

### 書籍與閱讀資料

- `books`
- `chapters`
- `bookmarks`
- `read_records`
- `download_tasks`
- `cache_table`

這組資料負責：

- 書架中的書籍狀態
- 章節快取
- 閱讀進度
- 書籤
- 離線下載任務

### 書源與規則資料

- `book_sources`
- `cookies`
- `rule_subs`
- `source_subscriptions`
- `replace_rules`
- `dict_rules`
- `http_tts_table`
- `txt_toc_rules`
- `servers`

這組資料負責：

- 書源規則本體
- cookie / 登入狀態
- 書源訂閱
- 文字替換規則
- 字典與 TTS 補充規則

### 搜尋與輔助資料

- `search_history_table`
- `search_books`
- `search_keywords`
- `keyboard_assists`
- `book_groups`

這組資料負責：

- 搜尋歷史與快取
- 使用者自訂分組
- 輔助輸入資料

## migration 重點

`AppDatabase.migration` 目前有兩個明確歷史節點：

- `< 7`
  - 移除舊 RSS 相關表：
    - `rss_articles`
    - `rss_sources`
    - `rss_stars`
    - `rss_read_records`
- `< 8`
  - `download_tasks` 新增：
    - `startChapterIndex`
    - `endChapterIndex`

另外，`beforeOpen` 會補做一次保底建表，避免舊資料庫版本在表缺失時直接壞掉。

## 與閱讀器直接相關的資料欄位

### `books`

閱讀器最核心的持久化欄位在 `books`：

- `durChapterTitle`
- `durChapterIndex`
- `durChapterPos`
- `durChapterTime`
- `readConfig`
- `isInBookshelf`

其中：

- `durChapterIndex`
- `durChapterPos`

是閱讀器 durable progress 的最主要資料落點。

### `chapters`

`chapters` 保存：

- 章節標題
- 章節 URL
- 章節索引
- 已抓取正文內容

### `read_records`

保存閱讀紀錄頁實際顯示所需的最近閱讀資訊。

## 維護規則

- 不在 UI 層自行拼裝 SQL
- 不把暫時 migration 計畫寫進文件，只有已存在的 migration 才記錄
- schema 變更時，同步更新這份文件中的：
  - schema version
  - migration 節點
  - 資料表分組
