# 墨頁 Inkpage Reader

`墨頁` 是一個使用 Flutter / Dart 開發的小說閱讀器，靈感來自 [Legado](https://github.com/gedoor/legado)，但功能範圍以本專案目前已實作的小說閱讀能力為準，不追求完整對齊 Legado 的所有功能。

本專案聚焦在幾件事：

- 自訂小說書源與規則解析
- 線上搜尋、探索、書籍詳情、目錄與正文抓取
- 本地小說匯入與閱讀
- 針對長篇文字內容優化的 Reader V2 閱讀器
- 備份、還原、下載與離線快取

## 專案定位

- 專案名稱：`inkpage_reader`
- App 顯示名稱：`墨頁`
- 技術棧：Flutter、Dart、Provider、Drift、Dio、WebView
- 產品方向：受 Legado 啟發的小說閱讀器
- 主要支援場景：Android 小說閱讀與書源管理

## 目前功能

### 1. 書源管理

- 匯入 JSON 或 URL 書源
- 預覽、啟用、停用、分組、排序、搜尋
- 書源編輯器，可調整搜尋、探索、詳情、目錄、正文等規則
- 批次檢查書源狀態與基本 debug 能力
- 支援需要登入、驗證碼或 Cookie 回寫的瀏覽器驗證流程

### 2. 搜尋與探索

- 多書源搜尋小說
- 顯示搜尋進度與結果
- 探索頁支援分類與列表流
- 可從搜尋或探索結果進入書籍詳情

### 3. 書架與書籍管理

- 加入 / 移除書架
- 書籍詳情、封面、章節列表
- 閱讀紀錄與最近閱讀狀態
- 書籤管理
- 換源相關流程

### 4. Reader V2 閱讀器

- 章節載入與預載
- 滑動 / 捲動模式閱讀
- 閱讀進度保存與恢復
- 字體、行距、段距、主題等閱讀設定
- 替換規則
- TTS 朗讀
- 自動翻頁
- 書籤與閱讀選單

### 5. 本地書與離線能力

- 匯入並閱讀 `TXT`、`EPUB`、`UMD`
- 章節下載與離線快取
- 章節內容儲存
- 封面與資源快取管理

### 6. 設定、備份與工具

- 主題與一般設定
- 閱讀設定與 TTS 設定
- 備份與還原
- 版本資訊與錯誤 / 記錄相關能力

## 非目標與功能邊界

這個專案雖然參考 Legado，但以下內容不應預設視為本專案待補功能：

- RSS
- 漫畫閱讀
- WebDAV
- 字典
- Mobi / PDF 等額外本地格式
- 完整 Android 原版 Legado 的所有 UI / 動畫 / 設定項

如果要新增這類功能，應視為新需求，而不是「補齊缺失」。

## 技術架構

### UI 與狀態管理

- Flutter Material App
- `provider` 作為主要狀態管理
- 部分模組透過 `event_bus` 做事件溝通

### 資料與持久化

- `drift` + SQLite
- `shared_preferences` 儲存使用者偏好
- 本地檔案系統用於封面、章節內容、快取與備份

### 網路與解析

- `dio`、`cookie_jar`、`dio_cookie_manager`
- HTML / CSS / XPath / JSONPath / Regex / JavaScript 規則解析
- `flutter_js` 用於部分 JS 規則相容能力
- `webview_flutter` 處理需要互動登入或驗證的書源流程

### 閱讀器與媒體

- 自製 Reader V2 排版、渲染、viewport 與 runtime
- `flutter_tts`、`audio_service`、`just_audio` 提供朗讀相關能力

## 專案結構

```text
.
├── lib/
│   ├── core/                  # 核心模型、資料庫、規則引擎、服務、工具
│   ├── features/              # 各功能模組
│   │   ├── bookshelf/         # 書架
│   │   ├── book_detail/       # 書籍詳情
│   │   ├── browser/           # 書源驗證 / WebView 流程
│   │   ├── explore/           # 探索
│   │   ├── reader_v2/         # 閱讀器主流程
│   │   ├── search/            # 搜尋
│   │   ├── settings/          # 設定
│   │   └── source_manager/    # 書源管理
│   ├── app_providers.dart
│   └── main.dart
├── test/                      # 單元測試、Widget 測試、重點回歸測試
├── docs/                      # 專案架構與模組導覽文件
├── assets/                    # 預設資源、預設書源、opencc 資料
└── .github/workflows/         # CI / release workflow
```

## 開發環境需求

建議環境：

- Flutter `3.41.6`
- Dart SDK `^3.7.0`
- Java `17`
- Android SDK 與可用裝置 / 模擬器

`pubspec.yaml` 目前版本：

- App version: `0.2.57+72`

## 快速開始

### 1. 安裝依賴

```bash
flutter pub get
```

### 2. 啟動專案

```bash
flutter run
```

如果要指定裝置：

```bash
flutter devices
flutter run -d <device-id>
```

### 3. 靜態分析

```bash
flutter analyze
```

## 測試

執行全部測試：

```bash
flutter test
```

執行重點閱讀器與書源管理測試：

```bash
flutter analyze lib/features/reader_v2 lib/features/source_manager test/features/reader_v2 test/features/source_manager
flutter test test/features/reader_v2 \
  test/features/source_manager/source_manager_provider_test.dart \
  test/features/source_manager/source_manager_page_smoke_test.dart \
  test/features/source_manager/source_login_test.dart
```

## Release 流程

Android release 由 GitHub Actions workflow `.github/workflows/android-release.yml` 處理。

### 觸發方式

- 推送符合 `v*` 的 tag
- 手動執行 `workflow_dispatch`

### 標準發布流程

```bash
flutter pub get
flutter analyze lib/features/reader_v2 lib/features/source_manager test/features/reader_v2 test/features/source_manager
flutter test test/features/reader_v2 \
  test/features/source_manager/source_manager_provider_test.dart \
  test/features/source_manager/source_manager_page_smoke_test.dart \
  test/features/source_manager/source_login_test.dart
git push origin HEAD
git tag vX.Y.Z
git push origin vX.Y.Z
```

### 發布規則

- 如果需要改版號，先更新 `pubspec.yaml`
- 先推送 branch / commit，再建立與推送 release tag
- 不要替尚未推送的本地 commit 建立 tag
- tag 推上去後，要確認 GitHub Actions 的 `Android Release` workflow 已經開始執行
- 看到遠端 workflow 已進入建置階段後，可以結束本次 release 任務，不必等待整個 build 完成

### Release workflow 目前會做的事

- checkout 原始碼
- 安裝 Java 17
- 安裝 Flutter `3.41.6`
- `flutter pub get`
- 執行關鍵 analyze / test
- 解出 Android release keystore
- 建置 `arm64-v8a` release APK
- 驗證 manifest
- 發佈 GitHub Release 與 APK 附件

## 重要相依套件

以下是這個專案中幾個關鍵依賴：

- `provider`
- `dio`
- `drift`
- `flutter_js`
- `webview_flutter`
- `flutter_tts`
- `audio_service`
- `just_audio`
- `cached_network_image`
- `shared_preferences`
- `workmanager`

完整依賴請參考 [pubspec.yaml](/home/benny/projects/reader/pubspec.yaml)。

## 文件

`docs/` 目錄包含較完整的模組導覽與設計地圖，適合在修改功能前先閱讀。重點文件包括：

- `docs/inkpage_reader_legado_index.md`
- `docs/inkpage_reader_legado_main_workflow.md`
- `docs/inkpage_reader_legado/reader_v2.md`
- `docs/inkpage_reader_legado/source_management_and_browser.md`
- `docs/inkpage_reader_legado/local_books_downloads_and_cache.md`
- `docs/inkpage_reader_legado/settings_backup_and_release.md`

## 開發注意事項

- 這是小說閱讀器，不要把 Legado 的其他產品線功能直接帶進來
- 書源、閱讀器、下載、快取與備份彼此有關聯，修改其中一塊通常要檢查其他流程
- Reader V2 與 Source Manager 是 release 的重點回歸區域
- 書源驗證流程涉及 WebView、Cookie 與實際網站互動，容易出現只有真機或真實網站才會發生的問題

## 參考專案

- Legado: <https://github.com/gedoor/legado>

## 授權

目前倉庫內未提供明確授權條款。若要對外散佈、商用或再利用，請先由專案擁有者補上正式 license。
