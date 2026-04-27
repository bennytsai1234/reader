# A 系列啟動與主入口功能驗證手冊

這份文件用來驗證「A 系列：啟動與主入口」功能。當啟動、主頁 tab、返回鍵或啟動失敗處理出問題時，先照這份文件查，不需要從整個系統重新翻起。

## 適用範圍

- App 啟動入口：`lib/main.dart`
- Splash / 歡迎畫面：`lib/features/welcome/splash_page.dart`
- 主頁與底部導覽：`lib/features/welcome/main_page.dart`
- 啟動失敗 UI：`lib/features/welcome/startup_failure_panel.dart`
- Provider 註冊：`lib/app_providers.dart`
- DI 與核心服務初始化：`lib/core/di/injection.dart`
- 預設資料初始化：`lib/core/services/default_data.dart`
- App 主題：`lib/shared/theme/app_theme.dart`
- 資料庫：`lib/core/database/app_database.dart`

## 快速驗證命令

```bash
flutter analyze
flutter test
```

針對 A 系列相關頁面做較快的局部驗證：

```bash
flutter test test/features/settings/settings_pages_compile_test.dart \
  test/features/bookshelf/bookshelf_page_compile_test.dart \
  test/features/explore/explore_page_compile_test.dart
```

## 最終功能表

| 編號 | 功能 | 現況 | 主要驗證點 |
| --- | --- | --- | --- |
| A1 | 打開 app → Splash / 歡迎畫面 → 書架首頁 | 保留 | 先看到 Splash，初始化後進 `MainPage`，預設書架 tab |
| A2 | 打開 app → 初始化預設資料 → 進入主頁 | 保留 | DI、Provider、DB、Network、TTS、CrashHandler、DefaultData essential、AppTheme 有完成 |
| A3 | 啟動後 deferred startup | 保留 | 第一幀後跑 DefaultData deferred 與 Workmanager |
| A4 | 底部 tab：書架 / 發現 / 我的切換 | 保留 | 固定三個 tab，`IndexedStack` 保留狀態 |
| A5 | 發現 tab 顯示控制 | 已移除 | 不再有 `showDiscovery`，不再有「顯示發現」開關 |
| A6 | 重複點擊目前 tab | 保留 | 目前支援書架 tab 快速重複點擊重新載入書架 |
| A7 | 首次啟動流程 / onboarding | 已移除 | 不做 first-run 引導、不做匯入書源或本地書 onboarding |
| A8 | 一般啟動流程 | 保留 | 讀取既有設定與書架資料，進入書架首頁 |
| A9 | 升級後啟動流程 | 工程底線 | 目前 schema v1 只有 onCreate；未來改 schema 時必須補 migration |
| A10 | 啟動失敗處理 | 保留 | 顯示失敗面板，提供重試、詳情、複製、應用日誌、崩潰日誌 |
| A11 | 主頁返回鍵行為 | 保留 | 發現/我的返回書架；書架連按兩次返回退出 |

## A1 驗證：Splash 到書架首頁

入口鏈路：

```text
main.dart
  -> _startApp()
  -> configureDependencies()
  -> runApp(MultiProvider + LegadoReaderApp)
  -> MaterialApp(home: SplashPage)
  -> SplashPage._initApp()
  -> DefaultData.initEssential()
  -> Navigator.pushReplacement(MainPage)
  -> MainPage index 0 = BookshelfPage
```

手動驗證：

1. 執行 `flutter run` 或從裝置冷啟 app。
2. 預期先看到 Splash / 歡迎畫面。
3. 初始化完成後自動進入主頁。
4. 預期底部 tab 顯示 `書架 / 發現 / 我的`。
5. 預期預設選中 `書架`，頁面標題為 `書架` 或顯示書架內容/空狀態。

故障定位：

- 如果完全黑屏，先看 `lib/main.dart` 的 `_startApp()` 是否進入 catch。
- 如果停在 Splash，先看 `SplashPage._initApp()` 是否卡在 `DefaultData.initEssential()`。
- 如果沒有進書架，檢查 `MainPage._currentIndex` 初始值是否仍為 `0`。

## A2 驗證：啟動必要初始化

必要初始化位置：

