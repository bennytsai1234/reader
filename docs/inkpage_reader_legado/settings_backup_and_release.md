# 設定、備份與發布

## 目前責任

- 管理 app 設定、閱讀設定、主題、TTS、資料隱私、備份還原、版本資訊、log/crash 顯示與 Android release workflow。

## 範圍

- Settings UI/provider：`lib/features/settings/`。
- Shared settings base：`lib/features/settings/provider/settings_base.dart`。
- Backup/restore/version/log：`BackupService`、`RestoreService`、`AppVersion`、`AppLogService`、`CrashHandler`。
- Release：`.github/workflows/android-release.yml`、`pubspec.yaml` version metadata。
- 測試：`test/features/settings/`、`test/backup_service_test.dart`。

## 依賴與影響

- 依賴 `SharedPreferences`、database DAOs、archive zip、package info、filesystem、TTSService、reader settings 與 GitHub Actions。
- 下游影響 app 啟動、Reader V2 設定、備份資料相容、release APK 產出與使用者資料安全。
- 備份欄位依目前 database/model 決定，不應包含未支援 Legado 功能。

## 關鍵流程

- `SettingsProvider` 載入與保存 preference，並同步部分值到 `AppConfig`。
- 設定頁提供閱讀、TTS、資料隱私、備份與其他設定入口。
- `BackupService` 匯出 manifest、主要 database tables 與 SharedPreferences，打包成 ZIP。
- Release workflow 在 `v*` tag 或手動觸發時，安裝 Flutter、跑重點 analyze/test、解 keystore、build arm64 APK、驗證 manifest 並發布 GitHub release。

## 常見修改起點

- 設定值新增或讀寫錯誤：先看 `SettingsProvider` 與 `settings_base.dart`。
- 閱讀設定與 Reader V2 不同步：先看 Reader V2 settings repository/controller 與 settings provider。
- TTS 設定：先看 `TTSService`、`tts_settings_page.dart` 與 Reader V2 TTS controller。
- 備份欄位：先看 `BackupService`、`RestoreService` 與相關 DAO/model。
- 發布流程：先看 `.github/workflows/android-release.yml` 與 `pubspec.yaml`。

## 修改路線

- 新增 preference 時，同步 key、default value、UI、load/save、備份與測試。
- 改備份格式時，同步 restore、manifest/schema version 與舊備份相容策略。
- 改 release workflow 時，確認 tag trigger、Flutter version、critical checks、keystore env 與 APK asset naming。

## 已知風險

- SettingsProvider 包含大量從 Legado 對應而來的設定欄位，其中部分可能尚未完整接到 UI 或 runtime。
- 備份 manifest 用 database schema version，schema migration 不完整時會影響還原可信度。
- Release workflow 依 GitHub secrets 解 keystore，本地無法完整驗證簽名流程。

## 參考備註

- Legado 對應區域是 `help/config`、`help/storage/Backup.kt`、閱讀設定 dialogs 與 TTS/read aloud service。
- 只參考與本專案現有設定、閱讀、TTS、備份相符的概念，不新增 WebDAV、自動備份或完整 Legado 設定面。

## 不要做

- 不要新增設定值卻不接 load/save/default。
- 不要改 release tag 流程時跳過「先推 branch 再推 tag」規則。
- 不要把 Legado 備份中的 RSS、字典、WebDAV 等未支援資料當成本專案必要欄位。
