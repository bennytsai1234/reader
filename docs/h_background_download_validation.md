# H 系列背景與下載功能驗證手冊

這份文件用來驗證「H 系列：背景與下載」功能。當章節預下載、下載佇列、失敗重試、書架批次下載或背景任務狀態出問題時，先照這份文件查。

## 適用範圍

- 下載服務：`lib/core/services/download_service.dart`
- 下載調度：`lib/core/services/download/download_scheduler.dart`
- 下載執行：`lib/core/services/download/download_executor.dart`
- 下載任務模型：`lib/core/models/download_task.dart`
- 下載任務 DAO：`lib/core/database/dao/download_dao.dart`
- 下載任務資料表：`lib/core/database/tables/app_tables.dart` / `DownloadTasks`
- 下載管理頁：`lib/features/cache_manager/download_manager_page.dart`
- 書籍詳情預下載入口：`lib/features/book_detail/book_detail_page.dart`
- 書籍詳情下載狀態：`lib/features/book_detail/book_detail_provider.dart`
- 書架批次下載：`lib/features/bookshelf/provider/bookshelf_update_mixin.dart`
- 書架更新檢查：`lib/features/bookshelf/provider/bookshelf_update_mixin.dart`
- Workmanager 初始化：`lib/main.dart`
- 全域 Provider：`lib/app_providers.dart`

## 快速驗證命令

```bash
dart analyze lib/core/models/download_task.dart \
  lib/core/services/download_service.dart \
  lib/core/services/download \
  lib/features/cache_manager/download_manager_page.dart \
  lib/features/book_detail/book_detail_page.dart \
  lib/features/book_detail/book_detail_provider.dart \
  lib/features/settings/settings_page.dart \
  test/download_executor_test.dart \
  test/features/book_detail/book_detail_provider_test.dart

flutter test test/download_executor_test.dart \
  test/features/book_detail/book_detail_provider_test.dart
```

全專案驗證：

```bash
flutter analyze
flutter test
```

## 功能表

| 編號 | 功能 | 現況 | 主要驗證點 |
| --- | --- | --- | --- |
| H1 | 背景下載章節 | 保留 | 詳情頁與書架批次入口可建立 `DownloadTask`，內容寫入 `reader_chapter_contents` |
| H2 | 下載管理：暫停 / 繼續 / 刪除 / 重試 / 失敗原因 | 修復後保留 | 「我的 → 背景下載佇列」可看任務、暫停、繼續、重試、刪除、查看失敗原因 |
| H3 | app 背景任務檢查書架更新 | 暫緩 | `Workmanager` 目前只初始化 callback，尚未排程週期性書架更新 |
| H4 | 更新檢查結果通知 | 不做 | 專案尚未接本地通知套件，不應宣稱有新章節通知 |
| H5 | 下載任務失敗原因明細 | 保留 | 任務顯示網路錯誤、書源失效、正文解析失敗、章節不存在、權限問題、儲存空間不足等分類 |
| H6 | 批次下載章節 | 保留 | 支援目前章節到結尾、後 10/50 章、指定範圍、全書、未快取章節 |
| H7 | 下載佇列排序 | 保留 | 下載管理頁可上移 / 下移任務；目前為執行期佇列排序，不另建資料庫排序欄位 |
| H8 | 僅 Wi-Fi 下載 | 暫緩 | 目前沒有下載網路策略；不要顯示 Wi-Fi only 開關 |
| H9 | 下載速度 / 並發數設定 | 暫緩 | 底層有固定並發 `maxConcurrent=3`、`maxChapterConcurrent=5`，尚未提供使用者設定 |
| H10 | 背景任務狀態頁 | 收斂 | 下載管理頁顯示下載佇列狀態；Workmanager 的上次 / 下次執行狀態頁暫不做 |
| H11 | 書架多選批次下載 | 額外保留 | 書架多選可批次加入未快取章節下載任務 |
| H12 | 匯出前補下載缺失章節 | 額外保留 | 詳情頁匯出全書時若正文不完整，可先加入缺失章節下載 |

## 驗證步驟