| 初始化項 | 檔案 / 方法 |
| --- | --- |
| Flutter binding | `main.dart` / `_startApp()` |
| DI | `core/di/injection.dart` / `configureDependencies()` |
| Provider | `app_providers.dart` / `AppProviders.providers` |
| DB singleton / DAO | `core/di/injection.dart`、`core/database/app_database.dart` |
| NetworkService | `core/di/injection.dart` / `getIt<NetworkService>().init()` |
| TTSService | `core/di/injection.dart` / `getIt<TTSService>().init()` |
| CrashHandler | `core/di/injection.dart` / `CrashHandler.init()` |
| DefaultData essential | `core/services/default_data.dart` / `initEssential()` |
| AppTheme | `shared/theme/app_theme.dart` / `AppTheme.init()` |

手動驗證：

1. 冷啟 app。
2. 確認沒有進入「核心初始化失敗」畫面。
3. 進入「我的」→「應用程式日誌」，確認可以看到啟動相關 log。
4. 進入書架、發現、我的三個 tab，確認 Provider 都能正常建立。

故障定位：

- DI 註冊失敗通常會在 `_startApp()` catch 中顯示「核心初始化失敗」。
- Provider 讀不到服務通常會在 `AppProviders.providers` 或對應 Provider constructor 爆出。
- DB 相關錯誤先看 `AppDatabase._openConnection()` 與平台的 application support directory 權限。

## A3 驗證：Deferred Startup

Deferred 任務分兩路：

| 任務 | 入口 | 內容 |
| --- | --- | --- |
| 預設資料 deferred | `SplashPage._initDeferredStartupData()` | `DefaultData.initDeferred()` |
| 第一幀後背景任務 | `main.dart` / `_runPostFirstFrameStartupTasks()` | debug log 設定、Workmanager init |

`DefaultData.initDeferred()` 目前包含：

- 匯入預設 TXT 目錄規則
- 匯入 HTTP TTS 設定
- 匯入預設書源
- 匯入字典規則
- 校正書源排序
- 清理 7 天前搜尋歷史
- 清理過期 cache
- 預熱簡繁轉換

注意：`assets/default_sources/*.json` 目前可能是空陣列。這代表「匯入流程存在」，但不一定會產生實際預設資料。

手動驗證：

1. 冷啟 app，確認先進入主頁，不被 deferred 任務阻塞。
2. 查看應用日誌，確認 deferred 任務失敗時會記錄錯誤，不會讓 app 退回 Splash。
3. 若要驗證 Workmanager，檢查 `main.dart` 的 `_runPostFirstFrameStartupTasks()` 是否執行到 `Workmanager().initialize(...)`。

故障定位：

- 預設資料沒匯入：先確認 `assets/default_sources/` 的 JSON 是否真的有內容。
- Workmanager 初始化失敗：看 `AppLog` 中 `Workmanager init failed`。
- 書源排序或清理失敗：看 `DefaultData._maintenance()` 的 `Maintenance error`。

## A4 驗證：底部 Tab 切換

目前主頁固定三個 tab：

```text
0 書架 -> BookshelfPage
1 發現 -> ExplorePage
2 我的 -> SettingsPage
```

實作位置：

- `lib/features/welcome/main_page.dart`
- `NavigationBar`
- `IndexedStack`

手動驗證：

1. 進入 app。
2. 點 `書架 / 發現 / 我的`。
3. 預期底部選中狀態正確變化。
4. 在某個 tab 捲動或打開局部狀態後切走再切回，預期 `IndexedStack` 保留該 tab 狀態。

故障定位：

- tab 消失：檢查 `MainPage.build()` 裡的 `items` 是否仍固定三筆。
- tab 狀態不保留：檢查 `body` 是否仍使用 `IndexedStack`，不是條件式重建單一 child。

## A5 驗證：發現 Tab 顯示控制已移除

A5 已從產品功能移除。現在不應再有以下內容：

- `SettingsProvider.showDiscovery`
- `SettingsProvider.setShowDiscovery`
- `PreferKey.showDiscovery`
- 外觀設定中的「顯示發現」開關
- `MainPage` 中依設定隱藏發現 tab 的分支

驗證命令：

```bash
rg "showDiscovery|顯示發現" lib test docs
```

預期：

- `lib` 與 `test` 不應有任何結果。
- `docs` 只應在歷史說明或本文件「已移除」段落中出現。

