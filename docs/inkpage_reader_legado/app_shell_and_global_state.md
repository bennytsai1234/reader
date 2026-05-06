# 啟動與全域狀態

## 目前責任

- 啟動 Flutter app、初始化核心服務、掛載全域 providers，並在啟動失敗時顯示可重試的錯誤畫面。
- 管理 app 的 MaterialApp、主題模式、locale、全域 navigator/scaffold messenger，以及主分頁入口。
- 背景任務目前只初始化 Workmanager 並讀取書架資料，沒有實際執行完整更新流程。

## 範圍

- 代表檔案：`lib/main.dart`、`lib/app_providers.dart`、`lib/core/di/injection.dart`。
- 入口 UI：`lib/features/welcome/splash_page.dart`、`lib/features/welcome/main_page.dart`、`lib/features/welcome/startup_failure_panel.dart`。
- 全域 providers：`BookshelfProvider`、`SettingsProvider`、`ChangeCoverProvider`、`DownloadService`、`TTSService`。
- 主要測試分散在 feature compile/smoke tests 與 provider tests。

## 依賴與影響

- 依賴 Drift database、DAO、`NetworkService`、`TTSService`、`CrashHandler`、`SharedPreferences`、`Workmanager`。
- 啟動流程改動會影響所有頁面、source verification overlay、主題、TTS、下載與書架資料載入。
- DI 註冊改動會影響測試可替換性與 runtime 單例一致性。

## 關鍵流程

- `main()` 透過 `runZonedGuarded` 啟動 `_startApp()`。
- `_startApp()` 初始化 Flutter binding、錯誤畫面、DI、Flutter error handler，然後用 `MultiProvider` 包住 app。
- `SplashPage` 執行 essential default data 初始化，成功後進入 `MainPage`。
- `MainPage` 用底部導覽切換書架、發現、我的，並延遲初始化 deferred default data。
- 第一幀後 `_runPostFirstFrameStartupTasks()` 開啟 debug log preference 並初始化 Workmanager。

## 常見修改起點

- 啟動失敗或初始化順序：先看 `lib/main.dart`。
- 全域 provider 新增或移除：先看 `lib/app_providers.dart`，再確認 DI 是否也需要註冊。
- get_it 單例、DAO、服務初始化：先看 `lib/core/di/injection.dart`。
- 主分頁、首頁、導覽邏輯：先看 `lib/features/welcome/main_page.dart`。
- 啟動畫面或 essential data：先看 `lib/features/welcome/splash_page.dart` 與 `lib/core/services/default_data.dart`。

## 修改路線

- 新增全域服務時，先定義服務生命週期，再同步 DI、provider、測試 setup，最後確認啟動失敗時有可讀錯誤。
- 改主導覽時，先確認頁面 provider 是否已由全域掛載；feature-local provider 不應無理由提升到全域。
- 改背景任務時，必須考慮 background isolate 需要重新初始化 DI，不能假設主 isolate 狀態可用。

## 已知風險

- Workmanager callback 目前只有讀書架與 log，註解也指出尚未接上真實更新流程。
- DI 使用單例資料庫與多個 lazy DAO，測試若沒有隔離 getIt 可能互相污染。
- 啟動錯誤畫面會顯示 stack trace，對 debug 友善，但 release 文字與隱私呈現需要另外判斷。

## 參考備註

- Legado 的 Android app 有 welcome/main/config 等入口層，但本專案使用 Flutter MaterialApp、provider 與 get_it，不應照搬 Android Activity/Fragment 架構。
- 可參考 Legado 的概念分層，但啟動與全域狀態以現有 Flutter 架構為準。

## 不要做

- 不要因為 Legado 有更多全域服務，就新增本專案沒有需求的 app-wide 狀態。
- 不要把 feature provider 無條件搬到全域。
- 不要讓背景任務依賴主 isolate 已初始化的物件。
