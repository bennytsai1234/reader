# 貢獻指南

這份文件只描述目前 `main` 的實際開發方式。

## 先讀哪些文件

- [README.md](README.md)
- [docs/architecture.md](docs/architecture.md)
- 如果要改閱讀器：
  - [docs/reader_runtime.md](docs/reader_runtime.md)
  - [docs/reader_spec.md](docs/reader_spec.md)

## 環境需求

- Flutter `stable`
- Dart `^3.7.0`
- 可運行 `flutter analyze`
- Linux / macOS / Windows 任一可用 Flutter 開發環境

## 本地初始化

```bash
git clone https://github.com/<your-username>/reader.git
cd reader
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
tool/flutter_test_with_quickjs.sh
```

## 變更前後的最低驗證

### 一般功能

```bash
flutter analyze
tool/flutter_test_with_quickjs.sh
```

### 只改閱讀器

```bash
flutter analyze
flutter test test/features/reader
```

### 改 Drift schema / DAO

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter analyze
tool/flutter_test_with_quickjs.sh
```

## 提交原則

- 一個 commit / PR 只解一個主問題
- 如果改了行為，就補對應測試
- 如果改了可見規格，就同步更新文件
- 如果某份文件已經不可靠，直接刪掉或重寫，不要繼續堆 handoff / backlog / TODO 文檔

## 文件規則

這個 repo 的文檔有一條硬規則：

- 文件只能描述 `main` 上已存在、可被程式碼驗證的事實

因此：

- 不保留過期 roadmap
- 不保留舊 handoff
- 不保留沒有落地的設計稿
- 不用文檔替代待辦清單

如果你改了以下內容，請同步更新文件：

- repo 模組邊界：`docs/architecture.md`
- 閱讀器 runtime / contract：`docs/reader_runtime.md`
- 閱讀器功能規格：`docs/reader_spec.md`
- 釋出流程：`docs/release.md`
- 資料表與 migration：`docs/DATABASE.md`

## 程式碼規則

- 狀態管理維持 Provider 鏈，不引入第二套全域狀態框架
- 資料庫經由 DAO / Drift，不直接在 UI 層拼 SQL
- 閱讀器位置語義以 `ReaderLocation(chapterIndex, charOffset)` 為 durable 真源
- 修改閱讀器時，優先沿用現有 runtime / coordinator / facade 邊界，不回退成大混雜 controller

## 發版相關

Release 不是手動編 `pubspec.yaml` 後直接上傳產物。

目前真實流程是：

1. `main` 上完成改動
2. 撰寫 `release-notes/vX.Y.Z.md`（可選，但建議）
3. 推送 tag `vX.Y.Z`
4. `build-release.yml` 會回寫 `pubspec.yaml` 版本到 `main` 並產生 release artifacts

完整規則見 [docs/release.md](docs/release.md)。