手動驗證：

1. 進入「我的」→「外觀與主題」。
2. 預期沒有「顯示發現」開關。
3. 回主頁，預期始終有 `書架 / 發現 / 我的` 三個 tab。

## A6 驗證：重複點擊目前 Tab

目前保留的行為：

- 快速重複點擊目前的 `書架` tab，會呼叫 `BookshelfProvider.loadBooks()`。
- 發現 / 我的 tab 目前沒有接刷新 hook。

實作位置：

- `lib/features/welcome/main_page.dart`
- `BookshelfProvider.loadBooks()`

手動驗證：

1. 進入主頁書架 tab。
2. 快速連點底部 `書架` tab 兩次，間隔需小於 300ms。
3. 預期書架重新載入。
4. 若不確定 UI 是否有變化，可在 `BookshelfProvider.loadBooks()` 設 breakpoint 或臨時觀察 log。

故障定位：

- 沒觸發：檢查 `_lastTapTime` 判斷與 `onDestinationSelected` 是否仍存在。
- 點發現或我的沒有刷新：這是目前設計，不是 bug。

## A7 驗證：首次啟動流程已移除

A7 onboarding 已從產品功能移除。現在不應期待：

- first-run 判斷
- 首次啟動歡迎引導
- 隱私或教學流程接在主入口前
- 引導匯入書源
- 引導匯入本地書

目前首次安裝與一般啟動一樣：

```text
Splash
  -> DefaultData.initEssential()
  -> MainPage
  -> 書架 tab
  -> deferred startup 背景執行
```

驗證方式：

1. 清除 app data 或重新安裝。
2. 冷啟 app。
3. 預期不出現 onboarding，直接進書架首頁。

## A8 驗證：一般啟動流程

一般啟動應完成：

- 讀取既有設定：`SettingsProvider._loadSettings()`
- 讀取書架 UI 偏好：`BookshelfProvider.loadUiPreferences()`
- 讀取書架資料：`BookshelfProvider.loadBooks()`
- 讀取分組：`BookshelfProvider.loadGroups()`
- 進入主頁書架 tab

手動驗證：

1. 修改主題或歡迎畫面設定。
2. 關閉 app 後重新開啟。
3. 預期設定仍保留。
4. 加入或匯入一本書後重啟。
5. 預期書架資料仍在。

目前不包含：

- 恢復上次所在 tab
- 恢復上次任意入口頁

這兩項不是目前 A 系列功能。

故障定位：

- 設定沒恢復：查 `SettingsProvider._loadSettings()` 與 `SharedPreferences` key。
- 書架沒恢復：查 `BookshelfProvider.loadBooks()` 與 `BookDao.getInBookshelf()`。

## A9 驗證：升級後啟動流程

目前資料庫狀態：

- `AppDatabase.schemaVersion == 1`
- `MigrationStrategy` 只有 `onCreate: (m) => m.createAll()`
- 目前沒有 `onUpgrade`

這代表：

- 現階段乾淨安裝可建立 schema v1。
- 未來只要改 Drift table 或 schema version，就必須補 migration。

