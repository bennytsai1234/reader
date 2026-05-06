# 資料模型與持久化

## 目前責任

- 定義 app 的 Drift database、資料表、DAO、資料模型與 generated database 產物。
- 保存書籍、章節、章節內容快取、書源、搜尋、書架分組、書籤、替換規則、cookie、下載任務、閱讀紀錄與設定相關資料。

## 範圍

- Database registration：`lib/core/database/app_database.dart`。
- Table definitions：`lib/core/database/tables/app_tables.dart`。
- DAO：`lib/core/database/dao/`。
- Model：`lib/core/models/`。
- Generated files：`lib/core/database/**/*.g.dart`。
- 測試：`test/core/database/`、`test/core/models/`，以及依賴 DAO 的 feature/provider tests。

## 依賴與影響

- 上游依賴 Drift、SQLite、`path_provider`、core models 的 `toJson`/`fromJson`。
- 下游影響書架、搜尋、書源管理、閱讀器、備份、下載、快取、cookie 與 read record。
- Schema 或 DAO 改動通常會連動 generated `.g.dart`、測試資料與備份欄位。

## 關鍵流程

- `AppDatabase` 註冊所有 table 與 DAO，並用 `schemaVersion` 控制 migration。
- `app_tables.dart` 用 `@UseRowClass` 將 Drift row 對應到 domain model。
- 多個 rule 欄位透過 Drift `TypeConverter` 在 JSON string 與 rule object 間轉換。
- DAO 提供 app 各 feature 使用的查詢、watch stream、upsert、批次更新與刪除。

## 常見修改起點

- 新增資料表或欄位：先看 `app_tables.dart`，再看 `app_database.dart` 是否要註冊。
- 查詢或 watch 行為：先看對應 `lib/core/database/dao/*_dao.dart`。
- JSON import/export 或備份欄位：先看 model 的 serialization 檔與 `BackupService`/`RestoreService`。
- model 相容 Legado 欄位：先看 `lib/core/models/book_source.dart` 與 `lib/core/models/source/`。

## 修改路線

- 改 schema 時，同步 table、row class、DAO、model serialization、備份/還原與測試 fixture。
- 改主鍵或 URL normalization 時，確認書架、搜尋結果合併、章節內容快取與下載任務是否使用相同 key。
- 改 generated database 產物時，使用 Drift build_runner 重新產生，不手寫 `.g.dart`。

## 已知風險

- `schemaVersion` 目前是 1，migration 只有 createAll；已有使用者資料後升級 schema 需要補 migration。
- 多個 converter 解析失敗時回傳 null，可能隱藏不相容資料。
- Generated `.g.dart` 很容易和 table/DAO 宣告不同步。

## 參考備註

- Legado 的 `data/entities`、`data/dao` 與 Room 資料模型可作欄位概念參考。
- 本專案持久化以 Drift/SQLite 為準，不追求 Room schema 或所有 Legado entity 完整對齊。

## 不要做

- 不要把 Legado 的 RSS、漫畫、字典、WebDAV 或其他未支援 entity 當成缺漏補進 schema。
- 不要只改 model 而不檢查 DAO、備份與既有 fixture。
- 不要手動編輯 generated Drift code 來修正 schema 問題。
