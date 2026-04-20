# 資料層現況

更新日期：2026-04-20

這份文檔只寫目前程式碼能直接驗證的事，主要依據：

- [app_database.dart](/home/benny/projects/reader/lib/core/database/app_database.dart:1)
- [app_tables.dart](/home/benny/projects/reader/lib/core/database/tables/app_tables.dart:1)
- `lib/core/database/dao/*.dart`

## 基本資訊

- 技術：Drift + SQLite
- 資料庫入口：`lib/core/database/app_database.dart`
- schema version：`8`
- DB 路徑：`ApplicationSupportDirectory/databases/inkpage_reader.db`
- `AppDatabase` 採 singleton factory

## 目前有哪些表

`AppDatabase` 目前掛了 20 張表：

1. `Books`
2. `Chapters`
3. `BookSources`
4. `BookGroups`
5. `SearchHistoryTable`
6. `ReplaceRules`
7. `Bookmarks`
8. `Cookies`
9. `DictRules`
10. `HttpTtsTable`
11. `ReadRecords`
12. `Servers`
13. `TxtTocRules`
14. `CacheTable`
15. `KeyboardAssists`
16. `RuleSubs`
17. `SourceSubscriptions`
18. `SearchBooks`
19. `DownloadTasks`
20. `SearchKeywords`

## 目前有哪些 DAO

也對應 20 個 DAO：

1. `BookDao`
2. `ChapterDao`
3. `BookSourceDao`
4. `BookGroupDao`
5. `BookmarkDao`
6. `ReplaceRuleDao`
7. `SearchHistoryDao`
8. `CookieDao`
9. `DictRuleDao`
10. `HttpTtsDao`
11. `ReadRecordDao`
12. `ServerDao`
13. `TxtTocRuleDao`
14. `CacheDao`
15. `KeyboardAssistDao`
16. `RuleSubDao`
17. `SourceSubscriptionDao`
18. `SearchBookDao`
19. `DownloadDao`
20. `SearchKeywordDao`

## 三個最關鍵的真源

### `Books`

主鍵是 `bookUrl`。

這張表同時承擔：

- 書籍基本資訊
- 書架狀態
- 閱讀進度
- 部分閱讀設定

閱讀器最關鍵的欄位：

- `durChapterIndex`
- `durChapterPos`
- `durChapterTitle`
- `readConfig`
- `isInBookshelf`

對 `reader` 而言，真正的持久化進度不是 page index，而是：

- `durChapterIndex`
- `durChapterPos`

這點和 `reader` 的 runtime 設計是一致的。

### `Chapters`

主鍵是 `url`。

這張表承擔：

- 章節目錄
- 正文快取
- 本地 TXT offset
- 部分片段定位資訊

重要欄位：

- `bookUrl`
- `title`
- `index`
- `content`
- `start` / `end`
- `startFragmentId` / `endFragmentId`

### `BookSources`

主鍵是 `bookSourceUrl`。

目前保存：

- 書源基本資訊
- login 設定
- JS lib
- explore/search URL
- search/explore/bookInfo/toc/content/review rule
- 開關與排序欄位

這張表目前沒有獨立的 health / check state 欄位。

## 目前 migration 真相

從 [app_database.dart](/home/benny/projects/reader/lib/core/database/app_database.dart:88) 可以直接確認：

- `schemaVersion == 8`
- `from < 7` 時會移除舊 RSS 相關表
- `from < 8` 時會為 `download_tasks` 新增 `startChapterIndex`、`endChapterIndex`
- `beforeOpen` 會補建所有已註冊表

這代表資料層策略偏保守：

- 先確保不缺表
- 再做少量增量欄位遷移
- 已經主動清掉被正式移除的 RSS 痕跡

## 與 legado 的手動對照

### 共同點

- 都有 `Book`、`BookChapter`、`BookSource` 這三條主線
- 都把閱讀進度與書架資料落進本地資料庫
- 都有書源規則、替換規則、書籤、搜尋歷史等資料結構

### `reader` 較簡化的地方

- 沒有 RSS 相關表，舊表還在 migration 中被清掉
- 沒有把 `legado` 的整個內容生態一比一搬過來
- schema 比 `legado` 明顯更偏向小說閱讀器本體

### `reader` 當前最明顯的缺口

- `BookSources` 沒有正式 health 欄位
- 最近一次書源校驗結果沒有正式持久化表
- 來源治理目前仍依賴 `bookSourceGroup` / `bookSourceComment`

這意味著資料層對書源治理仍停在過渡態，不算完全完成。

## 和 feature 的責任邊界

現在的正確邊界應該這樣理解：

- DAO：只做 CRUD、查詢、watch
- service：組合多個 DAO 與 engine/network/local-book 能力
- provider/controller：協調頁面狀態與使用者流程
- widget/page：不直接碰 DAO

這條原則大致成立，但不能誇大。像 `BookDetailProvider`、`BookshelfProvider` 這類 provider 仍直接操作 DAO，只是 UI widget 本身已不直接碰資料層。

## 目前最值得補的資料層工作

1. 將書源 health 正規化，別再靠 group/comment 推導。
2. 將最後一次書源校驗結果落地。
3. 讓來源治理資料能在重啟後保留，並支撐排序、篩選與清理建議。
4. 釐清 cache、download、chapter content 的資料責任。

## 結論

`reader` 的資料層已經足夠支撐小說閱讀主線，但它不是完全對齊 `legado` 的資料模型。

最準確的說法是：

- 書籍、章節、書源三條主線已成立
- RSS 線已被正式移除
- 書源治理資料仍處於「能用但不正規」的過渡階段