每次改 DB schema 時必做：

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test test/backup_service_test.dart
```

升級驗證清單：

1. 確認 `AppDatabase.schemaVersion` 有遞增。
2. 確認 `MigrationStrategy` 補上對應 `onUpgrade`。
3. 從舊版本資料庫啟動新版本 app。
4. 確認 app 不會進啟動失敗頁。
5. 確認書架、書源、閱讀進度、備份還原可用。
6. 更新 `docs/DATABASE.md` 的 migration 說明。

故障定位：

- 升級後啟動失敗且錯在資料庫：先看 `AppDatabase.migration`。
- 備份還原 schema 不相容：先看 `BackupService.currentSchemaVersion` 與 `RestoreService` 的 manifest 檢查。

## A10 驗證：啟動失敗處理

目前有兩條失敗路徑：

| 失敗階段 | 畫面 | 實作 |
| --- | --- | --- |
| 核心初始化失敗 | 核心初始化失敗 | `main.dart` / `_StartupFailureApp` |
| Splash essential init 失敗 | 啟動失敗 | `SplashPage` + `StartupFailurePanel` |

失敗面板應提供：

- `重試`
- `詳情`
- `複製`
- `應用日誌`
- `崩潰日誌`

手動驗證：

1. 用 debug 方式在 `configureDependencies()` 或 `DefaultData.initEssential()` 暫時丟出例外。
2. 冷啟 app。
3. 預期看到啟動失敗面板，而不是黑屏。
4. 點 `詳情`，預期可看到 exception 與 stack trace。
5. 點 `複製`，預期錯誤內容寫入剪貼簿並顯示 SnackBar。
6. 點 `應用日誌`，預期進入 `AppLogPage`。
7. 點 `崩潰日誌`，預期進入 `CrashLogPage`。
8. 修復錯誤後點 `重試`，預期可重新走啟動流程。

故障定位：

- 點重試沒反應：查 `StartupFailurePanel.onRetry`。
- 核心初始化重試仍失敗：查 `main.dart` / `_retryCriticalStartup()` 是否有 `getIt.reset()`。
- 詳情沒內容：查傳入 `StartupFailurePanel.details` 的字串。
- Crash log 沒寫入：查 `CrashHandler.init()` 是否已完成；核心初始化很早失敗時可能只有 AppLog 記錄。

## A11 驗證：主頁返回鍵行為

目前 Android 返回鍵規則：

```text
如果目前在發現 / 我的 tab
  -> 回到書架 tab

如果目前在書架 tab
  -> 第一次返回顯示「再按一次退出」
  -> 2 秒內第二次返回退出 app

如果目前有 dialog / menu / route overlay
  -> 優先由 Flutter route 關閉上層 UI
```

實作位置：

- `lib/features/welcome/main_page.dart`
- `PopScope`
- `_handleBackIntent()`
- `SystemNavigator.pop()`

手動驗證：

1. 進入 `發現` tab，按 Android 返回鍵。
2. 預期回到 `書架`，app 不退出。
3. 進入 `我的` tab，按 Android 返回鍵。
4. 預期回到 `書架`，app 不退出。
5. 在 `書架` tab 按返回鍵。
6. 預期顯示 SnackBar：`再按一次退出`。
7. 2 秒內再按返回鍵。
8. 預期 app 退出。
9. 打開 dialog 或 popup menu 後按返回鍵。
10. 預期先關閉 dialog / menu。

額外注意：

- 書架頁有自己的多選模式返回處理：`BookshelfPage` 的 `PopScope`。
- 若按返回時同時退出多選又顯示「再按一次退出」，檢查 `MainPage` 與 `BookshelfPage` 的巢狀 `PopScope` 互動。

## 常見問題索引

| 問題 | 先看哪裡 |
| --- | --- |
| app 一打開就黑屏 | `main.dart` / `ErrorWidget.builder`、`_StartupFailureApp` |
| app 停在 Splash | `SplashPage._initApp()`、`DefaultData.initEssential()` |
| 進不了主頁 | `Navigator.pushReplacement(MainPage)` |
| 底部 tab 少一個 | `MainPage.build()` 的固定 `items` |
| 外觀設定仍有顯示發現 | `AppearanceSettingsPage`，並用 `rg "showDiscovery|顯示發現" lib test` 查殘留 |
| 書架重複點擊沒刷新 | `MainPage.onDestinationSelected()`、`BookshelfProvider.loadBooks()` |
| 啟動失敗沒有重試按鈕 | `StartupFailurePanel` |
| 詳情或複製沒有錯誤內容 | `StartupFailurePanel.details` |
| 返回鍵直接退出 | `MainPage._handleBackIntent()` |
| 升級後資料庫錯誤 | `AppDatabase.schemaVersion`、`MigrationStrategy`、`docs/DATABASE.md` |

## 維護規則

- A 系列功能有變更時，同步更新本文件。
- 若重新加入 A5 或 A7，必須把「已移除」狀態改成實際驗證步驟。
- 改 DB schema 時，A9 與 `docs/DATABASE.md` 必須一起更新。
- 改主頁 tab、Splash、DI 或啟動失敗 UI 時，至少跑：

```bash
flutter analyze
flutter test test/features/settings/settings_pages_compile_test.dart \
  test/features/bookshelf/bookshelf_page_compile_test.dart \
  test/features/explore/explore_page_compile_test.dart
```