### H1 / H6 背景章節下載與批次下載

入口鏈路：

```text
BookDetailPage menu 預下載章節
  -> BookDetailProvider.queueDownload*
  -> DownloadService.addDownloadTask(book, chapters)
  -> DownloadScheduler.startDownloads()
  -> DownloadExecutor.processTask()
  -> ReaderChapterContentStorage.read(forceRefresh: true)
  -> ReaderChapterContentStore / ReaderChapterContentDao
```

手動驗證：

1. 準備一本可正常讀取正文的網路書，進入書籍詳情。
2. 右上選單點 `預下載章節`。
3. 分別測試 `從目前章節起下載到結尾`、`從目前章節起下載後 10 章`、`從目前章節起下載後 50 章`、`下載全書`、`下載全部未下載章節`、`指定章節範圍`。
4. 預期每次都顯示「已加入背景下載佇列，共 N 章」或合理阻擋訊息。
5. 進入 `我的 → 背景下載佇列`，預期任務出現在列表，進度會增加。
6. 回到詳情頁刷新「本書快取」，預期已快取章節數增加。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 預下載 UI | `features/book_detail/book_detail_page.dart` / `_showDownloadSheet()` |
| 批次章節解析 | `features/book_detail/book_detail_provider.dart` / `queueDownloadAll()`、`queueDownloadFromCurrent()`、`queueDownloadRange()`、`queueDownloadMissing()` |
| 任務建立 | `core/services/download/download_scheduler.dart` / `addDownloadTask()` |
| 章節下載 | `core/services/download/download_executor.dart` / `processTask()` |
| 正文儲存 | `core/services/reader_chapter_content_store.dart` |

常見故障定位：

- 顯示找不到書源：檢查 `BookDetailProvider._loadSource()` 與書源 `isReadingEnabledByRuntime`。
- 加入佇列後沒有下載：檢查 `DownloadService` 是否已由 `AppProviders.providers` 註冊。
- 快取數沒有增加：檢查 `ReaderChapterContentDao.saveContent()` 與書籍 `origin/bookUrl/chapterUrl` 是否一致。
- 指定範圍不對：UI 使用 1-based 輸入，Provider 內部轉為 0-based index。

### H2 / H5 / H7 下載管理、失敗明細與佇列排序

入口鏈路：

```text
SettingsPage
  -> DownloadManagerPage
  -> context.watch<DownloadService>()
  -> tasks
  -> pauseTask / resumeTask / retryTask / removeTask / moveTask
```

手動驗證：

1. 先加入至少兩個下載任務。
2. 進入 `我的 → 背景下載佇列`。
3. 點任務的暫停 icon，預期任務狀態變 `已暫停`。
4. 點繼續 icon，預期任務回到等待或下載中。
5. 使用更多操作中的 `上移` / `下移`，預期列表順序改變，等待中任務依新順序被調度。
6. 點 `刪除任務`，預期任務從列表消失。
7. 使用失效書源、斷網或錯誤正文規則製造失敗。
8. 預期任務顯示失敗分類與章節，更多操作可點 `查看失敗原因`。
9. 點重試，預期成功數 / 失敗數重置並重新加入等待。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 管理頁 UI | `features/cache_manager/download_manager_page.dart` |
| 全域 Provider | `app_providers.dart` / `ChangeNotifierProvider.value(value: DownloadService())` |
| 暫停 / 繼續 / 刪除 / 重試 | `core/services/download_service.dart` |
| 佇列排序 | `core/services/download_service.dart` / `moveTask()` |
| 失敗分類 | `core/services/download/download_executor.dart` / `classifyDownloadFailureReason()` |
| 任務模型 | `core/models/download_task.dart` |

常見故障定位：

- 打開管理頁出現 ProviderNotFound：檢查 `AppProviders.providers` 是否包含 `DownloadService()`。
- 暫停後仍有少量章節完成：已經發出的章節請求會自然結束，下一輪才停止。
- 重試後沒有立刻跑：檢查 `DownloadService.isDownloading`、全域暫停 `isPaused` 與任務 `status`。
- 失敗原因重啟後消失：目前明細存在任務物件；章節失敗內容會寫入 `reader_chapter_contents`，但 `download_tasks` schema v1 尚未新增錯誤文字欄位。

