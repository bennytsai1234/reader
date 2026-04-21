# Inkpage Reader

Inkpage 是一個以 Flutter 實作的中文小說閱讀器。這個 repo 的真實範圍是：

- 書架、書籍詳情、搜尋、發現、書源管理、閱讀器、設定
- 本地書匯入、備份還原、下載任務、TTS 與閱讀輔助
- Legado 風格的書源能力，但以 Flutter / Dart 結構維護，而不是搬運 Android Runtime

這份 README 只描述目前 `main` 分支的真實狀態，不保留舊規劃稿或歷史 handoff。

## 當前狀態

- 應用版本：`0.2.16+31`
- 發版 tag：`v0.2.16`
- Dart SDK：`^3.7.0`
- Flutter：`stable` channel
- 資料庫 schema：`8`
- 主要 CI：
  - `.github/workflows/dart.yml`
  - `.github/workflows/build-release.yml`

## 現有功能範圍

### 產品功能

- 書架與書籍分組
- 全域搜尋、單一書源搜尋、發現頁
- 書籍詳情、章節列表、換源
- 閱讀器：`slide` / `scroll`
- 閱讀進度保存與還原
- TTS、自動翻頁、亮度與主題設定
- TXT / EPUB / UMD 匯入
- 備份還原與下載任務

### 不在這個 repo 的產品目標內

- RSS 閱讀器
- Android-only 工具頁複製
- 額外閱讀模式實驗場
- 只為了像 Legado 而新增的非必要功能

## 程式結構

```text
lib/
  core/
    database/   Drift, DAO, migration
    engine/     書源解析、JS bridge、HTML/JSON/XPath 規則引擎
    models/     書籍、章節、書源、書籤等核心模型
    services/   TTS、儲存、下載、書源服務
  features/
    bookshelf/  書架
    book_detail/書籍詳情與換源入口
    explore/    發現頁
    search/     搜尋
    reader/     閱讀器 UI、runtime、engine、provider facade
    source_manager/ 書源管理
    settings/   設定
  shared/
    theme/      主題
    widgets/    共用元件
docs/
  只保留和目前 main 對得上的文檔
test/
  feature tests、runtime tests、engine tests
release-notes/
  每次 tag/release 的附加說明
```

## 閱讀器真實入口

- Provider 入口：`lib/features/reader/reader_provider.dart`
- 頁面殼：`lib/features/reader/reader_page.dart`
- 主控制器：`lib/features/reader/runtime/read_book_controller.dart`
- View 執行層：`lib/features/reader/view/read_view_runtime.dart`

閱讀器已經不是單一大 controller。它目前拆成：

- session / progress / restore
- content lifecycle / preload / pagination
- viewport runtime / lifecycle / execution bridge
- source switch runtime
- TTS / auto-page / display coordinator

細節請看 [docs/reader_runtime.md](docs/reader_runtime.md)。

## 開發環境

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
tool/flutter_test_with_quickjs.sh
```

如果修改了 Drift 相關檔案，必須重新生成程式碼：

- `lib/core/database/tables/`
- `lib/core/database/app_database.dart`
- `lib/core/database/dao/`

## Reader 相關驗證基線

```bash
flutter analyze
tool/flutter_test_with_quickjs.sh
flutter test test/features/reader
```

若只改閱讀器核心，也至少要跑：

```bash
flutter test test/features/reader
```

## 發版方式

Release 由 tag 觸發。

1. 確認 `main` 乾淨
2. 準備 `release-notes/vX.Y.Z.md`，沒有也可以，workflow 會退回 auto notes
3. 推送 tag：`git tag vX.Y.Z && git push origin vX.Y.Z`
4. `Build Release Artifacts` workflow 會：
   - 以 tag 版本同步 `pubspec.yaml` 回寫到 `main`
   - 建 Android split APK
   - 建 iOS unsigned IPA
   - 發佈 GitHub Release

完整流程見 [docs/release.md](docs/release.md)。

## 文檔

- [docs/README.md](docs/README.md) — 文檔索引
- [docs/architecture.md](docs/architecture.md) — repo 現況與模組邊界
- [docs/reader_runtime.md](docs/reader_runtime.md) — 閱讀器 runtime 真實結構
- [docs/reader_spec.md](docs/reader_spec.md) — 閱讀器目前可驗證的功能規格
- [docs/DATABASE.md](docs/DATABASE.md) — Drift schema 與資料表分工
- [docs/release.md](docs/release.md) — CI / tag / release 流程

## 內容與授權聲明

本專案只提供閱讀器程式本體，不提供書籍內容或任何站點資料。

- 授權：Apache License 2.0
- Release：<https://github.com/bennytsai1234/reader/releases>
- 問題回報：<https://github.com/bennytsai1234/reader/issues>
