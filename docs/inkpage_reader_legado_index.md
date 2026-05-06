# Inkpage Reader x Legado Atlas Index

## 目的與使用方式

- 這份 index 用來在看程式碼前定位應該先理解哪個模組。
- 這是工程地圖，不是完整架構書；細節放在各模組文件。
- 一般理解、修改、驗證或混合工作，請使用 main workflow，不要重新執行 Codebase Atlas。
- 只有使用者明確要求完整 rebuild、refresh、regenerate 或 rescan 時，才重新掃描整個 repo 並重建 atlas。

## 初始化決策

- Atlas 模式：部分參考 `/home/benny/projects/legado`。
- 工作語言：繁體中文。原因是 `AGENTS.md` 明確要求使用繁體中文做使用者溝通與專案規則討論。
- 參考範圍：以 `inkpage_reader` 現有功能為準，只參考 Legado 中和小說閱讀相關的既有概念、資料流與行為對照。
- 功能邊界：不要因為 Legado 有額外功能就把它們視為本專案缺失；本專案是縮減版，聚焦小說閱讀。
- 交付方式：一般工作不自動 commit 或 push；只有使用者明確要求提交、推送，或正在走發布流程時才做。
- Workflow 入口：`docs/inkpage_reader_legado_adapter.md` 是預設薄 adapter；另有 `.agents/skills/inkpage-reader/SKILL.md` 作為 Codex skill 入口。

## 參考邊界

Legado 只用於幫助理解現有 reader 的對應設計，不要求完整功能對齊。可參考的部分包括：

- 自訂書源、規則解析、搜尋、發現、書籍詳情、目錄與正文抓取。
- 閱讀器的章節載入、頁面切分、翻頁、朗讀與閱讀設定概念。
- 本地 TXT、EPUB、UMD 閱讀與備份資料格式思路。

不要從 Legado 引入新的對齊要求，例如 RSS、漫畫、Web API、Content Provider、WebDAV、字典、Mobi/PDF、完整 Android 架構或完整翻頁效果集合。

## 專案操作限制

既有專案規則要求所有 workflow 遵守：

- 這是 Flutter/Dart 專案 `inkpage_reader`。
- App 顯示名稱是 `墨頁`。
- 產品是受 Legado 啟發的小說閱讀器。
- 使用者溝通與專案規則討論使用繁體中文。
- Android release 由 `.github/workflows/android-release.yml` 處理。
- Release workflow 在推送符合 `v*` 的 tag 時觸發，也可用 `workflow_dispatch` 手動啟動。
- 發布時要先推送 release commit branch，再建立並推送 release tag；不要替尚未推送的本地 commit 建 tag。
- 推送 release tag 後，檢查 GitHub Actions 並確認 Android Release workflow 已開始 building；看到遠端 workflow 開始 building 後，可以不等 build 結束就關閉任務。

## Workflow 文件

- Main workflow: [inkpage_reader_legado_main_workflow.md](inkpage_reader_legado_main_workflow.md)
- Understand workflow: [inkpage_reader_legado_understand_workflow.md](inkpage_reader_legado_understand_workflow.md)
- Change workflow: [inkpage_reader_legado_change_workflow.md](inkpage_reader_legado_change_workflow.md)
- Validate workflow: [inkpage_reader_legado_validate_workflow.md](inkpage_reader_legado_validate_workflow.md)

## 模組列表

- [啟動與全域狀態](inkpage_reader_legado/app_shell_and_global_state.md)
- [資料模型與持久化](inkpage_reader_legado/persistence_and_models.md)
- [書源規則與解析引擎](inkpage_reader_legado/source_rules_and_parsing.md)
- [線上書籍內容流程](inkpage_reader_legado/web_book_content_pipeline.md)
- [書源管理與瀏覽驗證](inkpage_reader_legado/source_management_and_browser.md)
- [搜尋與發現](inkpage_reader_legado/search_and_discovery.md)
- [書架、書籍詳情與紀錄](inkpage_reader_legado/bookshelf_detail_and_records.md)
- [Reader V2 閱讀器](inkpage_reader_legado/reader_v2.md)
- [本地書、下載與快取](inkpage_reader_legado/local_books_downloads_and_cache.md)
- [設定、備份與發布](inkpage_reader_legado/settings_backup_and_release.md)

## 模組摘要

- 啟動與全域狀態：處理 app 啟動、DI、全域 provider、初始化錯誤與主分頁。遇到啟動失敗、全域服務注入、背景任務、主導覽或 app-wide provider 問題時從這裡開始。
- 資料模型與持久化：處理 Drift database、DAO、資料表、核心 model 與 schema 產物。遇到資料欄位、查詢、序列化、備份資料來源或 generated `.g.dart` 同步問題時從這裡開始。
- 書源規則與解析引擎：處理書源 rule model、URL 分析、CSS/XPath/JSONPath/regex/JS 解析與相容行為。遇到規則語法、解析結果、QuickJS/JS extension、字型反爬或 Legado rule 相容問題時從這裡開始。
- 線上書籍內容流程：處理從書源抓搜尋結果、書籍詳情、目錄與正文的流程。遇到線上來源載入、登入檢查、跳轉、目錄翻頁、正文多頁或 source health 造成的閱讀問題時從這裡開始。
- 書源管理與瀏覽驗證：處理書源匯入、編輯、分組、檢查、debug、瀏覽器登入/驗證與 cookie 回寫。遇到書源 CRUD、批次檢查、匯入預覽、規則編輯 UI 或驗證碼流程時從這裡開始。
- 搜尋與發現：處理多書源搜尋、搜尋範圍、結果合併、搜尋歷史、探索分類與探索列表。遇到找書、結果排序/篩選、搜尋進度、發現頁分類或 exploreUrl 行為時從這裡開始。
- 書架、書籍詳情與紀錄：處理書架列表、書籍詳情、加入/移除書架、章節列表、封面、書籤與閱讀紀錄。遇到書籍生命週期、書架排序、章節刷新、換源入口或閱讀紀錄顯示時從這裡開始。
- Reader V2 閱讀器：處理閱讀頁主流程、章節 repository、內容轉換、排版、渲染、runtime、viewport、選單、朗讀、自動翻頁、書籤與閱讀進度。遇到閱讀體驗、頁面切分、滑動/滾動、定位、進度保存或 TTS highlight 問題時從這裡開始。
- 本地書、下載與快取：處理 TXT/EPUB/UMD 匯入、章節內容讀取、背景下載、章節內容儲存、封面/資源與 cache 管理。遇到離線閱讀、匯入檔案、下載佇列、內容快取或本地檔案編碼問題時從這裡開始。
- 設定、備份與發布：處理使用者偏好、閱讀設定、TTS 設定、備份還原、版本資訊、release workflow 與發布檢查。遇到設定持久化、備份 ZIP、還原、release tag 或 CI 發布行為時從這裡開始。