### H3 / H4 / H10 背景更新檢查與通知

目前決策：

- `Workmanager` 初始化保留，callback 會在 background isolate 重新跑 DI 並讀取書架。
- 尚未呼叫 `registerPeriodicTask()`，所以不宣稱支援週期性書架更新。
- 尚未接 `flutter_local_notifications` 或等價套件，所以不宣稱支援新章節通知。
- 下載管理頁只顯示下載佇列狀態，不當作完整 Workmanager 狀態頁。

手動驗證：

1. 冷啟 app。
2. 查看應用日誌，確認 `_runPostFirstFrameStartupTasks()` 有嘗試初始化 `Workmanager`。
3. 使用 `rg "registerPeriodicTask|flutter_local_notifications|local_notifications" lib pubspec.yaml`。
4. 預期目前沒有週期排程與本地通知實作。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| Workmanager callback | `main.dart` / `callbackDispatcher()` |
| Workmanager 初始化 | `main.dart` / `_runPostFirstFrameStartupTasks()` |
| 書架更新邏輯 | `features/bookshelf/provider/bookshelf_update_mixin.dart` / `refreshBookshelf()`、`checkBookUpdate()` |
| 下載狀態摘要 | `features/cache_manager/download_manager_page.dart` / `_buildQueueSummary()` |

常見故障定位：

- 以為背景更新會自動跑：目前沒有週期任務註冊，這是刻意暫緩，不是 regression。
- 需要通知時找不到入口：目前沒有通知套件與權限流程，不應只加 UI 開關。
- Workmanager 初始化失敗：看 `AppLog` 中 `Workmanager init failed`。

### H8 / H9 Wi-Fi only 與速度設定

目前決策：

- 不新增 UI 開關，避免出現無效設定。
- 目前下載併發是程式常數：
  - `DownloadBase.maxConcurrent = 3`
  - `DownloadBase.maxChapterConcurrent = 5`
- 書源層仍可用 `concurrentRate` 做來源請求節流，但這不是 H9 的使用者下載設定。

手動驗證：

1. 進入 `我的` 與下載管理頁。
2. 預期沒有「僅 Wi-Fi 下載」或「同時下載章節數」等設定。
3. 檢查 `DownloadBase` 的固定並發值仍存在。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 固定任務並發 | `core/services/download/download_base.dart` / `maxConcurrent` |
| 固定章節並發 | `core/services/download/download_base.dart` / `maxChapterConcurrent` |
| 書源節流 | `core/services/rate_limiter.dart` |

常見故障定位：

- 下載太快或太慢：目前只能改底層常數或書源 `concurrentRate`，沒有設定頁。
- 想做 Wi-Fi only：需要先定義 connectivity 套件、平台權限、背景限制與排程互動，再接 UI。

### H11 / H12 額外找到的下載相關功能

手動驗證：

1. 在書架長按進入多選，選擇多本網路書。
2. 點批次下載 icon。
3. 預期加入多本書的未快取章節下載任務，本地書或不可閱讀書源會被略過。
4. 在書籍詳情點 `匯出全書`，若正文快取不完整，預期可選 `先下載缺失章節`。

相關檔案：

| 項目 | 檔案 / 方法 |
| --- | --- |
| 書架多選下載 UI | `features/bookshelf/bookshelf_page.dart` / `_batchDownload()` |
| 書架批次下載邏輯 | `features/bookshelf/provider/bookshelf_update_mixin.dart` / `batchDownload()` |
| 匯出前補下載 | `features/book_detail/book_detail_page.dart` / `_handleExport()` |
| 缺失章節下載 | `features/book_detail/book_detail_provider.dart` / `queueDownloadMissing()` |

常見故障定位：

- 批次下載略過太多書：檢查是否為本地書、書源是否停用或 runtime health 不允許閱讀。
- 匯出前沒有提示：只有網路書且 `missingChapterCount > 0` 時才提示。
